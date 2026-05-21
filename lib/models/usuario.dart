class Usuario {
  final String id;
  final String nome;
  final String email;
  final String perfil;
  final String? especialidade;
  final bool ativo;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.especialidade,
    this.ativo = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as String,
        nome: j['nome'] as String? ?? '',
        email: j['email'] as String? ?? '',
        perfil: j['perfil'] as String? ?? 'tecnico',
        especialidade: j['especialidade'] as String?,
        ativo: j['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'perfil': perfil,
        'especialidade': especialidade,
        'ativo': ativo,
      };

  bool get isAdmin => perfil == 'admin';
}
