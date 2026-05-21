class OrdemServico {
  final String id;
  final String numeroOs;
  final String? descricao;
  final String status;
  final String prioridade;
  final String? tipoOcorrencia;
  final DateTime dataEntrada;
  final String? horaEntrada;
  final DateTime? dataSaida;
  final String? acompanhante;
  final String? condicoesFisicas;
  final String? defeito;
  final String? statusEquipamento;
  final String? laudoTecnico;
  final String? solucaoAplicada;
  final String? pecasUtilizadas;
  final String? termosObservacoes;
  final double? geoLat;
  final double? geoLng;
  final String? geoEndereco;
  final bool ativo;
  final String clienteId;
  final String? clienteNome;
  final String? tecnicoId;
  final String? tecnicoNome;
  final String criadoPor;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final List<String> equipamentosIds;

  const OrdemServico({
    required this.id,
    required this.numeroOs,
    this.descricao,
    required this.status,
    required this.prioridade,
    this.tipoOcorrencia,
    required this.dataEntrada,
    this.horaEntrada,
    this.dataSaida,
    this.acompanhante,
    this.condicoesFisicas,
    this.defeito,
    this.statusEquipamento,
    this.laudoTecnico,
    this.solucaoAplicada,
    this.pecasUtilizadas,
    this.termosObservacoes,
    this.geoLat,
    this.geoLng,
    this.geoEndereco,
    this.ativo = true,
    required this.clienteId,
    this.clienteNome,
    this.tecnicoId,
    this.tecnicoNome,
    required this.criadoPor,
    required this.criadoEm,
    required this.atualizadoEm,
    this.equipamentosIds = const [],
  });

  factory OrdemServico.fromJson(Map<String, dynamic> j) {
    List<String> equips = [];
    if (j['os_equipamento'] != null) {
      equips = (j['os_equipamento'] as List)
          .map((e) => e['equipamento_id'] as String)
          .toList();
    }
    return OrdemServico(
      id: j['id'] as String,
      numeroOs: j['numero_os'] as String,
      descricao: j['descricao'] as String?,
      status: j['status'] as String? ?? 'Aberto',
      prioridade: j['prioridade'] as String? ?? 'Baixa',
      tipoOcorrencia: j['tipo_ocorrencia'] as String?,
      dataEntrada: DateTime.parse(j['data_entrada'] as String),
      horaEntrada: j['hora_entrada'] as String?,
      dataSaida: j['data_saida'] != null ? DateTime.tryParse(j['data_saida'] as String) : null,
      acompanhante: j['acompanhante'] as String?,
      condicoesFisicas: j['condicoes_fisicas'] as String?,
      defeito: j['defeito_relatado'] as String?,
      statusEquipamento: j['status_equipamento'] as String?,
      laudoTecnico: j['laudo_tecnico'] as String?,
      solucaoAplicada: j['solucao_aplicada'] as String?,
      pecasUtilizadas: j['pecas_utilizadas'] as String?,
      termosObservacoes: j['termos_observacoes'] as String?,
      geoLat: (j['geo_lat'] as num?)?.toDouble(),
      geoLng: (j['geo_lng'] as num?)?.toDouble(),
      geoEndereco: j['geo_endereco'] as String?,
      ativo: j['ativo'] as bool? ?? true,
      clienteId: j['cliente_id'] as String,
      clienteNome: j['cliente'] != null
          ? (j['cliente'] as Map<String, dynamic>)['nome'] as String?
          : null,
      tecnicoId: j['tecnico_id'] as String?,
      tecnicoNome: j['tecnico'] != null
          ? (j['tecnico'] as Map<String, dynamic>)['nome'] as String?
          : null,
      criadoPor: j['criado_por'] as String,
      criadoEm: DateTime.tryParse(j['criado_em'] as String? ?? '') ?? DateTime.now(),
      atualizadoEm: DateTime.tryParse(j['atualizado_em'] as String? ?? '') ?? DateTime.now(),
      equipamentosIds: equips,
    );
  }

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'status': status,
        'prioridade': prioridade,
        'tipo_ocorrencia': tipoOcorrencia,
        'data_entrada': dataEntrada.toIso8601String().substring(0, 10),
        'hora_entrada': horaEntrada,
        'data_saida': dataSaida?.toIso8601String().substring(0, 10),
        'acompanhante': acompanhante,
        'condicoes_fisicas': condicoesFisicas,
        'defeito_relatado': defeito,
        'status_equipamento': statusEquipamento,
        'laudo_tecnico': laudoTecnico,
        'solucao_aplicada': solucaoAplicada,
        'pecas_utilizadas': pecasUtilizadas,
        'termos_observacoes': termosObservacoes,
        'geo_lat': geoLat,
        'geo_lng': geoLng,
        'geo_endereco': geoEndereco,
        'ativo': ativo,
        'cliente_id': clienteId,
        'tecnico_id': tecnicoId,
      };

  Map<String, dynamic> toLocal() => {
        'id': id,
        'numero_os': numeroOs,
        'descricao': descricao ?? '',
        'status': status,
        'prioridade': prioridade,
        'tipo_ocorrencia': tipoOcorrencia ?? '',
        'data_entrada': dataEntrada.toIso8601String().substring(0, 10),
        'hora_entrada': horaEntrada ?? '',
        'data_saida': dataSaida?.toIso8601String().substring(0, 10) ?? '',
        'acompanhante': acompanhante ?? '',
        'condicoes_fisicas': condicoesFisicas ?? '',
        'defeito_relatado': defeito ?? '',
        'status_equipamento': statusEquipamento ?? '',
        'laudo_tecnico': laudoTecnico ?? '',
        'solucao_aplicada': solucaoAplicada ?? '',
        'pecas_utilizadas': pecasUtilizadas ?? '',
        'termos_observacoes': termosObservacoes ?? '',
        'geo_lat': geoLat,
        'geo_lng': geoLng,
        'geo_endereco': geoEndereco ?? '',
        'ativo': ativo ? 1 : 0,
        'cliente_id': clienteId,
        'cliente_nome': clienteNome ?? '',
        'tecnico_id': tecnicoId ?? '',
        'tecnico_nome': tecnicoNome ?? '',
        'criado_por': criadoPor,
        'criado_em': criadoEm.toIso8601String(),
        'atualizado_em': atualizadoEm.toIso8601String(),
        'synced': 1,
      };

  factory OrdemServico.fromLocal(Map<String, dynamic> m) => OrdemServico(
        id: m['id'] as String,
        numeroOs: m['numero_os'] as String,
        descricao: (m['descricao'] as String?) == '' ? null : m['descricao'] as String?,
        status: m['status'] as String,
        prioridade: m['prioridade'] as String,
        tipoOcorrencia: (m['tipo_ocorrencia'] as String?) == '' ? null : m['tipo_ocorrencia'] as String?,
        dataEntrada: DateTime.parse(m['data_entrada'] as String),
        horaEntrada: (m['hora_entrada'] as String?) == '' ? null : m['hora_entrada'] as String?,
        dataSaida: (m['data_saida'] as String?) != null && (m['data_saida'] as String).isNotEmpty
            ? DateTime.tryParse(m['data_saida'] as String)
            : null,
        acompanhante: (m['acompanhante'] as String?) == '' ? null : m['acompanhante'] as String?,
        condicoesFisicas: (m['condicoes_fisicas'] as String?) == '' ? null : m['condicoes_fisicas'] as String?,
        defeito: (m['defeito_relatado'] as String?) == '' ? null : m['defeito_relatado'] as String?,
        statusEquipamento: (m['status_equipamento'] as String?) == '' ? null : m['status_equipamento'] as String?,
        laudoTecnico: (m['laudo_tecnico'] as String?) == '' ? null : m['laudo_tecnico'] as String?,
        solucaoAplicada: (m['solucao_aplicada'] as String?) == '' ? null : m['solucao_aplicada'] as String?,
        pecasUtilizadas: (m['pecas_utilizadas'] as String?) == '' ? null : m['pecas_utilizadas'] as String?,
        termosObservacoes: (m['termos_observacoes'] as String?) == '' ? null : m['termos_observacoes'] as String?,
        geoLat: m['geo_lat'] as double?,
        geoLng: m['geo_lng'] as double?,
        geoEndereco: (m['geo_endereco'] as String?) == '' ? null : m['geo_endereco'] as String?,
        ativo: (m['ativo'] as int? ?? 1) == 1,
        clienteId: m['cliente_id'] as String,
        clienteNome: (m['cliente_nome'] as String?) == '' ? null : m['cliente_nome'] as String?,
        tecnicoId: (m['tecnico_id'] as String?) == '' ? null : m['tecnico_id'] as String?,
        tecnicoNome: (m['tecnico_nome'] as String?) == '' ? null : m['tecnico_nome'] as String?,
        criadoPor: m['criado_por'] as String,
        criadoEm: DateTime.tryParse(m['criado_em'] as String? ?? '') ?? DateTime.now(),
        atualizadoEm: DateTime.tryParse(m['atualizado_em'] as String? ?? '') ?? DateTime.now(),
        equipamentosIds: (m['_equip_ids'] as List?)?.cast<String>() ?? const [],
      );
}
