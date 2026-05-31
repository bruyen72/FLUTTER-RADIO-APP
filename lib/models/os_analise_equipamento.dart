import 'dart:convert';

class EquipamentoOS {
  // Identificação geral
  final String id;
  final String osId;
  final String tipoEquipamento;
  final String idNome;
  final String modelo;
  final String numeroSerie;

  // ── Campos específicos de rádio (Melhoria 3) ─────────────────
  final String tipoRadio;       // Portátil / Móvel / Repetidora / Base
  final String marcaRadio;      // Hytera / Motorola / Kenwood / Icom / Outro
  final String faixa;           // VHF / UHF / 700MHz / 800MHz
  final String firmware;
  final String condicoesFisicasRadio;
  final String defeitosRelatados;
  final List<String> acessoriosRadio; // antena, bateria, carregador, clipe
  final String solucaoProposta;
  final String laudoTecnicoRadio;
  final String termosGarantia;

  // Sistema Irradiante
  final String tipoAntena;
  final double alturaAntena;
  final String tipoCabo;
  final double comprCabo;

  // Medições de RF
  final double freqTx;
  final double freqRx;
  final double potencia;
  final double potenciaRefletida;
  final String roeVswr;

  // Alimentação
  final bool possuiFonteDedicada;
  final String voltagemFonte;

  // Extras
  final String observacoes;
  final List<String> fotos;

