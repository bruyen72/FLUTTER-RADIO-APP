import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ordem_servico.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

class OsCard extends StatelessWidget {
  final OrdemServico os;
  final VoidCallback onTap;

  const OsCard({super.key, required this.os, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: kPrimaryColor.withOpacity(0.08),
          highlightColor: kPrimaryColor.withOpacity(0.04),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1C12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Linha 1: Número OS + badges Status e Prioridade ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        os.numeroOs,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: kPrimaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ambos os badges juntos no topo direito
                    Wrap(
                      spacing: 5,
                      children: [
                        StatusBadge.status(os.status),
                        StatusBadge.prioridade(os.prioridade),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Linha 2: Cliente ──────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.business_outlined, size: 13, color: kTextColor3),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        os.clienteNome ?? 'Cliente não informado',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Linha 3: Defeito ──────────────────────────────
                if (os.defeito != null && os.defeito!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, size: 13, color: kTextColor3),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          os.defeito!,
                          style: const TextStyle(fontSize: 12, color: kTextColor3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Linha 4: Técnico ──────────────────────────────
                if (os.tecnicoNome != null && os.tecnicoNome!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.build_outlined, size: 13, color: kTextColor3),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Técnico: ${os.tecnicoNome!}',
                          style: const TextStyle(fontSize: 12, color: kTextColor3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // ── Linha 5: Data de entrada ──────────────────────
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: kTextColor3),
                    const SizedBox(width: 5),
                    Text(
                      fmt.format(os.dataEntrada),
                      style: const TextStyle(fontSize: 11, color: kTextColor3),
                    ),
                    if (os.tipoOcorrencia != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.build_outlined, size: 12, color: kTextColor3),
                      const SizedBox(width: 4),
                      Text(
                        os.tipoOcorrencia!,
                        style: const TextStyle(fontSize: 11, color: kTextColor3),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
