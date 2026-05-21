import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _form      = GlobalKey<FormState>();
  final _nomeCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _espCtrl   = TextEditingController();
  String _perfil   = 'tecnico';
  bool _salvando   = false;
  bool _obscure    = true;

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nomeCtrl.text = widget.usuario!.nome;
      _perfil        = widget.usuario!.perfil;
      _espCtrl.text  = widget.usuario!.especialidade ?? '';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _espCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      if (widget.usuario == null) {
        await UsuarioService.criarUsuario(
          email:         _emailCtrl.text.trim(),
          senha:         _senhaCtrl.text,
          nome:          _nomeCtrl.text.trim(),
          perfil:        _perfil,
          especialidade: _espCtrl.text.trim().isEmpty ? null : _espCtrl.text.trim(),
        );
      } else {
        await UsuarioService.atualizarPerfil(widget.usuario!.id, {
          'nome':          _nomeCtrl.text.trim(),
          'perfil':        _perfil,
          'especialidade': _espCtrl.text.trim().isEmpty ? null : _espCtrl.text.trim(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.usuario == null ? 'Usuário criado!' : 'Usuário atualizado!'),
          backgroundColor: kPrimaryColor,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('internet_necessaria') ||
          e.toString().contains('Sem conexão')) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: kCardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 48),
            title: const Text('Sem Conexão',
                style: TextStyle(color: kTextColor, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            content: const Text(
              'Para criar ou editar usuários é necessário estar conectado à internet ou Wi-Fi.\n\nConecte-se e tente novamente.',
              style: TextStyle(color: kTextColor2, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ── VISUAL ────────────────────────────────────────────────────
  static final _enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: kBorderColor, width: 1),
  );
  static final _focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
  );
  static final _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: kColorCancelado, width: 1),
  );

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
    filled: true,
    fillColor: kCardColor,
    suffixIcon: suffix,
    enabledBorder: _enabledBorder,
    focusedBorder: _focusBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final criando = widget.usuario == null;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(criando ? 'Novo Usuário' : 'Editar Usuário'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            _secao('Dados do Usuário', Icons.person_outline),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nomeCtrl,
              validator: obrigatorio,
              style: const TextStyle(color: kTextColor, fontSize: 15),
              decoration: _dec('Nome Completo *'),
            ),
            const SizedBox(height: 20),

            if (criando) ...[
              _secao('Acesso ao Sistema', Icons.lock_outline),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                validator: email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: kTextColor, fontSize: 15),
                decoration: _dec('E-mail *'),
              ),
            ] else if (widget.usuario!.email.isNotEmpty) ...[
              _secao('Acesso ao Sistema', Icons.lock_outline),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: widget.usuario!.email,
                readOnly: true,
                style: const TextStyle(color: kTextDim, fontSize: 15),
                decoration: _dec('E-mail').copyWith(
                  prefixIcon: const Icon(Icons.email_outlined, color: kTextDim, size: 18),
                  suffixIcon: const Tooltip(
                    message: 'E-mail não pode ser alterado pelo app',
                    child: Icon(Icons.lock_outline, color: kTextDim, size: 16),
                  ),
                ),
              ),
            ],
            if (criando) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _senhaCtrl,
                validator: senha,
                obscureText: _obscure,
                style: const TextStyle(color: kTextColor, fontSize: 15),
                decoration: _dec(
                  'Senha * (mín. 6 caracteres)',
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20, color: kTextColor3,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _secao('Perfil e Especialidade', Icons.manage_accounts_outlined),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _perfil,
              isExpanded: true,
              dropdownColor: kCardColor,
              style: const TextStyle(color: kTextColor, fontSize: 15),
              decoration: _dec('Perfil *'),
              items: const [
                DropdownMenuItem(value: 'tecnico',    child: Text('Técnico')),
                DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                DropdownMenuItem(value: 'admin',      child: Text('Administrador')),
              ],
              onChanged: (v) => setState(() => _perfil = v!),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _espCtrl,
              style: const TextStyle(color: kTextColor, fontSize: 15),
              decoration: _dec('Especialidade (opcional)'),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kPrimaryColor.withOpacity(0.45),
                  elevation: 3,
                  shadowColor: kPrimaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _salvando
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        criando ? 'CRIAR USUÁRIO' : 'SALVAR ALTERAÇÕES',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, IconData icon) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: kPrimaryLight, size: 16),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(titulo,
            style: const TextStyle(color: kTextColor2, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ],
  );
}
