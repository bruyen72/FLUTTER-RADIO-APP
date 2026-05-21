import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notificacao.dart';
import '../../services/notificacao_service.dart';
import '../../utils/constants.dart';

class NotificacaoListaScreen extends StatefulWidget {
  const NotificacaoListaScreen({super.key});

  @override
  State<NotificacaoListaScreen> createState() => _NotificacaoListaScreenState();
}

class _NotificacaoListaScreenState extends State<NotificacaoListaScreen> {
  List<Notificacao> _lista = [];
  bool _loading = true;
  String _filtro = 'todas';

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await NotificacaoService.listar();
    if (mounted) setState(() { _lista = lista; _loading = false; });
  }

  Future<void> _marcarTodas() async {
    await NotificacaoService.marcarTodasLidas();
    _carregar();
  }

  List<Notificacao> get _filtrada {
    if (_filtro == 'todas')     return _lista;
    if (_filtro == 'nao_lidas') return _lista.where((n) => !n.lida).toList();
    return _lista.where((n) => n.tipo == _filtro).toList();
  }

  // ── Cores e ícones por tipo — igual ao web CSS ───────────────
  Color _cor(String tipo) {
    switch (tipo) {
      case 'urgente': case 'danger': return kColorCancelado;
      case 'warning':                return kColorAndamento;
      case 'success':                return kColorConcluido;
      default:                       return kColorAberto;
    }
  }

  IconData _icone(String tipo) {
    switch (tipo) {
      case 'urgente': case 'danger': return Icons.local_fire_department_outlined;
      case 'warning':                return Icons.warning_amber_outlined;
      case 'success':                return Icons.check_circle_outline;
      default:                       return Icons.info_outline;
    }
  }

  // ── VISUAL ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fmt      = DateFormat('dd/MM/yyyy HH:mm');
    final naoLidas = _lista.where((n) => !n.lida).length;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text('Notificações${naoLidas > 0 ? " ($naoLidas)" : ""}'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (naoLidas > 0)
            TextButton.icon(
              onPressed: _marcarTodas,
              icon: const Icon(Icons.done_all, size: 16, color: kPrimaryLight),
              label: const Text('Marcar lidas',
                  style: TextStyle(color: kPrimaryLight, fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [

          // ── Stats: Total / Não lidas / Lidas ─────────────────
          if (!_loading && _lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  _statCard('Total',     _lista.length,                         kPrimaryLight,   Icons.notifications_outlined),
                  const SizedBox(width: 8),
                  _statCard('Não lidas', naoLidas,                              kColorAndamento, Icons.mark_email_unread_outlined),
                  const SizedBox(width: 8),
                  _statCard('Lidas',     _lista.length - naoLidas,              kColorConcluido, Icons.mark_email_read_outlined),
                ],
              ),
            ),

          // ── Filtros ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                for (final f in [
                  ('todas',     'Todas',    Icons.list_outlined),
                  ('nao_lidas', 'Não lidas',Icons.mark_email_unread_outlined),
                  ('info',      'Info',     Icons.info_outline),
                  ('urgente',   'Urgente',  Icons.local_fire_department_outlined),
                  ('success',   'Sucesso',  Icons.check_circle_outline),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filtroBtn(f.$1, f.$2, f.$3),
                  ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _filtrada.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: kCardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kBorderColor),
                              ),
                              child: const Icon(Icons.notifications_off_outlined,
                                  size: 40, color: kTextDim),
                            ),
                            const SizedBox(height: 16),
                            const Text('Nenhuma notificação',
                                style: TextStyle(color: kTextColor2, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Você está em dia!',
                                style: TextStyle(color: kTextDim, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        color: kPrimaryColor,
                        backgroundColor: kCardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                          itemCount: _filtrada.length,
                          itemBuilder: (_, i) => _buildItem(_filtrada[i], fmt),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Stat card compacto ────────────────────────────────────────
  Widget _statCard(String label, int valor, Color cor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$valor', style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(label, style: TextStyle(
                      color: cor.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botão de filtro estilo web ────────────────────────────────
  Widget _filtroBtn(String valor, String label, IconData icon) {
    final ativo = _filtro == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtro = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: ativo ? kPrimaryColor.withOpacity(0.18) : kCardColor,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: ativo ? kPrimaryColor.withOpacity(0.5) : kBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: ativo ? kPrimaryLight : kTextColor3),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: ativo ? kPrimaryLight : kTextColor3,
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  // ── Item de notificação ───────────────────────────────────────
  Widget _buildItem(Notificacao n, DateFormat fmt) {
    final cor = _cor(n.tipo);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: n.lida ? kCardColor : cor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: n.lida ? kBorderColor : cor.withOpacity(0.28),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (!n.lida) {
            await NotificacaoService.marcarLida(n.id);
            _carregar();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone colorido
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icone(n.tipo), color: cor, size: 18),
              ),
              const SizedBox(width: 12),
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.mensagem,
                      style: TextStyle(
                        color: kTextColor,
                        fontSize: 13.5,
                        fontWeight: n.lida ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: kTextDim),
                        const SizedBox(width: 4),
                        Text(fmt.format(n.criadoEm),
                            style: const TextStyle(fontSize: 11, color: kTextDim)),
                      ],
                    ),
                  ],
                ),
              ),
              // Ponto não lida
              if (!n.lida) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
