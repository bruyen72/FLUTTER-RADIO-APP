import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/ordem_servico.dart';
import '../../models/os_visita.dart';
import '../../services/os_service.dart';
import '../../utils/constants.dart';
import '../../widgets/foto_picker.dart';
import 'os_detalhe_screen.dart';

/// Tela de Visita Técnica — vinculada a uma OS (Melhoria 2)
///
/// Uso:
///   OsVisitaScreen(osId: 'uuid', os: ordemServico) → abre diretamente o form
///   OsVisitaScreen() → mostra picker de OS primeiro
class OsVisitaScreen extends StatefulWidget {
  final String? osId;
  final OrdemServico? os;

  const OsVisitaScreen({super.key, this.osId, this.os});

  @override
  State<OsVisitaScreen> createState() => _OsVisitaScreenState();
}

class _OsVisitaScreenState extends State<OsVisitaScreen> {
  // ── State de seleção de OS ──────────────────────────────────
  String? _osId;
  OrdemServico? _os;
  bool _carregandoOs = false;
  List<OrdemServico> _listaOs = [];

  // ── State do formulário ─────────────────────────────────────
  bool _carregando = false;
  bool _salvando   = false;
  OsVisita? _visitaExistente;

  final _formKey = GlobalKey<FormState>();

  final _localCtrl         = TextEditingController();
  final _tecnicoCtrl       = TextEditingController();
  final _descricaoCtrl     = TextEditingController();
  final _equipamentosCtrl  = TextEditingController();
  final _observacoesCtrl   = TextEditingController();

  DateTime? _dataHora;
  String _status = 'Em andamento';

  List<String> _fotosUrls   = [];
  final List<File> _fotosLocais = [];

