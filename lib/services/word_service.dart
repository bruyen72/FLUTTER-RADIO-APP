import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ordem_servico.dart';
import '../models/os_acessorio.dart';
import '../models/os_checklist.dart';
import '../models/usuario.dart';
import 'auth_service.dart';
import 'os_service.dart';

class WordService {
  // ── Gera e salva o .docx ───────────────────────────────────
  static Future<File> gerarWord(OrdemServico os) async {
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

    // Determina nome do técnico
    String tecnicoNome = os.tecnicoNome ?? '-';
    if (tecnicoNome == '-' && os.tecnicoId != null && perfil != null) {
      if (os.tecnicoId == perfil.id) {
        tecnicoNome = perfil.nome;
      }
    }

    final sigCliBytes = _decodeSig(assinatura?['sig_cliente'] as String?);
    final sigTecBytes = _decodeSig(assinatura?['sig_tecnico'] as String?);

    final archive = Archive();

    // Partes obrigatórias do DOCX
    _addFile(archive, '[Content_Types].xml', _contentTypes(sigCliBytes != null, sigTecBytes != null));
    _addFile(archive, '_rels/.rels', _rootRels());
    _addFile(archive, 'word/styles.xml', _styles());
    _addFile(archive, 'word/settings.xml', _settings());
    _addFile(archive, 'word/_rels/document.xml.rels', _docRels(sigCliBytes != null, sigTecBytes != null));

    // Imagens de assinatura
    if (sigCliBytes != null) _addBinary(archive, 'word/media/sig_cli.png', sigCliBytes);
    if (sigTecBytes != null) _addBinary(archive, 'word/media/sig_tec.png', sigTecBytes);

    // Documento principal
    _addFile(archive, 'word/document.xml',
        _document(os, checklist, acessorios, sigCliBytes != null, sigTecBytes != null, tecnicoNome));

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw Exception('Falha ao gerar arquivo Word');
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/OS_${os.numeroOs.replaceAll('-', '_')}.docx');
    await file.writeAsBytes(Uint8List.fromList(encoded));
    return file;
  }

