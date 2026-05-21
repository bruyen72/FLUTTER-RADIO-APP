class ChecklistItem {
  final String itemId;
  final String itemNome;
  bool feito;
  DateTime? dataVerificacao;
  String? tecnicoVerificador;

  ChecklistItem({
    required this.itemId,
    required this.itemNome,
    this.feito = false,
    this.dataVerificacao,
    this.tecnicoVerificador,
  });

  static const List<Map<String, String>> itensPadrao = [
    {'id': 'bat',  'nome': 'Teste de Bateria / Carga'},
    {'id': 'tx',   'nome': 'Teste de Transmissão (TX)'},
    {'id': 'rx',   'nome': 'Teste de Recepção (RX)'},
    {'id': 'freq', 'nome': 'Verificação de Frequência / Canal'},
    {'id': 'prog', 'nome': 'Programação / Software'},
    {'id': 'ant',  'nome': 'Inspeção da Antena'},
    {'id': 'mic',  'nome': 'Teste de Microfone / Áudio'},
    {'id': 'btn',  'nome': 'Teste de Botões / Display'},
    {'id': 'con',  'nome': 'Teste de Conector / Solda'},
    {'id': 'fis',  'nome': 'Inspeção Física / Limpeza'},
    {'id': 'fab',  'nome': 'Encaminhado ao Fabricante'},
    {'id': 'qc',   'nome': 'Controle de Qualidade Final'},
  ];

  static List<ChecklistItem> padrao() =>
      itensPadrao.map((m) => ChecklistItem(itemId: m['id']!, itemNome: m['nome']!)).toList();

  Map<String, dynamic> toJson(String osId) => {
        'os_id': osId,
        'item_id': itemId,
        'item_nome': itemNome,
        'feito': feito,
        'data_verificacao': dataVerificacao?.toIso8601String().substring(0, 10),
        'tecnico_verificador': tecnicoVerificador,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        itemId: j['item_id'] as String,
        itemNome: j['item_nome'] as String,
        feito: j['feito'] as bool? ?? false,
        dataVerificacao: j['data_verificacao'] != null
            ? DateTime.tryParse(j['data_verificacao'] as String)
            : null,
        tecnicoVerificador: j['tecnico_verificador'] as String?,
      );
}
