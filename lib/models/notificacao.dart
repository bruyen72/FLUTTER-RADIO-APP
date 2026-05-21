class Notificacao {
  final String id;
  final String usuarioId;
  final String? osId;
  final String mensagem;
  final String tipo;
  final bool lida;
  final DateTime criadoEm;

  const Notificacao({
    required this.id,
    required this.usuarioId,
    this.osId,
    required this.mensagem,
    required this.tipo,
    required this.lida,
    required this.criadoEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
        id: j['id'] as String,
        usuarioId: j['usuario_id'] as String,
        osId: j['os_id'] as String?,
        mensagem: j['mensagem'] as String,
        tipo: j['tipo'] as String? ?? 'info',
        lida: j['lida'] as bool? ?? false,
        criadoEm: DateTime.tryParse(j['criado_em'] as String? ?? '') ?? DateTime.now(),
      );
}
