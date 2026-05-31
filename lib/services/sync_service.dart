import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../supabase_config.dart';
import 'offline_service.dart';

const _kTaskName = 'tecpoint-sync-15min';
const _kTaskTag  = 'syncBackground';

class SyncService {
  static StreamSubscription? _sub;
  static Timer? _timer;
  static bool _syncing = false;

  static void iniciar() {
    _sub?.cancel();
    _timer?.cancel();

    // Sync imediato ao abrir o app (captura itens pendentes se online)
    isOnline().then((online) {
      if (online && !_syncing) _processarTudo();
    });

    // Sync quando a conexão volta (offline → online)
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online && !_syncing) _processarTudo();
    });

    // Sync periódico a cada 15 min enquanto o app está em foreground
    _timer = Timer.periodic(const Duration(minutes: 15), (_) async {
      if (await isOnline() && !_syncing) _processarTudo();
    });

    // Registra task WorkManager para sync em background (app fechado)
    Workmanager().registerPeriodicTask(
      _kTaskName,
      _kTaskTag,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  static void parar() {
    _sub?.cancel();
    _sub = null;
    _timer?.cancel();
    _timer = null;
  }

  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  static Future<void> sincronizarAgora() async {
    if (await isOnline()) {
      await _processarTudo();
    }
  }

  static Future<void> _processarTudo() async {
    _syncing = true;
    try {
      await _processarFila();
      await _processarFotosPendentes();
    } finally {
      _syncing = false;
    }
  }

  // Mapa: nome da tabela no Supabase → nome da tabela no SQLite local
  static const _localTable = {
    'cliente':       'clientes',
    'equipamento':   'equipamentos',
    'ordem_servico': 'ordens_servico',
  };

  static Future<void> _processarFila() async {
    final pendentes = await OfflineService.getPendentes();
    for (final item in pendentes) {
      try {
        final tabela   = item['tabela']   as String;
        final operacao = item['operacao'] as String;
        final payload  = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final queueId  = item['id']       as int;
        final regId    = item['registro_id'] as String;

        if (operacao == 'INSERT') {
          await _processarInsert(tabela, payload);
        } else if (operacao == 'UPDATE') {
          await _processarUpdate(tabela, regId, payload);
        } else if (operacao == 'UPSERT') {
          await supabase.from(tabela).upsert(payload);
        } else if (operacao == 'DELETE') {
          await supabase.from(tabela).delete().eq('id', regId);
        }

        // Marca synced:1 no SQLite após envio bem-sucedido ao Supabase
        final local = _localTable[tabela];
        if (local != null) {
          await OfflineService.marcarSynced(local, regId);
        }

        await OfflineService.removerDaFila(queueId);
      } catch (_) {
        // Item falhou — mantém na fila para próximo ciclo
      }
    }
  }

  static Future<void> _processarFotosPendentes() async {
    final fotos = await OfflineService.getFotosPendentes();
    for (final foto in fotos) {
      try {
        final osId     = foto['os_id']     as String;
        final filePath = foto['file_path'] as String;
        final arquivo  = File(filePath);

        if (!await arquivo.exists()) {
          await OfflineService.removerFotoPendente(foto['id'] as int);
          continue;
        }

        final nome    = '${osId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final caminho = 'os/$osId/$nome';
        await supabase.storage.from('os-fotos').upload(caminho, arquivo);
        final url = supabase.storage.from('os-fotos').getPublicUrl(caminho);
        await supabase.from('os_foto').insert({
          'os_id': osId,
          'nome_arquivo': nome,
          'caminho': url,
          'tamanho_bytes': await arquivo.length(),
        });
        await OfflineService.removerFotoPendente(foto['id'] as int);
        try { await arquivo.delete(); } catch (_) {}
      } catch (_) {
        // Falhou — mantém na fila para próximo ciclo
      }
    }
  }

  // ── INSERT ────────────────────────────────────────────────
  static Future<void> _processarInsert(String tabela, Map<String, dynamic> payload) async {
    if (tabela == 'ordem_servico') {
      await _syncOrdemServico(payload, isUpdate: false);
    } else {
      final limpo = Map<String, dynamic>.from(payload)
        ..remove('equipamentos_ids')
        ..remove('checklist')
        ..remove('acessorios')
        ..remove('sig_cliente')
        ..remove('sig_tecnico');
      await supabase.from(tabela).upsert(limpo);
    }
  }

  // ── UPDATE ────────────────────────────────────────────────
  static Future<void> _processarUpdate(String tabela, String id, Map<String, dynamic> payload) async {
    if (tabela == 'ordem_servico') {
      await _syncOrdemServico(payload, isUpdate: true, osId: id);
    } else {
      final limpo = Map<String, dynamic>.from(payload)
        ..remove('equipamentos_ids')
        ..remove('checklist')
        ..remove('acessorios')
        ..remove('sig_cliente')
        ..remove('sig_tecnico');
      await supabase.from(tabela).update(limpo).eq('id', id);
    }
  }

  // ── Sincroniza OS + todos os relacionamentos ──────────────
  static Future<void> _syncOrdemServico(
    Map<String, dynamic> payload, {
    required bool isUpdate,
    String? osId,
  }) async {
    final equips     = (payload.remove('equipamentos_ids') as List?)
        ?.map((e) => e as String).toList() ?? [];
    final checklist  = (payload.remove('checklist') as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final acessorios = (payload.remove('acessorios') as List?)
        ?.map((e) => e as String).toList() ?? [];
    final sigCli     = payload.remove('sig_cliente') as String?;
    final sigTec     = payload.remove('sig_tecnico') as String?;

    final id = osId ?? payload['id'] as String;

    // 1. OS principal
    if (isUpdate) {
      await supabase.from('ordem_servico').update(payload).eq('id', id);
    } else {
      await supabase.from('ordem_servico').upsert(payload);
    }

    // 2. Equipamentos (N:N)
    await supabase.from('os_equipamento').delete().eq('os_id', id);
    if (equips.isNotEmpty) {
      await supabase.from('os_equipamento').insert(
        equips.map((eid) => {'os_id': id, 'equipamento_id': eid}).toList(),
      );
    }

    // 3. Checklist (delete + insert — upsert sem id cria duplicatas)
    if (checklist.isNotEmpty) {
      await supabase.from('os_checklist').delete().eq('os_id', id);
      await supabase.from('os_checklist').insert(
        checklist.map((c) => {'os_id': id, ...c}).toList(),
      );
    }

    // 4. Acessórios (recria completo)
    if (acessorios.isNotEmpty) {
      await supabase.from('os_acessorio').delete().eq('os_id', id);
      await supabase.from('os_acessorio').insert(
        acessorios.map((a) => {'os_id': id, 'nome': a}).toList(),
      );
    }

    // 5. Assinaturas
    if (sigCli != null || sigTec != null) {
      await supabase.from('os_assinatura').upsert({
        'os_id': id,
        if (sigCli != null) 'sig_cliente': 'data:image/png;base64,$sigCli',
        if (sigTec != null) 'sig_tecnico': 'data:image/png;base64,$sigTec',
      });
    }
  }
}
