import 'package:flutter/material.dart';
import '../../models/ordem_servico.dart';
import '../../services/os_service.dart';
import '../../utils/constants.dart';
import '../../widgets/os_card.dart';
import 'os_form_screen.dart';
import 'os_detalhe_screen.dart';

class OsListaScreen extends StatefulWidget {
  const OsListaScreen({super.key});

  @override
  State<OsListaScreen> createState() => _OsListaScreenState();
}

class _OsListaScreenState extends State<OsListaScreen> {
  List<OrdemServico> _lista = [];
  List<OrdemServico> _filtrada = [];
  // _clientes reservado para filtro futuro por cliente
  Map<String, int> _stats = {};
  bool _loading = true;
  String? _filtroStatus;
  String? _filtroPrioridade;
  String? _filtroClienteId;
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      OsService.listar(status: _filtroStatus, clienteId: _filtroClienteId, prioridade: _filtroPrioridade),
      OsService.obterStats(),
    ]);
    if (mounted) {
      setState(() {
        _lista = results[0] as List<OrdemServico>;
        _stats = results[1] as Map<String, int>;
        _loading = false;
      });
      _filtrar();
    }
  }

  void _filtrar() {
    final q = _buscaCtrl.text.toLowerCase();
    setState(() {
      _filtrada = _lista.where((os) {
        final matchBusca = q.isEmpty ||
            os.numeroOs.toLowerCase().contains(q) ||
            (os.clienteNome?.toLowerCase().contains(q) ?? false) ||
            (os.defeito?.toLowerCase().contains(q) ?? false);
        return matchBusca;
      }).toList();
    });
  }

  Widget _statCard(String label, int valor, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$valor',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: cor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'limpar', child: Text('Limpar filtros')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'status_null', child: Text('Status: Todos')),
              ...kStatusOS.map((s) => PopupMenuItem(value: 'status_$s', child: Text('Status: $s'))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'prio_null', child: Text('Prioridade: Todas')),
              ...kPrioridades.map((p) => PopupMenuItem(value: 'prio_$p', child: Text('Prioridade: $p'))),
            ],
            onSelected: (v) {
              if (v == 'limpar') {
                setState(() { _filtroStatus = null; _filtroPrioridade = null; _filtroClienteId = null; });
              } else if (v.startsWith('status_')) {
                final val = v.substring(7);
                setState(() => _filtroStatus = val.isEmpty || val == 'null' ? null : val);
              } else if (v.startsWith('prio_')) {
                final val = v.substring(5);
                setState(() => _filtroPrioridade = val.isEmpty || val == 'null' ? null : val);
              }
              _carregar();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_stats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(child: _statCard('Total', _stats['total'] ?? 0, kPrimaryColor)),
                  const SizedBox(width: 6),
                  Expanded(child: _statCard('Abertas', _stats['abertas'] ?? 0, Colors.blue)),
                  const SizedBox(width: 6),
                  Expanded(child: _statCard('Em\nAndamento', _stats['andamento'] ?? 0, Colors.orange)),
                  const SizedBox(width: 6),
                  Expanded(child: _statCard('Concluídas', _stats['concluidas'] ?? 0, Colors.green)),
                  const SizedBox(width: 6),
                  Expanded(child: _statCard('Urgentes', _stats['urgentes'] ?? 0, Colors.red)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              style: const TextStyle(color: kTextColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar OS, cliente...',
                hintStyle: const TextStyle(color: kTextDim, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: kTextColor3, size: 20),
                filled: true,
                fillColor: kCardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          if (_filtroStatus != null || _filtroPrioridade != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  if (_filtroStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text('Status: $_filtroStatus'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () { setState(() => _filtroStatus = null); _carregar(); },
                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                        labelStyle: const TextStyle(color: kPrimaryColor),
                      ),
                    ),
                  if (_filtroPrioridade != null)
                    Chip(
                      label: Text('Prioridade: $_filtroPrioridade'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () { setState(() => _filtroPrioridade = null); _carregar(); },
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.orange),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtrada.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 64, color: kTextColor3),
                            SizedBox(height: 12),
                            Text('Nenhuma OS encontrada',
                                style: TextStyle(color: kTextColor3)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filtrada.length,
                          itemBuilder: (_, i) => OsCard(
                            os: _filtrada[i],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OsDetalheScreen(os: _filtrada[i]),
                                ),
                              );
                              _carregar();
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OsFormScreen()),
          );
          _carregar();
        },
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova OS'),
      ),
    );
  }
}
