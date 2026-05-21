import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../models/equipamento.dart';
import '../../services/cliente_service.dart';
import '../../services/equipamento_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class EquipamentoFormScreen extends StatefulWidget {
  final Equipamento? equipParaEditar;
  const EquipamentoFormScreen({super.key, this.equipParaEditar});

  @override
  State<EquipamentoFormScreen> createState() => _EquipamentoFormScreenState();
}

class _EquipamentoFormScreenState extends State<EquipamentoFormScreen> {
  final _form       = GlobalKey<FormState>();
  final _tipoCtrl   = TextEditingController();
  final _marcaCtrl  = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _serieCtrl  = TextEditingController();
  final _corCtrl    = TextEditingController();
  final _canalCtrl  = TextEditingController();
  String? _clienteId;
  List<Cliente> _clientes = [];
  bool _loading  = true;
  bool _salvando = false;

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _carregarClientes();
    if (widget.equipParaEditar != null) {
      final e = widget.equipParaEditar!;
      _tipoCtrl.text   = e.tipo;
      _marcaCtrl.text  = e.marca;
      _modeloCtrl.text = e.modelo;
      _serieCtrl.text  = e.numeroSerie;
      _corCtrl.text    = e.corIdentificacao ?? '';
      _canalCtrl.text  = e.canalFrequencia  ?? '';
      _clienteId       = e.clienteId;
    }
  }

  @override
  void dispose() {
    for (final c in [_tipoCtrl, _marcaCtrl, _modeloCtrl, _serieCtrl, _corCtrl, _canalCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    try {
      final lista = await ClienteService.listar();
      if (mounted) setState(() => _clientes = lista);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o cliente'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final dados = {
        'tipo':              _tipoCtrl.text.trim(),
        'marca':             _marcaCtrl.text.trim(),
        'modelo':            _modeloCtrl.text.trim(),
        'numero_serie':      _serieCtrl.text.trim(),
        'cliente_id':        _clienteId,
        'cor_identificacao': _corCtrl.text.trim().isEmpty   ? null : _corCtrl.text.trim(),
        'canal_frequencia':  _canalCtrl.text.trim().isEmpty ? null : _canalCtrl.text.trim(),
      };
      if (widget.equipParaEditar == null) {
        await EquipamentoService.criar(dados);
      } else {
        await EquipamentoService.atualizar(widget.equipParaEditar!.id, dados);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.equipParaEditar == null ? 'Equipamento criado!' : 'Equipamento atualizado!'),
          backgroundColor: kPrimaryColor,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ── VISUAL ────────────────────────────────────────────────────
  static final _inputBorder = OutlineInputBorder(
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

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
    filled: true,
    fillColor: kCardColor,
    enabledBorder: _inputBorder,
    focusedBorder: _focusBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final criando = widget.equipParaEditar == null;
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(criando ? 'Novo Equipamento' : 'Editar Equipamento'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  // ── Cliente ───────────────────────────────────
                  _secaoLabel('Vínculo', Icons.people_outline),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _clienteId,
                    dropdownColor: kCardColor,
                    style: const TextStyle(color: kTextColor, fontSize: 15),
                    decoration: _dec('Cliente *'),
                    items: _clientes
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nome, style: const TextStyle(color: kTextColor)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _clienteId = v),
                    validator: (v) => v == null ? 'Selecione o cliente' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Identificação ─────────────────────────────
                  _secaoLabel('Identificação', Icons.devices_outlined),
                  const SizedBox(height: 12),
                  _campo('Tipo *',             _tipoCtrl,   validator: obrigatorio),
                  _campo('Marca *',            _marcaCtrl,  validator: obrigatorio),
                  _campo('Modelo *',           _modeloCtrl, validator: obrigatorio),
                  _campo('Número de Série *',  _serieCtrl,  validator: obrigatorio),
                  const SizedBox(height: 4),

                  // ── Extras ────────────────────────────────────
                  _secaoLabel('Informações Extras', Icons.tune_outlined),
                  const SizedBox(height: 12),
                  _campo('Cor de Identificação', _corCtrl),
                  _campo('Canal / Frequência',   _canalCtrl),
                  const SizedBox(height: 24),

                  // ── Botão ─────────────────────────────────────
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
                              criando ? 'CRIAR EQUIPAMENTO' : 'SALVAR ALTERAÇÕES',
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

  Widget _secaoLabel(String titulo, IconData icon) => Row(
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
      Text(titulo, style: const TextStyle(color: kTextColor2, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _campo(String label, TextEditingController ctrl, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(color: kTextColor, fontSize: 15),
          decoration: _dec(label),
        ),
      );
}
