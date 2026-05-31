import 'package:flutter/material.dart';

// ── Paleta principal — espelha exatamente o CSS do projeto web ──
const Color kBgColor        = Color(0xFF050e08); // --bg
const Color kSurfaceColor   = Color(0xFF060F09); // --surface
const Color kCardColor      = Color(0xFF0F1C12); // --card (rgba(255,255,255,.055) sobre bg)
const Color kPrimaryColor   = Color(0xFF16a34a); // --primary
const Color kPrimaryDark    = Color(0xFF15803d); // --primary-d
const Color kPrimaryLight   = Color(0xFF22c55e); // --primary-l
const Color kPrimaryXLight  = Color(0xFF4ade80); // --primary-xl

// ── Alias para compatibilidade com código existente ─────────
const Color kBackgroundColor = kBgColor;

// ── Texto ────────────────────────────────────────────────────
const Color kTextColor  = Color(0xFFFFFFFF); // --text
const Color kTextColor2 = Color(0xFFd4e8da); // --text-2
const Color kTextColor3 = Color(0xFF92b89e); // --text-3
const Color kTextDim    = Color(0xFF4d7a5c); // --text-dim

// ── Bordas ───────────────────────────────────────────────────
const Color kBorderColor = Color(0x1AFFFFFF); // rgba(255,255,255,.10)

// ── Status — cores exatas do CSS (".badge-*") ────────────────
const Color kColorAberto    = Color(0xFF67e8f9); // cyan
const Color kColorAndamento = Color(0xFFfbbf24); // amber
const Color kColorConcluido = Color(0xFF4ade80); // green
const Color kColorCancelado = Color(0xFFf87171); // red

// ── Prioridade — cores exatas do CSS (".badge-baixa/media/urgente") ─
const Color kColorBaixa   = Color(0xFF6ee7b7); // emerald-300 (badge-baixa)
const Color kColorMedia   = Color(0xFFfcd34d); // amber-300   (badge-media)
const Color kColorUrgente = Color(0xFFfca5a5); // red-300     (badge-urgente)

// ── Listas de domínio ────────────────────────────────────────
const List<String> kStatusOS       = ['Aberto', 'Em Andamento', 'Concluído', 'Cancelado'];
const List<String> kPrioridades    = ['Baixa', 'Média', 'Urgente'];
const List<String> kTiposOcorrencia = ['Preventiva', 'Manutenção', 'Corretiva', 'Laboratório', 'Campo'];

// ── Helpers de cor ───────────────────────────────────────────
Color statusColor(String status) {
  switch (status) {
    case 'Aberto':       return kColorAberto;
    case 'Em Andamento': return kColorAndamento;
    case 'Concluído':    return kColorConcluido;
    case 'Cancelado':    return kColorCancelado;
    default:             return kTextColor3;
  }
}

Color prioridadeColor(String prioridade) {
  switch (prioridade) {
    case 'Baixa':   return kColorBaixa;
    case 'Média':   return kColorMedia;
    case 'Urgente': return kColorUrgente;
    default:        return kTextColor3;
  }
}
