import 'package:connectivity_plus/connectivity_plus.dart';
import '../supabase_config.dart';
import '../models/notificacao.dart';
import 'auth_service.dart';
import 'offline_service.dart';

class NotificacaoService {
  static Future<bool> _offline() async {
    final c = await Connectivity().checkConnectivity();
    return c.contains(ConnectivityResult.none);
  }

  static Future<List<Notificacao>> listar() async {
    // Funciona tanto com sessão Supabase (online) quanto com login offline
    final userId = AuthService.currentAuthUser?.id ?? await AuthService.userIdOffline();
    if (userId == null) return [];

    if (await _offline()) return _listarLocal(userId);

    try {
      final data = await supabase
          .from('notificacao')
          .select()
          .eq('usuario_id', userId)
          .order('criado_em', ascending: false)
          .limit(50);
      final lista = (data as List).cast<Map<String, dynamic>>();
      await OfflineService.salvarNotificacoes(lista);
      return lista.map((e) => Notificacao.fromJson(e)).toList();
    } catch (_) {
      return _listarLocal(userId);
    }
  }

  static Future<List<Notificacao>> _listarLocal(String usuarioId) async {
    final local = await OfflineService.getNotificacoes(usuarioId);
    return local.map((m) => Notificacao(
          id:        m['id'] as String,
          usuarioId: m['usuario_id'] as String,
          osId:      m['os_id'] as String?,
          mensagem:  m['mensagem'] as String,
          tipo:      m['tipo'] as String? ?? 'info',
          lida:      (m['lida'] as int? ?? 0) == 1,
          criadoEm:  DateTime.tryParse(m['criado_em'] as String? ?? '') ?? DateTime.now(),
        )).toList();
  }

  static Future<int> contarNaoLidas() async {
    final userId = AuthService.currentAuthUser?.id ?? await AuthService.userIdOffline();
    if (userId == null) return 0;

    if (await _offline()) return OfflineService.contarNaoLidasLocal(userId);

    try {
      final data = await supabase
          .from('notificacao')
          .select('id')
          .eq('usuario_id', userId)
          .eq('lida', false);
      return (data as List).length;
    } catch (_) {
      return OfflineService.contarNaoLidasLocal(userId);
    }
  }

  static Future<void> marcarLida(String id) async {
    await OfflineService.marcarNotificacaoLidaLocal(id);
    try {
      await supabase.from('notificacao').update({'lida': true}).eq('id', id);
    } catch (_) {
      // Entra na fila de sync — será enviado ao Supabase quando voltar online
      await OfflineService.adicionarFila('notificacao', 'UPDATE', id, {'lida': true});
    }
  }

  static Future<void> marcarTodasLidas() async {
    final userId = AuthService.currentAuthUser?.id ?? await AuthService.userIdOffline();
    if (userId == null) return;
    await OfflineService.marcarTodasLidasLocal(userId);
    try {
      await supabase
          .from('notificacao')
          .update({'lida': true})
          .eq('usuario_id', userId)
          .eq('lida', false);
    } catch (_) {
      final naoLidas = await OfflineService.getNotificacoes(userId);
      for (final n in naoLidas) {
        if ((n['lida'] as int? ?? 0) == 0) {
          await OfflineService.adicionarFila(
            'notificacao', 'UPDATE', n['id'] as String, {'lida': true},
          );
        }
      }
    }
  }
}