  @override
  void initState() {
    super.initState();
    if (widget.osId != null) {
      _osId = widget.osId;
      _os   = widget.os;
      _carregarVisita();
    } else {
      _carregarListaOs();
    }
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _tecnicoCtrl.dispose();
    _descricaoCtrl.dispose();
    _equipamentosCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  // ── Carrega lista de OS para seleção ───────────────────────
  Future<void> _carregarListaOs() async {
    setState(() => _carregandoOs = true);
    try {
      final lista = await OsService.listar();
      if (mounted) setState(() { _listaOs = lista; _carregandoOs = false; });
    } catch (_) {
      if (mounted) setState(() => _carregandoOs = false);
    }
  }

  // ── Carrega visita existente para a OS ──────────────────────
  Future<void> _carregarVisita() async {
    if (_osId == null) return;
    setState(() => _carregando = true);
    try {
      final visita = await OsService.listarVisita(_osId!);
      if (mounted) {
        setState(() {
          _visitaExistente = visita;
          _carregando = false;
        });
        if (visita != null) _preencherForm(visita);
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _preencherForm(OsVisita v) {
    _localCtrl.text        = v.localVisita;
    _tecnicoCtrl.text      = v.tecnicoResponsavel;
    _descricaoCtrl.text    = v.descricaoProblema;
    _equipamentosCtrl.text = v.equipamentosEncontrados;
    _observacoesCtrl.text  = v.observacoesCampo;
    _dataHora              = v.dataHora;
    _status                = v.status;
    _fotosUrls             = List<String>.from(v.fotos);
  }

  void _selecionarOs(OrdemServico os) {
    setState(() {
      _osId = os.id;
      _os   = os;
    });
    _carregarVisita();
  }

  Future<void> _selecionarDataHora() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataHora ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: kPrimaryColor),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora ?? DateTime.now()),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: kPrimaryColor),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _dataHora = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _salvar() async {
    if (_osId == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    try {
      final todasFotos = [..._fotosUrls, ..._fotosLocais.map((f) => f.path)];
      final agora = DateTime.now();
      final visita = OsVisita(
        id: _visitaExistente?.id ?? const Uuid().v4(),
        osId: _osId!,
        localVisita: _localCtrl.text.trim(),
        tecnicoResponsavel: _tecnicoCtrl.text.trim(),
        dataHora: _dataHora,
        descricaoProblema: _descricaoCtrl.text.trim(),
        equipamentosEncontrados: _equipamentosCtrl.text.trim(),
        fotos: todasFotos,
        observacoesCampo: _observacoesCtrl.text.trim(),
        status: _status,
        criadoEm: _visitaExistente?.criadoEm ?? agora,
        atualizadoEm: agora,
      );
      await OsService.salvarVisita(visita);
      if (mounted) {
        setState(() {
          _visitaExistente = visita;
          _fotosLocais.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Visita técnica salva com sucesso'),
          backgroundColor: kPrimaryDark,
        ));
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
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(
          _osId == null ? 'Visita Técnica' : 'Visita — ${_os?.numeroOs ?? _osId}',
          style: const TextStyle(color: kTextColor, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_osId != null && _os != null)
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OsDetalheScreen(os: _os!))),
              icon: const Icon(Icons.assignment_outlined, size: 16, color: kPrimaryLight),
              label: const Text('Ver OS', style: TextStyle(color: kPrimaryLight, fontSize: 13)),
            ),
        ],
      ),
      body: _osId == null ? _buildOsPicker() : _buildForm(),
      floatingActionButton: _osId != null
          ? FloatingActionButton.extended(
              onPressed: _salvando ? null : _salvar,
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              icon: _salvando
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_salvando ? 'Salvando...' : 'Salvar Visita'),
            )
          : null,
    );
  }

  // ── Picker de OS ─────────────────────────────────────────────
  Widget _buildOsPicker() {
    if (_carregandoOs) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: kSurfaceColor,
          child: const Text(
            'Selecione a OS para registrar a visita técnica:',
            style: TextStyle(color: kTextColor2, fontSize: 14),
          ),
        ),
        Expanded(
          child: _listaOs.isEmpty
              ? const Center(
                  child: Text('Nenhuma OS disponível',
                      style: TextStyle(color: kTextColor3)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _listaOs.length,
                  itemBuilder: (_, i) {
                    final os = _listaOs[i];
                    return Card(
                      color: kCardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: kBorderColor)),
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined, color: kPrimaryLight),
                        title: Text(os.numeroOs,
                            style: const TextStyle(
                                color: kPrimaryLight, fontWeight: FontWeight.w700)),
                        subtitle: Text(os.clienteNome ?? 'Cliente não informado',
                            style: const TextStyle(color: kTextColor3, fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right, color: kTextDim),
                        onTap: () => _selecionarOs(os),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Formulário de visita ─────────────────────────────────────
  Widget _buildForm() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    final dataStr = _dataHora != null
        ? '${_dataHora!.day.toString().padLeft(2, '0')}/'
            '${_dataHora!.month.toString().padLeft(2, '0')}/'
            '${_dataHora!.year}  '
            '${_dataHora!.hour.toString().padLeft(2, '0')}:'
            '${_dataHora!.minute.toString().padLeft(2, '0')}'
        : 'Selecionar data e hora';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // Status
          _secao('Status da Visita'),
          Row(
            children: ['Em andamento', 'Concluída'].map((s) {
              final sel = _status == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _status = s),
                  child: Container(
                    margin: EdgeInsets.only(right: s == 'Em andamento' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? kPrimaryColor.withOpacity(0.15) : kCardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? kPrimaryColor : kBorderColor,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: sel ? kPrimaryLight : kTextColor3,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(s,
                            style: TextStyle(
                              color: sel ? kPrimaryLight : kTextColor2,
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          _secao('Informações da Visita'),
          _campo('Local da Visita', _localCtrl, hint: 'Endereço ou nome do local',
              required: true),
          _campo('Técnico Responsável', _tecnicoCtrl, hint: 'Nome do técnico em campo'),

          // Data/Hora
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _selecionarDataHora,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: kPrimaryLight, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    dataStr,
                    style: TextStyle(
                      color: _dataHora != null ? kTextColor : kTextDim,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          _secao('Detalhes Técnicos'),
          _campo('Descrição do Problema no Local', _descricaoCtrl,
              maxLines: 3, hint: 'Descreva o problema relatado'),
          _campo('Equipamentos Encontrados', _equipamentosCtrl,
              maxLines: 2, hint: 'Liste os equipamentos no local'),

          _secao('Fotos da Visita (máx 5)'),
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
          const SizedBox(height: 12),

          _secao('Observações de Campo'),
          _campo('Observações', _observacoesCtrl, maxLines: 4,
              hint: 'Anotações gerais da visita'),
        ],
      ),
    );
  }

  // ── Helpers de layout ────────────────────────────────────────
  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(children: [
          Container(width: 3, height: 16, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(titulo, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: kPrimaryLight)),
        ]),
      );

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: kTextColor, fontSize: 14),
          validator: required && maxLines == 1
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
              : null,
          decoration: InputDecoration(
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
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      );
}
