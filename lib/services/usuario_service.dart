import 'package:connectivity_plus/connectivity_plus.dart';
import '../supabase_config.dart';
import '../models/usuario.dart';
import 'auth_service.dart';
import 'offline_service.dart';

class UsuarioService {
  static Future<bool> _offline() async {
    final c = await Connectivity().checkConnectivity();
    return c.contains(ConnectivityResult.none);
  }

  // ── Listar ────────────────────────────────────────────────
  static Future<List<Usuario>> listar() async {
    if (await _offline()) return _listarLocal();
    try {
      final data  = await supabase.from('profiles').select().order('nome');
      final lista = (data as List).map((e) => Usuario.fromJson(e)).toList();
      await OfflineService.salvarProfiles(
        lista.map((u) => {
          'id':            u.id,
          'nome':          u.nome,
          'email':         u.email,
          'perfil':        u.perfil,
          'especialidade': u.especialidade,
          'ativo':         u.ativo ? 1 : 0,
        }).toList(),
      );
      return lista;
    } catch (_) {
      return _listarLocal();
    }
  }

  static Future<List<Usuario>> _listarLocal() async {
    final local = await OfflineService.getProfiles();
    return local.map((m) => Usuario(
          id:            m['id']    as String,
          nome:          m['nome']  as String,
          email:         m['email'] as String? ?? '',
          perfil:        m['perfil'] as String? ?? 'tecnico',
          especialidade: m['especialidade'] as String?,
          ativo:         (m['ativo'] as int? ?? 1) == 1,
        )).toList();
  }

  // ── Criar usuário via Edge Function ───────────────────────
  // Usa service_role no servidor — email já confirmado, sem precisar de e-mail
  static Future<void> criarUsuario({
    required String email,
    required String senha,
    required String nome,
    required String perfil,
    String? especialidade,
  }) async {
    if (await _offline()) {
      throw Exception('Sem conexão com a internet.\nConecte-se para criar usuários.');
    }

    final res = await supabase.functions.invoke(
      'criar-usuario',
      body: {
        'email':         email,
        'senha':         senha,
        'nome':          nome,
        'perfil':        perfil,
        'especialidade': especialidade,
      },
    );

    final data = res.data as Map<String, dynamic>?;

    if (res.status != 200) {
      final msg = data?['error'] as String? ?? 'Erro ao criar usuário';
      throw Exception(msg);
    }

    // Salva no cache local imediatamente
    await OfflineService.salvarProfiles([{
      'id':            data?['id'],
      'nome':          nome,
      'email':         email,
      'perfil':        perfil,
      'especialidade': especialidade,
      'ativo':         1,
    }]);
  }

  // ── Deletar usuário via Edge Function (só admin) ─────────
  static Future<void> deletarUsuario(String usuarioId) async {
    if (await _offline()) {
      throw Exception('Sem conexão com a internet.\nConecte-se para deletar usuários.');
    }

    final res = await supabase.functions.invoke(
      'deletar-usuario',
      body: {'usuario_id': usuarioId},
    );

    final data = res.data as Map<String, dynamic>?;

    if (res.status != 200) {
      final msg = data?['error'] as String? ?? 'Erro ao deletar usuário';
      throw Exception(msg);
    }

    await OfflineService.deletarProfile(usuarioId);
  }

  // ── Resetar senha via Edge Function (só admin) ────────────
  static Future<void> resetarSenha(String usuarioId, String novaSenha) async {
    if (await _offline()) {
      throw Exception('Sem conexão com a internet.\nConecte-se para resetar senhas.');
    }

    final res = await supabase.functions.invoke(
      'resetar-senha',
      body: {'usuario_id': usuarioId, 'nova_senha': novaSenha},
    );

    final data = res.data as Map<String, dynamic>?;

    if (res.status != 200) {
      final msg = data?['error'] as String? ?? 'Erro ao resetar senha';
      throw Exception(msg);
    }
  }

  // ── Atualizar perfil ──────────────────────────────────────
  static Future<void> atualizarPerfil(String id, Map<String, dynamic> dados) async {
    await OfflineService.salvarProfiles([{
      'id': id, ...dados,
      if (!dados.containsKey('ativo')) 'ativo': 1,
    }]);
    try {
      await supabase.from('profiles').update(dados).eq('id', id);
    } catch (_) {
      await OfflineService.adicionarFila('profiles', 'UPDATE', id, dados);
    }
  }

  // ── Desativar / Ativar (soft delete) ─────────────────────
  static Future<void> desativar(String id) async {
    if (await _offline()) throw Exception('internet_necessaria');
    final self = AuthService.currentAuthUser?.id;
    if (self == id) throw Exception('Não é possível desativar seu próprio usuário');
    await supabase.from('profiles').update({'ativo': false}).eq('id', id);
    await OfflineService.atualizarAtivoProfile(id, 0);
  }

  static Future<void> ativar(String id) async {
    if (await _offline()) throw Exception('internet_necessaria');
    await supabase.from('profiles').update({'ativo': true}).eq('id', id);
    await OfflineService.atualizarAtivoProfile(id, 1);
  }
}
