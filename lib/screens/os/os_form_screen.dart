import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/ordem_servico.dart';
import '../../models/cliente.dart';
import '../../models/equipamento.dart';
import '../../models/usuario.dart';
import '../../models/os_checklist.dart';
import '../../models/os_acessorio.dart';
import '../../models/os_analise_equipamento.dart';
import '../../services/os_service.dart';
import '../../services/cliente_service.dart';
import '../../services/equipamento_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/analise_equipamento_form.dart';
import '../../widgets/foto_picker.dart';
import '../../widgets/signature_pad_widget.dart';

class OsFormScreen extends StatefulWidget {
  final OrdemServico? osParaEditar;
  const OsFormScreen({super.key, this.osParaEditar});

  @override
  State<OsFormScreen> createState() => _OsFormScreenState();
}

class _OsFormScreenState extends State<OsFormScreen> {
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  bool _salvando = false;

  List<Cliente> _clientes = [];
  List<Equipamento> _equipamentos = [];
  List<Usuario> _tecnicos = [];

  String? _clienteId;
  String? _tecnicoId;
  final List<String> _equipSelecionados = [];

  final _descCtrl = TextEditingController();
  final _acompCtrl = TextEditingController();
  final _condicoesFisicasCtrl = TextEditingController();
  final _defeitoCtrl = TextEditingController();
  final _laudoCtrl = TextEditingController();
  final _solucaoCtrl = TextEditingController();
  final _pecasCtrl = TextEditingController();
  final _termosCtrl = TextEditingController();
  final _outrosAcessoriosCtrl = TextEditingController();
  final _geoCepCtrl = TextEditingController();
  final _geoLogradouroCtrl = TextEditingController();
  final _geoNumeroCtrl = TextEditingController();
  final _geoBairroCtrl = TextEditingController();
  final _geoCidadeCtrl = TextEditingController();
  final _geoUfCtrl = TextEditingController();
  bool _buscandoCep = false;

  String _status = 'Aberto';
  String _prioridade = 'Baixa';
  String? _tipoOcorrencia;
  String? _statusEquipamento;

  DateTime _dataEntrada = DateTime.now();
  DateTime? _dataSaida;
  TimeOfDay? _horaEntrada;

  double? _geoLat;
  double? _geoLng;
  bool _buscandoGps = false;

  final List<File> _fotosLocais = [];
  List<String> _fotosUrl = [];

  final Set<String> _acessoriosSelecionados = {};

  late List<ChecklistItem> _checklist;

  final _sigClienteCtrl = SignaturePadController();
  final _sigTecnicoCtrl = SignaturePadController();

  EquipamentoOS? _analise;
  late String _analiseOsId;
  final _analiseKey = GlobalKey<AnaliseEquipamentoFormState>();

  static const List<String> _statusEquipOpcoes = [
    'Funcionando', 'Em Diagnóstico', 'Em Reparo', 'Ag. Retirada', 'Sem Conserto',
  ];

  @override
  void initState() {
    super.initState();
    _checklist = ChecklistItem.padrao();
    _analiseOsId = widget.osParaEditar?.id ?? const Uuid().v4();
    _carregar();
    if (widget.osParaEditar != null) _preencherCampos();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _acompCtrl.dispose();
    _condicoesFisicasCtrl.dispose();
    _defeitoCtrl.dispose();
    _laudoCtrl.dispose();
    _solucaoCtrl.dispose();
    _pecasCtrl.dispose();
    _termosCtrl.dispose();
    _outrosAcessoriosCtrl.dispose();
    _geoCepCtrl.dispose();
    _geoLogradouroCtrl.dispose();
    _geoNumeroCtrl.dispose();
    _geoBairroCtrl.dispose();
    _geoCidadeCtrl.dispose();
    _geoUfCtrl.dispose();
    _sigClienteCtrl.dispose();
    _sigTecnicoCtrl.dispose();
    super.dispose();
  }

