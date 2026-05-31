import 'dart:convert';

/// Modelo para Visita Técnica vinculada a uma OS (Melhoria 2)
class OsVisita {
  final String id;
  final String osId;
  final String localVisita;
  final String tecnicoResponsavel;
  final DateTime? dataHora;
  final String descricaoProblema;
  final String equipamentosEncontrados;
  final List<String> fotos;
  final String observacoesCampo;
  final String status; // 'Em andamento' / 'Concluída'
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const OsVisita({
    required this.id,
    required this.osId,
    this.localVisita = '',
    this.tecnicoResponsavel = '',
    this.dataHora,
    this.descricaoProblema = '',
    this.equipamentosEncontrados = '',
    this.fotos = const [],
    this.observacoesCampo = '',
    this.status = 'Em andamento',
    required this.criadoEm,
    required this.atualizadoEm,
  });

  static List<String> _parseJsonList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.cast<String>();
    if (v is String && v.isNotEmpty) {
      try { return (jsonDecode(v) as List).cast<String>(); } catch (_) {}
    }
    return const [];
  }

  factory OsVisita.fromJson(Map<String, dynamic> j) => OsVisita(
        id: j['id'] as String,
        osId: j['os_id'] as String,
        localVisita: j['local_visita'] as String? ?? '',
        tecnicoResponsavel: j['tecnico_responsavel'] as String? ?? '',
        dataHora: j['data_hora'] != null ? DateTime.tryParse(j['data_hora'] as String) : null,
        descricaoProblema: j['descricao_problema'] as String? ?? '',
        equipamentosEncontrados: j['equipamentos_encontrados'] as String? ?? '',
        fotos: _parseJsonList(j['fotos']),
        observacoesCampo: j['observacoes_campo'] as String? ?? '',
        status: j['status'] as String? ?? 'Em andamento',
        criadoEm: DateTime.tryParse(j['criado_em'] as String? ?? '') ?? DateTime.now(),
        atualizadoEm: DateTime.tryParse(j['atualizado_em'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'os_id': osId,
        'local_visita': localVisita,
        'tecnico_responsavel': tecnicoResponsavel,
        'data_hora': dataHora?.toIso8601String(),
        'descricao_problema': descricaoProblema,
        'equipamentos_encontrados': equipamentosEncontrados,
        'fotos': fotos,
        'observacoes_campo': observacoesCampo,
        'status': status,
        'criado_em': criadoEm.toIso8601String(),
        'atualizado_em': atualizadoEm.toIso8601String(),
      };

  Map<String, dynamic> toLocal() => {
        'id': id,
        'os_id': osId,
        'local_visita': localVisita,
        'tecnico_responsavel': tecnicoResponsavel,
        'data_hora': dataHora?.toIso8601String() ?? '',
        'descricao_problema': descricaoProblema,
        'equipamentos_encontrados': equipamentosEncontrados,
        'fotos': jsonEncode(fotos),
        'observacoes_campo': observacoesCampo,
        'status': status,
        'criado_em': criadoEm.toIso8601String(),
        'atualizado_em': atualizadoEm.toIso8601String(),
        'synced': 0,
      };

  factory OsVisita.fromLocal(Map<String, dynamic> m) => OsVisita(
        id: m['id'] as String,
        osId: m['os_id'] as String,
        localVisita: m['local_visita'] as String? ?? '',
        tecnicoResponsavel: m['tecnico_responsavel'] as String? ?? '',
        dataHora: (m['data_hora'] as String?)?.isNotEmpty == true
            ? DateTime.tryParse(m['data_hora'] as String)
            : null,
        descricaoProblema: m['descricao_problema'] as String? ?? '',
        equipamentosEncontrados: m['equipamentos_encontrados'] as String? ?? '',
        fotos: _parseJsonList(m['fotos']),
        observacoesCampo: m['observacoes_campo'] as String? ?? '',
        status: m['status'] as String? ?? 'Em andamento',
        criadoEm: DateTime.tryParse(m['criado_em'] as String? ?? '') ?? DateTime.now(),
        atualizadoEm: DateTime.tryParse(m['atualizado_em'] as String? ?? '') ?? DateTime.now(),
      );
}
