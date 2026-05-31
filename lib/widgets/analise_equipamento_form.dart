import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/os_analise_equipamento.dart';
import '../services/os_service.dart';
import '../utils/constants.dart';

class AnaliseEquipamentoForm extends StatefulWidget {
  final String osId;
  final EquipamentoOS? analiseExistente;
  final VoidCallback? onSalvo;
  /// false → esconde o botão "Salvar Análise" (use quando há botão externo que
  /// chama salvarSePreenchido(), como no os_form_screen.dart)
  final bool mostrarBotaoSalvar;

  const AnaliseEquipamentoForm({
    super.key,
    required this.osId,
    this.analiseExistente,
    this.onSalvo,
    this.mostrarBotaoSalvar = true,
  });

  @override
  State<AnaliseEquipamentoForm> createState() => AnaliseEquipamentoFormState();
}

class AnaliseEquipamentoFormState extends State<AnaliseEquipamentoForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _formKey = GlobalKey<FormState>();
  bool _salvando = false;

  late String _analiseId;

  // Identificação geral
  String _tipoEquipamento = '';
  final _idNomeCtrl       = TextEditingController();
  final _modeloCtrl       = TextEditingController();
  final _numeroSerieCtrl  = TextEditingController();

  // ── Campos de Rádio (Melhoria 3) ──────────────────────────
  String _tipoRadio = '';
  String _marcaRadio = '';
  String _faixa = '';
  final _firmwareCtrl             = TextEditingController();
  final _condicoesFisicasRadioCtrl = TextEditingController();
  final _defeitosRelatadosCtrl    = TextEditingController();
  final Set<String> _acessoriosRadio = {};
  final _solucaoPropostaCtrl      = TextEditingController();
  final _laudoTecnicoRadioCtrl    = TextEditingController();
  final _termosGarantiaCtrl       = TextEditingController();

  // Sistema Irradiante
  final _tipoAntenaCtrl   = TextEditingController();
  final _alturaAntenaCtrl = TextEditingController();
  final _tipoCaboCtrl     = TextEditingController();
  final _comprCaboCtrl    = TextEditingController();

  // Medições de RF
  final _freqTxCtrl            = TextEditingController();
  final _freqRxCtrl            = TextEditingController();
  final _potenciaCtrl          = TextEditingController();
  final _potenciaRefletidaCtrl = TextEditingController();
  final _roeVswrCtrl           = TextEditingController();

  // Alimentação
  bool _possuiFonteDedicada = false;
  final _voltagemFonteCtrl = TextEditingController();

  // Observações
  final _observacoesCtrl = TextEditingController();

  // Fotos (máx 5)
  final List<File> _fotosLocais    = [];
  List<String>     _fotosExistentes = [];

  // Opções estáticas
  static const _tiposEquipamento = [
    'Repetidora', 'Rádio Base', 'Rádio Móvel', 'Rádio Portátil',
    'Antena', 'Cabo', 'Outro',
  ];
  static const _tiposRadio = ['Portátil', 'Móvel', 'Repetidora', 'Base'];
  static const _marcasRadio = ['Hytera', 'Motorola', 'Kenwood', 'Icom', 'Outro'];
  static const _faixasRadio = ['VHF', 'UHF', '700MHz', '800MHz'];
  static const _acessoriosOpcoes = ['Antena', 'Bateria', 'Carregador', 'Clipe'];

  @override
  void initState() {
    super.initState();
    _analiseId = widget.analiseExistente?.id ?? const Uuid().v4();
    _preencherExistente();
  }

  @override
  void didUpdateWidget(AnaliseEquipamentoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só repreenche se o ID da análise mudou de verdade (novo registro carregado).
    // Comparar por referência de objeto causava reset toda vez que o pai
    // chamava setState, apagando o que o usuário estava digitando.
    final oldId = oldWidget.analiseExistente?.id;
    final newId = widget.analiseExistente?.id;
    if (newId != null && newId != oldId) {
      _analiseId = newId;
      setState(() => _preencherExistente());
    }
  }

  void _preencherExistente() {
    final a = widget.analiseExistente;
    if (a == null) return;
    _tipoEquipamento              = a.tipoEquipamento;
    _idNomeCtrl.text              = a.idNome;
    _modeloCtrl.text              = a.modelo;
    _numeroSerieCtrl.text         = a.numeroSerie;
    _tipoRadio                    = a.tipoRadio;
    _marcaRadio                   = a.marcaRadio;
    _faixa                        = a.faixa;
    _firmwareCtrl.text            = a.firmware;
    _condicoesFisicasRadioCtrl.text = a.condicoesFisicasRadio;
    _defeitosRelatadosCtrl.text   = a.defeitosRelatados;
    _acessoriosRadio
      ..clear()
      ..addAll(a.acessoriosRadio);
    _solucaoPropostaCtrl.text     = a.solucaoProposta;
    _laudoTecnicoRadioCtrl.text   = a.laudoTecnicoRadio;
    _termosGarantiaCtrl.text      = a.termosGarantia;
    _tipoAntenaCtrl.text          = a.tipoAntena;
    _alturaAntenaCtrl.text        = a.alturaAntena == 0.0 ? '' : a.alturaAntena.toString();
    _tipoCaboCtrl.text            = a.tipoCabo;
    _comprCaboCtrl.text           = a.comprCabo == 0.0 ? '' : a.comprCabo.toString();
    _freqTxCtrl.text              = a.freqTx == 0.0 ? '' : a.freqTx.toString();
    _freqRxCtrl.text              = a.freqRx == 0.0 ? '' : a.freqRx.toString();
    _potenciaCtrl.text            = a.potencia == 0.0 ? '' : a.potencia.toString();
    _potenciaRefletidaCtrl.text   = a.potenciaRefletida == 0.0 ? '' : a.potenciaRefletida.toString();
    _roeVswrCtrl.text             = a.roeVswr;
    _possuiFonteDedicada          = a.possuiFonteDedicada;
    _voltagemFonteCtrl.text       = a.voltagemFonte;
    _observacoesCtrl.text         = a.observacoes;
    _fotosExistentes              = List<String>.from(a.fotos);
  }

  @override
  void dispose() {
    _idNomeCtrl.dispose();
    _modeloCtrl.dispose();
    _numeroSerieCtrl.dispose();
    _firmwareCtrl.dispose();
    _condicoesFisicasRadioCtrl.dispose();
    _defeitosRelatadosCtrl.dispose();
    _solucaoPropostaCtrl.dispose();
    _laudoTecnicoRadioCtrl.dispose();
    _termosGarantiaCtrl.dispose();
    _tipoAntenaCtrl.dispose();
    _alturaAntenaCtrl.dispose();
    _tipoCaboCtrl.dispose();
    _comprCaboCtrl.dispose();
    _freqTxCtrl.dispose();
    _freqRxCtrl.dispose();
    _potenciaCtrl.dispose();
    _potenciaRefletidaCtrl.dispose();
    _roeVswrCtrl.dispose();
    _voltagemFonteCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  int get _totalFotos => _fotosExistentes.length + _fotosLocais.length;

  bool _temDados() =>
      _tipoEquipamento.isNotEmpty ||
      _tipoRadio.isNotEmpty ||
      _marcaRadio.isNotEmpty ||
      _idNomeCtrl.text.trim().isNotEmpty ||
      _modeloCtrl.text.trim().isNotEmpty ||
      _numeroSerieCtrl.text.trim().isNotEmpty ||
      _faixa.isNotEmpty ||
      _firmwareCtrl.text.trim().isNotEmpty ||
      _condicoesFisicasRadioCtrl.text.trim().isNotEmpty ||
      _defeitosRelatadosCtrl.text.trim().isNotEmpty ||
      _acessoriosRadio.isNotEmpty ||
      _solucaoPropostaCtrl.text.trim().isNotEmpty ||
      _laudoTecnicoRadioCtrl.text.trim().isNotEmpty ||
      _termosGarantiaCtrl.text.trim().isNotEmpty ||
      _tipoAntenaCtrl.text.trim().isNotEmpty ||
      _tipoCaboCtrl.text.trim().isNotEmpty ||
      _freqTxCtrl.text.trim().isNotEmpty ||
      _freqRxCtrl.text.trim().isNotEmpty ||
      _potenciaCtrl.text.trim().isNotEmpty ||
      _roeVswrCtrl.text.trim().isNotEmpty ||
      _alturaAntenaCtrl.text.trim().isNotEmpty ||
      _comprCaboCtrl.text.trim().isNotEmpty ||
      _potenciaRefletidaCtrl.text.trim().isNotEmpty ||
      _voltagemFonteCtrl.text.trim().isNotEmpty ||
      _observacoesCtrl.text.trim().isNotEmpty ||
      _possuiFonteDedicada ||
      _fotosLocais.isNotEmpty ||
      _fotosExistentes.isNotEmpty;

  // Constrói o objeto com lista de fotos personalizada (caminhos permanentes)
  EquipamentoOS _buildEquipComFotos(List<String> fotos) => EquipamentoOS(
        id: _analiseId,
        osId: widget.osId,
        tipoEquipamento: _tipoEquipamento,
        idNome: _idNomeCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        numeroSerie: _numeroSerieCtrl.text.trim(),
        tipoRadio: _tipoRadio,
        marcaRadio: _marcaRadio,
        faixa: _faixa,
        firmware: _firmwareCtrl.text.trim(),
        condicoesFisicasRadio: _condicoesFisicasRadioCtrl.text.trim(),
        defeitosRelatados: _defeitosRelatadosCtrl.text.trim(),
        acessoriosRadio: _acessoriosRadio.toList(),
        solucaoProposta: _solucaoPropostaCtrl.text.trim(),
        laudoTecnicoRadio: _laudoTecnicoRadioCtrl.text.trim(),
        termosGarantia: _termosGarantiaCtrl.text.trim(),
        tipoAntena: _tipoAntenaCtrl.text.trim(),
        alturaAntena: double.tryParse(_alturaAntenaCtrl.text) ?? 0.0,
        tipoCabo: _tipoCaboCtrl.text.trim(),
        comprCabo: double.tryParse(_comprCaboCtrl.text) ?? 0.0,
        freqTx: double.tryParse(_freqTxCtrl.text) ?? 0.0,
        freqRx: double.tryParse(_freqRxCtrl.text) ?? 0.0,
        potencia: double.tryParse(_potenciaCtrl.text) ?? 0.0,
        potenciaRefletida: double.tryParse(_potenciaRefletidaCtrl.text) ?? 0.0,
        roeVswr: _roeVswrCtrl.text.trim(),
        possuiFonteDedicada: _possuiFonteDedicada,
        voltagemFonte: _voltagemFonteCtrl.text.trim(),
        observacoes: _observacoesCtrl.text.trim(),
        fotos: fotos,
      );

  EquipamentoOS _buildEquip() => EquipamentoOS(
        id: _analiseId,
        osId: widget.osId,
        tipoEquipamento: _tipoEquipamento,
        idNome: _idNomeCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        numeroSerie: _numeroSerieCtrl.text.trim(),
        tipoRadio: _tipoRadio,
        marcaRadio: _marcaRadio,
        faixa: _faixa,
        firmware: _firmwareCtrl.text.trim(),
        condicoesFisicasRadio: _condicoesFisicasRadioCtrl.text.trim(),
        defeitosRelatados: _defeitosRelatadosCtrl.text.trim(),
        acessoriosRadio: _acessoriosRadio.toList(),
        solucaoProposta: _solucaoPropostaCtrl.text.trim(),
        laudoTecnicoRadio: _laudoTecnicoRadioCtrl.text.trim(),
        termosGarantia: _termosGarantiaCtrl.text.trim(),
        tipoAntena: _tipoAntenaCtrl.text.trim(),
        alturaAntena: double.tryParse(_alturaAntenaCtrl.text) ?? 0.0,
        tipoCabo: _tipoCaboCtrl.text.trim(),
        comprCabo: double.tryParse(_comprCaboCtrl.text) ?? 0.0,
        freqTx: double.tryParse(_freqTxCtrl.text) ?? 0.0,
        freqRx: double.tryParse(_freqRxCtrl.text) ?? 0.0,
        potencia: double.tryParse(_potenciaCtrl.text) ?? 0.0,
        potenciaRefletida: double.tryParse(_potenciaRefletidaCtrl.text) ?? 0.0,
        roeVswr: _roeVswrCtrl.text.trim(),
        possuiFonteDedicada: _possuiFonteDedicada,
        voltagemFonte: _voltagemFonteCtrl.text.trim(),
        observacoes: _observacoesCtrl.text.trim(),
        fotos: [..._fotosExistentes, ..._fotosLocais.map((f) => f.path)],
      );

  Future<void> _salvar() async {
    if (!_temDados()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha pelo menos um campo antes de salvar'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ));
      return;
    }
    return _executarSave(mostrarSnackbar: true);
  }

  Future<void> salvarSePreenchido() async {
    if (!_temDados()) return;
    await _executarSave(mostrarSnackbar: false);
  }

  Future<void> _executarSave({required bool mostrarSnackbar}) async {
    setState(() => _salvando = true);
    try {
      // Copia fotos locais para storage permanente antes de salvar.
      // Paths do image_picker são temporários no cache Android e somem.
      final fotasPermanentes = <String>[];
      for (final f in _fotosLocais) {
        try {
          final caminho = await OsService.copiarFotoParaPermanente(f, widget.osId);
          fotasPermanentes.add(caminho);
        } catch (_) {
          fotasPermanentes.add(f.path);
        }
      }
      // Substitui _fotosLocais pelos caminhos permanentes no objeto
      final equip = _buildEquipComFotos([..._fotosExistentes, ...fotasPermanentes]);
      await OsService.salvarAnaliseEquipamento(equip);
      if (mounted) {
        setState(() => _fotosLocais.clear());
        if (mostrarSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Análise salva com sucesso'),
            backgroundColor: kPrimaryDark,
          ));
        }
        widget.onSalvo?.call();
      }
    } catch (e) {
      if (mounted && mostrarSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ── Foto ──────────────────────────────────────────────────

  Future<void> _adicionarFoto() async {
    if (_totalFotos >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo de 5 fotos atingido')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: kBorderColor, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryLight),
              title: const Text('Tirar foto', style: TextStyle(color: kTextColor)),
              onTap: () { Navigator.pop(context); _capturar(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryLight),
              title: const Text('Escolher da galeria', style: TextStyle(color: kTextColor)),
              onTap: () { Navigator.pop(context); _capturar(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _capturar(ImageSource source) async {
    if (source == ImageSource.camera) {
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de câmera negada')),
        );
        return;
      }
    }
    try {
      final xfile = await ImagePicker().pickImage(
        source: source, imageQuality: 80, maxWidth: 1280,
      );
      if (xfile != null && mounted) {
        setState(() => _fotosLocais.add(File(xfile.path)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context); // obrigatório para AutomaticKeepAliveClientMixin
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identificação Geral ───────────────────────────
          _secao('Identificação'),
          _dropdown('Tipo de Equipamento', _tiposEquipamento, _tipoEquipamento,
              (v) => setState(() => _tipoEquipamento = v ?? '')),
          _campo('ID / Nome', _idNomeCtrl, hint: 'Ex: RPT-01-SEDE'),
          _campo('Modelo', _modeloCtrl, hint: 'Ex: SLR5700'),
          _campo('Número de Série', _numeroSerieCtrl, hint: 'Ex: 123ABC456'),

          // ── Dados específicos de Rádio (Melhoria 3) ──────
          _secao('Dados do Rádio'),
          _dropdown('Tipo de Rádio', _tiposRadio, _tipoRadio,
              (v) => setState(() => _tipoRadio = v ?? '')),
          _dropdown('Marca', _marcasRadio, _marcaRadio,
              (v) => setState(() => _marcaRadio = v ?? '')),
          _dropdown('Faixa', _faixasRadio, _faixa,
              (v) => setState(() => _faixa = v ?? '')),
          _campo('Firmware / Versão', _firmwareCtrl, hint: 'Ex: R06.16.01'),

          // ── Frequências e Potência ────────────────────────
          _secao('Frequências e Potência'),
          _campoNum('Freq. TX (MHz)', _freqTxCtrl, hint: 'Ex: 462.500'),
          _campoNum('Freq. RX (MHz)', _freqRxCtrl, hint: 'Ex: 467.550'),
          _campoNum('Potência TX (W)', _potenciaCtrl, hint: '45.0'),
          _campoNum('Potência Refletida (W)', _potenciaRefletidaCtrl, hint: '0.5'),
          _campo('ROE / VSWR', _roeVswrCtrl, hint: '1.2:1'),

          // ── Sistema Irradiante ────────────────────────────
          _secao('Sistema Irradiante'),
          _campo('Tipo de Antena', _tipoAntenaCtrl, hint: 'Ex: Dipolo 3dB'),
          _campoNum('Altura da Antena (m)', _alturaAntenaCtrl, hint: '30.0'),
          _campo('Tipo de Cabo', _tipoCaboCtrl, hint: 'Ex: RGC-213'),
          _campoNum('Comprimento do Cabo (m)', _comprCaboCtrl, hint: '40.0'),

          // ── Alimentação ───────────────────────────────────
          _secao('Alimentação'),
          CheckboxListTile(
            value: _possuiFonteDedicada,
            onChanged: (v) => setState(() => _possuiFonteDedicada = v ?? false),
            title: const Text('Possui Fonte Dedicada',
                style: TextStyle(color: kTextColor, fontSize: 14)),
            activeColor: kPrimaryColor,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_possuiFonteDedicada) ...[
            const SizedBox(height: 8),
            _campo('Voltagem da Fonte (V)', _voltagemFonteCtrl, hint: 'Ex: -48.5'),
          ],

          // ── Condições e Defeitos ──────────────────────────
          _secao('Condições e Defeitos'),
          _campo('Condições Físicas', _condicoesFisicasRadioCtrl, maxLines: 2,
              hint: 'Estado físico do rádio'),
          _campo('Defeitos Relatados', _defeitosRelatadosCtrl, maxLines: 2,
              hint: 'Descreva os problemas encontrados'),

          // ── Acessórios (checkbox) ─────────────────────────
          _secao('Acessórios Presentes'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _acessoriosOpcoes.map((nome) {
              final selecionado = _acessoriosRadio.contains(nome);
              return FilterChip(
                label: Text(nome,
                    style: TextStyle(
                      color: selecionado ? Colors.white : kTextColor2,
                      fontSize: 13,
                    )),
                selected: selecionado,
                onSelected: (v) => setState(() {
                  if (v) {
                    _acessoriosRadio.add(nome);
                  } else {
                    _acessoriosRadio.remove(nome);
                  }
                }),
                selectedColor: kPrimaryColor,
                backgroundColor: kCardColor,
                checkmarkColor: Colors.white,
                side: BorderSide(
                    color: selecionado ? kPrimaryColor : kBorderColor),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Laudo e Solução ───────────────────────────────
          _secao('Laudo e Solução'),
          _campo('Solução Proposta', _solucaoPropostaCtrl, maxLines: 3,
              hint: 'Descreva a solução técnica proposta'),
          _campo('Laudo Técnico', _laudoTecnicoRadioCtrl, maxLines: 3,
              hint: 'Diagnóstico técnico do equipamento'),
          _campo('Termos de Garantia', _termosGarantiaCtrl, maxLines: 2,
              hint: 'Condições de garantia aplicáveis'),

          // ── Observações Gerais ────────────────────────────
          _secao('Observações Gerais'),
          _campo('Observações', _observacoesCtrl, maxLines: 3),

          // ── Fotos do Equipamento ──────────────────────────
          _secao('Fotos do Equipamento (máx 5)'),
          _fotosWidget(),

          const SizedBox(height: 24),

          // ── Botão Salvar (ocultável) ───────────────────────
          if (widget.mostrarBotaoSalvar)
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
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _salvando ? 'Salvando...' : 'Salvar Análise',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers de layout ──────────────────────────────────────

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(children: [
          Container(width: 3, height: 16, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(titulo, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: kPrimaryLight)),
        ]),
      );

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
        hintStyle: const TextStyle(color: kTextDim, fontSize: 13),
        filled: true,
        fillColor: kCardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryColor)),
      );

  Widget _campo(String label, TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: kTextColor, fontSize: 14),
          decoration: _dec(label, hint: hint),
        ),
      );

  Widget _campoNum(String label, TextEditingController ctrl, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: kTextColor, fontSize: 14),
          decoration: _dec(label, hint: hint),
        ),
      );

  Widget _dropdown(String label, List<String> opcoes, String valor,
          void Function(String?) onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: valor.isEmpty ? null : valor,
          decoration: _dec(label),
          dropdownColor: kCardColor,
          style: const TextStyle(color: kTextColor, fontSize: 14),
          hint: Text('Selecione', style: const TextStyle(color: kTextDim)),
          items: opcoes.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      );

  Widget _fotosWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_totalFotos > 0) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _totalFotos,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i < _fotosExistentes.length) {
                  final path = _fotosExistentes[i];
                  return _fotoItem(
                    child: _imgFromPath(path),
                    onRemove: () => setState(() => _fotosExistentes.removeAt(i)),
                  );
                }
                final li = i - _fotosExistentes.length;
                return _fotoItem(
                  child: Image.file(_fotosLocais[li], width: 100, height: 100, fit: BoxFit.cover),
                  onRemove: () => setState(() => _fotosLocais.removeAt(li)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_totalFotos < 5)
          GestureDetector(
            onTap: _adicionarFoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0x05FFFFFF),
                border: Border.all(color: kBorderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: kPrimaryLight, size: 26),
                  SizedBox(height: 6),
                  Text('Toque para adicionar foto',
                      style: TextStyle(color: kPrimaryLight, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imgFromPath(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, width: 100, height: 100, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fotoPlaceholder(error: true));
    }
    return Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fotoPlaceholder(error: true));
  }

  Widget _fotoItem({required Widget child, required VoidCallback onRemove}) =>
      Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ]);

  Widget _fotoPlaceholder({bool error = false}) => Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: Icon(
          error ? Icons.broken_image_outlined : Icons.image_outlined,
          color: kTextColor3, size: 28,
        ),
      );
}
