/// Modelo para checklist de testes realizados em uma OS (Melhoria 4)
class OsTesteItem {
  final String itemId;
  final String itemNome;
  final bool feito;
  final String observacao;
  final DateTime? dataVerificacao;

  const OsTesteItem({
    required this.itemId,
    required this.itemNome,
    this.feito = false,
    this.observacao = '',
    this.dataVerificacao,
  });

  /// Lista padrão dos 9 testes de rádio
  static List<OsTesteItem> padrao() => const [
        OsTesteItem(itemId: 'tx',          itemNome: 'Teste TX (transmissão)'),
        OsTesteItem(itemId: 'rx',          itemNome: 'Teste RX (recepção)'),
        OsTesteItem(itemId: 'audio',       itemNome: 'Teste de áudio'),
        OsTesteItem(itemId: 'bateria',     itemNome: 'Teste de bateria'),
        OsTesteItem(itemId: 'canais',      itemNome: 'Teste de canais'),
        OsTesteItem(itemId: 'alcance',     itemNome: 'Teste de alcance'),
        OsTesteItem(itemId: 'programacao', itemNome: 'Teste de programação'),
        OsTesteItem(itemId: 'higienizacao',itemNome: 'Higienização'),
        OsTesteItem(itemId: 'final',       itemNome: 'Teste final aprovado'),
      ];

  factory OsTesteItem.fromJson(Map<String, dynamic> j) => OsTesteItem(
        itemId: j['item_id'] as String,
        itemNome: j['item_nome'] as String,
        feito: (j['feito'] == true || j['feito'] == 1),
        observacao: j['observacao'] as String? ?? '',
        dataVerificacao: j['data_verificacao'] != null
            ? DateTime.tryParse(j['data_verificacao'] as String)
            : null,
      );

  Map<String, dynamic> toJson(String osId) => {
        'os_id': osId,
        'item_id': itemId,
        'item_nome': itemNome,
        'feito': feito,
        'observacao': observacao,
        'data_verificacao': dataVerificacao?.toIso8601String(),
      };

  Map<String, dynamic> toLocal(String osId) => {
        'os_id': osId,
        'item_id': itemId,
        'item_nome': itemNome,
        'feito': feito ? 1 : 0,
        'observacao': observacao,
        'data_verificacao': dataVerificacao?.toIso8601String(),
      };

  OsTesteItem copyWith({bool? feito, String? observacao, DateTime? dataVerificacao}) =>
      OsTesteItem(
        itemId: itemId,
        itemNome: itemNome,
        feito: feito ?? this.feito,
        observacao: observacao ?? this.observacao,
        dataVerificacao: dataVerificacao ?? this.dataVerificacao,
      );
}
