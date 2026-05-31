import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ordem_servico.dart';
import '../../models/os_checklist.dart';
import '../../models/os_acessorio.dart';
import '../../models/os_analise_equipamento.dart';
import '../../services/os_service.dart';
import '../../services/pdf_service.dart';
import '../../services/word_service.dart';
import '../../utils/constants.dart';
import '../../widgets/analise_equipamento_form.dart';
import '../../widgets/testes_form.dart';
import '../../widgets/foto_picker.dart';
import '../../widgets/status_badge.dart';
import 'os_form_screen.dart';

class OsDetalheScreen extends StatefulWidget {
  final OrdemServico os;
  const OsDetalheScreen({super.key, required this.os});

  @override
  State<OsDetalheScreen> createState() => _OsDetalheScreenState();
}

class _OsDetalheScreenState extends State<OsDetalheScreen> {
  late OrdemServico _os;
  List<Map<String, dynamic>> _fotos = [];
  List<ChecklistItem> _checklist = [];
  List<OsAcessorio> _acessorios = [];
  Map<String, dynamic>? _assinatura;
  EquipamentoOS? _analise;
  bool _gerando = false;

  // ── Fotos por seção (Melhoria 1) ─────────────────────────────
  List<String> _fotosVisitaUrls      = [];
  final List<File> _fotosVisitaLocais = [];
  List<String> _fotosEquipUrls       = [];
  final List<File> _fotosEquipLocais  = [];
  List<String> _fotosTestesUrls      = [];
  final List<File> _fotosTestesLocais = [];

  @override
  void initState() {
    super.initState();
    _os = widget.os;
    _carregar();
  }

  Future<void> _carregar() async {
    // Carrega cada dado individualmente para que uma falha parcial
    // não impeça os demais (incluindo _analise) de serem exibidos.
    List<Map<String, dynamic>> fotos = [];
    List<ChecklistItem> checklist = [];
    List<OsAcessorio> acessorios = [];
    Map<String, dynamic>? assinatura;
    EquipamentoOS? analise;

    await Future.wait([
      OsService.listarFotos(_os.id)
          .then((v) => fotos = v)
          .catchError((_) {}),
      OsService.listarChecklist(_os.id)
          .then((v) => checklist = v)
          .catchError((_) {}),
      OsService.listarAcessorios(_os.id)
          .then((v) => acessorios = v)
          .catchError((_) {}),
      OsService.listarAssinatura(_os.id)
          .then((v) => assinatura = v)
          .catchError((_) {}),
      OsService.listarAnaliseEquipamento(_os.id)
          .then((v) => analise = v)
          .catchError((_) {}),
    ]);

    if (mounted) {
      setState(() {
        _fotos      = fotos;
        _checklist  = checklist;
        _acessorios = acessorios;
        _assinatura = assinatura;
        _analise    = analise;
        // Fotos por seção
        _fotosVisitaUrls = List<String>.from(_os.fotosVisita);
        _fotosEquipUrls  = List<String>.from(_os.fotosEquipamento);
        _fotosTestesUrls = List<String>.from(_os.fotosTestes);
      });
    }
  }

  // ── Salva fotos de uma seção ──────────────────────────────────
  Future<void> _salvarFotosSecao(
      String coluna, List<String> urls, List<File> locais) async {
    // Copia fotos locais para storage permanente antes de salvar.
    // Paths do image_picker somem do cache Android — sem isso o PDF não acha o arquivo.
    final permanentes = <String>[];
    for (final f in locais) {
      try {
        final caminho = await OsService.copiarFotoParaPermanente(f, _os.id);
        permanentes.add(caminho);
      } catch (_) {
        permanentes.add(f.path);
      }
    }
    final todas = [...urls, ...permanentes];
    await OsService.atualizarFotosSecao(_os.id, coluna, todas);
    final nova = await OsService.buscarPorId(_os.id);
    if (nova != null && mounted) setState(() => _os = nova);
  }