  // Timestamps
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  EquipamentoOS({
    required this.id,
    required this.osId,
    required this.tipoEquipamento,
    required this.idNome,
    required this.modelo,
    required this.numeroSerie,
    this.tipoRadio = '',
    this.marcaRadio = '',
    this.faixa = '',
    this.firmware = '',
    this.condicoesFisicasRadio = '',
    this.defeitosRelatados = '',
    this.acessoriosRadio = const [],
    this.solucaoProposta = '',
    this.laudoTecnicoRadio = '',
    this.termosGarantia = '',
    required this.tipoAntena,
    this.alturaAntena = 30.0,
    required this.tipoCabo,
    this.comprCabo = 40.0,
    required this.freqTx,
    required this.freqRx,
    this.potencia = 45.0,
    this.potenciaRefletida = 0.5,
    this.roeVswr = '1.2:1',
    this.possuiFonteDedicada = false,
    this.voltagemFonte = '',
    this.observacoes = '',
    this.fotos = const [],
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  // ── Helpers ───────────────────────────────────────────────────
  static List<String> _parseJsonList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.cast<String>();
    if (v is String && v.isNotEmpty) {
      try { return (jsonDecode(v) as List).cast<String>(); } catch (_) {}
    }
    return const [];
  }

  factory EquipamentoOS.fromJson(Map<String, dynamic> j) => EquipamentoOS(
        id: j['id'] as String,
        osId: j['os_id'] as String,
        tipoEquipamento: j['tipo_equipamento'] as String? ?? '',
        idNome: j['id_nome'] as String? ?? '',
        modelo: j['modelo'] as String? ?? '',
        numeroSerie: j['numero_serie'] as String? ?? '',
        tipoRadio: j['tipo_radio'] as String? ?? '',
        marcaRadio: j['marca_radio'] as String? ?? '',
        faixa: j['faixa'] as String? ?? '',
        firmware: j['firmware'] as String? ?? '',
        condicoesFisicasRadio: j['condicoes_fisicas_radio'] as String? ?? '',
        defeitosRelatados: j['defeitos_relatados'] as String? ?? '',
        acessoriosRadio: _parseJsonList(j['acessorios_radio']),
        solucaoProposta: j['solucao_proposta'] as String? ?? '',
        laudoTecnicoRadio: j['laudo_tecnico_radio'] as String? ?? '',
        termosGarantia: j['termos_garantia'] as String? ?? '',
        tipoAntena: j['tipo_antena'] as String? ?? '',
        alturaAntena: (j['altura_antena'] as num?)?.toDouble() ?? 30.0,
        tipoCabo: j['tipo_cabo'] as String? ?? '',
        comprCabo: (j['compr_cabo'] as num?)?.toDouble() ?? 40.0,
        freqTx: (j['freq_tx'] as num?)?.toDouble() ?? 0.0,
        freqRx: (j['freq_rx'] as num?)?.toDouble() ?? 0.0,
        potencia: (j['potencia'] as num?)?.toDouble() ?? 45.0,
        potenciaRefletida: (j['potencia_refletida'] as num?)?.toDouble() ?? 0.5,
        roeVswr: j['roe_vswr'] as String? ?? '1.2:1',
        possuiFonteDedicada: j['possui_fonte_dedicada'] as bool? ?? false,
        voltagemFonte: j['voltagem_fonte'] as String? ?? '',
        observacoes: j['observacoes'] as String? ?? '',
        fotos: _parseJsonList(j['fotos']),
        criadoEm: DateTime.tryParse(j['criado_em'] as String? ?? ''),
        atualizadoEm: DateTime.tryParse(j['atualizado_em'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'os_id': osId,
        'tipo_equipamento': tipoEquipamento,
        'id_nome': idNome,
        'modelo': modelo,
        'numero_serie': numeroSerie,
        'tipo_radio': tipoRadio,
        'marca_radio': marcaRadio,
        'faixa': faixa,
        'firmware': firmware,
        'condicoes_fisicas_radio': condicoesFisicasRadio,
        'defeitos_relatados': defeitosRelatados,
        'acessorios_radio': acessoriosRadio,
        'solucao_proposta': solucaoProposta,
        'laudo_tecnico_radio': laudoTecnicoRadio,
        'termos_garantia': termosGarantia,
        'tipo_antena': tipoAntena,
        'altura_antena': alturaAntena,
        'tipo_cabo': tipoCabo,
        'compr_cabo': comprCabo,
        'freq_tx': freqTx,
        'freq_rx': freqRx,
        'potencia': potencia,
        'potencia_refletida': potenciaRefletida,
        'roe_vswr': roeVswr,
        'possui_fonte_dedicada': possuiFonteDedicada,
        'voltagem_fonte': voltagemFonte,
        'observacoes': observacoes,
        'fotos': fotos,
        'atualizado_em': DateTime.now().toIso8601String(),
      };

  Map<String, dynamic> toLocal() => {
        'id': id,
        'os_id': osId,
        'tipo_equipamento': tipoEquipamento,
        'id_nome': idNome,
        'modelo': modelo,
        'numero_serie': numeroSerie,
        'tipo_radio': tipoRadio,
        'marca_radio': marcaRadio,
        'faixa': faixa,
        'firmware': firmware,
        'condicoes_fisicas_radio': condicoesFisicasRadio,
        'defeitos_relatados': defeitosRelatados,
        'acessorios_radio': jsonEncode(acessoriosRadio),
        'solucao_proposta': solucaoProposta,
        'laudo_tecnico_radio': laudoTecnicoRadio,
        'termos_garantia': termosGarantia,
        'tipo_antena': tipoAntena,
        'altura_antena': alturaAntena,
        'tipo_cabo': tipoCabo,
        'compr_cabo': comprCabo,
        'freq_tx': freqTx,
        'freq_rx': freqRx,
        'potencia': potencia,
        'potencia_refletida': potenciaRefletida,
        'roe_vswr': roeVswr,
        'possui_fonte_dedicada': possuiFonteDedicada ? 1 : 0,
        'voltagem_fonte': voltagemFonte,
        'observacoes': observacoes,
        'fotos': jsonEncode(fotos),
        'criado_em': criadoEm.toIso8601String(),
        'atualizado_em': atualizadoEm.toIso8601String(),
      };

  factory EquipamentoOS.fromLocal(Map<String, dynamic> m) => EquipamentoOS(
        id: m['id'] as String,
        osId: m['os_id'] as String,
        tipoEquipamento: m['tipo_equipamento'] as String? ?? '',
        idNome: m['id_nome'] as String? ?? '',
        modelo: m['modelo'] as String? ?? '',
        numeroSerie: m['numero_serie'] as String? ?? '',
        tipoRadio: m['tipo_radio'] as String? ?? '',
        marcaRadio: m['marca_radio'] as String? ?? '',
        faixa: m['faixa'] as String? ?? '',
        firmware: m['firmware'] as String? ?? '',
        condicoesFisicasRadio: m['condicoes_fisicas_radio'] as String? ?? '',
        defeitosRelatados: m['defeitos_relatados'] as String? ?? '',
        acessoriosRadio: _parseJsonList(m['acessorios_radio']),
        solucaoProposta: m['solucao_proposta'] as String? ?? '',
        laudoTecnicoRadio: m['laudo_tecnico_radio'] as String? ?? '',
        termosGarantia: m['termos_garantia'] as String? ?? '',
        tipoAntena: m['tipo_antena'] as String? ?? '',
        alturaAntena: (m['altura_antena'] as num?)?.toDouble() ?? 30.0,
        tipoCabo: m['tipo_cabo'] as String? ?? '',
        comprCabo: (m['compr_cabo'] as num?)?.toDouble() ?? 40.0,
        freqTx: (m['freq_tx'] as num?)?.toDouble() ?? 0.0,
        freqRx: (m['freq_rx'] as num?)?.toDouble() ?? 0.0,
        potencia: (m['potencia'] as num?)?.toDouble() ?? 45.0,
        potenciaRefletida: (m['potencia_refletida'] as num?)?.toDouble() ?? 0.5,
        roeVswr: m['roe_vswr'] as String? ?? '1.2:1',
        possuiFonteDedicada: (m['possui_fonte_dedicada'] as int? ?? 0) == 1,
        voltagemFonte: m['voltagem_fonte'] as String? ?? '',
        observacoes: m['observacoes'] as String? ?? '',
        fotos: _parseJsonList(m['fotos']),
        criadoEm: DateTime.tryParse(m['criado_em'] as String? ?? ''),
        atualizadoEm: DateTime.tryParse(m['atualizado_em'] as String? ?? ''),
      );
}