  void _preencherCampos() {
    final os = widget.osParaEditar!;
    _status = os.status;
    _prioridade = os.prioridade;
    _tipoOcorrencia = os.tipoOcorrencia;
    _statusEquipamento = os.statusEquipamento;
    _dataEntrada = os.dataEntrada;
    _dataSaida = os.dataSaida;
    if (os.horaEntrada != null) {
      final parts = os.horaEntrada!.split(':');
      if (parts.length >= 2) {
        _horaEntrada = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    _clienteId = os.clienteId;
    _tecnicoId = os.tecnicoId;
    _equipSelecionados.addAll(os.equipamentosIds);
    _geoLat = os.geoLat;
    _geoLng = os.geoLng;
    _geoLogradouroCtrl.text = os.geoEndereco ?? '';
    _descCtrl.text = os.descricao ?? '';
    _acompCtrl.text = os.acompanhante ?? '';
    _condicoesFisicasCtrl.text = os.condicoesFisicas ?? '';
    _defeitoCtrl.text = os.defeito ?? '';
    _laudoCtrl.text = os.laudoTecnico ?? '';
    _solucaoCtrl.text = os.solucaoAplicada ?? '';
    _pecasCtrl.text = os.pecasUtilizadas ?? '';
    _termosCtrl.text = os.termosObservacoes ?? '';
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ClienteService.listar(),
        AuthService.listarTecnicos(),
      ]);
      _clientes = results[0] as List<Cliente>;
      _tecnicos = results[1] as List<Usuario>;

      // Se o técnico da OS não está na lista (desativado ou cache offline incompleto):
      // - Ao EDITAR: mantém o técnico como opção no dropdown (não apaga)
      // - Ao CRIAR:  limpa (não deve ter valor inválido em nova OS)
      if (_tecnicoId != null && !_tecnicos.any((t) => t.id == _tecnicoId)) {
        if (widget.osParaEditar != null) {
          final nome = widget.osParaEditar!.tecnicoNome ?? _tecnicoId!;
          _tecnicos = [
            ..._tecnicos,
            Usuario(id: _tecnicoId!, nome: nome, email: '', perfil: 'tecnico'),
          ];
        } else {
          _tecnicoId = null;
        }
      }

      if (_tecnicoId == null && widget.osParaEditar == null) {
        final currentId = AuthService.currentAuthUser?.id ??
            await AuthService.userIdOffline();
        if (currentId != null && _tecnicos.any((t) => t.id == currentId)) {
          _tecnicoId = currentId;
        }
      }

      if (_clienteId != null) {
        _equipamentos = await EquipamentoService.listar(clienteId: _clienteId);
      }

      if (widget.osParaEditar != null) {
        final osId = widget.osParaEditar!.id;
        final res2 = await Future.wait([
          OsService.listarFotos(osId),
          OsService.listarChecklist(osId),
          OsService.listarAcessorios(osId),
          OsService.listarAnaliseEquipamento(osId),
        ]);

        _fotosUrl = (res2[0] as List<Map<String, dynamic>>)
            .where((f) => f['pendente'] != true)
            .map((f) => f['caminho'] as String)
            .toList();

        final checkItems = res2[1] as List<ChecklistItem>;
        if (checkItems.isNotEmpty) {
          for (final item in _checklist) {
            final existente = checkItems.where((c) => c.itemId == item.itemId).toList();
            if (existente.isNotEmpty) {
              item.feito = existente.first.feito;
              item.dataVerificacao = existente.first.dataVerificacao;
              item.tecnicoVerificador = existente.first.tecnicoVerificador;
            }
          }
        }

        for (final a in res2[2] as List<OsAcessorio>) {
          if (OsAcessorio.opcoesPadrao.contains(a.nome)) {
            _acessoriosSelecionados.add(a.nome);
          } else {
            _outrosAcessoriosCtrl.text = a.nome;
          }
        }

        _analise = res2[3] as EquipamentoOS?;
        setState(() {});
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarData(bool isEntrada) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEntrada ? _dataEntrada : (_dataSaida ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isEntrada ? _dataEntrada = picked : _dataSaida = picked);
  }

  Future<void> _selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaEntrada ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _horaEntrada = picked);
  }

  Future<void> _buscarCepGps(String cep) async {
    setState(() => _buscandoCep = true);
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      ).timeout(const Duration(seconds: 8));
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final j = jsonDecode(body) as Map<String, dynamic>;
        if (j['erro'] != true && mounted) {
          final rua    = j['logradouro'] as String? ?? '';
          final bairro = j['bairro']    as String? ?? '';
          final cidade = j['localidade'] as String? ?? '';
          final uf     = j['uf']        as String? ?? '';
          setState(() {
            _geoLogradouroCtrl.text = rua;
            _geoBairroCtrl.text = bairro;
            _geoCidadeCtrl.text = cidade;
            _geoUfCtrl.text = uf;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _capturarGps() async {
    final perm = await Permission.location.request();
    if (!perm.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada')),
        );
      }
      return;
    }
    setState(() => _buscandoGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      if (mounted) setState(() { _geoLat = pos.latitude; _geoLng = pos.longitude; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _salvando = true);
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      final sigCli = await _sigClienteCtrl.toPngBytes();
      final sigTec = await _sigTecnicoCtrl.toPngBytes();

      final todosAcessorios = List<String>.from(_acessoriosSelecionados);
      final outros = _outrosAcessoriosCtrl.text.trim();
      if (outros.isNotEmpty) todosAcessorios.add(outros);

      final hora = _horaEntrada != null
          ? '${_horaEntrada!.hour.toString().padLeft(2, '0')}:${_horaEntrada!.minute.toString().padLeft(2, '0')}'
          : null;

      final dados = {
        'descricao': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'status': _status,
        'prioridade': _prioridade,
        'tipo_ocorrencia': _tipoOcorrencia,
        'data_entrada': fmt.format(_dataEntrada),
        'hora_entrada': hora,
        'data_saida': _dataSaida != null ? fmt.format(_dataSaida!) : null,
        'acompanhante': _acompCtrl.text.trim().isEmpty ? null : _acompCtrl.text.trim(),
        'condicoes_fisicas': _condicoesFisicasCtrl.text.trim().isEmpty ? null : _condicoesFisicasCtrl.text.trim(),
        'defeito_relatado': _defeitoCtrl.text.trim().isEmpty ? null : _defeitoCtrl.text.trim(),
        'status_equipamento': _statusEquipamento,
        'laudo_tecnico': _laudoCtrl.text.trim().isEmpty ? null : _laudoCtrl.text.trim(),
        'solucao_aplicada': _solucaoCtrl.text.trim().isEmpty ? null : _solucaoCtrl.text.trim(),
        'pecas_utilizadas': _pecasCtrl.text.trim().isEmpty ? null : _pecasCtrl.text.trim(),
        'termos_observacoes': _termosCtrl.text.trim().isEmpty ? null : _termosCtrl.text.trim(),
        'geo_lat': _geoLat,
        'geo_lng': _geoLng,
        'geo_endereco': _buildGeoEndereco(),
        'cliente_id': _clienteId,
        'tecnico_id': _tecnicoId,
      };

      OrdemServico os;
      if (widget.osParaEditar == null) {
        // Nova OS: criar OS primeiro, depois análise (FK constraint no Supabase)
        os = await OsService.criar(
            dados, _equipSelecionados, _checklist, todosAcessorios,
            sigCli != null ? List<int>.from(sigCli) : null,
            sigTec != null ? List<int>.from(sigTec) : null,
            preId: _analiseOsId);
        await _analiseKey.currentState?.salvarSePreenchido();
      } else {
        // Editar OS: análise antes (OS já existe, sem risco de FK)
        await _analiseKey.currentState?.salvarSePreenchido();
        await OsService.atualizar(
            widget.osParaEditar!.id, dados, _equipSelecionados,
            _checklist, todosAcessorios,
            sigCli != null ? List<int>.from(sigCli) : null,
            sigTec != null ? List<int>.from(sigTec) : null);
        os = widget.osParaEditar!;
      }

      for (final foto in _fotosLocais) {
        await OsService.uploadFoto(os.id, foto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.osParaEditar == null ? 'OS criada!' : 'OS atualizada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _buildGeoEndereco() {
    final log = _geoLogradouroCtrl.text.trim();
    final num = _geoNumeroCtrl.text.trim();
    final bai = _geoBairroCtrl.text.trim();
    final cid = _geoCidadeCtrl.text.trim();
    final uf  = _geoUfCtrl.text.trim();
    final parts = <String>[];
    if (log.isNotEmpty) parts.add(num.isNotEmpty ? '$log, $num' : log);
    if (bai.isNotEmpty) parts.add(bai);
    if (cid.isNotEmpty) parts.add(uf.isNotEmpty ? '$cid - $uf' : cid);
    return parts.isEmpty ? null : parts.join(', ');
  }

  // ── UI Helpers ─────────────────────────────────────────────

  // Dark form field decoration matching web form-control
  InputDecoration _dec(String label, {bool alignTop = false}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: kTextColor3, fontSize: 13),
    filled: true,
    fillColor: const Color(0x0AFFFFFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    alignLabelWithHint: alignTop,
  );

  Widget _campo(String label, TextEditingController ctrl,
      {int maxLines = 1, String? Function(String?)? validator, TextInputType? type}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          validator: validator,
          maxLines: maxLines,
          keyboardType: type,
          style: const TextStyle(color: kTextColor, fontSize: 14),
          decoration: _dec(label, alignTop: maxLines > 1),
        ),
      );

  // Section card matching web .section-card with gradient header and numbered badge
  Widget _sectionCard(int num, String title, Widget body) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: const Color(0x08FFFFFF),
      border: Border.all(color: const Color(0x14FFFFFF)),
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x1A16A34A), Color(0x0A22C55E)],
            ),
            border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text('$num',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor2)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: body,
        ),
      ],
    ),
  );

  // Pill chip matching web .chip style
  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0x1F4ADE80) : const Color(0x08FFFFFF),
        border: Border.all(
          color: selected ? const Color(0x594ADE80) : const Color(0x1FFFFFFF),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          color: selected ? kPrimaryLight : kTextColor2,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );

  // Priority button matching web .priority-btn
  Widget _priorBtn(String label, Color bgActive, Color borderActive, Color textActive,
      {List<BoxShadow>? shadowActive}) {
    final sel = _prioridade == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _prioridade = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? bgActive : const Color(0x08FFFFFF),
            border: Border.all(color: sel ? borderActive : const Color(0x1AFFFFFF)),
            borderRadius: BorderRadius.circular(9),
            boxShadow: sel ? shadowActive : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: sel ? textActive : kTextColor3,
            ),
          ),
        ),
      ),
    );
  }

  // OS status button matching web .status-btn with gradient active
  Widget _osStatusBtn(String label) {
    final sel = _status == label;
    return GestureDetector(
      onTap: () => setState(() => _status = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                )
              : null,
          color: sel ? null : const Color(0x08FFFFFF),
          border: sel ? null : Border.all(color: const Color(0x1AFFFFFF)),
          borderRadius: BorderRadius.circular(9),
          boxShadow: sel
              ? [const BoxShadow(color: Color(0x4D16A34A), blurRadius: 12, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : kTextColor3,
          ),
        ),
      ),
    );
  }

  // Equipment status button (same style, different state)
  Widget _statusEquipBtn(String label) {
    final sel = _statusEquipamento == label;
    return GestureDetector(
      onTap: () => setState(() => _statusEquipamento = sel ? null : label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                )
              : null,
          color: sel ? null : const Color(0x08FFFFFF),
          border: sel ? null : Border.all(color: const Color(0x1AFFFFFF)),
          borderRadius: BorderRadius.circular(9),
          boxShadow: sel
              ? [const BoxShadow(color: Color(0x4D16A34A), blurRadius: 12, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : kTextColor3,
          ),
        ),
      ),
    );
  }

  int get _checklistFeitos => _checklist.where((c) => c.feito).length;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    var _n = 0; // contador de seções — incrementa automaticamente
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(widget.osParaEditar == null ? 'Nova OS' : 'Editar OS'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ── 1. Identificação ──────────────────────────────
                  _sectionCard(++_n, 'Identificação do Chamado', Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cliente
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: _clienteId,
                          isExpanded: true,
                          dropdownColor: kCardColor,
                          style: const TextStyle(color: kTextColor, fontSize: 14),
                          decoration: _dec('Cliente *'),
                          items: _clientes
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                              .toList(),
                          onChanged: (v) async {
                            setState(() {
                              _clienteId = v;
                              _equipSelecionados.clear();
                              _equipamentos = [];
                            });
                            if (v != null) {
                              final eq = await EquipamentoService.listar(clienteId: v);
                              if (mounted) setState(() => _equipamentos = eq);
                            }
                          },
                          validator: (v) => v == null ? 'Selecione o cliente' : null,
                        ),
                      ),

                      // Status buttons
                      const Text('Status',
                          style: TextStyle(fontSize: 12, color: kTextColor3, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(children: kStatusOS.map(_osStatusBtn).toList()),
                      const SizedBox(height: 6),

                      // Priority buttons
                      const Text('Prioridade',
                          style: TextStyle(fontSize: 12, color: kTextColor3, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _priorBtn('Baixa',
                              const Color(0x1A4ADE80), const Color(0x664ADE80), const Color(0xFF6EE7B7)),
                          const SizedBox(width: 8),
                          _priorBtn('Média',
                              const Color(0x1AFBBF24), const Color(0x66FBBF24), const Color(0xFFFCD34D)),
                          const SizedBox(width: 8),
                          _priorBtn('Urgente',
                              const Color(0x1AF87171), const Color(0x66F87171), const Color(0xFFFCA5A5),
                              shadowActive: [
                                const BoxShadow(color: Color(0x33EF4444), blurRadius: 12),
                              ]),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tipo de Ocorrência
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: _tipoOcorrencia,
                          isExpanded: true,
                          dropdownColor: kCardColor,
                          style: const TextStyle(color: kTextColor, fontSize: 14),
                          decoration: _dec('Tipo de Ocorrência'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('—')),
                            ...kTiposOcorrencia.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                          ],
                          onChanged: (v) => setState(() => _tipoOcorrencia = v),
                        ),
                      ),

                      // Datas e hora
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selecionarData(true),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: InputDecorator(
                                  decoration: _dec('Data Entrada *'),
                                  child: Text(fmt.format(_dataEntrada),
                                      style: const TextStyle(color: kTextColor, fontSize: 14)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: _selecionarHora,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: InputDecorator(
                                  decoration: _dec('Hora Entrada'),
                                  child: Text(
                                    _horaEntrada != null ? _horaEntrada!.format(context) : '—',
                                    style: const TextStyle(color: kTextColor, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _selecionarData(false),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: InputDecorator(
                            decoration: _dec('Data Saída'),
                            child: Text(
                              _dataSaida != null ? fmt.format(_dataSaida!) : '—',
                              style: const TextStyle(color: kTextColor, fontSize: 14),
                            ),
                          ),
                        ),
                      ),

                      // Técnico
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: _tecnicoId,
                          isExpanded: true,
                          dropdownColor: kCardColor,
                          style: const TextStyle(color: kTextColor, fontSize: 14),
                          decoration: _dec('Técnico Responsável'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('—')),
                            ..._tecnicos.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
                          ],
                          onChanged: (v) => setState(() => _tecnicoId = v),
                        ),
                      ),

                      _campo('Acompanhou a Execução', _acompCtrl),
                    ],
                  )),

                  // ── 2. Acessórios ─────────────────────────────────
                  _sectionCard(++_n, 'Acessórios Recebidos', Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        children: OsAcessorio.opcoesPadrao.map((a) {
                          final sel = _acessoriosSelecionados.contains(a);
                          return _chip(a, sel, () => setState(() =>
                              sel ? _acessoriosSelecionados.remove(a) : _acessoriosSelecionados.add(a)));
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      _campo('Outros acessórios', _outrosAcessoriosCtrl),
                    ],
                  )),

                  // ── 3. Análise de Equipamentos ────────────────────
                  _sectionCard(++_n, 'Análise de Equipamentos',
                    AnaliseEquipamentoForm(
                      key: _analiseKey,
                      osId: _analiseOsId,
                      analiseExistente: _analise,
                      mostrarBotaoSalvar: false,
                      onSalvo: () async {
                        final nova = await OsService.listarAnaliseEquipamento(_analiseOsId);
                        if (mounted) setState(() => _analise = nova);
                      },
                    ),
                  ),

                  // ── 4. Equipamentos ───────────────────────────────
                  if (_equipamentos.isNotEmpty)
                    _sectionCard(++_n, 'Equipamentos Vinculados', Column(
                      children: _equipamentos.map((eq) {
                        final sel = _equipSelecionados.contains(eq.id);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0x0F4ADE80) : const Color(0x05FFFFFF),
                            border: Border.all(
                              color: sel ? const Color(0x334ADE80) : const Color(0x1AFFFFFF),
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            child: CheckboxListTile(
                              title: Text(eq.descricaoCompleta,
                                  style: const TextStyle(color: kTextColor, fontSize: 14)),
                              subtitle: Text('Série: ${eq.numeroSerie}',
                                  style: const TextStyle(color: kTextColor3, fontSize: 12)),
                              value: sel,
                              activeColor: kPrimaryColor,
                              checkColor: Colors.white,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _equipSelecionados.add(eq.id);
                                } else {
                                  _equipSelecionados.remove(eq.id);
                                }
                              }),
                            ),
                          ),
                        );
                      }).toList(),
                    )),

                  // ── 5. Condição e Defeito ─────────────────────────
                  _sectionCard(++_n, 'Condição e Defeito', Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _campo('Condições Físicas', _condicoesFisicasCtrl, maxLines: 3),
                      _campo('Defeito Relatado', _defeitoCtrl, maxLines: 3),
                      const Text('Status do Equipamento',
                          style: TextStyle(fontSize: 12, color: kTextColor3, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(children: _statusEquipOpcoes.map(_statusEquipBtn).toList()),
                      const SizedBox(height: 4),
                    ],
                  )),

                  // ── 6. Checklist ──────────────────────────────────
                  _sectionCard(++_n, 'Checklist de Testes', Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$_checklistFeitos/${_checklist.length} concluídos',
                              style: const TextStyle(
                                  fontSize: 13, color: kPrimaryLight, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _checklist.isEmpty ? 0 : _checklistFeitos / _checklist.length,
                              backgroundColor: const Color(0x1AFFFFFF),
                              color: kPrimaryColor,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ..._checklist.map(_buildChecklistItem),
                    ],
                  )),

                  // ── 7. Laudo e Solução ────────────────────────────
                  _sectionCard(++_n, 'Laudo Técnico e Solução', Column(
                    children: [
                      _campo('Laudo / Diagnóstico Técnico', _laudoCtrl, maxLines: 4),
                      _campo('Solução Aplicada', _solucaoCtrl, maxLines: 3),
                      _campo('Peças Utilizadas', _pecasCtrl, maxLines: 2),
                      _campo('Termos e Observações', _termosCtrl, maxLines: 3),
                      _campo('Descrição Geral', _descCtrl, maxLines: 2),
                    ],
                  )),

                  // ── 8. GPS ────────────────────────────────────────
                  _sectionCard(++_n, 'Localização GPS', Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CEP auto-preenche Logradouro, Bairro, Cidade e UF
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _geoCepCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: kTextColor, fontSize: 14),
                                decoration: _dec('CEP (auto-preenche)').copyWith(
                                  suffixIcon: _buscandoCep
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(width: 16, height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: kPrimaryLight)),
                                        )
                                      : null,
                                ),
                                onChanged: (v) {
                                  final d = v.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (d.length == 8) _buscarCepGps(d);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _buscandoGps ? null : _capturarGps,
                              icon: _buscandoGps
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.my_location, size: 16),
                              label: const Text('GPS', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Campos de endereço individuais
                      _campo('Logradouro', _geoLogradouroCtrl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _campo('Número / Complemento', _geoNumeroCtrl)),
                          const SizedBox(width: 10),
                          Expanded(child: _campo('Bairro', _geoBairroCtrl)),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _campo('Cidade', _geoCidadeCtrl)),
                          const SizedBox(width: 10),
                          SizedBox(width: 72, child: _campo('UF', _geoUfCtrl)),
                        ],
                      ),
                      // Coordenadas capturadas
                      if (_geoLat != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0x0A4ADE80),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x334ADE80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: kPrimaryLight, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Lat: ${_geoLat!.toStringAsFixed(5)}  |  Lng: ${_geoLng!.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 12, color: kTextColor2),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )),

                  // ── 9. Fotos ──────────────────────────────────────
                  _sectionCard(++_n, 'Fotos', FotoPicker(
                    fotosUrl: _fotosUrl,
                    fotosLocais: _fotosLocais,
                    onFotoAdicionada: (f) => setState(() => _fotosLocais.add(f)),
                    onFotoUrlRemovida: (i) => setState(() => _fotosUrl.removeAt(i)),
                    onFotoLocalRemovida: (i) => setState(() => _fotosLocais.removeAt(i)),
                  )),

                  // ── 10. Assinaturas ───────────────────────────────
                  _sectionCard(++_n, 'Assinaturas', Column(
                    children: [
                      SignaturePadWidget(controller: _sigClienteCtrl, label: 'Assinatura do Cliente'),
                      const SizedBox(height: 16),
                      SignaturePadWidget(controller: _sigTecnicoCtrl, label: 'Assinatura do Técnico'),
                    ],
                  )),

                  // ── Salvar ────────────────────────────────────────
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              widget.osParaEditar == null ? 'CRIAR OS' : 'SALVAR ALTERAÇÕES',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // Checklist item matching web .check-item with custom checkbox
  Widget _buildChecklistItem(ChecklistItem item) {
    return GestureDetector(
      onTap: () => setState(() => item.feito = !item.feito),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.feito ? const Color(0x0A4ADE80) : const Color(0x05FFFFFF),
          border: Border.all(
            color: item.feito ? const Color(0x334ADE80) : const Color(0x0FFFFFFF),
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: item.feito ? const Color(0x264ADE80) : Colors.transparent,
                    border: Border.all(
                      color: item.feito ? kPrimaryLight : const Color(0x33FFFFFF),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: item.feito
                      ? const Icon(Icons.check, size: 16, color: kPrimaryLight)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.itemNome,
                      style: TextStyle(
                        fontSize: 13,
                        decoration: item.feito ? TextDecoration.lineThrough : null,
                        color: item.feito ? const Color(0x59FFFFFF) : kTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (item.feito) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: item.dataVerificacao ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => item.dataVerificacao = d);
                      },
                      child: InputDecorator(
                        decoration: _dec('Data').copyWith(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        child: Text(
                          item.dataVerificacao != null
                              ? DateFormat('dd/MM/yy').format(item.dataVerificacao!)
                              : '—',
                          style: const TextStyle(fontSize: 12, color: kTextColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: item.tecnicoVerificador,
                      onChanged: (v) => item.tecnicoVerificador = v.isEmpty ? null : v,
                      style: const TextStyle(fontSize: 12, color: kTextColor),
                      decoration: _dec('Técnico').copyWith(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
