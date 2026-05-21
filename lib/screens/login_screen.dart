import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';

// ── Cores locais da tela de login (fundo único escuro) ───────
const _kBg        = Color(0xFF050e08); // fundo principal
const _kGreen     = Color(0xFF16a34a); // botão e acentos
const _kGreenGlow = Color(0xFF22c55e); // verde claro
const _kInputBg   = Color(0xFF0F2217); // campo semi-transparente
const _kBorder    = Color(0x33FFFFFF); // borda sutil branca
const _kBorderFoc = Color(0xFF16a34a); // borda foco
const _kText      = Color(0xFFFFFFFF); // texto principal
const _kTextMuted = Color(0xFF92b89e); // texto secundário
const _kTextDim   = Color(0xFF4d7a5c); // placeholder / dim

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form      = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  bool _offline  = false;
  String? _emailOfflineSalvo;
  StreamSubscription? _connSub;

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarEstado() async {
    final results = await Future.wait([
      Connectivity().checkConnectivity(),
      AuthService.emailOffline(),
    ]);
    final conn       = results[0] as List<ConnectivityResult>;
    final emailSalvo = results[1] as String?;

    if (mounted) {
      setState(() {
        _offline           = conn.contains(ConnectivityResult.none);
        _emailOfflineSalvo = emailSalvo;
        if (emailSalvo != null && _emailCtrl.text.isEmpty) {
          _emailCtrl.text = emailSalvo;
        }
      });
    }

    _connSub = Connectivity().onConnectivityChanged.listen((conn) {
      if (mounted) setState(() => _offline = conn.contains(ConnectivityResult.none));
    });
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await AuthService.login(_emailCtrl.text, _senhaCtrl.text);
      if (mounted) {
        if (result.offline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrou em modo offline. Dados serão sincronizados ao conectar.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg    = _mensagemErro(e.toString());
        final isRede = e.toString().contains('Sem internet') ||
                       e.toString().contains('nenhuma sessão') ||
                       e.toString().contains('Somente o usuário') ||
                       e.toString().contains('Conta não registrada') ||
                       e.toString().contains('Faça login com internet') ||
                       e.toString().contains('network') ||
                       e.toString().contains('SocketException');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isRede ? Colors.orange.shade700 : Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mensagemErro(String raw) {
    if (raw.contains('Invalid login credentials')) return 'E-mail ou senha inválidos';
    if (raw.contains('Email not confirmed'))       return 'E-mail ainda não confirmado. Contate o administrador.';
    if (raw.contains('Sem internet'))              return raw.replaceFirst('Exception: ', '');
    if (raw.contains('nenhuma sessão offline'))    return raw.replaceFirst('Exception: ', '');
    if (raw.contains('Somente o usuário'))         return raw.replaceFirst('Exception: ', '');
    if (raw.contains('Conta não registrada'))      return raw.replaceFirst('Exception: ', '');
    if (raw.contains('Faça login com internet'))   return raw.replaceFirst('Exception: ', '');
    if (raw.contains('Senha incorreta'))           return 'Senha incorreta para acesso offline.';
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'Sem conexão com a internet';
    }
    return 'Falha ao fazer login. Verifique suas credenciais.';
  }

  // ── VISUAL: fundo único escuro, sem divisão de cores ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _kBg,
      body: Container(
        // Gradiente sutil do topo (mais verde) para baixo (mais escuro)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0e2418), _kBg],
            stops: [0.0, 0.65],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  const SizedBox(height: 52),

                  // ── Logo centralizado ───────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 88, height: 88,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'TECPOINT',
                    style: TextStyle(
                      color: _kText,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gerenciador de Ordens de Serviço',
                    style: TextStyle(color: _kTextMuted, fontSize: 12.5),
                  ),

                  const SizedBox(height: 52),

                  // ── Heading ─────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bem-vindo de volta',
                      style: TextStyle(
                        color: _kText,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: _kGreen.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _offline
                        ? 'Modo offline${_emailOfflineSalvo != null ? " · $_emailOfflineSalvo" : ""}'
                        : 'Entre com suas credenciais para acessar',
                      style: TextStyle(
                        color: _offline ? Colors.orange.shade400 : _kTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // ── Banner offline ──────────────────────────
                  if (_offline) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.30)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade400, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _emailOfflineSalvo != null
                                ? 'Modo offline disponível'
                                : 'Faça login online ao menos uma vez para habilitar o modo offline.',
                              style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Campo E-mail ────────────────────────────
                  _label('E-MAIL', Icons.email_outlined),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _emailCtrl,
                    hint: 'seu@email.com',
                    type: TextInputType.emailAddress,
                    validator: email,
                  ),

                  const SizedBox(height: 20),

                  // ── Campo Senha ─────────────────────────────
                  _label('SENHA', Icons.lock_outline),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _senhaCtrl,
                    hint: '••••••••',
                    obscure: _obscure,
                    validator: senha,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                        size: 20,
                        color: _kTextMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Botão ENTRAR ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kGreen.withOpacity(0.45),
                        elevation: 4,
                        shadowColor: _kGreen.withOpacity(0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _offline ? 'ENTRAR (MODO OFFLINE)' : 'ENTRAR',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Divisor decorativo ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.08),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(Icons.shield_outlined, size: 14, color: _kTextDim),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.08),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Acesso restrito a usuários autorizados',
                    style: TextStyle(color: _kTextDim, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2026 TECPOINT · UniSENAI MT',
                    style: TextStyle(color: Color(0xFF2a5238), fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Label de campo ───────────────────────────────────────────
  Widget _label(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 14, color: _kGreenGlow),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFd4e8da),
          letterSpacing: 0.9,
        ),
      ),
    ],
  );

  // ── Campo de input escuro semi-transparente ──────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kTextDim, fontSize: 15),
          filled: true,
          fillColor: _kInputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorderFoc, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFf87171), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFf87171), width: 1.5),
          ),
          errorStyle: const TextStyle(color: Color(0xFFf87171)),
        ),
      );
}
