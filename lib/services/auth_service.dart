import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/usuario.dart';
import 'offline_service.dart';

// ── Chaves "último usuário ativo" (para auto-bypass no _AuthGate) ──
const _kEmail     = 'offline_email';
const _kUserId    = 'offline_user_id';
const _kNome      = 'offline_nome';
const _kPerfil    = 'offline_perfil';
const _kDeslogado = 'offline_deslogado';

// ── Mapa de contas offline ─────────────────────────────────────────
// JSON: { "email": { "hash": "...", "userId": "...", "nome": "...", "perfil": "...", "ts": 12345 } }
const _kMapContas = 'offline_accounts_map';
const _kMaxContas = 10;

// ── Chave legada (hash único do último usuário — migração) ─────────
const _kLegacyHash = 'offline_pw_hash';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: false),
);

class AuthService {
  // ─── Login ────────────────────────────────────────────────
  static Future<_LoginResult> login(String email, String password) async {
    final conn    = await Connectivity().checkConnectivity();
    final offline = conn.contains(ConnectivityResult.none);

    if (offline) return _tentarLoginOffline(email.trim(), password);

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email.trim(), password: password,
      );
      if (res.user != null) {
        await _salvarCredenciaisOffline(email.trim(), password, res.user!.id);
        return _LoginResult(user: res.user, offline: false);
      }
      throw Exception('Login retornou usuário nulo');
    } on AuthException catch (e) {
      final isCredentialError = e.statusCode == '400' ||
          e.message.contains('Invalid login') ||
          e.message.contains('Email not confirmed') ||
          e.message.contains('invalid');
      if (isCredentialError) rethrow;
      return _tentarLoginOffline(email.trim(), password);
    } catch (e) {
      return _tentarLoginOffline(email.trim(), password);
    }
  }

  // ── Salva conta no mapa e atualiza "último ativo" ─────────────
  static Future<void> _salvarCredenciaisOffline(
      String email, String password, String userId) async {
    final hash = _hashSenha(password);

    // 1. Atualiza globals do último usuário ativo
    try {
      await _storage.write(key: _kEmail,  value: email);
      await _storage.write(key: _kUserId, value: userId);
      await _storage.delete(key: _kDeslogado);
    } catch (e) {
      debugPrint('[Auth] ERRO ao salvar globals: $e');
    }

    // 2. Adiciona/atualiza entrada no mapa (sem nome/perfil ainda)
    await _atualizarMapaContas(email, hash, userId);

    // 3. Busca nome/perfil no Supabase e complementa a entrada
    try {
      final profile = await supabase
          .from('profiles').select().eq('id', userId).maybeSingle();
      if (profile != null) {
        final nome   = profile['nome']   as String? ?? email;
        final perfil = profile['perfil'] as String? ?? 'tecnico';
        await _storage.write(key: _kNome,   value: nome);
        await _storage.write(key: _kPerfil, value: perfil);
        await _atualizarMapaContas(email, hash, userId, nome: nome, perfil: perfil);
      }
    } catch (_) {}
  }

  // ── Adiciona/atualiza entrada no mapa de contas (LRU, limite 10) ─
  static Future<void> _atualizarMapaContas(
      String email, String hash, String userId,
      {String? nome, String? perfil}) async {
    try {
      final raw = await _storage.read(key: _kMapContas) ?? '{}';
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);

      // Mescla com dados existentes para não apagar nome/perfil já salvos
      final existente = map[email] as Map<String, dynamic>? ?? {};
      map[email] = {
        ...existente,
        'hash':   hash,
        'userId': userId,
        'ts':     DateTime.now().millisecondsSinceEpoch,
        if (nome   != null) 'nome':   nome,
        if (perfil != null) 'perfil': perfil,
      };

      // Limite de _kMaxContas: remove a entrada com menor timestamp (mais antiga)
      if (map.length > _kMaxContas) {
        final mais_antiga = map.entries.reduce((a, b) {
          final ta = ((a.value as Map)['ts'] as int?) ?? 0;
          final tb = ((b.value as Map)['ts'] as int?) ?? 0;
          return ta <= tb ? a : b;
        });
        map.remove(mais_antiga.key);
        debugPrint('[Auth] Limite $_kMaxContas contas atingido — removeu: ${mais_antiga.key}');
      }

      await _storage.write(key: _kMapContas, value: jsonEncode(map));
      debugPrint('[Auth] Mapa atualizado — contas salvas: ${map.length}');
    } catch (e) {
      debugPrint('[Auth] ERRO ao atualizar mapa de contas: $e');
    }
  }

  // ── Login offline: busca email no mapa ───────────────────────
  static Future<_LoginResult> _tentarLoginOffline(
      String email, String password) async {
    final hashDigitado = _hashSenha(password);

    // 1. Tenta no mapa de contas (novo sistema)
    Map<String, dynamic>? entry;
    try {
      final raw = await _storage.read(key: _kMapContas) ?? '{}';
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      entry = map[email] as Map<String, dynamic>?;
    } catch (_) {
      // Mapa ilegível — ignora e tenta fallback legado
    }

    if (entry != null) {
      final storedHash = entry['hash'] as String?;
      if (storedHash == null || storedHash != hashDigitado) {
        throw Exception('Senha incorreta para acesso offline.');
      }

      final userId = entry['userId'] as String;
      final nome   = entry['nome']   as String?;
      final perfil = entry['perfil'] as String?;

      // Atualiza globals do último ativo
      await _storage.write(key: _kEmail,  value: email);
      await _storage.write(key: _kUserId, value: userId);
      if (nome   != null) await _storage.write(key: _kNome,   value: nome);
      if (perfil != null) await _storage.write(key: _kPerfil, value: perfil);
      await _storage.delete(key: _kDeslogado);

      // Atualiza timestamp (marca como mais recente para o LRU)
      try {
        final raw2 = await _storage.read(key: _kMapContas) ?? '{}';
        final map2 = Map<String, dynamic>.from(jsonDecode(raw2) as Map);
        if (map2.containsKey(email)) {
          (map2[email] as Map)['ts'] = DateTime.now().millisecondsSinceEpoch;
          await _storage.write(key: _kMapContas, value: jsonEncode(map2));
        }
      } catch (_) {}

      debugPrint('[Auth] Login offline OK — email: $email');
      return _LoginResult(user: null, offline: true, userId: userId);
    }

    // 2. Fallback legado: sistema anterior usava _kEmail + _kLegacyHash
    //    (migração automática para o novo mapa na próxima vez que entrar online)
    final legacyEmail = await _storage.read(key: _kEmail);
    final legacyHash  = await _storage.read(key: _kLegacyHash);
    final legacyId    = await _storage.read(key: _kUserId);

    if (legacyEmail != null && legacyId != null && legacyHash != null &&
        legacyEmail.toLowerCase() == email.toLowerCase()) {
      if (legacyHash != hashDigitado) {
        throw Exception('Senha incorreta para acesso offline.');
      }
      await _storage.delete(key: _kDeslogado);
      debugPrint('[Auth] Login offline via credencial legada — email: $email');
      return _LoginResult(user: null, offline: true, userId: legacyId);
    }

    // 3. Conta não encontrada em nenhum sistema
    throw Exception(
        'Conta não registrada offline neste dispositivo.\n'
        'Faça login com internet ao menos uma vez.');
  }

  static String _hashSenha(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  // ─── Sessão salva ─────────────────────────────────────────
  static Future<bool> temCredenciaisOffline() async {
    final email = await _storage.read(key: _kEmail);
    return email != null;
  }

  static Future<bool> foiDeslogado() async {
    final v = await _storage.read(key: _kDeslogado);
    return v == 'true';
  }

  static Future<String?> emailOffline()  => _storage.read(key: _kEmail);
  static Future<String?> nomeOffline()   => _storage.read(key: _kNome);
  static Future<String?> perfilOffline() => _storage.read(key: _kPerfil);
  static Future<String?> userIdOffline() => _storage.read(key: _kUserId);

  // ─── Logout ───────────────────────────────────────────────
  static Future<void> logout() async {
    try { await supabase.auth.signOut(); } catch (_) {}
    // Marca deslogado — NÃO apaga o mapa de contas offline
    // Todos os usuários cadastrados continuam disponíveis para login offline
    await _storage.write(key: _kDeslogado, value: 'true');
  }

  // ─── Getters ──────────────────────────────────────────────
  static User? get currentAuthUser => supabase.auth.currentUser;
  static bool  get isLoggedIn      => supabase.auth.currentUser != null;

  static Future<bool> _offline() async {
    final c = await Connectivity().checkConnectivity();
    return c.contains(ConnectivityResult.none);
  }

  // ─── Perfil ───────────────────────────────────────────────
  static Future<Usuario?> getProfile() async {
    final user = currentAuthUser;
    final id   = user?.id ?? await userIdOffline();
    if (id == null) return null;

    if (await _offline()) return _perfilLocal(id, user);

    try {
      final data = await supabase.from('profiles').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      final profileEmail  = data['email'] as String?;
      final resolvedEmail = (profileEmail != null && profileEmail.isNotEmpty)
          ? profileEmail
          : (user?.email ?? await emailOffline() ?? '');
      return Usuario.fromJson({...data, 'email': resolvedEmail});
    } catch (_) {
      return _perfilLocal(id, user);
    }
  }

  // Busca perfil offline na ordem: SQLite → mapa de contas → globals
  static Future<Usuario?> _perfilLocal(String id, User? user) async {
    // 1. SQLite por ID — fonte mais confiável, funciona para qualquer usuário cacheado
    try {
      final row = await OfflineService.getProfileById(id);
      if (row != null) {
        return Usuario(
          id: id,
          nome:   row['nome']   as String,
          email:  row['email']  as String? ?? user?.email ?? await emailOffline() ?? '',
          perfil: row['perfil'] as String? ?? 'tecnico',
          especialidade: row['especialidade'] as String?,
          ativo: (row['ativo'] as int? ?? 1) == 1,
        );
      }
    } catch (_) {}

    // 2. Mapa de contas offline — usa o email de quem está logado agora,
    //    não o global "_kNome" que pode ser do último usuário online diferente
    final email = user?.email ?? await emailOffline();
    if (email != null) {
      try {
        final raw   = await _storage.read(key: _kMapContas) ?? '{}';
        final map   = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final entry = map[email] as Map<String, dynamic>?;
        if (entry != null) {
          final nome   = entry['nome']   as String?;
          final perfil = entry['perfil'] as String?;
          if (nome != null && nome.isNotEmpty) {
            return Usuario(
              id: id,
              nome:   nome,
              email:  email,
              perfil: perfil ?? 'tecnico',
            );
          }
        }
      } catch (_) {}
    }

    // 3. Fallback final: globals (última linha de defesa)
    final nome   = await nomeOffline();
    final perfil = await perfilOffline();
    if (nome == null) return null;
    return Usuario(
      id: id,
      nome:   nome,
      email:  email ?? user?.email ?? '',
      perfil: perfil ?? 'tecnico',
    );
  }

  // ─── Técnicos ─────────────────────────────────────────────
  static Future<List<Usuario>> listarTecnicos() async {
    if (await _offline()) return _tecnicosLocal();
    try {
      final data  = await supabase.from('profiles').select()
          .eq('ativo', true).eq('perfil', 'tecnico').order('nome');
      final lista = (data as List).map((e) => Usuario.fromJson(e)).toList();
      await OfflineService.salvarProfiles(
        lista.map((u) => {
          'id': u.id, 'nome': u.nome, 'perfil': u.perfil,
          'especialidade': u.especialidade, 'ativo': u.ativo ? 1 : 0,
        }).toList(),
      );
      return lista;
    } catch (_) {
      return _tecnicosLocal();
    }
  }

  static Future<List<Usuario>> _tecnicosLocal() async {
    final local = await OfflineService.getProfiles();
    return local
        .where((m) => m['perfil'] == 'tecnico')
        .map((m) => Usuario(
              id: m['id'] as String,
              nome: m['nome'] as String,
              email: m['email'] as String? ?? '',
              perfil: 'tecnico',
              especialidade: m['especialidade'] as String?,
              ativo: (m['ativo'] as int? ?? 1) == 1,
            ))
        .toList();
  }

  static Future<void> updateProfile(Map<String, dynamic> dados) async {
    final user = currentAuthUser;
    if (user == null) return;
    await supabase.from('profiles').update(dados).eq('id', user.id);
  }
}

class _LoginResult {
  final User? user;
  final bool offline;
  final String? userId;
  const _LoginResult({required this.user, required this.offline, this.userId});
}
