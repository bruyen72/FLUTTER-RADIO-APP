"""
PDF Portfolio — TECPOINT
Execute: python meu_portfolio.py
Gera:    Portfolio_TECPOINT.pdf
"""
import os
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                 TableStyle, HRFlowable, PageBreak, KeepTogether)
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import reportlab.rl_config

reportlab.rl_config.warnOnMissingFontGlyphs = 0

# ── Fontes ─────────────────────────────────────────────────────
def _reg():
    for n, b in [
        (r'C:\Windows\Fonts\arial.ttf', r'C:\Windows\Fonts\arialbd.ttf'),
        ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
         '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'),
    ]:
        if os.path.exists(n) and os.path.exists(b):
            pdfmetrics.registerFont(TTFont('Arial', n))
            pdfmetrics.registerFont(TTFont('Arial-Bold', b))
            return True
    return False

_ok = _reg()
F  = 'Arial'      if _ok else 'Helvetica'
FB = 'Arial-Bold' if _ok else 'Helvetica-Bold'

# ── Cores ──────────────────────────────────────────────────────
GREEN   = colors.HexColor('#16a34a')
GREEN_D = colors.HexColor('#15803d')
GREEN_L = colors.HexColor('#dcfce7')
DARK    = colors.HexColor('#0f172a')
MUTED   = colors.HexColor('#64748b')
LIGHT   = colors.HexColor('#f8fafc')
LIGHT2  = colors.HexColor('#f0fdf4')
WHITE   = colors.white
BLUE    = colors.HexColor('#0284c7')
BLUE_L  = colors.HexColor('#eff6ff')
PURPLE  = colors.HexColor('#7c3aed')
PURPLE_L= colors.HexColor('#faf5ff')
ORANGE  = colors.HexColor('#d97706')
ORANGE_L= colors.HexColor('#fffbeb')
RED     = colors.HexColor('#dc2626')
RED_L   = colors.HexColor('#fef2f2')
BORDER  = colors.HexColor('#e2e8f0')

W = 176 * mm   # largura util da pagina

# ── Utilitarios ────────────────────────────────────────────────
def sp(n=3):  return Spacer(1, n * mm)
def hr(c=GREEN_L): return HRFlowable(width='100%', thickness=0.5, color=c, spaceAfter=2)

def txt(t, fn=None, fs=9, cor=DARK, align=TA_LEFT, lead=15, sb=2, sa=2, li=0):
    return Paragraph(t, ParagraphStyle('_', fontName=fn or F, fontSize=fs,
        textColor=cor, alignment=align, leading=lead,
        spaceBefore=sb, spaceAfter=sa, leftIndent=li))

def titulo(t, cor=GREEN_D):
    tbl = Table([[txt(t.upper(), fn=FB, fs=10, cor=WHITE)]], colWidths=[W])
    tbl.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), cor),
        ('LEFTPADDING',   (0,0), (-1,-1), 10),
        ('TOPPADDING',    (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
    ]))
    return tbl

# ── Tabela de 2 colunas (label | descricao) ────────────────────
def tabela2(linhas, c1=48*mm, cor_label=GREEN_D, bg_label=LIGHT, bg_alt=WHITE):
    """
    linhas : lista de (label, descricao)
    Texto nunca e cortado — Paragraph faz wrapping automatico.
    """
    rows = []
    for label, desc in linhas:
        rows.append([
            Paragraph(label, ParagraphStyle('l', fontName=FB, fontSize=9,
                      textColor=cor_label, leading=14)),
            Paragraph(desc,  ParagraphStyle('d', fontName=F,  fontSize=9,
                      textColor=DARK, leading=14)),
        ])
    c2 = W - c1
    t = Table(rows, colWidths=[c1, c2])
    bgs = []
    for i in range(len(linhas)):
        bg = bg_label if i % 2 == 0 else bg_alt
        bgs.append(('BACKGROUND', (0, i), (0, i), bg_label))
        bgs.append(('BACKGROUND', (1, i), (1, i), bg))
    t.setStyle(TableStyle([
        ('GRID',          (0,0), (-1,-1), 0.3, BORDER),
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('RIGHTPADDING',  (0,0), (-1,-1), 8),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        *bgs,
    ]))
    return t

