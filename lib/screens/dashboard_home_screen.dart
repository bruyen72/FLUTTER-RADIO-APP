import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../utils/constants.dart';
import 'os/os_form_screen.dart';
import 'os/os_lista_screen.dart';
import 'clientes/cliente_lista_screen.dart';
import 'equipamentos/equipamento_lista_screen.dart';
import 'notificacoes/notificacao_lista_screen.dart';
import 'usuarios/usuario_lista_screen.dart';
import 'relatorios/relatorio_screen.dart';

// Tela sem Scaffold próprio — renderizada dentro do DashboardScreen
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  Usuario? _usuario;
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      AuthService.getProfile(),
      OsService.obterStats(),
    ]);
    if (mounted) {
      setState(() {
        _usuario = results[0] as Usuario?;
        _stats   = results[1] as Map<String, int>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: kPrimaryColor,
      backgroundColor: kCardColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildGreeting(),
          const SizedBox(height: 22),
          _buildStats(),
          const SizedBox(height: 22),
          _buildNovaOsButton(context),
          const SizedBox(height: 22),
          _buildAcessoRapido(context),
        ],
      ),
    );
  }

  // ── Saudação ─────────────────────────────────────────────────
  Widget _buildGreeting() {
    final nome = _usuario?.nome ?? 'Usuário';
    final perfil = _usuario?.perfil ?? 'tecnico';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0e2418), Color(0xFF0F1C12)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá,',
                  style: TextStyle(color: kTextColor3, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  nome,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.35)),
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
          const SizedBox(width: 12),
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
            ),
            child: const Icon(Icons.cell_tower, color: kPrimaryLight, size: 26),
          ),
        ],
      ),
    );
  }

  // ── Cards de stats — layout horizontal igual ao web ──────────
  Widget _buildStats() {
    final itens = [
      ('Total',      _stats['total']      ?? 0, kPrimaryLight,   Icons.assignment_outlined),
      ('Abertas',    _stats['abertas']    ?? 0, kColorAberto,    Icons.folder_open_outlined),
      ('Andamento',  _stats['andamento']  ?? 0, kColorAndamento, Icons.pending_outlined),
      ('Concluídas', _stats['concluidas'] ?? 0, kColorConcluido, Icons.check_circle_outline),
      ('Canceladas', _stats['canceladas'] ?? 0, kColorCancelado, Icons.cancel_outlined),
      ('Urgentes',   _stats['urgentes']   ?? 0, kColorUrgente,   Icons.priority_high_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RESUMO DE OS',
          style: TextStyle(color: kTextColor3, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        // Grid responsivo: altura fixa 80px; tablet→3 colunas, celular→2 colunas
        LayoutBuilder(
          builder: (_, constraints) {
            final cols = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 80,
              ),
              itemCount: itens.length,
              itemBuilder: (_, i) {
                final item = itens[i];
                return _statCard(item.$1, item.$2, item.$3, item.$4);
              },
            );
          },
        ),
      ],
    );
  }

  // Layout horizontal: [Icon 48x48] | [Valor + Label] — igual ao web
  Widget _statCard(String label, int valor, Color cor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$valor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Botão Nova OS ─────────────────────────────────────────────
  Widget _buildNovaOsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OsFormScreen()),
          );
          _carregar();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: kPrimaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 22),
        label: const Text(
          'Nova Ordem de Serviço',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Acesso rápido ─────────────────────────────────────────────
  Widget _buildAcessoRapido(BuildContext context) {
    final isAdmin = _usuario?.isAdmin ?? false;

    final itens = [
      (Icons.assignment_outlined,      'Ordens de\nServiço',  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OsListaScreen()))),
      (Icons.people_outline,           'Clientes',            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteListaScreen()))),
      (Icons.devices_outlined,         'Equipamentos',        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipamentoListaScreen()))),
      (Icons.notifications_outlined,   'Notificações',        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacaoListaScreen()))),
      (Icons.picture_as_pdf_outlined,  'Relatórios',          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatorioScreen()))),
      if (isAdmin)
        (Icons.manage_accounts_outlined, 'Usuários',          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuarioListaScreen()))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACESSO RÁPIDO',
          style: TextStyle(color: kTextColor3, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        // Grid responsivo: altura fixa 100px; tablet→4+ colunas, celular→3 colunas
        LayoutBuilder(
          builder: (_, constraints) {
            final w    = constraints.maxWidth;
            final cols = w >= 800 ? 5 : w >= 600 ? 4 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 100,
              ),
              itemCount: itens.length,
              itemBuilder: (_, i) {
                final item = itens[i];
                return InkWell(
                  onTap: () => item.$3(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$1, color: kPrimaryLight, size: 26),
                        const SizedBox(height: 8),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: kTextColor2,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
