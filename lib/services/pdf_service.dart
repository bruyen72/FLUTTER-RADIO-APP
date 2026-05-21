import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ordem_servico.dart';
import '../models/os_acessorio.dart';
import '../models/os_checklist.dart';
import '../models/usuario.dart';
import 'auth_service.dart';
import 'os_service.dart';

class PdfService {
  // ── Paleta idêntica ao web ─────────────────────────────────
  static final _green  = PdfColor.fromHex('#16a34a');
  static final _greenD = PdfColor.fromHex('#15803d');
  static final _dark   = PdfColor.fromHex('#0f172a');
  static final _muted  = PdfColor.fromHex('#64748b');
  static final _light  = PdfColor.fromHex('#f8fafc');
  static final _danger = PdfColor.fromHex('#dc2626');
  static final _warn   = PdfColor.fromHex('#d97706');
  static final _info   = PdfColor.fromHex('#0284c7');
  static const _white  = PdfColors.white;

  // ── Carrega tudo e gera PDF ────────────────────────────────
  static Future<File> gerarPdf(OrdemServico os) async {
    final results = await Future.wait([
      OsService.listarChecklist(os.id),
      OsService.listarAcessorios(os.id),
      OsService.listarAssinatura(os.id),
      AuthService.getProfile(),
    ]);
    final checklist  = results[0] as List<ChecklistItem>;
    final acessorios = results[1] as List<OsAcessorio>;
    final assinatura = results[2] as Map<String, dynamic>?;
    final perfil     = results[3] as Usuario?;

    // Determina nome do técnico (prioriza objeto, depois perfil logado se ID bater)
    String tecnicoNome = os.tecnicoNome ?? '-';
    if (tecnicoNome == '-' && os.tecnicoId != null && perfil != null) {
      if (os.tecnicoId == perfil.id) {
        tecnicoNome = perfil.nome;
      }
    }

    final sigCli = _decodeSig(assinatura?['sig_cliente'] as String?);
    final sigTec = _decodeSig(assinatura?['sig_tecnico'] as String?);

    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 48, top: 48, right: 48, bottom: 20),
      footer: (context) {
        if (context.pageNumber == context.pagesCount) {
          return pw.Align(
            alignment: pw.Alignment.bottomCenter,
            child: _footer(),
          );
        }
        return pw.SizedBox();
      },
      build: (_) => [
        _header(os),
        pw.SizedBox(height: 12),
        _statusFaixa(os),
        pw.SizedBox(height: 12),

        _sectionTitle('IDENTIFICAÇÃO DA OS'),
        _identTable(os, fmt, tecnicoNome),
        pw.SizedBox(height: 12),

        if (acessorios.isNotEmpty) ...[
          _sectionTitle('ACESSÓRIOS RECEBIDOS'),
          _acessoriosWidget(acessorios),
          pw.SizedBox(height: 12),
        ],

        _sectionTitle('LAUDO TÉCNICO E SOLUÇÃO'),
        if (os.condicoesFisicas != null) _campo('CONDIÇÕES FÍSICAS DO EQUIPAMENTO', os.condicoesFisicas!),
        if (os.defeito != null) _campo('DEFEITO RELATADO', os.defeito!),
        if (os.laudoTecnico != null) _campo('LAUDO / DIAGNÓSTICO TÉCNICO', os.laudoTecnico!),
        if (os.solucaoAplicada != null) _campo('SOLUÇÃO APLICADA', os.solucaoAplicada!),
        if (os.pecasUtilizadas != null) _campo('PEÇAS / MATERIAIS UTILIZADOS', os.pecasUtilizadas!),
        if (os.termosObservacoes != null) _campo('TERMOS E OBSERVAÇÕES', os.termosObservacoes!),
        pw.SizedBox(height: 12),

        if (checklist.isNotEmpty) ...[
          _sectionTitle('CHECKLIST DE TESTES'),
          _checklistTable(checklist),
          pw.SizedBox(height: 12),
        ],

        if (os.geoLat != null) ...[
          _sectionTitle('LOCALIZAÇÃO GPS'),
          _campo('COORDENADAS',
              'Lat: ${os.geoLat!.toStringAsFixed(6)}  |  Lng: ${os.geoLng!.toStringAsFixed(6)}'),
          if (os.geoEndereco != null && os.geoEndereco!.isNotEmpty)
            _campo('ENDEREÇO', os.geoEndereco!),
          pw.SizedBox(height: 12),
        ],

        pw.SizedBox(height: 20),
        _sectionTitle('ASSINATURAS'),
        _assinaturasWidget(sigCli, sigTec),
      ],
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/OS_${os.numeroOs.replaceAll('-', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Compartilhar PDF ───────────────────────────────────────
  static Future<void> compartilhar(File arquivo, String nomeOs) async {
    final bytes = await arquivo.readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: 'OS_$nomeOs.pdf');
  }

  // ── Header ─────────────────────────────────────────────────
  static pw.Widget _header(OrdemServico os) => pw.Container(
    decoration: pw.BoxDecoration(color: _greenD),
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('GERENCIADOR DE OS PARA CAMPO',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _white)),
        pw.Text('Nº ${os.numeroOs}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _white)),
      ],
    ),
  );

  // ── Footer ─────────────────────────────────────────────────
  static pw.Widget _footer() => pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(height: 1, color: _green),
      pw.SizedBox(height: 3),
      pw.Text(
        'TECPOINT  ·  SURVEY  ·  Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        style: pw.TextStyle(fontSize: 7, color: _muted),
        textAlign: pw.TextAlign.center,
      ),
    ],
  );

  // ── Faixa status/prioridade/tipo ───────────────────────────
  static pw.Widget _statusFaixa(OrdemServico os) {
    final statusCor = switch (os.status) {
      'Em Andamento' => _warn,
      'Concluído'    => _green,
      'Cancelado'    => _danger,
      _              => _info,
    };
    final priorCor = switch (os.prioridade) {
      'Urgente' => _danger,
      'Média'   => _warn,
      _         => _green,
    };
    final tipoCor = PdfColor.fromHex('#94a3b8');

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          _faixaCell('STATUS',      os.status,                  statusCor),
          _faixaCell('PRIORIDADE',  os.prioridade,              priorCor),
          _faixaCell('OCORRENCIA',  os.tipoOcorrencia ?? '-',   tipoCor),
        ]),
      ],
    );
  }

  static pw.Widget _faixaCell(String label, String value, PdfColor cor) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        color: cor,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColor(1, 1, 1, 0.7),
                fontWeight: pw.FontWeight.bold)),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, color: _white,
                fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  // ── Cabeçalho de seção ─────────────────────────────────────
  static pw.Widget _sectionTitle(String titulo) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    color: _greenD,
    child: pw.Text(titulo,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white)),
  );

  // ── Tabela de identificação ────────────────────────────────
  static pw.Widget _identTable(OrdemServico os, DateFormat fmt, String tecnicoNome) {
    final border = pw.TableBorder.all(color: PdfColors.grey300, width: 0.3);

    pw.Widget label(String t) => pw.Container(
      padding: const pw.EdgeInsets.all(4),
      color: _light,
      child: pw.Text(t, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _muted)),
    );
    pw.Widget value(String t) => pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 8, color: _dark)),
    );
    pw.TableRow kv(String k, String v) => pw.TableRow(children: [label(k), value(v)]);

    return pw.Table(
      border: border,
      columnWidths: const {0: pw.FixedColumnWidth(110), 1: pw.FlexColumnWidth()},
      children: [
        kv('Nº OS',               os.numeroOs),
        kv('Status',              os.status),
        kv('Prioridade',          os.prioridade),
        kv('Tipo de Ocorrência',  os.tipoOcorrencia ?? '-'),
        kv('Data de Entrada',     fmt.format(os.dataEntrada)),
        kv('Hora de Entrada',     os.horaEntrada ?? '-'),
        kv('Data de Saída',       os.dataSaida != null ? fmt.format(os.dataSaida!) : '-'),
        kv('Cliente',             os.clienteNome ?? os.clienteId),
        kv('Técnico Responsável', tecnicoNome),
        kv('Acompanhou',          os.acompanhante ?? '-'),
        kv('Endereço / Local',    os.geoEndereco ?? '-'),
      ],
    );
  }

  // ── Campo de texto longo ───────────────────────────────────
  static pw.Widget _campo(String label, String valor) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 4),
      pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _muted)),
      pw.SizedBox(height: 2),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          color: _light,
          border: pw.Border.all(color: PdfColors.grey300, width: 0.3),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
        child: pw.Text(valor, style: pw.TextStyle(fontSize: 9, color: _dark)),
      ),
    ],
  );

  // ── Acessórios como chips (Corrigido para evitar erro vetorial) ──
  static pw.Widget _acessoriosWidget(List<OsAcessorio> items) => pw.Wrap(
    spacing: 10,
    runSpacing: 10,
    children: items.map((a) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#dcfce7'),
        border: pw.Border.all(color: _green, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(a.nome,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _greenD)),
    )).toList(),
  );

  // ── Tabela de checklist ────────────────────────────────────
  static pw.Widget _checklistTable(List<ChecklistItem> items) {
    final fmtDt = DateFormat('dd/MM/yy');

    pw.Widget head(String t) => pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _white)),
    );
    pw.Widget cell(String t, {PdfColor? color}) => pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 7, color: color ?? _dark)),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: const {
        0: pw.FixedColumnWidth(24),
        1: pw.FlexColumnWidth(4),
        2: pw.FixedColumnWidth(36),
        3: pw.FixedColumnWidth(50),
        4: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _greenD),
          children: ['#', 'Item de Verificação', 'Feito', 'Data', 'Técnico Verif.'].map(head).toList(),
        ),
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final bg = e.key.isEven ? _white : _light;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              cell('${e.key + 1}', color: _muted),
              cell(item.itemNome),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  item.feito ? 'Sim' : 'Nao',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: item.feito ? _green : _danger,
                  ),
                ),
              ),
              cell(item.dataVerificacao != null ? fmtDt.format(item.dataVerificacao!) : '-', color: _muted),
              cell(item.tecnicoVerificador ?? '-', color: _muted),
            ],
          );
        }),
      ],
    );
  }

  // ── Assinaturas com imagem real ────────────────────────────
  static pw.Widget _assinaturasWidget(Uint8List? sigCli, Uint8List? sigTec) =>
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(children: [
            _sigCell('Assinatura do Cliente', sigCli),
            _sigCell('Assinatura do Técnico Responsável', sigTec),
          ]),
        ],
      );

  static pw.Widget _sigCell(String label, Uint8List? bytes) => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    height: 100,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _muted),
            textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        if (bytes != null)
          pw.Container(
            height: 60,
            child: pw.Center(
              child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
            ),
          )
        else
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
          ),
      ],
    ),
  );

  // ── Decodifica base64 → bytes ──────────────────────────────
  static Uint8List? _decodeSig(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final b64 = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }
}
