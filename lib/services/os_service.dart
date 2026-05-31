import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../supabase_config.dart';
import '../models/ordem_servico.dart';
import '../models/os_checklist.dart';
import '../models/os_acessorio.dart';
import '../models/os_analise_equipamento.dart';
import '../models/os_testes.dart';
import '../models/os_visita.dart';
import 'offline_service.dart';
import 'auth_service.dart';

class OsService {
  // ── Helper de conectividade ───────────────────────────────
  static Future<bool> _offline() async {
    final c = await Connectivity().checkConnectivity();
    return c.contains(ConnectivityResult.none);
  }

  // ── Listar OS ─────────────────────────────────────────────
  static Future<List<OrdemServico>> listar({
    String? status,
    String? clienteId,
    String? prioridade,
  }) async {
    // Offline-first: SQLite instantâneo se sem internet
    if (await _offline()) return _listarLocal(status: status, clienteId: clienteId, prioridade: prioridade);

    try {
      var query = supabase
          .from('ordem_servico')
          .select('*, cliente(nome), tecnico:profiles!tecnico_id(nome), os_equipamento(equipamento_id)')
          .eq('ativo', true);
      if (status != null)     query = query.eq('status', status);
      if (clienteId != null)  query = query.eq('cliente_id', clienteId);
      if (prioridade != null) query = query.eq('prioridade', prioridade);
      final data  = await query.order('data_entrada', ascending: false);
      final lista = (data as List).map((e) => OrdemServico.fromJson(e)).toList();
      await OfflineService.salvarOS(lista.map((os) => os.toLocal()).toList());
      final equipMap = {for (final os in lista) os.id: os.equipamentosIds};
      await _salvarEquipamentosOsEmLote(equipMap);
      return lista;
    } catch (_) {
      return _listarLocal(status: status, clienteId: clienteId, prioridade: prioridade);
    }
  }

  static Future<List<OrdemServico>> _listarLocal({
    String? status,
    String? clienteId,
    String? prioridade,
  }) async {
    var local = await OfflineService.getOS();
    if (status != null)     local = local.where((m) => m['status'] == status).toList();
    if (clienteId != null)  local = local.where((m) => m['cliente_id'] == clienteId).toList();
    if (prioridade != null) local = local.where((m) => m['prioridade'] == prioridade).toList();
    if (local.isEmpty) return [];
    final osIds      = local.map((m) => m['id'] as String).toList();
    final equipMap   = await OfflineService.getEquipamentosOsMap(osIds);
    final nomesCache = await _profilesNomePorId();
    return local.map((m) {
      final osId = m['id'] as String;
      final row  = _enriquecerTecnico(m, nomesCache);
      return OrdemServico.fromLocal({...row, '_equip_ids': equipMap[osId] ?? const []});
    }).toList();
  }

  // ── Stats (dashboard) ─────────────────────────────────────
  static Future<Map<String, int>> obterStats() async {
    if (await _offline()) return _statsLocal();
    try {
      final results = await Future.wait([
        supabase.from('ordem_servico').select('id').eq('ativo', true),
        supabase.from('ordem_servico').select('id').eq('ativo', true).eq('status', 'Aberto'),
        supabase.from('ordem_servico').select('id').eq('ativo', true).eq('status', 'Em Andamento'),
        supabase.from('ordem_servico').select('id').eq('ativo', true).eq('status', 'Concluído'),
        supabase.from('ordem_servico').select('id').eq('ativo', true).eq('status', 'Cancelado'),
        supabase.from('ordem_servico').select('id').eq('ativo', true).eq('prioridade', 'Urgente'),
      ]);
      return {
        'total':      (results[0] as List).length,
        'abertas':    (results[1] as List).length,
        'andamento':  (results[2] as List).length,
        'concluidas': (results[3] as List).length,
        'canceladas': (results[4] as List).length,
        'urgentes':   (results[5] as List).length,
      };
    } catch (_) {
      return _statsLocal();
    }
  }

  static Future<Map<String, int>> _statsLocal() async {
    try {
      final local = await OfflineService.getOS();
      return {
        'total':      local.length,
        'abertas':    local.where((m) => m['status'] == 'Aberto').length,
        'andamento':  local.where((m) => m['status'] == 'Em Andamento').length,
        'concluidas': local.where((m) => m['status'] == 'Concluído').length,
        'canceladas': local.where((m) => m['status'] == 'Cancelado').length,
        'urgentes':   local.where((m) => m['prioridade'] == 'Urgente').length,
      };
    } catch (_) {
      return {'total': 0, 'abertas': 0, 'andamento': 0, 'concluidas': 0, 'canceladas': 0, 'urgentes': 0};
    }
  }

