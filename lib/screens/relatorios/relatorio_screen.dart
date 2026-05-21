import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ordem_servico.dart';
import '../../services/os_service.dart';
import '../../services/pdf_service.dart';
import '../../services/word_service.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';

class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  List<OrdemServico> _lista  = [];
  bool _loading              = true;
  String? _gerando; // "pdf_{id}" ou "word_{id}"

  // ── LÓGICA INTACTA ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await OsService.listar();
    if (mounted) setState(() { _lista = lista; _loading = false; });
  }

  Future<void> _gerarPdf(OrdemServico os) async {
    setState(() => _gerando = 'pdf_${os.id}');
    try {
      final arquivo = await PdfService.gerarPdf(os);
      await PdfService.compartilhar(arquivo, os.numeroOs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro PDF: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _gerando = null);
    }
  }

  Future<void> _gerarWord(OrdemServico os) async {
    setState(() => _gerando = 'word_${os.id}');
    try {
      final arquivo = await WordService.gerarWord(os);
      await WordService.compartilhar(arquivo, os.numeroOs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro Word: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _gerando = null);
    }
  }

  // ── VISUAL ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: kSurfaceColor,
        foregroundColor: kTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _lista.isEmpty
              ? _buildVazio()
              : Column(
                  children: [
                    // ── Header info ───────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined,
                              color: kPrimaryLight, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_lista.length} ordem${_lista.length != 1 ? "s" : ""} disponível${_lista.length != 1 ? "is" : ""} para gerar PDF',
                              style: const TextStyle(
                                  color: kTextColor2, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Lista ─────────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _carregar,
                        color: kPrimaryColor,
                        backgroundColor: kCardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                          itemCount: _lista.length,
                          itemBuilder: (_, i) => _buildItem(_lista[i], fmt),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildItem(OrdemServico os, DateFormat fmt) {
    final gerandoPdf  = _gerando == 'pdf_${os.id}';
    final gerandoWord = _gerando == 'word_${os.id}';
    final gerandoQualquer = gerandoPdf || gerandoWord;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: kPrimaryLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(os.numeroOs,
                          style: const TextStyle(
                              color: kPrimaryLight, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(os.clienteNome ?? '—',
                          style: const TextStyle(color: kTextColor, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        StatusBadge.status(os.status),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_outlined, size: 11, color: kTextDim),
                        const SizedBox(width: 4),
                        Text(fmt.format(os.dataEntrada),
                            style: const TextStyle(color: kTextDim, fontSize: 11)),
                      ]),
                      if (os.tecnicoNome != null && os.tecnicoNome!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.build_outlined, size: 11, color: kTextDim),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Técnico: ${os.tecnicoNome!}',
                                style: const TextStyle(color: kTextDim, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botões PDF e Word
            Row(
              children: [
                Expanded(child: _btnFormato(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  cor: const Color(0xFFdc2626),
                  gerando: gerandoPdf,
                  bloqueado: gerandoQualquer,
                  onTap: () => _gerarPdf(os),
                )),
                const SizedBox(width: 8),
                Expanded(child: _btnFormato(
                  icon: Icons.article_outlined,
                  label: 'Word (.docx)',
                  cor: const Color(0xFF2563eb),
                  gerando: gerandoWord,
                  bloqueado: gerandoQualquer,
                  onTap: () => _gerarWord(os),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btnFormato({
    required IconData icon,
    required String label,
    required Color cor,
    required bool gerando,
    required bool bloqueado,
    required VoidCallback onTap,
  }) =>
      ElevatedButton.icon(
        onPressed: bloqueado ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: cor.withOpacity(0.12),
          foregroundColor: cor,
          disabledBackgroundColor: kCardColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: cor.withOpacity(0.3)),
          ),
        ),
        icon: gerando
            ? SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: cor))
            : Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _buildVazio() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor),
          ),
          child: const Icon(Icons.picture_as_pdf_outlined,
              size: 40, color: kTextDim),
        ),
        const SizedBox(height: 16),
        const Text('Nenhuma OS disponível',
            style: TextStyle(color: kTextColor2, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Crie ordens de serviço para gerar relatórios PDF.',
            style: TextStyle(color: kTextDim, fontSize: 12),
            textAlign: TextAlign.center),
      ],
    ),
  );
}
