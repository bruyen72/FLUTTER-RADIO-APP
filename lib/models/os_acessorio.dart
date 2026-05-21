class OsAcessorio {
  final String nome;

  const OsAcessorio({required this.nome});

  static const List<String> opcoesPadrao = [
    'Antena', 'Bateria', 'Clip', 'Fone', 'Carregador', 'Case', 'Cabo',
  ];

  Map<String, dynamic> toJson(String osId) => {'os_id': osId, 'nome': nome};

  factory OsAcessorio.fromJson(Map<String, dynamic> j) =>
      OsAcessorio(nome: j['nome'] as String);
}