  // ── Buscar por ID ─────────────────────────────────────────
  static Future<OrdemServico?> buscarPorId(String id) async {
    if (await _offline()) {
      final local  = await OfflineService.getOSById(id);
      if (local == null) return null;
      final equips      = await OfflineService.getEquipamentosOs(id);
      final nomesCache  = await _profilesNomePorId();
      final row         = _enriquecerTecnico(local, nomesCache);
      return OrdemServico.fromLocal({...row, '_equip_ids': equips});
    }
    try {
      final data = await supabase
          .from('ordem_servico')
          .select('*, cliente(nome), tecnico:profiles!tecnico_id(nome), os_equipamento(equipamento_id)')
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return OrdemServico.fromJson(data);
    } catch (_) {
      final local = await OfflineService.getOSById(id);
      if (local == null) return null;
      final equips = await OfflineService.getEquipamentosOs(id);
      return OrdemServico.fromLocal({...local, '_equip_ids': equips});
    }
  }

  // ── Criar OS ──────────────────────────────────────────────
  static Future<OrdemServico> criar(
    Map<String, dynamic> dados,
    List<String> equipamentosIds,
    List<ChecklistItem> checklist,
    List<String> acessorios,
    List<int>? sigClienteBytes,
    List<int>? sigTecnicoBytes, {
    String? preId,
  }) async {
    final id     = preId ?? const Uuid().v4();
    final userId = AuthService.currentAuthUser?.id
        ?? await AuthService.userIdOffline()
        ?? '';
    final agora  = DateTime.now();

    String numeroOs;
    try {
      final res = await supabase.rpc('gerar_numero_os');
      numeroOs = res as String;
    } catch (_) {
      final d = agora;
      numeroOs = 'OS-${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

    final payload = {...dados, 'id': id, 'numero_os': numeroOs, 'criado_por': userId};

    // Resolve nomes do cache SQLite — usados quando Supabase não está disponível
    final clientesCache = await OfflineService.getClientes();
    final clienteNome = clientesCache
        .where((c) => c['id'] == dados['cliente_id'])
        .map((c) => c['nome'] as String?)
        .firstOrNull;

    String? tecnicoNome;
    if (dados['tecnico_id'] != null) {
      final profilesCache = await OfflineService.getProfiles();
      tecnicoNome = profilesCache
          .where((p) => p['id'] == dados['tecnico_id'])
          .map((p) => p['nome'] as String?)
          .firstOrNull;
    }

    final os = OrdemServico(
      id: id,
      numeroOs: numeroOs,
      clienteId: dados['cliente_id'] as String,
      clienteNome: clienteNome,
      tecnicoId: dados['tecnico_id'] as String?,
      tecnicoNome: tecnicoNome,
      status: dados['status'] as String? ?? 'Aberto',
      prioridade: dados['prioridade'] as String? ?? 'Baixa',
      tipoOcorrencia: dados['tipo_ocorrencia'] as String?,
      descricao: dados['descricao'] as String?,
      dataEntrada: DateTime.parse(dados['data_entrada'] as String),
      horaEntrada: dados['hora_entrada'] as String?,
      dataSaida: dados['data_saida'] != null
          ? DateTime.tryParse(dados['data_saida'] as String)
          : null,
      acompanhante: dados['acompanhante'] as String?,
      condicoesFisicas: dados['condicoes_fisicas'] as String?,
      defeito: dados['defeito_relatado'] as String?,
      statusEquipamento: dados['status_equipamento'] as String?,
      laudoTecnico: dados['laudo_tecnico'] as String?,
      solucaoAplicada: dados['solucao_aplicada'] as String?,
      pecasUtilizadas: dados['pecas_utilizadas'] as String?,
      termosObservacoes: dados['termos_observacoes'] as String?,
      geoLat: (dados['geo_lat'] as num?)?.toDouble(),
      geoLng: (dados['geo_lng'] as num?)?.toDouble(),
      geoEndereco: dados['geo_endereco'] as String?,
      criadoPor: userId,
      criadoEm: agora,
      atualizadoEm: agora,
    );

    try {
      await supabase.from('ordem_servico').insert(payload);
      final res = await supabase
          .from('ordem_servico')
          .select('*, cliente(nome), tecnico:profiles!tecnico_id(nome), os_equipamento(equipamento_id)')
          .eq('id', id)
          .single();
      final criada = OrdemServico.fromJson(res);
      await OfflineService.insertOS(criada.toLocal());
      await _salvarRelacionamentos(id, equipamentosIds, checklist, acessorios, sigClienteBytes, sigTecnicoBytes);
      return criada;
    } catch (_) {
      await OfflineService.insertOS(os.toLocal());
      await OfflineService.salvarEquipamentosOs(id, equipamentosIds);
      await OfflineService.salvarChecklistLocal(id, checklist.map((c) => c.toJson(id)).toList());
      await OfflineService.salvarAcessoriosLocal(id, acessorios);
      await OfflineService.salvarAssinaturaLocal(
        id,
        sigClienteBytes != null ? base64Encode(sigClienteBytes) : null,
        sigTecnicoBytes != null ? base64Encode(sigTecnicoBytes) : null,
      );
      await OfflineService.adicionarFila('ordem_servico', 'INSERT', id, {
        ...payload,
        'equipamentos_ids': equipamentosIds,
        'checklist':        checklist.map((c) => c.toJson(id)).toList(),
        'acessorios':       acessorios,
        'sig_cliente':      sigClienteBytes != null ? base64Encode(sigClienteBytes) : null,
        'sig_tecnico':      sigTecnicoBytes != null ? base64Encode(sigTecnicoBytes) : null,
      });
      return os;
    }
  }

  // ── Salvar relacionamentos ────────────────────────────────
  static Future<void> _salvarRelacionamentos(
    String osId,
    List<String> equipamentosIds,
    List<ChecklistItem> checklist,
    List<String> acessorios,
    List<int>? sigClienteBytes,
    List<int>? sigTecnicoBytes,
  ) async {
    await OfflineService.salvarEquipamentosOs(osId, equipamentosIds);
    if (equipamentosIds.isNotEmpty) {
      await supabase.from('os_equipamento').upsert(
        equipamentosIds.map((eid) => {'os_id': osId, 'equipamento_id': eid}).toList(),
      );
    }
    if (checklist.isNotEmpty) {
      await supabase.from('os_checklist').delete().eq('os_id', osId);
      await supabase.from('os_checklist').insert(
        checklist.map((c) => c.toJson(osId)).toList(),
      );
    }
    if (acessorios.isNotEmpty) {
      await supabase.from('os_acessorio').delete().eq('os_id', osId);
      await supabase.from('os_acessorio').insert(
        acessorios.map((a) => {'os_id': osId, 'nome': a}).toList(),
      );
    }
    final sigCli = sigClienteBytes != null ? base64Encode(sigClienteBytes) : null;
    final sigTec = sigTecnicoBytes != null ? base64Encode(sigTecnicoBytes) : null;
    if (sigCli != null || sigTec != null) {
      await supabase.from('os_assinatura').upsert({
        'os_id':       osId,
        'sig_cliente': sigCli != null ? 'data:image/png;base64,$sigCli' : null,
        'sig_tecnico': sigTec != null ? 'data:image/png;base64,$sigTec' : null,
      });
    }
  }

  // ── Atualizar OS ──────────────────────────────────────────
  static Future<void> atualizar(
    String id,
    Map<String, dynamic> dados,
    List<String> equipamentosIds,
    List<ChecklistItem> checklist,
    List<String> acessorios,
    List<int>? sigClienteBytes,
    List<int>? sigTecnicoBytes,
  ) async {
    final atualizadoEm = DateTime.now().toIso8601String();

    // Resolve tecnico_nome a partir do cache de profiles para manter SQLite consistente
    final dadosLocal = Map<String, dynamic>.from(dados);
    if (dados.containsKey('tecnico_id')) {
      final tecId = dados['tecnico_id'] as String?;
      String? tecnicoNome;
      if (tecId != null) {
        final profilesCache = await OfflineService.getProfiles();
        tecnicoNome = profilesCache
            .where((p) => p['id'] == tecId)
            .map((p) => p['nome'] as String?)
            .firstOrNull;
      }
      dadosLocal['tecnico_nome'] = tecnicoNome ?? '';
    }

    // dadosLocal (com tecnico_nome) para o SQLite; dados original para o Supabase
    await OfflineService.updateOS(id, {...dadosLocal, 'atualizado_em': atualizadoEm});
    try {
      await supabase.from('ordem_servico').update({...dados, 'atualizado_em': atualizadoEm}).eq('id', id);
      await _salvarRelacionamentos(id, equipamentosIds, checklist, acessorios, sigClienteBytes, sigTecnicoBytes);
    } catch (_) {
      await OfflineService.salvarEquipamentosOs(id, equipamentosIds);
      await OfflineService.salvarChecklistLocal(id, checklist.map((c) => c.toJson(id)).toList());
      await OfflineService.salvarAcessoriosLocal(id, acessorios);
      await OfflineService.salvarAssinaturaLocal(
        id,
        sigClienteBytes != null ? base64Encode(sigClienteBytes) : null,
        sigTecnicoBytes != null ? base64Encode(sigTecnicoBytes) : null,
      );
      await OfflineService.adicionarFila('ordem_servico', 'UPDATE', id, {
        ...dados,
        'equipamentos_ids': equipamentosIds,
        'checklist':        checklist.map((c) => c.toJson(id)).toList(),
        'acessorios':       acessorios,
        'sig_cliente':      sigClienteBytes != null ? base64Encode(sigClienteBytes) : null,
        'sig_tecnico':      sigTecnicoBytes != null ? base64Encode(sigTecnicoBytes) : null,
      });
    }
  }

  // ── Desativar OS ──────────────────────────────────────────
  static Future<void> desativar(String id) async {
    final dados = {'ativo': false, 'atualizado_em': DateTime.now().toIso8601String()};
    await OfflineService.updateOS(id, {'ativo': 0, 'atualizado_em': dados['atualizado_em']!});
    try {
      await supabase.from('ordem_servico').update(dados).eq('id', id);
    } catch (_) {
      await OfflineService.adicionarFila('ordem_servico', 'UPDATE', id, dados);
    }
  }

  // ── Fotos ─────────────────────────────────────────────────
  static Future<String?> uploadFoto(String osId, File arquivo) async {
    try {
      final nome    = '${osId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final caminho = 'os/$osId/$nome';
      await supabase.storage.from('os-fotos').upload(caminho, arquivo);
      final url = supabase.storage.from('os-fotos').getPublicUrl(caminho);
      await supabase.from('os_foto').insert({
        'os_id': osId, 'nome_arquivo': nome,
        'caminho': url, 'tamanho_bytes': await arquivo.length(),
      });
      return url;
    } catch (_) {
      final caminhoPermamente = await _permanente(arquivo, osId);
      await OfflineService.salvarFotoPendente(osId, caminhoPermamente);
      return null;
    }
  }

  /// Copia um arquivo para storage permanente da OS (fora do cache temporário)
  static Future<String> copiarFotoParaPermanente(File arquivo, String osId) =>
      _permanente(arquivo, osId);

  static Future<String> _permanente(File arquivo, String osId) async {
    final dir   = await getApplicationDocumentsDirectory();
    final pasta = Directory(p.join(dir.path, 'survey_fotos'));
    await pasta.create(recursive: true);
    final ext   = p.extension(arquivo.path).isNotEmpty ? p.extension(arquivo.path) : '.jpg';
    final nome  = '${osId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest  = File(p.join(pasta.path, nome));
    await arquivo.copy(dest.path);
    return dest.path;
  }

  static Future<List<Map<String, dynamic>>> listarFotos(String osId) async {
    final resultado = <Map<String, dynamic>>[];
    if (!await _offline()) {
      try {
        final data = await supabase.from('os_foto').select().eq('os_id', osId).order('criado_em');
        resultado.addAll((data as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    final pendentes = await OfflineService.getFotosPendentesPorOs(osId);
    for (final f in pendentes) {
      resultado.add({'os_id': osId, 'caminho': f['file_path'] as String, 'nome_arquivo': 'local', 'pendente': true});
    }
    return resultado;
  }

  // ── Checklist ─────────────────────────────────────────────
  static Future<List<ChecklistItem>> listarChecklist(String osId) async {
    if (await _offline()) return _checklistLocal(osId);
    try {
      final data  = await supabase.from('os_checklist').select().eq('os_id', osId).order('item_id');
      final lista = (data as List).map((e) => ChecklistItem.fromJson(e)).toList();
      await OfflineService.salvarChecklistLocal(osId, lista.map((c) => c.toJson(osId)).toList());
      return lista;
    } catch (_) {
      return _checklistLocal(osId);
    }
  }

  static Future<List<ChecklistItem>> _checklistLocal(String osId) async {
    final local = await OfflineService.getChecklistLocal(osId);
    return local.map((m) => ChecklistItem(
          itemId: m['item_id'] as String,
          itemNome: m['item_nome'] as String,
          feito: (m['feito'] as int? ?? 0) == 1,
          dataVerificacao: m['data_verificacao'] != null
              ? DateTime.tryParse(m['data_verificacao'] as String)
              : null,
          tecnicoVerificador: m['tecnico_verificador'] as String?,
        )).toList();
  }

  // ── Acessórios ────────────────────────────────────────────
  static Future<List<OsAcessorio>> listarAcessorios(String osId) async {
    if (await _offline()) {
      final nomes = await OfflineService.getAcessoriosLocal(osId);
      return nomes.map((n) => OsAcessorio(nome: n)).toList();
    }
    try {
      final data  = await supabase.from('os_acessorio').select().eq('os_id', osId);
      final lista = (data as List).map((e) => OsAcessorio.fromJson(e)).toList();
      await OfflineService.salvarAcessoriosLocal(osId, lista.map((a) => a.nome).toList());
      return lista;
    } catch (_) {
      final nomes = await OfflineService.getAcessoriosLocal(osId);
      return nomes.map((n) => OsAcessorio(nome: n)).toList();
    }
  }

  // ── Assinatura ────────────────────────────────────────────
  static Future<Map<String, dynamic>?> listarAssinatura(String osId) async {
    if (await _offline()) return _assinaturaLocal(osId);
    try {
      final data = await supabase.from('os_assinatura').select().eq('os_id', osId).maybeSingle();
      if (data != null) {
        String? extractBase64(String? dataUri) {
          if (dataUri == null) return null;
          if (dataUri.contains(',')) return dataUri.split(',').last;
          return dataUri;
        }
        await OfflineService.salvarAssinaturaLocal(
          osId,
          extractBase64(data['sig_cliente'] as String?),
          extractBase64(data['sig_tecnico'] as String?),
        );
      }
      return data;
    } catch (_) {
      return _assinaturaLocal(osId);
    }
  }

  static Future<Map<String, dynamic>?> _assinaturaLocal(String osId) async {
    final local = await OfflineService.getAssinaturaLocal(osId);
    if (local == null) return null;
    return {
      'os_id':       osId,
      'sig_cliente': local['sig_cliente'],
      'sig_tecnico': local['sig_tecnico'],
      'offline':     true,
    };
  }

  // ── Helpers ───────────────────────────────────────────────
  static Future<void> _salvarEquipamentosOsEmLote(Map<String, List<String>> equipMap) async {
    for (final entry in equipMap.entries) {
      await OfflineService.salvarEquipamentosOs(entry.key, entry.value);
    }
  }

  // Monta mapa { userId → nome } a partir do cache de profiles
  static Future<Map<String, String>> _profilesNomePorId() async {
    final profiles = await OfflineService.getProfiles();
    return {
      for (final p in profiles)
        if (p['id'] != null) p['id'] as String: (p['nome'] as String? ?? ''),
    };
  }

  // Preenche tecnico_nome quando ausente, usando o mapa de profiles
  static Map<String, dynamic> _enriquecerTecnico(
      Map<String, dynamic> row, Map<String, String> nomesCache) {
    final tecNome = row['tecnico_nome'] as String? ?? '';
    if (tecNome.isNotEmpty) return row;   // já tem — não precisa de nada
    final tecId = row['tecnico_id'] as String? ?? '';
    if (tecId.isEmpty) return row;        // sem técnico — ok
    final nome = nomesCache[tecId];
    if (nome == null || nome.isEmpty) return row;
    return {...row, 'tecnico_nome': nome};
  }

  // ── Análise de Equipamento (EquipamentoOS) ─────────────────
  static Future<EquipamentoOS?> listarAnaliseEquipamento(String osId) async {
    if (await _offline()) return _analiseLocal(osId);
    try {
      final data = await supabase
          .from('os_analise_equipamento')
          .select()
          .eq('os_id', osId)
          .maybeSingle();
      if (data != null) {
        final equip = EquipamentoOS.fromJson(data);
        await OfflineService.salvarAnaliseEquipamento(equip.toLocal());
        return equip;
      }
      // Supabase retornou null — tenta SQLite (salvo offline ou upsert falhou)
      return _analiseLocal(osId);
    } catch (_) {
      return _analiseLocal(osId);
    }
  }

  static Future<EquipamentoOS?> _analiseLocal(String osId) async {
    try {
      final m = await OfflineService.getAnaliseEquipamento(osId);
      return m != null ? EquipamentoOS.fromLocal(m) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvarAnaliseEquipamento(EquipamentoOS equip) async {
    await OfflineService.salvarAnaliseEquipamento(equip.toLocal());
    final payload = {
      ...equip.toJson(),
      'id': equip.id,
      'criado_em': equip.criadoEm.toIso8601String(),
    };
    try {
      await supabase
          .from('os_analise_equipamento')
          .upsert(payload, onConflict: 'id');
    } catch (e) {
      // ignore: avoid_print
      print('[AnaliseEquip] Supabase erro: $e');
      await OfflineService.adicionarFila(
          'os_analise_equipamento', 'UPSERT', equip.id, payload);
    }
  }

  // ── Testes Realizados (Melhoria 4) ────────────────────────
  static Future<List<OsTesteItem>> listarTestes(String osId) async {
    if (await _offline()) return _testesLocal(osId);
    try {
      final data = await supabase
          .from('os_testes')
          .select()
          .eq('os_id', osId)
          .order('item_id');
      final lista = (data as List).map((e) => OsTesteItem.fromJson(e)).toList();
      await OfflineService.salvarTestesLocal(
          osId, lista.map((t) => t.toLocal(osId)).toList());
      return lista;
    } catch (_) {
      return _testesLocal(osId);
    }
  }

  static Future<List<OsTesteItem>> _testesLocal(String osId) async {
    final local = await OfflineService.getTestesLocal(osId);
    if (local.isEmpty) return OsTesteItem.padrao();
    return local.map((m) => OsTesteItem.fromJson({
          'item_id': m['item_id'],
          'item_nome': m['item_nome'],
          'feito': m['feito'],
          'observacao': m['observacao'],
          'data_verificacao': m['data_verificacao'],
        })).toList();
  }

  static Future<void> salvarTestes(
      String osId, List<OsTesteItem> testes) async {
    final localMaps = testes.map((t) => t.toLocal(osId)).toList();
    await OfflineService.salvarTestesLocal(osId, localMaps);
    try {
      await supabase.from('os_testes').delete().eq('os_id', osId);
      if (testes.isNotEmpty) {
        await supabase
            .from('os_testes')
            .insert(testes.map((t) => t.toJson(osId)).toList());
      }
    } catch (_) {
      await OfflineService.adicionarFila('os_testes', 'UPSERT', osId, {
        'os_id': osId,
        'itens': testes.map((t) => t.toJson(osId)).toList(),
      });
    }
  }

  // ── Visita Técnica (Melhoria 2) ───────────────────────────
  static Future<OsVisita?> listarVisita(String osId) async {
    if (await _offline()) return _visitaLocal(osId);
    try {
      final data = await supabase
          .from('os_visita')
          .select()
          .eq('os_id', osId)
          .maybeSingle();
      if (data != null) {
        final visita = OsVisita.fromJson(data);
        await OfflineService.salvarVisitaLocal(visita.toLocal());
        return visita;
      }
      return _visitaLocal(osId);
    } catch (_) {
      return _visitaLocal(osId);
    }
  }

  static Future<OsVisita?> _visitaLocal(String osId) async {
    final m = await OfflineService.getVisitaLocal(osId);
    return m != null ? OsVisita.fromLocal(m) : null;
  }

  static Future<void> salvarVisita(OsVisita visita) async {
    await OfflineService.salvarVisitaLocal(visita.toLocal());
    try {
      await supabase
          .from('os_visita')
          .upsert(visita.toJson(), onConflict: 'id');
    } catch (_) {
      await OfflineService.adicionarFila(
          'os_visita', 'UPSERT', visita.id, visita.toJson());
    }
  }

  // ── Atualizar fotos de seção (Melhoria 1) ─────────────────
  /// [secao] = 'fotos_visita' | 'fotos_equipamento' | 'fotos_testes'
  static Future<void> atualizarFotosSecao(
      String osId, String secao, List<String> fotos) async {
    await OfflineService.atualizarFotosSecaoOS(osId, secao, fotos);
    try {
      await supabase
          .from('ordem_servico')
          .update({secao: fotos, 'atualizado_em': DateTime.now().toIso8601String()})
          .eq('id', osId);
    } catch (_) {
      await OfflineService.adicionarFila(
          'ordem_servico', 'UPDATE', osId, {secao: fotos});
    }
  }
}
