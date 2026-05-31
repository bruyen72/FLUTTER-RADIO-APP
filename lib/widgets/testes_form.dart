import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/os_testes.dart';
import '../services/os_service.dart';
import '../widgets/foto_picker.dart';
import '../utils/constants.dart';

/// Widget com checklist de testes realizados no rádio (Melhoria 4)
class TestesForm extends StatefulWidget {
  final String osId;
  final List<String> fotosTesteUrls;
  final VoidCallback? onSalvo;

  const TestesForm({
    super.key,
    required this.osId,
    this.fotosTesteUrls = const [],
    this.onSalvo,
  });

  @override
  State<TestesForm> createState() => _TestesFormState();
}

class _TestesFormState extends State<TestesForm> {
  bool _carregando = true;
  bool _salvando   = false;

  List<OsTesteItem> _testes = [];
  final Map<String, TextEditingController> _obsCtrl = {};

  // Fotos dos testes
  List<String> _fotosUrls   = [];
  final List<File> _fotosLocais = [];

  @override
  void initState() {
    super.initState();
    _fotosUrls = List<String>.from(widget.fotosTesteUrls);
    _carregar();
  }

  @override
  void dispose() {
    for (final c in _obsCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await OsService.listarTestes(widget.osId);
      final testes = lista.isEmpty ? OsTesteItem.padrao() : lista;
      final ctrl = <String, TextEditingController>{};
      for (final t in testes) {
        ctrl[t.itemId] = TextEditingController(text: t.observacao);
      }
      if (mounted) {
        setState(() {
          _testes  = testes;
          _obsCtrl.clear();
          _obsCtrl.addAll(ctrl);
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      // Salva testes
      final atualizados = _testes.map((t) => t.copyWith(
        observacao: _obsCtrl[t.itemId]?.text.trim() ?? '',
        dataVerificacao: t.feito ? DateTime.now() : null,
      )).toList();
      await OsService.salvarTestes(widget.osId, atualizados);

      // Copia fotos locais para storage permanente antes de salvar
      final permanentes = <String>[];
      for (final f in _fotosLocais) {
        try {
          final caminho = await OsService.copiarFotoParaPermanente(f, widget.osId);
          permanentes.add(caminho);
        } catch (_) {
          permanentes.add(f.path);
        }
      }
      final todasFotos = [..._fotosUrls, ...permanentes];
      await OsService.atualizarFotosSecao(widget.osId, 'fotos_testes', todasFotos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Testes salvos com sucesso'),
          backgroundColor: kPrimaryDark,
        ));
        setState(() => _fotosLocais.clear());
        widget.onSalvo?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de testes com checkbox + campo observação
        ..._testes.asMap().entries.map((entry) {
          final i    = entry.key;
          final test = entry.value;
          final ctrl = _obsCtrl[test.itemId] ??= TextEditingController();
          return _testeItem(test, ctrl, i);
        }),

        const SizedBox(height: 16),

        // Fotos dos testes
        _secao('Fotos dos Testes (máx 5)'),
        FotoPicker(
          fotosUrl: _fotosUrls,
          fotosLocais: _fotosLocais,
          onFotoAdicionada: (_fotosUrls.length + _fotosLocais.length) >= 5
              ? (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Máximo de 5 fotos atingido')),
                  )
              : (f) => setState(() => _fotosLocais.add(f)),
          onFotoUrlRemovida: (i) => setState(() => _fotosUrls.removeAt(i)),
          onFotoLocalRemovida: (i) => setState(() => _fotosLocais.removeAt(i)),
        ),

        const SizedBox(height: 24),

        // Botão salvar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _salvando ? null : _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kCardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _salvando
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.checklist_outlined),
            label: Text(
              _salvando ? 'Salvando...' : 'Salvar Testes',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _testeItem(OsTesteItem test, TextEditingController obsCtrl, int index) {
    final feito = test.feito;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: feito
            ? kPrimaryColor.withOpacity(0.08)
            : kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: feito ? kPrimaryColor.withOpacity(0.4) : kBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha do checkbox
          CheckboxListTile(
            value: feito,
            onChanged: (v) => setState(() {
              _testes[index] = test.copyWith(feito: v ?? false);
            }),
            title: Text(
              test.itemNome,
              style: TextStyle(
                color: feito ? kPrimaryLight : kTextColor,
                fontSize: 14,
                fontWeight: feito ? FontWeight.w600 : FontWeight.w400,
                decoration: feito ? TextDecoration.none : null,
              ),
            ),
            activeColor: kPrimaryColor,
            checkColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          // Campo de observação
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextFormField(
              controller: obsCtrl,
              style: const TextStyle(color: kTextColor2, fontSize: 13),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Observação (opcional)',
                hintStyle: const TextStyle(color: kTextDim, fontSize: 12),
                filled: true,
                fillColor: const Color(0x08FFFFFF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 3, height: 16, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(titulo, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: kPrimaryLight)),
        ]),
      );
}
