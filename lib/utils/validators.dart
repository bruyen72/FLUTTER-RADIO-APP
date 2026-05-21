String? obrigatorio(String? v) {
  if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
  return null;
}

String? email(String? v) {
  if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
  final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!re.hasMatch(v.trim())) return 'E-mail inválido';
  return null;
}

String? telefone(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  final limpo = v.replaceAll(RegExp(r'\D'), '');
  if (limpo.length < 10) return 'Telefone inválido';
  return null;
}

String? senha(String? v) {
  if (v == null || v.isEmpty) return 'Campo obrigatório';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}