  // ── Compartilhar .docx ─────────────────────────────────────
  static Future<void> compartilhar(File arquivo, String nomeOs) async {
    await Share.shareXFiles(
      [XFile(arquivo.path,
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
      subject: 'OS_$nomeOs',
    );
  }

  // ─── Helpers de arquivo ────────────────────────────────────
  static void _addFile(Archive a, String name, String content) {
    final bytes = utf8.encode(content);
    a.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static void _addBinary(Archive a, String name, Uint8List bytes) {
    a.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  // ─── XML Parts ────────────────────────────────────────────

  static String _contentTypes(bool hasSigCli, bool hasSigTec) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  ${hasSigCli || hasSigTec ? '<Default Extension="png" ContentType="image/png"/>' : ''}
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
</Types>''';

  static String _rootRels() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static String _docRels(bool hasSigCli, bool hasSigTec) {
    final imgs = StringBuffer();
    if (hasSigCli) imgs.write('\n  <Relationship Id="rIdSigCli" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/sig_cli.png"/>');
    if (hasSigTec) imgs.write('\n  <Relationship Id="rIdSigTec" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/sig_tec.png"/>');
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>$imgs
</Relationships>''';
  }

  static String _settings() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:defaultTabStop w:val="720"/>
</w:settings>''';

  static String _styles() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/><w:color w:val="0f172a"/></w:rPr>
  </w:style>
</w:styles>''';

  // ─── Documento principal ───────────────────────────────────
  static String _document(OrdemServico os, List<ChecklistItem> checklist,
      List<OsAcessorio> acessorios, bool hasSigCli, bool hasSigTec, String tecnicoNome) {
    final fmt   = DateFormat('dd/MM/yyyy');
    final fmtDt = DateFormat('dd/MM/yy');
    final agora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final body  = StringBuffer();

    // ── Cabeçalho ──────────────────────────────────────────
    body.write(_tbl([
      _tr([
        _tc(_p('GERENCIADOR DE OS PARA CAMPO', bold: true, color: 'FFFFFF', sz: 26), bg: '15803d'),
        _tc(_p('Nº ${os.numeroOs}',           bold: true, color: 'FFFFFF', sz: 26, align: 'right'), bg: '166534'),
      ]),
    ], borders: false));

    body.write(_emptyP());

    // ── Identificação ───────────────────────────────────────
    body.write(_sectionHeader('IDENTIFICAÇÃO DA OS'));
    body.write(_tbl([
      _kvRow('Nº OS',               os.numeroOs),
      _kvRow('Status',              os.status),
      _kvRow('Prioridade',          os.prioridade),
      _kvRow('Tipo de Ocorrência',  os.tipoOcorrencia ?? '-'),
      _kvRow('Data de Entrada',     fmt.format(os.dataEntrada)),
      _kvRow('Hora de Entrada',     os.horaEntrada ?? '-'),
      _kvRow('Data de Saída',       os.dataSaida != null ? fmt.format(os.dataSaida!) : '-'),
      _kvRow('Cliente',             os.clienteNome ?? 'Não informado'),
      _kvRow('Técnico Responsável', tecnicoNome),
      _kvRow('Acompanhou',          os.acompanhante ?? '-'),
      _kvRow('Endereço / Local',    os.geoEndereco ?? '-'),
    ]));
    body.write(_emptyP());

    // ── Acessórios ──────────────────────────────────────────
    if (acessorios.isNotEmpty) {
      body.write(_sectionHeader('ACESSÓRIOS RECEBIDOS'));
      body.write(_p(acessorios.map((a) => a.nome).join('  |  '), sz: 18));
      body.write(_emptyP());
    }

    // ── Laudo ───────────────────────────────────────────────
    final laudoRows = [
      if (os.condicoesFisicas != null) _kvRow('Condições Físicas', os.condicoesFisicas!),
      if (os.defeito != null) _kvRow('Defeito Relatado', os.defeito!),
      if (os.laudoTecnico != null) _kvRow('Laudo / Diagnóstico', os.laudoTecnico!),
      if (os.solucaoAplicada != null) _kvRow('Solução Aplicada', os.solucaoAplicada!),
      if (os.pecasUtilizadas != null) _kvRow('Peças / Materiais', os.pecasUtilizadas!),
      if (os.termosObservacoes != null) _kvRow('Termos e Observações', os.termosObservacoes!),
    ];
    body.write(_sectionHeader('LAUDO TÉCNICO E SOLUÇÃO'));
    if (laudoRows.isNotEmpty) body.write(_tbl(laudoRows));
    body.write(_emptyP());

    // ── Checklist ───────────────────────────────────────────
    if (checklist.isNotEmpty) {
      body.write(_sectionHeader('CHECKLIST DE TESTES'));
      body.write(_tbl([
        _tr([
          _tc(_p('#',              bold: true, color: 'FFFFFF', sz: 16), bg: '15803d', w: '400'),
          _tc(_p('Teste',          bold: true, color: 'FFFFFF', sz: 16), bg: '15803d'),
          _tc(_p('Feito',         bold: true, color: 'FFFFFF', sz: 16), bg: '15803d', w: '700'),
          _tc(_p('Data',          bold: true, color: 'FFFFFF', sz: 16), bg: '15803d', w: '1400'),
          _tc(_p('Técnico Verif.',bold: true, color: 'FFFFFF', sz: 16), bg: '15803d'),
        ]),
        ...checklist.asMap().entries.map((e) {
          final item = e.value;
          final feito = item.feito ? 'Sim' : 'Nao';
          return _tr([
            _tc(_p('${e.key + 1}',                  sz: 16, color: '64748b'), w: '400'),
            _tc(_p(item.itemNome,                   sz: 16)),
            _tc(_p(feito, bold: true,               sz: 16, color: item.feito ? '16a34a' : 'dc2626'), w: '700'),
            _tc(_p(item.dataVerificacao != null ? fmtDt.format(item.dataVerificacao!) : '-', sz: 16, color: '64748b'), w: '1400'),
            _tc(_p(item.tecnicoVerificador ?? '-',  sz: 16, color: '64748b')),
          ]);
        }),
      ]));
      body.write(_emptyP());
    }

    // ── GPS ─────────────────────────────────────────────────
    if (os.geoLat != null) {
      body.write(_sectionHeader('LOCALIZAÇÃO GPS'));
      body.write(_tbl([
        _kvRow('Coordenadas', 'Lat: ${os.geoLat!.toStringAsFixed(6)}  |  Lng: ${os.geoLng!.toStringAsFixed(6)}'),
        if (os.geoEndereco != null && os.geoEndereco!.isNotEmpty)
          _kvRow('Endereço', os.geoEndereco!),
      ]));
      body.write(_emptyP());
    }

    // ── Assinaturas ─────────────────────────────────────────
    body.write(_sectionHeader('ASSINATURAS'));
    body.write(_tbl([
      _tr([
        _tc(_p('Assinatura do Cliente',            bold: true, color: '64748b', sz: 16, align: 'center'), bg: 'f8fafc'),
        _tc(_p('Assinatura do Técnico Responsável', bold: true, color: '64748b', sz: 16, align: 'center'), bg: 'f8fafc'),
      ]),
      _tr([
        _tc(hasSigCli ? _imgXml('rIdSigCli', '2160000', '900000', id: 1) : _espacoSig()),
        _tc(hasSigTec ? _imgXml('rIdSigTec', '2160000', '900000', id: 2) : _espacoSig()),
      ]),
    ]));
    body.write(_emptyP());

    // ── Rodapé ──────────────────────────────────────────────
    body.write(_p('TECPOINT  ·  SURVEY  ·  Gerado em $agora',
        sz: 14, color: '64748b', align: 'center'));

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:body>
    $body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="850" w:right="850" w:bottom="850" w:left="850"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  // ─── Helpers XML ──────────────────────────────────────────

  static String _escXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _p(String text, {bool bold = false, String? color, int? sz, String? align}) {
    final rpr = [
      if (bold)   '<w:b/>',
      if (color != null) '<w:color w:val="$color"/>',
      if (sz != null) '<w:sz w:val="$sz"/><w:szCs w:val="$sz"/>',
    ].join();
    final ppr = align != null ? '<w:pPr><w:jc w:val="$align"/></w:pPr>' : '';
    return '<w:p>$ppr<w:r>${rpr.isNotEmpty ? '<w:rPr>$rpr</w:rPr>' : ''}<w:t xml:space="preserve">${_escXml(text)}</w:t></w:r></w:p>';
  }

  static String _emptyP() => '<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>';

  static String _tc(String content, {String? bg, String? w}) {
    final tcpr = [
      if (bg != null) '<w:shd w:val="clear" w:color="auto" w:fill="$bg"/>',
      if (w  != null) '<w:tcW w:w="$w" w:type="dxa"/>',
    ].join();
    return '<w:tc>${tcpr.isNotEmpty ? '<w:tcPr>$tcpr</w:tcPr>' : ''}$content</w:tc>';
  }

  static String _tr(List<String> cells) => '<w:tr>${cells.join()}</w:tr>';

  static String _tbl(List<String> rows, {bool borders = true}) {
    final border = borders ? '''
      <w:tblBorders>
        <w:top    w:val="single" w:sz="2" w:color="e2e8f0"/>
        <w:left   w:val="single" w:sz="2" w:color="e2e8f0"/>
        <w:bottom w:val="single" w:sz="2" w:color="e2e8f0"/>
        <w:right  w:val="single" w:sz="2" w:color="e2e8f0"/>
        <w:insideH w:val="single" w:sz="2" w:color="e2e8f0"/>
        <w:insideV w:val="single" w:sz="2" w:color="e2e8f0"/>
      </w:tblBorders>''' : '';
    return '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>$border</w:tblPr>${rows.join()}</w:tbl>';
  }

  static String _sectionHeader(String text) => _tbl([
    _tr([_tc(_p(text, bold: true, color: 'FFFFFF', sz: 18), bg: '15803d')]),
  ], borders: false);

  static String _kvRow(String label, String value) => _tr([
    _tc(_p(label, bold: true, color: '64748b', sz: 16), bg: 'f8fafc', w: '2268'),
    _tc(_p(value, sz: 16)),
  ]);

  // Imagem inline para assinatura
  static String _imgXml(String rId, String cx, String cy, {int id = 1}) => '''
<w:p><w:r><w:drawing>
  <wp:inline distT="0" distB="0" distL="0" distR="0">
    <wp:extent cx="$cx" cy="$cy"/>
    <wp:effectExtent l="0" t="0" r="0" b="0"/>
    <wp:docPr id="$id" name="sig$id"/>
    <wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>
    <a:graphic>
      <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
        <pic:pic>
          <pic:nvPicPr>
            <pic:cNvPr id="$id" name="sig$id"/>
            <pic:cNvPicPr/>
          </pic:nvPicPr>
          <pic:blipFill>
            <a:blip r:embed="$rId"/>
            <a:stretch><a:fillRect/></a:stretch>
          </pic:blipFill>
          <pic:spPr>
            <a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>
            <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
          </pic:spPr>
        </pic:pic>
      </a:graphicData>
    </a:graphic>
  </wp:inline>
</w:drawing></w:r></w:p>''';

  static String _espacoSig() =>
      '<w:p><w:pPr><w:spacing w:before="1800"/></w:pPr></w:p>';

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