  Future<void> _gerarPdf() async {
    setState(() => _gerando = true);
    try {
      final arquivo = await PdfService.gerarPdf(_os);
      await PdfService.compartilhar(arquivo, _os.numeroOs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _gerarWord() async {
    setState(() => _gerando = true);
    try {
      final arquivo = await WordService.gerarWord(_os);
      await WordService.compartilhar(arquivo, _os.numeroOs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar Word: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _desativar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desativar OS'),
        content: Text('Desativar a OS ${_os.numeroOs}?\nEla não será deletada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await OsService.desativar(_os.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ── Helpers de UI ─────────────────────────────────────────
  Widget _linha(String label, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kTextColor3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(valor, style: const TextStyle(fontSize: 14, color: kTextColor)),
          const Divider(height: 16),
        ],
      ),
    );
  }

  /// Widget reutilizável de fotos por seção (Melhoria 1)
  Widget _fotosSecaoWidget({
    required String coluna,
    required List<String> urls,
    required List<File> locais,
    required void Function(String) onAddUrl,
    required void Function(int) onRemoveUrl,
    required void Function(File) onAddLocal,
    required void Function(int) onRemoveLocal,
  }) {
    final total = urls.length + locais.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FotoPicker(
          fotosUrl: urls,
          fotosLocais: locais,
          onFotoAdicionada: total >= 5
              ? (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Máximo de 5 fotos atingido')),
                  )
              : onAddLocal,
          onFotoUrlRemovida: onRemoveUrl,
          onFotoLocalRemovida: onRemoveLocal,
        ),
        if (total > 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _salvarFotosSecao(coluna, urls, locais),
              style: TextButton.styleFrom(
                backgroundColor: kPrimaryColor.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: kPrimaryColor, width: 0.5)),
              ),
              icon: const Icon(Icons.save_outlined, size: 16, color: kPrimaryLight),
              label: const Text('Salvar fotos desta seção',
                  style: TextStyle(color: kPrimaryLight, fontSize: 13)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            Container(width: 4, height: 18, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryLight)),
          ],
        ),
      );

  // Converte base64 ou data URI em Widget de imagem
  Widget? _imagemAssinatura(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final base64str = raw.contains(',') ? raw.split(',').last : raw;
      final bytes = base64Decode(base64str);
      return Image.memory(bytes, fit: BoxFit.contain, width: double.infinity);
    } catch (_) {
      return null;
    }
  }

