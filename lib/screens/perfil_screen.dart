import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../models/usuario.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'relatorios/relatorio_screen.dart';
import 'notificacoes/notificacao_lista_screen.dart';
import 'usuarios/usuario_lista_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  bool _loading = true;
  bool _sincronizando = false;

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final u = await AuthService.getProfile();
      if (mounted) setState(() { _usuario = u; });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    await SyncService.sincronizarAgora();
    if (mounted) {
      setState(() => _sincronizando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronização concluída'), backgroundColor: kPrimaryColor),
      );
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sair', style: TextStyle(color: kTextColor)),
        content: const Text('Deseja sair do aplicativo?', style: TextStyle(color: kTextColor2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: kTextColor3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: kColorCancelado)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // ── VISUAL ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Card do usuário ───────────────────────────
                _buildUserCard(),
                const SizedBox(height: 20),

                // ── Menu ─────────────────────────────────────
                _menuLabel('SISTEMA'),
                const SizedBox(height: 8),
                _menuCard([
                  _menuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notificações',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificacaoListaScreen())),
                  ),
                  if (_usuario?.isAdmin == true)
                    _menuItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Gerenciar Usuários',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const UsuarioListaScreen())),
                    ),
                  _menuItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Relatórios / Gerar PDF',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RelatorioScreen())),
                  ),
                  _menuItem(
                    icon: Icons.sync_outlined,
                    label: 'Sincronizar dados offline',
                    trailing: _sincronizando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryLight))
                        : null,
                    onTap: _sincronizando ? null : _sincronizar,
                  ),
                  _menuItem(
                    icon: Icons.info_outline,
                    label: 'Versão do app',
                    trailing: const Text('1.0.0',
                        style: TextStyle(color: kTextColor3, fontSize: 13)),
                    showArrow: false,
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Zona de perigo ────────────────────────────
                _menuLabel('CONTA'),
                const SizedBox(height: 8),
                _menuCard([
                  _menuItem(
                    icon: Icons.logout,
                    label: 'Sair do aplicativo',
                    labelColor: kColorCancelado,
                    iconColor: kColorCancelado,
                    showArrow: false,
                    onTap: _logout,
                  ),
                ]),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ── Card do usuário no topo ────────────────────────────────────
  Widget _buildUserCard() {
    final nome   = _usuario?.nome   ?? 'Usuário';
    final email  = _usuario?.email  ?? '';
    final perfil = _usuario?.perfil ?? 'tecnico';
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0e2418), kCardColor],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                inicial,
                style: const TextStyle(
                  color: kPrimaryLight,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(color: kTextColor3, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    perfil.toUpperCase(),
                    style: const TextStyle(
                      color: kPrimaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Label de seção ────────────────────────────────────────────
  Widget _menuLabel(String texto) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      texto,
      style: const TextStyle(
        color: kTextDim,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );

  // ── Container de grupo de itens ────────────────────────────────
  Widget _menuCard(List<Widget> itens) => Container(
    decoration: BoxDecoration(
      color: kCardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorderColor),
    ),
    child: Column(
      children: itens,
    ),
  );

  // ── Item de menu ──────────────────────────────────────────────
  Widget _menuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    bool showArrow = true,
    Color? labelColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? kPrimaryLight, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? kTextColor2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && showArrow)
              const Icon(Icons.chevron_right, color: kTextDim, size: 18),
          ],
        ),
      ),
    );
  }
}
