class Equipamento {
  final String id;
  final String tipo;
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String clienteId;
  final String? clienteNome;
  final String? corIdentificacao;
  final String? canalFrequencia;
  final bool ativo;
  final DateTime criadoEm;

  const Equipamento({
    required this.id,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    required this.clienteId,
    this.clienteNome,
    this.corIdentificacao,
    this.canalFrequencia,
    this.ativo = true,
    required this.criadoEm,
  });

  factory Equipamento.fromJson(Map<String, dynamic> j) => Equipamento(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        marca: j['marca'] as String,
        modelo: j['modelo'] as String,
        numeroSerie: j['numero_serie'] as String,
        clienteId: j['cliente_id'] as String,
        clienteNome: j['cliente'] != null
            ? (j['cliente'] as Map<String, dynamic>)['nome'] as String?
            : null,
        corIdentificacao: j['cor_identificacao'] as String?,
        canalFrequencia: j['canal_frequencia'] as String?,
        ativo: j['ativo'] as bool? ?? true,
        criadoEm: DateTime.tryParse(j['criado_em'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'marca': marca,
        'modelo': modelo,
        'numero_serie': numeroSerie,
        'cliente_id': clienteId,
        'cor_identificacao': corIdentificacao,
        'canal_frequencia': canalFrequencia,
        'ativo': ativo,
      };

  Map<String, dynamic> toLocal() => {
        'id': id,
        'tipo': tipo,
        'marca': marca,
        'modelo': modelo,
        'numero_serie': numeroSerie,
        'cliente_id': clienteId,
        'cliente_nome': clienteNome ?? '',
        'cor_identificacao': corIdentificacao ?? '',
        'canal_frequencia': canalFrequencia ?? '',
        'ativo': ativo ? 1 : 0,
        'criado_em': criadoEm.toIso8601String(),
        'synced': 1,
      };

  factory Equipamento.fromLocal(Map<String, dynamic> m) => Equipamento(
        id: m['id'] as String,
        tipo: m['tipo'] as String,
        marca: m['marca'] as String,
        modelo: m['modelo'] as String,
        numeroSerie: m['numero_serie'] as String,
        clienteId: m['cliente_id'] as String,
        clienteNome: (m['cliente_nome'] as String?) == '' ? null : m['cliente_nome'] as String?,
        corIdentificacao: (m['cor_identificacao'] as String?) == '' ? null : m['cor_identificacao'] as String?,
        canalFrequencia: (m['canal_frequencia'] as String?) == '' ? null : m['canal_frequencia'] as String?,
        ativo: (m['ativo'] as int? ?? 1) == 1,
        criadoEm: DateTime.tryParse(m['criado_em'] as String? ?? '') ?? DateTime.now(),
      );

  String get descricaoCompleta => '$marca $modelo ($tipo)';
}
