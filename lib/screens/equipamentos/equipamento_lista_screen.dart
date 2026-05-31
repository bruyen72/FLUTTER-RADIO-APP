import 'package:flutter/material.dart';
import '../../models/equipamento.dart';
import '../../services/equipamento_service.dart';
import '../../utils/constants.dart';
import 'equipamento_form_screen.dart';

class EquipamentoListaScreen extends StatefulWidget {
  const EquipamentoListaScreen({super.key});

  @override
  State<EquipamentoListaScreen> createState() => _EquipamentoListaScreenState();
}

class _EquipamentoListaScreenState extends State<EquipamentoListaScreen> {
  List<Equipamento> _lista = [];
  List<Equipamento> _filtrada = [];
  bool _loading = true;
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
    final lista = await EquipamentoService.listar();
    if (mounted) {
      setState(() { _lista = lista; _loading = false; });
      _filtrar();
    }
  }

  void _filtrar() {
    final q = _buscaCtrl.text.toLowerCase();
    setState(() {
      _filtrada = q.isEmpty
          ? List.from(_lista)
          : _lista.where((e) =>
              e.marca.toLowerCase().contains(q) ||
              e.modelo.toLowerCase().contains(q) ||
              e.numeroSerie.toLowerCase().contains(q) ||
              e.tipo.toLowerCase().contains(q) ||
              (e.clienteNome?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Equipamentos'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              style: const TextStyle(color: kTextColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por marca, modelo, série...',
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtrada.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices_outlined, size: 64, color: kTextColor3),
                            SizedBox(height: 12),
                            Text('Nenhum equipamento encontrado',
                                style: TextStyle(color: kTextColor3)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filtrada.length,
                          itemBuilder: (_, i) {
                            final e = _filtrada[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.devices, color: kPrimaryColor),
                                ),
                                title: Text('${e.marca} ${e.modelo}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.tipo, style: const TextStyle(fontSize: 12)),
                                    Text('Série: ${e.numeroSerie}',
                                        style: TextStyle(
                                            fontSize: 11, color: kTextColor3)),
                                    if (e.clienteNome != null)
                                      Text('Cliente: ${e.clienteNome}',
                                          style: const TextStyle(
                                              fontSize: 11, color: kPrimaryColor)),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: kTextColor3),
                                  color: kCardColor,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'editar',    child: Text('Editar')),
                                    PopupMenuItem(value: 'desativar', child: Text('Desativar')),
                                    PopupMenuItem(value: 'apagar',    child: Text('Apagar', style: TextStyle(color: Colors.red))),
                                  ],
                                  onSelected: (v) async {
                                    if (v == 'editar') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EquipamentoFormScreen(equipParaEditar: e),
                                        ),
                                      );
                                      _carregar();
                                    } else if (v == 'desativar') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Desativar Equipamento'),
                                          content: Text('Desativar "${e.marca} ${e.modelo}"?\nEle não será deletado.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                            TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Desativar')),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await EquipamentoService.desativar(e.id);
                                        _carregar();
                                      }
                                    } else if (v == 'apagar') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Apagar Equipamento'),
                                          content: Text('Apagar "${e.marca} ${e.modelo}" permanentemente?\nEsta ação não pode ser desfeita.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Apagar', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await EquipamentoService.deletar(e.id);
                                        _carregar();
                                      }
                                    }
                                  },
                                ),
                                isThreeLine: true,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EquipamentoFormScreen(equipParaEditar: e),
                                    ),
                                  );
                                  _carregar();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EquipamentoFormScreen()),
          );
          _carregar();
        },
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
