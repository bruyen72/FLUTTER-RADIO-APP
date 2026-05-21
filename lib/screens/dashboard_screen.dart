import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../widgets/offline_banner.dart';
import 'dashboard_home_screen.dart';
import 'os/os_lista_screen.dart';
import 'os/os_form_screen.dart';
import 'clientes/cliente_lista_screen.dart';
import 'equipamentos/equipamento_lista_screen.dart';
import 'notificacoes/notificacao_lista_screen.dart';
import 'usuarios/usuario_lista_screen.dart';
import 'perfil_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;
  Usuario? _usuario;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Tab 0 = Home sem Scaffold próprio; as demais têm Scaffold próprio
  final List<Widget> _telas = const [
    DashboardHomeScreen(),
    OsListaScreen(),
    ClienteListaScreen(),
    EquipamentoListaScreen(),
    PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SyncService.iniciar();
    _carregarUsuario();
  }

  @override
  void dispose() {
    SyncService.parar();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    try {
      final u = await AuthService.getProfile();
      if (mounted) setState(() => _usuario = u);
    } catch (_) {}
  }

  // Navega pelo bottom nav e fecha o drawer
  void _irParaTab(int index) {
    setState(() => _tabIndex = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  // Abre nova tela sobre o drawer e fecha o drawer
  void _irParaTela(Widget tela) {
    _scaffoldKey.currentState?.closeDrawer();
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _usuario?.isAdmin ?? false;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBgColor,
      // AppBar só no tab Home (outras telas têm AppBar próprio)
      appBar: _tabIndex == 0
          ? AppBar(
              backgroundColor: kSurfaceColor,
              foregroundColor: kTextColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: kTextColor),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(color: kTextColor, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: kPrimaryLight),
                  tooltip: 'Nova OS',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OsFormScreen()),
                  ),
                ),
              ],
            )
          : null,
      drawer: _buildDrawer(isAdmin),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _telas[_tabIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: kSurfaceColor,
        indicatorColor: kPrimaryColor.withOpacity(0.22),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: kTextColor3),
            selectedIcon: Icon(Icons.dashboard, color: kPrimaryLight),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined, color: kTextColor3),
            selectedIcon: Icon(Icons.assignment, color: kPrimaryLight),
            label: 'OS',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: kTextColor3),
            selectedIcon: Icon(Icons.people, color: kPrimaryLight),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined, color: kTextColor3),
            selectedIcon: Icon(Icons.devices, color: kPrimaryLight),
            label: 'Equip.',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: kTextColor3),
            selectedIcon: Icon(Icons.person, color: kPrimaryLight),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ── Drawer lateral ────────────────────────────────────────────
  Widget _buildDrawer(bool isAdmin) {
    final nome   = _usuario?.nome   ?? '...';
    final perfil = _usuario?.perfil ?? 'tecnico';

    return Drawer(
      backgroundColor: kBgColor,
      width: 280,
      child: Column(
        children: [

          // ── Header com dados do usuário ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0e2418), kCardColor],
              ),
              border: Border(bottom: BorderSide(color: kBorderColor)),
            ),
            child: Row(
              children: [
                // Avatar com inicial
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: kPrimaryLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          color: kTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Itens de navegação ───────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _itemTab(Icons.dashboard_outlined,    Icons.dashboard,          'Dashboard',         0),
                _itemTab(Icons.assignment_outlined,   Icons.assignment,         'Ordens de Serviço', 1),
                _itemTab(Icons.people_outline,        Icons.people,             'Clientes',          2),
                _itemTab(Icons.devices_outlined,      Icons.devices,            'Equipamentos',      3),
                _divider(),
                _itemTela(Icons.add_circle_outline,   'Nova OS',        const OsFormScreen()),
                _itemTela(Icons.notifications_outlined,'Notificações',  const NotificacaoListaScreen()),
                if (isAdmin)
                  _itemTela(Icons.manage_accounts_outlined, 'Usuários', const UsuarioListaScreen()),
                _divider(),
                _itemTab(Icons.person_outline, Icons.person, 'Perfil', 4),
              ],
            ),
          ),

          // ── Rodapé ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorderColor)),
            ),
            child: const Row(
              children: [
                Icon(Icons.cell_tower, color: kTextDim, size: 16),
                SizedBox(width: 8),
                Text(
                  'TECPOINT  ·  v1.0.0',
                  style: TextStyle(color: kTextDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Item que navega para um tab do bottom nav
  Widget _itemTab(IconData iconOff, IconData iconOn, String label, int index) {
    final ativo = _tabIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: ativo ? kPrimaryColor.withOpacity(0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: ativo ? Border.all(color: kPrimaryColor.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          ativo ? iconOn : iconOff,
          color: ativo ? kPrimaryLight : kTextColor3,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: ativo ? kPrimaryLight : kTextColor2,
            fontSize: 14,
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: ativo
            ? Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: () => _irParaTab(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Item que abre uma nova tela (push)
  Widget _itemTela(IconData icon, String label, Widget tela) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: kTextColor3, size: 22),
        title: Text(
          label,
          style: const TextStyle(color: kTextColor2, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: kTextDim, size: 18),
        onTap: () => _irParaTela(tela),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Divider(color: kBorderColor, height: 1),
  );
}