  Widget _sigBox(String label, String? raw) {
    final img = _imagemAssinatura(raw);
    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: img != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: img,
                )
              : const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Sem assinatura',
                        style: TextStyle(color: kTextColor3, fontSize: 11)),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextColor3)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final sigCli = _assinatura?['sig_cliente'] as String?;
    final sigTec = _assinatura?['sig_tecnico'] as String?;
    final sigOffline = _assinatura?['offline'] == true;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(_os.numeroOs),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_gerando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Gerar PDF', onPressed: _gerarPdf),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar',    child: Text('Editar')),
              const PopupMenuItem(value: 'word',      child: Text('Exportar Word (.docx)')),
              const PopupMenuItem(value: 'desativar', child: Text('Desativar', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) async {
              if (v == 'editar') {
                final atualizado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => OsFormScreen(osParaEditar: _os)),
                );
                if (atualizado == true) {
                  final nova = await OsService.buscarPorId(_os.id);
                  if (nova != null && mounted) setState(() => _os = nova);
                }
                _carregar();
              } else if (v == 'word') {
                await _gerarWord();
              } else if (v == 'desativar') {
                await _desativar();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ─────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_os.numeroOs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
                        const SizedBox(height: 4),
                        Text(_os.clienteNome ?? 'Cliente não informado', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge.status(_os.status),
                      const SizedBox(height: 6),
                      StatusBadge.prioridade(_os.prioridade),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Datas e Responsável ────────────────────────────
          _secao('Datas e Responsável'),
          _linha('Data de Entrada', fmt.format(_os.dataEntrada)),
          _linha('Hora de Entrada', _os.horaEntrada),
          _linha('Data de Saída', _os.dataSaida != null ? fmt.format(_os.dataSaida!) : null),
          _linha('Tipo de Ocorrência', _os.tipoOcorrencia),
          _linha('Técnico', _os.tecnicoNome),
          _linha('Acompanhou a Execução', _os.acompanhante),

          // ── Acessórios ─────────────────────────────────────
          if (_acessorios.isNotEmpty) ...[
            _secao('Acessórios Recebidos'),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _acessorios
                  .map((a) => Chip(label: Text(a.nome, style: const TextStyle(fontSize: 12))))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],

          // ── Fotos da Visita Técnica (Melhoria 1) ──────────
          _secao('Fotos da Visita Técnica'),
          _fotosSecaoWidget(
            coluna: 'fotos_visita',
            urls: _fotosVisitaUrls,
            locais: _fotosVisitaLocais,
            onAddUrl: (url) => setState(() => _fotosVisitaUrls.add(url)),
            onRemoveUrl: (i) => setState(() => _fotosVisitaUrls.removeAt(i)),
            onAddLocal: (f) => setState(() => _fotosVisitaLocais.add(f)),
            onRemoveLocal: (i) => setState(() => _fotosVisitaLocais.removeAt(i)),
          ),

          // ── Análise de Equipamentos ────────────────────────
          _secao('Análise de Equipamentos'),
          // Fotos de Equipamento (Melhoria 1)
          _fotosSecaoWidget(
            coluna: 'fotos_equipamento',
            urls: _fotosEquipUrls,
            locais: _fotosEquipLocais,
            onAddUrl: (url) => setState(() => _fotosEquipUrls.add(url)),
            onRemoveUrl: (i) => setState(() => _fotosEquipUrls.removeAt(i)),
            onAddLocal: (f) => setState(() => _fotosEquipLocais.add(f)),
            onRemoveLocal: (i) => setState(() => _fotosEquipLocais.removeAt(i)),
          ),
          const SizedBox(height: 12),
          AnaliseEquipamentoForm(
            osId: _os.id,
            analiseExistente: _analise,
            onSalvo: () async {
              final nova = await OsService.listarAnaliseEquipamento(_os.id);
              if (mounted) setState(() => _analise = nova);
            },
          ),

          // ── Detalhes do Serviço ────────────────────────────
          _secao('Detalhes do Serviço'),
          _linha('Condições Físicas', _os.condicoesFisicas),
          _linha('Defeito Relatado', _os.defeito),
          _linha('Status do Equipamento', _os.statusEquipamento),
          _linha('Laudo Técnico', _os.laudoTecnico),
          _linha('Solução Aplicada', _os.solucaoAplicada),
          _linha('Peças Utilizadas', _os.pecasUtilizadas),
          _linha('Termos e Observações', _os.termosObservacoes),

          // ── Testes Realizados (Melhoria 4) ────────────────
          _secao('Testes Realizados'),
          TestesForm(
            osId: _os.id,
            fotosTesteUrls: _fotosTestesUrls,
            onSalvo: () async {
              final nova = await OsService.buscarPorId(_os.id);
              if (nova != null && mounted) {
                setState(() {
                  _os = nova;
                  _fotosTestesUrls = List<String>.from(nova.fotosTestes);
                });
              }
            },
          ),

          // ── Checklist legado ───────────────────────────────
          if (_checklist.isNotEmpty) ...[
            _secao('Checklist de Testes (legado)'),
            ..._checklist.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.feito ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: item.feito ? kColorConcluido : kTextColor3,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.itemNome,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: item.feito ? TextDecoration.lineThrough : null,
                            color: item.feito ? kTextColor3 : kTextColor,
                          ),
                        ),
                      ),
                      if (item.feito && item.dataVerificacao != null)
                        Text(
                          DateFormat('dd/MM').format(item.dataVerificacao!),
                          style: const TextStyle(fontSize: 11, color: kTextColor3),
                        ),
                    ],
                  ),
                )),
          ],

          // ── GPS ────────────────────────────────────────────
          if (_os.geoLat != null) ...[
            _secao('Localização GPS'),
            _linha('Coordenadas', 'Lat: ${_os.geoLat!.toStringAsFixed(6)} | Lng: ${_os.geoLng!.toStringAsFixed(6)}'),
          ],

          // ── Fotos ──────────────────────────────────────────
          if (_fotos.isNotEmpty) ...[
            _secao('Fotos (${_fotos.length})'),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final foto = _fotos[i];
                  final caminho = foto['caminho'] as String;
                  final isPendente = foto['pendente'] == true;
                  final isLocal = isPendente || caminho.startsWith('/');

                  Widget imagem;
                  if (isLocal) {
                    imagem = Image.file(File(caminho),
                        width: 110, height: 110, fit: BoxFit.cover);
                  } else {
                    // CachedNetworkImage: baixa 1x e fica em cache no disco
                    // → funciona offline após a primeira exibição online
                    imagem = CachedNetworkImage(
                      imageUrl: caminho,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 110, height: 110,
                        color: kCardColor,
                        child: const Icon(Icons.image_outlined,
                            color: kTextColor3),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 110, height: 110,
                        color: kCardColor,
                        child: const Icon(Icons.broken_image_outlined,
                            color: kTextColor3),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: isLocal
                            ? null
                            : () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: CachedNetworkImage(imageUrl: caminho),
                                  ),
                                ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: imagem),
                      ),
                      if (isPendente)
                        Positioned(
                          bottom: 4, right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: const Icon(Icons.sync, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],

          // ── Assinaturas ────────────────────────────────────
          if (sigCli != null || sigTec != null) ...[
            _secao('Assinaturas${sigOffline ? " (offline)" : ""}'),
            if (sigOffline)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('Pendente de sincronização', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sigCli != null)
                  Expanded(child: _sigBox('Assinatura do Cliente', sigCli)),
                if (sigCli != null && sigTec != null) const SizedBox(width: 12),
                if (sigTec != null)
                  Expanded(child: _sigBox('Assinatura do Técnico', sigTec)),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
