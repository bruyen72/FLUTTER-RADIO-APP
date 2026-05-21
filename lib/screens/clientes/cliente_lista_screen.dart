import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import '../../utils/constants.dart';
import 'cliente_form_screen.dart';

class ClienteListaScreen extends StatefulWidget {
  const ClienteListaScreen({super.key});

  @override
  State<ClienteListaScreen> createState() => _ClienteListaScreenState();
}

class _ClienteListaScreenState extends State<ClienteListaScreen> {
  List<Cliente> _lista = [];
  List<Cliente> _filtrada = [];
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
    try {
      final lista = await ClienteService.listar();
      if (mounted) {
        setState(() { _lista = lista; _loading = false; });
        _filtrar();
      }
    } catch (_) {
      if (mounted) setState(() { _lista = []; _loading = false; });
    }
  }

  void _filtrar() {
    final q = _buscaCtrl.text.toLowerCase();
    setState(() {
      _filtrada = q.isEmpty
          ? List.from(_lista)
          : _lista.where((c) =>
              c.nome.toLowerCase().contains(q) ||
              (c.telefone?.toLowerCase().contains(q) ?? false) ||
              (c.email?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Clientes'),
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
                hintText: 'Buscar cliente...',
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
                            Icon(Icons.people_outline, size: 64, color: kTextColor3),
                            SizedBox(height: 12),
                            Text('Nenhum cliente encontrado',
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
                            final c = _filtrada[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: kPrimaryColor,
                                  child: Text(
                                    c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(c.nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (c.telefone != null)
                                      Text(c.telefone!,
                                          style: const TextStyle(fontSize: 12)),
                                    if (c.email != null)
                                      Text(c.email!,
                                          style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClienteFormScreen(clienteParaEditar: c),
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
            MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
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
