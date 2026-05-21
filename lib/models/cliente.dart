class Cliente {
  final String id;
  final String nome;
  final String? telefone;
  final String? email;
  final String? endereco;         // endereço concatenado para exibição
  final String? logradouro;
  final String? numeroComplemento;
  final String? bairro;
  final String? cidade;
  final String? uf;
  final bool ativo;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Cliente({
    required this.id,
    required this.nome,
    this.telefone,
    this.email,
    this.endereco,
    this.logradouro,
    this.numeroComplemento,
    this.bairro,
    this.cidade,
    this.uf,
    this.ativo = true,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id: j['id'] as String,
        nome: j['nome'] as String,
        telefone: j['telefone'] as String?,
        email: j['email'] as String?,
        endereco: j['endereco'] as String?,
        logradouro: j['logradouro'] as String?,
        numeroComplemento: j['numero_complemento'] as String?,
        bairro: j['bairro'] as String?,
        cidade: j['cidade'] as String?,
        uf: j['uf'] as String?,
        ativo: j['ativo'] as bool? ?? true,
        criadoEm: DateTime.tryParse(j['criado_em'] as String? ?? '') ?? DateTime.now(),
        atualizadoEm: DateTime.tryParse(j['atualizado_em'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'telefone': telefone,
        'email': email,
        'endereco': endereco,
        'logradouro': logradouro,
        'numero_complemento': numeroComplemento,
        'bairro': bairro,
        'cidade': cidade,
        'uf': uf,
        'ativo': ativo,
      };

  Map<String, dynamic> toLocal() => {
        'id': id,
        'nome': nome,
        'telefone': telefone ?? '',
        'email': email ?? '',
        'endereco': endereco ?? '',
        'logradouro': logradouro ?? '',
        'numero_complemento': numeroComplemento ?? '',
        'bairro': bairro ?? '',
        'cidade': cidade ?? '',
        'uf': uf ?? '',
        'ativo': ativo ? 1 : 0,
        'criado_em': criadoEm.toIso8601String(),
        'atualizado_em': atualizadoEm.toIso8601String(),
        'synced': 1,
      };

  factory Cliente.fromLocal(Map<String, dynamic> m) => Cliente(
        id: m['id'] as String,
        nome: m['nome'] as String,
        telefone: (m['telefone'] as String?) == '' ? null : m['telefone'] as String?,
        email: (m['email'] as String?) == '' ? null : m['email'] as String?,
        endereco: (m['endereco'] as String?) == '' ? null : m['endereco'] as String?,
        logradouro: (m['logradouro'] as String?) == '' ? null : m['logradouro'] as String?,
        numeroComplemento: (m['numero_complemento'] as String?) == '' ? null : m['numero_complemento'] as String?,
        bairro: (m['bairro'] as String?) == '' ? null : m['bairro'] as String?,
        cidade: (m['cidade'] as String?) == '' ? null : m['cidade'] as String?,
        uf: (m['uf'] as String?) == '' ? null : m['uf'] as String?,
        ativo: (m['ativo'] as int? ?? 1) == 1,
        criadoEm: DateTime.tryParse(m['criado_em'] as String? ?? '') ?? DateTime.now(),
        atualizadoEm: DateTime.tryParse(m['atualizado_em'] as String? ?? '') ?? DateTime.now(),
      );

  Cliente copyWith({
    String? nome,
    String? telefone,
    String? email,
    String? endereco,
    String? logradouro,
    String? numeroComplemento,
    String? bairro,
    String? cidade,
    String? uf,
    bool? ativo,
  }) =>
      Cliente(
        id: id,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        email: email ?? this.email,
        endereco: endereco ?? this.endereco,
        logradouro: logradouro ?? this.logradouro,
        numeroComplemento: numeroComplemento ?? this.numeroComplemento,
        bairro: bairro ?? this.bairro,
        cidade: cidade ?? this.cidade,
        uf: uf ?? this.uf,
        ativo: ativo ?? this.ativo,
        criadoEm: criadoEm,
        atualizadoEm: DateTime.now(),
      );
}