# ── Bloco de categoria (titulo colorido + tabela) ──────────────
def categoria(nome_grupo, desc_grupo, itens, cor_tema, bg_tema):
    """Nunca corta texto — usa Paragraph com wrapping em todas as celulas."""
    header = Table([[
        txt(nome_grupo, fn=FB, fs=10, cor=cor_tema),
        txt(desc_grupo, fn=F,  fs=8,  cor=MUTED, align=TA_RIGHT),
    ]], colWidths=[100*mm, W - 100*mm])
    header.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), bg_tema),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('RIGHTPADDING',  (0,0), (-1,-1), 8),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('VALIGN',        (0,0), (-1,-1), 'MIDDLE'),
        ('LINEBELOW',     (0,0), (-1,-1), 1, cor_tema),
    ]))

    rows = []
    for i, (lib, uso) in enumerate(itens):
        bg = bg_tema if i % 2 == 0 else WHITE
        rows.append([
            Paragraph(lib, ParagraphStyle('lib', fontName=FB, fontSize=8,
                      textColor=cor_tema, leading=13)),
            Paragraph(uso, ParagraphStyle('uso', fontName=F,  fontSize=8,
                      textColor=DARK, leading=13)),
        ])
    corpo = Table(rows, colWidths=[52*mm, W - 52*mm])
    bgs_style = []
    for i in range(len(itens)):
        bg = bg_tema if i % 2 == 0 else WHITE
        bgs_style += [
            ('BACKGROUND', (0, i), (0, i), bg),
            ('BACKGROUND', (1, i), (1, i), bg),
        ]
    corpo.setStyle(TableStyle([
        ('GRID',          (0,0), (-1,-1), 0.25, BORDER),
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('RIGHTPADDING',  (0,0), (-1,-1), 8),
        ('TOPPADDING',    (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        *bgs_style,
    ]))
    return [header, corpo]


# ══════════════════════════════════════════════════════════════
def gerar():
    caminho = 'Portfolio_TECPOINT.pdf'
    doc = SimpleDocTemplate(caminho, pagesize=A4,
                            leftMargin=17*mm, rightMargin=17*mm,
                            topMargin=14*mm, bottomMargin=14*mm)
    el = []

    # ── Cabecalho ──────────────────────────────────────────────
    cab = Table([[
        txt('TECPOINT — Gerenciador de Ordens de Servico',
            fn=FB, fs=14, cor=WHITE),
        txt(f'Portfolio Tecnico  |  {datetime.now().strftime("%d/%m/%Y")}',
            fn=F, fs=9, cor=GREEN_L, align=TA_RIGHT),
    ]], colWidths=[115*mm, 61*mm])
    cab.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), GREEN_D),
        ('LEFTPADDING',   (0,0), (-1,-1), 12),
        ('RIGHTPADDING',  (0,0), (-1,-1), 12),
        ('TOPPADDING',    (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('VALIGN',        (0,0), (-1,-1), 'MIDDLE'),
    ]))
    el += [cab, sp(4)]

    # ── Sobre o Projeto ────────────────────────────────────────
    el += [titulo('Sobre o Projeto'), sp(2)]
    el += [
        txt('App Android para gerenciar Ordens de Servico de tecnicos em campo. '
            'Funciona 100% offline com sincronizacao automatica ao reconectar a internet. '
            'Permite criar OS, registrar defeitos e laudos, tirar fotos, coletar assinaturas '
            'digitais, capturar GPS e exportar relatorios em PDF e Word.',
            lead=16),
        sp(2),
    ]

    stats = Table([[
        txt('45+\nTelas e widgets',    fn=FB, fs=10, cor=WHITE, align=TA_CENTER, lead=15),
        txt('8.500+\nLinhas de codigo',fn=FB, fs=10, cor=WHITE, align=TA_CENTER, lead=15),
        txt('9\nTabelas SQLite',       fn=FB, fs=10, cor=WHITE, align=TA_CENTER, lead=15),
        txt('10\nTabelas Supabase',    fn=FB, fs=10, cor=WHITE, align=TA_CENTER, lead=15),
        txt('100%\nOffline-First',     fn=FB, fs=10, cor=WHITE, align=TA_CENTER, lead=15),
    ]], colWidths=[W/5]*5)
    stats.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (0,0), GREEN_D),
        ('BACKGROUND',    (1,0), (1,0), GREEN),
        ('BACKGROUND',    (2,0), (2,0), BLUE),
        ('BACKGROUND',    (3,0), (3,0), PURPLE),
        ('BACKGROUND',    (4,0), (4,0), ORANGE),
        ('TOPPADDING',    (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('INNERGRID',     (0,0), (-1,-1), 0.5, WHITE),
    ]))
    el += [stats, sp(4)]

    # ── Linguagens ─────────────────────────────────────────────
    el += [titulo('Linguagens de Programacao'), sp(2)]

    langs = Table([[
        txt('Dart',            fn=FB, fs=15, cor=BLUE,   align=TA_CENTER),
        txt('Python',          fn=FB, fs=15, cor=ORANGE, align=TA_CENTER),
        txt('SQL (PostgreSQL)',fn=FB, fs=15, cor=PURPLE, align=TA_CENTER),
        txt('XML',             fn=FB, fs=15, cor=MUTED,  align=TA_CENTER),
    ]], colWidths=[W/4]*4)
    desc_langs = Table([[
        txt('App mobile Android\n(100% do app)',              fn=F, fs=8, cor=MUTED, align=TA_CENTER, lead=12),
        txt('Sistema web Flask\n+ geracao PDF/Word',          fn=F, fs=8, cor=MUTED, align=TA_CENTER, lead=12),
        txt('Banco Supabase\ntabelas, RLS, triggers',         fn=F, fs=8, cor=MUTED, align=TA_CENTER, lead=12),
        txt('AndroidManifest\n+ recursos nativos',            fn=F, fs=8, cor=MUTED, align=TA_CENTER, lead=12),
    ]], colWidths=[W/4]*4)
    for t, bg in [(langs, LIGHT), (desc_langs, WHITE)]:
        t.setStyle(TableStyle([
            ('BACKGROUND',    (0,0), (-1,-1), bg),
            ('BOX',           (0,0), (-1,-1), 0.5, BORDER),
            ('INNERGRID',     (0,0), (-1,-1), 0.5, BORDER),
            ('TOPPADDING',    (0,0), (-1,-1), 8),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ]))
    el += [langs, desc_langs, sp(4)]

    # ── Stack Tecnico por categoria ────────────────────────────
    el += [titulo('Stack Tecnico — O que cada parte faz'), sp(2)]
    el += [
        txt('Bibliotecas agrupadas por FUNCAO para facilitar o entendimento.',
            cor=MUTED, fs=8),
        sp(3),
    ]

    grupos = [
        (
            '1.  Banco de Dados e Armazenamento',
            'Onde os dados ficam guardados',
            [
                ('supabase_flutter',
                 'Banco de dados na NUVEM (PostgreSQL). Online, todos os dados vao para ca e ficam disponiveis em qualquer dispositivo.'),
                ('sqflite',
                 'Banco LOCAL no celular/tablet (SQLite). Guarda os dados offline para uso sem internet. 9 tabelas, versao 7.'),
                ('path_provider',
                 'Encontra a pasta correta no dispositivo para salvar arquivos como fotos e PDFs gerados.'),
                ('path',
                 'Monta caminhos de arquivo corretamente no Android (ex: /storage/emulated/0/...).'),
            ],
            GREEN, LIGHT2,
        ),
        (
            '2.  Conectividade e Sincronizacao',
            'Detectar internet e enviar dados pendentes',
            [
                ('connectivity_plus',
                 'Verifica em tempo real se o dispositivo tem internet. E chamado antes de qualquer operacao de rede.'),
                ('SyncService (interno)',
                 'Fila de sincronizacao criada no projeto. Guarda alteracoes feitas offline e envia ao Supabase automaticamente ao reconectar.'),
            ],
            BLUE, BLUE_L,
        ),
        (
            '3.  Autenticacao e Seguranca',
            'Login online e offline com seguranca',
            [
                ('supabase_flutter (Auth)',
                 'Login com e-mail e senha via Supabase. Gera token JWT para autenticacao segura online.'),
                ('flutter_secure_storage',
                 'Guarda credenciais no dispositivo com criptografia forte. Permite login offline sem internet.'),
                ('crypto',
                 'Hash SHA-256 da senha para verificacao offline — a senha nunca fica em texto puro no dispositivo.'),
            ],
            RED, RED_L,
        ),
        (
            '4.  Geracao de Documentos',
            'Criar PDF e Word dentro do app, sem internet',
            [
                ('pdf',
                 'Gera arquivos PDF profissionais direto no app Android. Layout com cores, tabelas, logos e imagens de assinatura.'),
                ('printing',
                 'Abre o menu de compartilhamento para enviar o PDF por WhatsApp, e-mail, Drive, Bluetooth, etc.'),
                ('archive',
                 'Gera arquivos Word (.docx). O formato Word e internamente um ZIP com XMLs — esta biblioteca monta esse ZIP.'),
                ('share_plus',
                 'Compartilha qualquer arquivo (PDF, Word, imagem) com outros aplicativos instalados no dispositivo.'),
            ],
            PURPLE, PURPLE_L,
        ),
        (
            '5.  Camera, GPS e Permissoes',
            'Funcionalidades de hardware do dispositivo',
            [
                ('image_picker',
                 'Abre a camera ou galeria do dispositivo para o tecnico adicionar fotos nas OS.'),
                ('geolocator',
                 'Captura latitude e longitude da localizacao atual. Usa o GPS do dispositivo sem precisar de internet.'),
                ('permission_handler',
                 'Solicita as permissoes necessarias ao usuario em tempo de execucao: camera, localizacao, armazenamento.'),
                ('cached_network_image',
                 'Baixa fotos das OS e guarda em cache local. Apos a primeira visualizacao, funcionam offline.'),
            ],
            ORANGE, ORANGE_L,
        ),
        (
            '6.  Interface e Experiencia do Usuario',
            'O que o usuario ve e como o app se comporta',
            [
                ('flutter + Material 3',
                 'Framework principal. Tudo que o usuario ve — telas, botoes, cards, animacoes — e construido com Flutter.'),
                ('flutter_localizations',
                 'Garante que datas, horas e textos aparecem em portugues (ex: "janeiro" em vez de "january").'),
                ('intl',
                 'Formata datas no padrao brasileiro (dd/MM/yyyy), horas e numeros com separador correto.'),
                ('uuid',
                 'Gera IDs unicos para OS, clientes e equipamentos criados offline, evitando conflitos ao sincronizar.'),
                ('flutter_native_splash',
                 'Splash screen nativa exibida imediatamente ao abrir o app, antes do Flutter carregar — sem tela branca.'),
                ('flutter_launcher_icons',
                 'Gera o icone do app em todos os tamanhos e densidades necessarios para Android.'),
            ],
            GREEN_D, LIGHT2,
        ),
    ]

    for nome_g, desc_g, itens, cor, bg in grupos:
        bloco = categoria(nome_g, desc_g, itens, cor, bg)
        el += bloco
        el.append(sp(3))

    el.append(PageBreak())

    # ── Arquitetura ────────────────────────────────────────────
    el += [titulo('Arquitetura — Como o App Foi Construido'), sp(3)]

    el += [txt('PADRAO PRINCIPAL: OFFLINE-FIRST', fn=FB, fs=11, cor=GREEN_D), sp(1)]
    el += [txt('Toda tela e servico seguem a mesma logica antes de qualquer operacao:', fs=9), sp(1)]

    fluxo = Table([[
        txt('1\nVerifica\nconectividade',
            fn=FB, fs=9, cor=WHITE, align=TA_CENTER, lead=13),
        txt('SEM INTERNET\n►  SQLite local\n(instantaneo)',
            fn=F, fs=8, cor=DARK, align=TA_CENTER, lead=13),
        txt('COM INTERNET\n►  Supabase\n(nuvem)',
            fn=F, fs=8, cor=DARK, align=TA_CENTER, lead=13),
        txt('ERRO DE REDE\n►  SQLite local\n(fallback)',
            fn=F, fs=8, cor=DARK, align=TA_CENTER, lead=13),
    ]], colWidths=[38*mm, 46*mm, 46*mm, 46*mm])
    fluxo.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (0,0), GREEN),
        ('BACKGROUND',    (1,0), (1,0), ORANGE_L),
        ('BACKGROUND',    (2,0), (2,0), BLUE_L),
        ('BACKGROUND',    (3,0), (3,0), RED_L),
        ('BOX',           (0,0), (-1,-1), 0.5, BORDER),
        ('INNERGRID',     (0,0), (-1,-1), 0.5, BORDER),
        ('TOPPADDING',    (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('VALIGN',        (0,0), (-1,-1), 'MIDDLE'),
    ]))
    el += [fluxo, sp(4)]

    el += [txt('ESTRUTURA DE CAMADAS', fn=FB, fs=11, cor=GREEN_D), sp(1)]
    camadas = [
        ('Screens (Telas)',      'O que o usuario ve e toca. Cada funcionalidade tem sua propria tela separada.'),
        ('Services (Servicos)',  'A logica do app. Decide se busca dados do SQLite ou do Supabase conforme a conexao.'),
        ('OfflineService',       'Unico ponto de acesso ao SQLite. Todas as leituras e escritas locais passam por aqui.'),
        ('SyncService',          'Roda em background. Monitora a conexao e envia dados pendentes ao Supabase automaticamente.'),
        ('Models (Modelos)',     'Representacao dos dados: OS, Cliente, Equipamento, Usuario, Checklist, etc.'),
        ('Supabase (Nuvem)',     'Banco central com RLS por usuario, autenticacao JWT e armazenamento de fotos.'),
        ('SQLite (Local)',       '9 tabelas offline espelhando os dados da nuvem. Versao 7 com migracao automatica entre versoes.'),
    ]
    el += [tabela2(camadas, c1=52*mm, cor_label=GREEN_D), sp(4)]

    # ── Desenvolvido por ───────────────────────────────────────
    el += [titulo('Desenvolvido por Bruno (@yen)'), sp(2)]
    el += [
        txt('Todo o projeto foi idealizado, construido e executado pelo desenvolvedor:', fs=9, lead=14),
        sp(2),
    ]
    feito = [
        ('Design do App',         'Identidade visual completa: tema dark green, paleta de cores, tipografia e layout de todas as telas e componentes.'),
        ('UI / UX',               'Experiencia do usuario: fluxo de navegacao, cards, badges, animacoes da splash screen e assinatura em modo paisagem.'),
        ('Codigo Flutter',        'Escrita e ajuste do codigo Dart, construcao das telas, formularios, logica e comportamentos do app.'),
        ('Funcionalidades',       'Definicao de todos os requisitos: OS, checklist, GPS, fotos, assinaturas, PDF, Word e modo offline.'),
        ('Integracao Supabase',   'Configuracao do projeto, tabelas, politicas de seguranca (RLS) e autenticacao de usuarios.'),
        ('Testes via terminal',   'Execucao de comandos no terminal: flutter run, flutter build apk, dart run e analise de erros e warnings.'),
        ('Geracao de APK',        'Build e configuracao do APK de release para instalacao em dispositivos Android reais.'),
        ('Testes em dispositivos','Validacao do app em tablet e celular — bugs visuais, travamentos e comportamentos inesperados.'),
        ('Estabilidade do app',   'Identificacao e correcao de travamentos, spinners infinitos e problemas de performance em uso real.'),
        ('Decisoes do produto',   'O que entra ou nao no app, prioridades, o que funciona offline e a experiencia do tecnico em campo.'),
    ]
    el += [tabela2(feito, c1=52*mm, cor_label=GREEN_D, bg_label=LIGHT2), sp(4)]

    # ── IA ─────────────────────────────────────────────────────
    el += [titulo('Inteligencia Artificial no Desenvolvimento', PURPLE), sp(2)]

    ia_cab = Table([[
        txt('Claude Code  (Anthropic)', fn=FB, fs=13, cor=PURPLE),
        txt('Modelo: Claude Sonnet 4.6  |  Interface: CLI',
            fn=F, fs=9, cor=MUTED, align=TA_RIGHT),
    ]], colWidths=[100*mm, W - 100*mm])
    ia_cab.setStyle(TableStyle([
        ('VALIGN',        (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING',    (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    el += [ia_cab]
    el += [
        txt('O desenvolvimento contou com apoio da IA Claude Code nas seguintes areas:', fs=9, lead=14),
        sp(2),
    ]
    ia_itens = [
        ('Codigo Flutter/Dart', 'Implementacao completa de todos os 45+ arquivos Dart do projeto.'),
        ('SQL / Supabase',      'Schema completo, RLS policies, functions, triggers e storage.'),
        ('Logica Offline',      'SQLite schema, sync queue e offline-first em todos os servicos.'),
        ('PDF e Word',          'Geradores completos em Dart (pdf + archive) e Python (reportlab + docx).'),
        ('Bugs e auditoria',    'Analise e correcao de todos os bugs encontrados ao longo do projeto.'),
        ('Performance',         'Otimizacao offline-first: de timeout 30 segundos para 0ms sem internet.'),
    ]
    el += [tabela2(ia_itens, c1=52*mm, cor_label=PURPLE, bg_label=PURPLE_L), sp(4)]

    # ── Ferramentas ────────────────────────────────────────────
    el += [titulo('Ferramentas Utilizadas'), sp(2)]
    tools = [
        ('Android Studio',     'IDE principal para escrever, testar e depurar o codigo Flutter/Android.'),
        ('Claude Code CLI',    'Interface da IA Claude no terminal do Android Studio para co-desenvolvimento.'),
        ('Supabase Dashboard', 'Painel web para gerenciar banco, usuarios, storage e politicas de seguranca.'),
        ('Git',                'Controle de versao — historico de todas as alteracoes do projeto.'),
        ('Python 3',           'Linguagem do sistema web e dos scripts de geracao de PDF/Word e deste portfolio.'),
        ('ViaCEP (API)',        'API gratuita que retorna endereco completo a partir do CEP digitado pelo usuario.'),
        ('Windows 10',         'Sistema operacional do ambiente de desenvolvimento.'),
    ]
    el += [tabela2(tools, c1=52*mm, cor_label=BLUE, bg_label=BLUE_L), sp(6)]

    # ── Rodape ─────────────────────────────────────────────────
    el.append(hr(GREEN))
    el.append(sp(2))
    rod = Table([[
        txt('TECPOINT  |  UniSENAI MT  |  2026', fn=FB, fs=10, cor=GREEN_D),
        txt(f'Gerado em {datetime.now().strftime("%d/%m/%Y  %H:%M")}',
            fn=F, fs=8, cor=MUTED, align=TA_RIGHT),
    ]], colWidths=[88*mm, 88*mm])
    rod.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'MIDDLE')]))
    el.append(rod)

    doc.build(el)
    print(f'\nPortfolio gerado: {caminho}')


if __name__ == '__main__':
    gerar()
