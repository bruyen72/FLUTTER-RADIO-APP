import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? clienteParaEditar;
  const ClienteFormScreen({super.key, this.clienteParaEditar});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _form          = GlobalKey<FormState>();
  final _nomeCtrl      = TextEditingController();
  final _telCtrl       = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _cepCtrl       = TextEditingController();
  final _logradouroCtrl= TextEditingController();
  final _numeroCtrl    = TextEditingController();
  final _bairroCtrl    = TextEditingController();
  final _cidadeCtrl    = TextEditingController();
  final _ufCtrl        = TextEditingController();
  bool _salvando       = false;
  bool _buscandoCep    = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clienteParaEditar;
    if (c != null) {
      _nomeCtrl.text  = c.nome;
      _telCtrl.text   = c.telefone ?? '';
      _emailCtrl.text = c.email    ?? '';
      // Preenche os 5 campos estruturados se existirem,
      // senão coloca o endereço antigo no logradouro
      if (c.logradouro != null && c.logradouro!.isNotEmpty) {
        _logradouroCtrl.text = c.logradouro!;
        _numeroCtrl.text     = c.numeroComplemento ?? '';
        _bairroCtrl.text     = c.bairro   ?? '';
        _cidadeCtrl.text     = c.cidade   ?? '';
        _ufCtrl.text         = c.uf       ?? '';
      } else {
        _logradouroCtrl.text = c.endereco ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _ufCtrl.dispose();
    super.dispose();
  }

  // Concatena os 5 campos em endereço completo para exibição
  String? _buildEndereco() {
    final log = _logradouroCtrl.text.trim();
    final num = _numeroCtrl.text.trim();
    final bai = _bairroCtrl.text.trim();
    final cid = _cidadeCtrl.text.trim();
    final uf  = _ufCtrl.text.trim();
    final parts = <String>[];
    if (log.isNotEmpty) parts.add(num.isNotEmpty ? '$log, $num' : log);
    if (bai.isNotEmpty) parts.add(bai);
    if (cid.isNotEmpty) parts.add(uf.isNotEmpty ? '$cid - $uf' : cid);
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _buscarCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return;
    setState(() => _buscandoCep = true);
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client
          .getUrl(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 8));
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final j = jsonDecode(body) as Map<String, dynamic>;
        if (j['erro'] != true && mounted) {
          setState(() {
            _logradouroCtrl.text = j['logradouro'] as String? ?? '';
            _bairroCtrl.text     = j['bairro']     as String? ?? '';
            _cidadeCtrl.text     = j['localidade']  as String? ?? '';
            _ufCtrl.text         = j['uf']          as String? ?? '';
          });
        }
      }
    } catch (_) {
      // sem internet ou timeout — ignora silenciosamente
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final dados = {
        'nome':               _nomeCtrl.text.trim(),
        'telefone':           _telCtrl.text.trim().isEmpty  ? null : _telCtrl.text.trim(),
        'email':              _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'logradouro':         _logradouroCtrl.text.trim().isEmpty ? null : _logradouroCtrl.text.trim(),
        'numero_complemento': _numeroCtrl.text.trim().isEmpty ? null : _numeroCtrl.text.trim(),
        'bairro':             _bairroCtrl.text.trim().isEmpty ? null : _bairroCtrl.text.trim(),
        'cidade':             _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
        'uf':                 _ufCtrl.text.trim().isEmpty ? null : _ufCtrl.text.trim(),
        'endereco':           _buildEndereco(),
      };
      if (widget.clienteParaEditar == null) {
        await ClienteService.criar(dados);
      } else {
        await ClienteService.atualizar(widget.clienteParaEditar!.id, dados);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.clienteParaEditar == null ? 'Cliente criado!' : 'Cliente atualizado!'),
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

  @override
  Widget build(BuildContext context) {
    final criando = widget.clienteParaEditar == null;
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(criando ? 'Novo Cliente' : 'Editar Cliente'),
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

            // ── Dados do Cliente ─────────────────────────────
            _secao('Dados do Cliente', Icons.person_outline),
            const SizedBox(height: 16),
            _campo('Nome *',   _nomeCtrl,  validator: obrigatorio),
            _campo('Telefone', _telCtrl,   validator: telefone, type: TextInputType.phone),
            _campo('E-mail',   _emailCtrl, type: TextInputType.emailAddress),

            // ── Endereço ─────────────────────────────────────
            _secao('Endereço', Icons.location_on_outlined),
            const SizedBox(height: 16),

            // CEP com busca automática
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: const TextStyle(color: kTextColor, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'CEP (auto-preenche)',
                  labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
                  filled: true,
                  fillColor: kCardColor,
                  suffixIcon: _buscandoCep
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kPrimaryLight)),
                        )
                      : const Icon(Icons.search, color: kTextColor3, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onChanged: (v) {
                  if (v.length == 8) _buscarCep(v);
                },
              ),
            ),

            // Logradouro
            _campo('Logradouro', _logradouroCtrl),

            // Número / Complemento e Bairro
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _campo('Número / Complemento', _numeroCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Bairro', _bairroCtrl)),
              ],
            ),

            // Cidade e UF
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _campo('Cidade', _cidadeCtrl)),
                const SizedBox(width: 12),
                SizedBox(width: 80, child: _campo('UF', _ufCtrl)),
              ],
            ),

            const SizedBox(height: 24),
            _botaoSalvar(criando),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, IconData icon) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kPrimaryLight, size: 18),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(titulo,
          style: const TextStyle(
              color: kTextColor, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ],
  );

  Widget _campo(String label, TextEditingController ctrl, {
    String? Function(String?)? validator,
    TextInputType? type,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          validator: validator,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: kTextColor, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
            filled: true,
            fillColor: kCardColor,
            alignLabelWithHint: maxLines > 1,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kColorCancelado, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kColorCancelado, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      );

  Widget _botaoSalvar(bool criando) => SizedBox(
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
              criando ? 'CRIAR CLIENTE' : 'SALVAR ALTERAÇÕES',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
    ),
  );
}
