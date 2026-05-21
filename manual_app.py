"""
Gerador do Manual do Usuário — TECPOINT App
Execute: python manual_app.py
Gera: TECPOINT_Manual_App.pdf
"""
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                 TableStyle, HRFlowable, PageBreak)
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import reportlab.rl_config

reportlab.rl_config.warnOnMissingFontGlyphs = 0

# ── Fontes ─────────────────────────────────────────────────────
def _reg_fonts():
    for normal, bold in [
        (r'C:\Windows\Fonts\arial.ttf', r'C:\Windows\Fonts\arialbd.ttf'),
        ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
         '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'),
    ]:
        if os.path.exists(normal) and os.path.exists(bold):
            pdfmetrics.registerFont(TTFont('Arial',      normal))
            pdfmetrics.registerFont(TTFont('Arial-Bold', bold))
            return True
    return False

_ok = _reg_fonts()
F  = 'Arial'      if _ok else 'Helvetica'
FB = 'Arial-Bold' if _ok else 'Helvetica-Bold'

# ── Paleta ─────────────────────────────────────────────────────
GREEN   = colors.HexColor('#16a34a')
GREEN_D = colors.HexColor('#15803d')
GREEN_L = colors.HexColor('#dcfce7')
DARK    = colors.HexColor('#0f172a')
MUTED   = colors.HexColor('#64748b')
LIGHT   = colors.HexColor('#f8fafc')
WHITE   = colors.white
WARN    = colors.HexColor('#d97706')
DANGER  = colors.HexColor('#dc2626')
INFO    = colors.HexColor('#0284c7')

# ── Estilos ────────────────────────────────────────────────────
def estilos():
    return {
        'capa_titulo': ParagraphStyle('ct', fontName=FB, fontSize=32,
            textColor=WHITE, alignment=TA_CENTER, spaceAfter=6),
        'capa_sub': ParagraphStyle('cs', fontName=F, fontSize=14,
            textColor=GREEN_L, alignment=TA_CENTER, spaceAfter=4),
        'capa_versao': ParagraphStyle('cv', fontName=F, fontSize=10,
            textColor=MUTED, alignment=TA_CENTER),
        'capitulo': ParagraphStyle('cap', fontName=FB, fontSize=18,
            textColor=WHITE, spaceAfter=4, spaceBefore=2),
        'secao': ParagraphStyle('sec', fontName=FB, fontSize=13,
            textColor=GREEN_D, spaceBefore=10, spaceAfter=4),
        'subsecao': ParagraphStyle('sub', fontName=FB, fontSize=11,
            textColor=DARK, spaceBefore=8, spaceAfter=3),
        'corpo': ParagraphStyle('cor', fontName=F, fontSize=10,
            textColor=DARK, leading=15, spaceAfter=5, alignment=TA_JUSTIFY),
        'lista': ParagraphStyle('lis', fontName=F, fontSize=10,
            textColor=DARK, leading=15, spaceAfter=3, leftIndent=12),
        'nota': ParagraphStyle('not', fontName=F, fontSize=9,
            textColor=MUTED, leading=13, spaceAfter=4, leftIndent=8),
        'rodape': ParagraphStyle('rod', fontName=F, fontSize=7,
            textColor=MUTED, alignment=TA_CENTER),
        'destaque': ParagraphStyle('des', fontName=FB, fontSize=10,
            textColor=GREEN_D, spaceAfter=3),
    }

S = estilos()

def capitulo_header(numero, titulo):
    t = Table([[Paragraph(f'{numero}. {titulo}'.upper(), S['capitulo'])]],
              colWidths=[175*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), GREEN_D),
        ('LEFTPADDING',   (0,0), (-1,-1), 10),
        ('TOPPADDING',    (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
    ]))
    return t

def info_box(texto, cor=INFO):
    t = Table([[Paragraph(texto, ParagraphStyle('ib', fontName=F, fontSize=9,
                textColor=WHITE, leading=13))]],
              colWidths=[175*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), cor),
        ('LEFTPADDING',   (0,0), (-1,-1), 10),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('ROUNDEDCORNERS', [4]),
    ]))
    return t

def tabela_info(dados, col1=55*mm, col2=120*mm):
    rows = []
    for k, v in dados:
        rows.append([
            Paragraph(k, ParagraphStyle('tk', fontName=FB, fontSize=9, textColor=MUTED)),
            Paragraph(v, ParagraphStyle('tv', fontName=F,  fontSize=9, textColor=DARK, leading=13)),
        ])
    t = Table(rows, colWidths=[col1, col2])
    t.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (0,-1), LIGHT),
        ('GRID',          (0,0), (-1,-1), 0.3, colors.HexColor('#e2e8f0')),
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING',   (0,0), (-1,-1), 6),
        ('TOPPADDING',    (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ]))
    return t

def li(texto): return Paragraph(f'  •  {texto}', S['lista'])
def p(texto):  return Paragraph(texto, S['corpo'])
def sp(n=4):   return Spacer(1, n*mm)
def hr():      return HRFlowable(width='100%', thickness=0.5, color=GREEN_L, spaceAfter=4)


# ══════════════════════════════════════════════════════════════
def gerar_manual():
    caminho = 'TECPOINT_Manual_App.pdf'
    doc = SimpleDocTemplate(caminho, pagesize=A4,
                            leftMargin=17*mm, rightMargin=17*mm,
                            topMargin=15*mm, bottomMargin=15*mm)
    el = []

    # ══ CAPA ══════════════════════════════════════════════════
    el += [sp(20)]
    capa = Table([[
        Paragraph('TECPOINT', S['capa_titulo']),
    ]], colWidths=[175*mm])
    capa.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), GREEN_D),
        ('LEFTPADDING',   (0,0), (-1,-1), 14),
        ('TOPPADDING',    (0,0), (-1,-1), 20),
        ('BOTTOMPADDING', (0,0), (-1,-1), 20),
    ]))
    el += [capa, sp(3)]

    capa2 = Table([[
        Paragraph('Gerenciador de Ordens de Servico', S['capa_sub']),
    ]], colWidths=[175*mm])
    capa2.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), GREEN),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
    ]))
    el += [capa2, sp(6)]

    el += [
        Paragraph('Manual do Usuario — Versao 1.0', S['capa_versao']),
        Paragraph('UniSENAI MT  |  2026', S['capa_versao']),
        sp(40),
        PageBreak(),
    ]

    # ══ INDICE ═════════════════════════════════════════════════
    el += [
        Paragraph('INDICE', ParagraphStyle('idx', fontName=FB, fontSize=16,
            textColor=GREEN_D, spaceBefore=4, spaceAfter=8)),
        hr(),
    ]
    indice = [
        ('1', 'Introducao ao TECPOINT'),
        ('2', 'Primeiro Acesso e Login'),
        ('3', 'Dashboard — Tela Principal'),
        ('4', 'Ordens de Servico (OS)'),
        ('5', 'Clientes'),
        ('6', 'Equipamentos'),
        ('7', 'Relatorios — PDF e Word'),
        ('8', 'Gerenciar Usuarios (Admin)'),
        ('9', 'Perfil e Sincronizacao'),
        ('10', 'Uso Offline — Sem Internet'),
        ('11', 'Perguntas Frequentes'),
    ]
    for num, titulo in indice:
        el.append(Paragraph(
            f'  {num}.  {titulo}',
            ParagraphStyle('idx2', fontName=F, fontSize=11, textColor=DARK,
                           spaceAfter=5, leading=16)
        ))
    el += [sp(4), PageBreak()]

    # ══ CAP 1 — INTRODUCAO ════════════════════════════════════
    el += [capitulo_header('1', 'Introducao ao TECPOINT'), sp(4)]
    el += [
        p('O TECPOINT e um aplicativo Android desenvolvido para gerenciar Ordens de Servico (OS) de tecnicos em campo. Com ele, voce pode criar, editar e acompanhar todas as ordens de servico mesmo sem conexao com a internet.'),
        sp(2),
        Paragraph('O que voce pode fazer com o TECPOINT:', S['secao']),
        li('Criar e gerenciar Ordens de Servico completas'),
        li('Cadastrar clientes e equipamentos'),
        li('Registrar defeitos, laudos e solucoes tecnicas'),
        li('Fazer checklist de testes com data e nome do tecnico'),
        li('Capturar localizacao GPS e preencher endereco via CEP'),
        li('Tirar fotos e anexar a OS'),
        li('Coletar assinaturas do cliente e do tecnico'),
        li('Gerar relatorios em PDF e Word'),
        li('Trabalhar completamente offline em campo'),
        sp(3),
        info_box('O app funciona 100% offline. Todos os dados sao salvos no dispositivo e sincronizados automaticamente quando voce conectar a internet.', GREEN),
        sp(4),
        tabela_info([
            ('Plataforma', 'Android (celular e tablet)'),
            ('Versao', '1.0 — 2026'),
            ('Desenvolvido por', 'UniSENAI MT'),
            ('Banco de dados', 'Supabase (nuvem) + SQLite (offline)'),
        ]),
        sp(4), PageBreak(),
    ]

    # ══ CAP 2 — LOGIN ══════════════════════════════════════════
    el += [capitulo_header('2', 'Primeiro Acesso e Login'), sp(4)]
    el += [
        Paragraph('Fazendo Login', S['secao']),
        p('Na tela inicial do app voce vera os campos de e-mail e senha. Digite as credenciais fornecidas pelo administrador e toque em Entrar.'),
        sp(2),
        tabela_info([
            ('E-mail',    'Digite o e-mail cadastrado pelo administrador'),
            ('Senha',     'Digite a senha (minimo 6 caracteres)'),
            ('Entrar',    'Toque no botao verde para acessar'),
        ]),
        sp(3),
        Paragraph('Login Offline', S['secao']),
        p('Apos fazer login pelo menos uma vez com internet, o app salva suas credenciais com seguranca no dispositivo. Nas proximas vezes voce pode logar mesmo sem internet.'),
        sp(2),
        info_box('IMPORTANTE: O primeiro login obrigatoriamente precisa de internet. Depois disso, voce pode logar offline quantas vezes quiser.', WARN),
        sp(3),
        Paragraph('Esqueci a senha', S['secao']),
        p('Se esqueceu sua senha, fale com o administrador do sistema para que ele crie um novo acesso para voce. O reset de senha so pode ser feito online pelo administrador.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 3 — DASHBOARD ═════════════════════════════════════
    el += [capitulo_header('3', 'Dashboard — Tela Principal'), sp(4)]
    el += [
        p('Apos o login voce ve o Dashboard — a tela principal do app. Ele mostra um resumo de todas as ordens de servico.'),
        sp(2),
        Paragraph('Cards de Estatisticas', S['secao']),
        tabela_info([
            ('Total',       'Numero total de OS cadastradas'),
            ('Abertas',     'OS aguardando atendimento'),
            ('Em Andamento','OS que estao sendo executadas'),
            ('Concluidas',  'OS finalizadas com sucesso'),
            ('Urgentes',    'OS com prioridade urgente'),
            ('Canceladas',  'OS canceladas'),
        ]),
        sp(3),
        Paragraph('Navegacao inferior', S['secao']),
        p('Na parte de baixo da tela ha 5 abas de navegacao:'),
        li('Casa — Dashboard com estatisticas'),
        li('Lista — Todas as Ordens de Servico'),
        li('Clientes — Gerenciar clientes'),
        li('Equipamentos — Gerenciar equipamentos'),
        li('Perfil — Configuracoes e sincronizacao'),
        sp(3),
        Paragraph('Menu lateral (Drawer)', S['secao']),
        p('Deslize da esquerda para a direita ou toque no icone de menu para abrir o menu lateral. Nele voce acessa Relatorios, Usuarios (admin) e pode fazer logout.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 4 — OS ════════════════════════════════════════════
    el += [capitulo_header('4', 'Ordens de Servico (OS)'), sp(4)]
    el += [
        Paragraph('Lista de OS', S['secao']),
        p('Na aba Lista voce ve todas as OS ordenadas por data. Use a barra de busca para filtrar por numero da OS, cliente ou defeito. Puxe a lista para baixo para atualizar.'),
        sp(2),
        Paragraph('Card da OS', S['secao']),
        p('Cada card mostra as informacoes principais da OS:'),
        li('Numero da OS (ex: OS-20260517-0001)'),
        li('Badges de Status e Prioridade no canto direito'),
        li('Nome do cliente'),
        li('Descricao do defeito'),
        li('Badge verde com o nome do tecnico responsavel'),
        li('Data de entrada e tipo de ocorrencia'),
        sp(3),
        Paragraph('Criar Nova OS', S['secao']),
        p('Toque no botao verde "Nova OS" no canto inferior direito. O formulario e dividido em secoes numeradas:'),
        sp(2),
        tabela_info([
            ('1. Identificacao',   'Cliente, status, prioridade, tipo, datas, tecnico, acompanhante'),
            ('2. Acessorios',      'Selecione os acessorios recebidos com o equipamento'),
            ('3. Equipamentos',    'Vincule os equipamentos do cliente a esta OS'),
            ('4. Condicao',        'Condicoes fisicas, defeito relatado, status do equipamento'),
            ('5. Checklist',       'Lista de testes tecnicos com data e nome do verificador'),
            ('6. Laudo',           'Laudo tecnico, solucao aplicada, pecas utilizadas, termos'),
            ('7. Localizacao GPS', 'CEP auto-preenche os campos. Botao GPS captura coordenadas'),
            ('8. Fotos',           'Adicione fotos da camera ou galeria. Toque na area vazia para adicionar'),
            ('9. Assinaturas',     'Assinatura do cliente e do tecnico em tela cheia (paisagem)'),
        ]),
        sp(3),
        Paragraph('Campos de Status', S['secao']),
        tabela_info([
            ('Aberto',       'OS registrada, aguardando inicio do atendimento'),
            ('Em Andamento', 'Tecnico ja esta trabalhando na OS'),
            ('Concluido',    'Servico finalizado com sucesso'),
            ('Cancelado',    'OS cancelada por qualquer motivo'),
        ]),
        sp(3),
        Paragraph('Prioridade', S['secao']),
        tabela_info([
            ('Baixa',   'Atendimento normal, sem urgencia'),
            ('Media',   'Atendimento prioritario'),
            ('Urgente', 'Atendimento imediato necessario'),
        ]),
        sp(3),
        Paragraph('Localizacao GPS', S['secao']),
        p('Na secao 7 do formulario voce tem duas opcoes para preencher o endereco:'),
        li('CEP: Digite o CEP e o app preenche automaticamente Logradouro, Bairro, Cidade e UF via ViaCEP'),
        li('Botao GPS: Toque em "GPS" para capturar as coordenadas geograficas exatas da localizacao atual'),
        li('Voce tambem pode preencher os campos manualmente'),
        sp(3),
        Paragraph('Fotos', S['secao']),
        p('Na secao de fotos voce pode:'),
        li('Tocar na area vazia para adicionar a primeira foto'),
        li('Tirar foto diretamente pela camera'),
        li('Escolher da galeria do dispositivo'),
        li('Remover foto tocando no X vermelho sobre ela'),
        p('Fotos tiradas offline ficam salvas localmente e sao enviadas automaticamente quando voce conectar a internet.'),
        sp(3),
        Paragraph('Assinaturas', S['secao']),
        p('Toque em "Tela cheia" ou diretamente no campo de assinatura. O app gira automaticamente para paisagem (horizontal) para dar mais espaco para assinar. Toque em Confirmar para salvar ou Cancelar para descartar.'),
        sp(2),
        info_box('Dica: Peca para o cliente e para o tecnico assinarem antes de salvar a OS. As assinaturas aparecem no PDF gerado.', GREEN),
        sp(3),
        Paragraph('Editar OS', S['secao']),
        p('Na tela de detalhe da OS toque no menu (tres pontos) no canto superior direito e selecione Editar. Todas as informacoes podem ser alteradas.'),
        sp(3),
        Paragraph('Desativar OS', S['secao']),
        p('Para remover uma OS da lista, acesse o menu da OS e toque em Desativar. A OS nao e deletada permanentemente — ela apenas nao aparece mais na listagem.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 5 — CLIENTES ══════════════════════════════════════
    el += [capitulo_header('5', 'Clientes'), sp(4)]
    el += [
        p('Na aba Clientes voce gerencia todos os clientes cadastrados. Use a barra de busca para filtrar por nome, telefone ou e-mail.'),
        sp(2),
        Paragraph('Cadastrar Cliente', S['secao']),
        p('Toque no botao "+" para abrir o formulario de novo cliente. Preencha os dados:'),
        tabela_info([
            ('Nome *',             'Nome completo ou razao social (obrigatorio)'),
            ('Telefone',           'Numero de contato com DDD'),
            ('E-mail',             'Endereco de e-mail do cliente'),
            ('CEP',                'Digite o CEP para auto-preencher o endereco'),
            ('Logradouro',         'Rua, avenida ou localidade'),
            ('Numero/Complemento', 'Numero do imovel, apartamento, sala, etc.'),
            ('Bairro',             'Bairro ou distrito'),
            ('Cidade',             'Cidade do cliente'),
            ('UF',                 'Estado (ex: MT, SP, RJ)'),
        ]),
        sp(3),
        p('Ao digitar o CEP completo (8 digitos), o app busca automaticamente o logradouro, bairro, cidade e UF. Voce so precisa preencher o numero/complemento manualmente.'),
        sp(3),
        Paragraph('Editar Cliente', S['secao']),
        p('Toque no card do cliente na lista para abrir o formulario de edicao. Todas as informacoes podem ser alteradas.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 6 — EQUIPAMENTOS ══════════════════════════════════
    el += [capitulo_header('6', 'Equipamentos'), sp(4)]
    el += [
        p('Os equipamentos sao vinculados a um cliente especifico. Cada OS pode ter um ou mais equipamentos associados.'),
        sp(2),
        Paragraph('Cadastrar Equipamento', S['secao']),
        tabela_info([
            ('Tipo',             'Categoria do equipamento (ex: Radiotransmissor, Notebook)'),
            ('Marca',            'Fabricante do equipamento'),
            ('Modelo',           'Modelo especifico'),
            ('Numero de Serie *', 'Numero de serie unico — obrigatorio'),
            ('Cliente *',        'Cliente proprietario do equipamento — obrigatorio'),
            ('Cor/Identificacao','Cor ou marcacao visual para identificacao em campo'),
            ('Canal/Frequencia', 'Canal ou frequencia de operacao (para radios)'),
        ]),
        sp(3),
        Paragraph('Vincular a uma OS', S['secao']),
        p('Ao criar ou editar uma OS, selecione o cliente primeiro. O app carrega automaticamente todos os equipamentos daquele cliente. Marque os equipamentos relacionados ao servico.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 7 — RELATORIOS ════════════════════════════════════
    el += [capitulo_header('7', 'Relatorios — PDF e Word'), sp(4)]
    el += [
        p('Na tela de Relatorios voce pode gerar documentos profissionais de qualquer OS. Acesse pelo menu lateral.'),
        sp(2),
        Paragraph('Gerar PDF', S['secao']),
        p('Toque no botao vermelho "PDF" ao lado da OS desejada. O app gera o documento e abre a opcao de compartilhar por WhatsApp, e-mail, Drive, etc.'),
        sp(2),
        p('O PDF contem:'),
        li('Cabecalho com numero da OS'),
        li('Faixa de status, prioridade e tipo de ocorrencia'),
        li('Identificacao completa com datas e tecnico responsavel'),
        li('Cliente e atendimento'),
        li('Acessorios recebidos'),
        li('Laudo tecnico e solucao aplicada'),
        li('Checklist de testes com Sim/Nao, data e tecnico verificador'),
        li('Localizacao GPS com coordenadas e endereco'),
        li('Assinaturas do cliente e do tecnico'),
        li('Rodape com data e hora de geracao'),
        sp(3),
        Paragraph('Gerar Word (.docx)', S['secao']),
        p('Toque no botao azul "Word (.docx)" para gerar o documento editavel. Ideal quando o cliente precisa de um documento que possa ser modificado posteriormente.'),
        sp(2),
        info_box('Dica: O PDF e o formato recomendado para envio ao cliente. O Word e util quando o documento precisa ser editado ou impresso com formatacao personalizada.', INFO),
        sp(3),
        Paragraph('Gerar direto da OS', S['secao']),
        p('Voce tambem pode gerar PDF/Word diretamente da tela de detalhe de uma OS. Toque no icone de PDF na barra superior, ou no menu (tres pontos) para exportar em Word.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 8 — USUARIOS ══════════════════════════════════════
    el += [capitulo_header('8', 'Gerenciar Usuarios (Admin)'), sp(4)]
    el += [
        info_box('Esta secao e visivel apenas para usuarios com perfil Administrador.', WARN),
        sp(3),
        p('Acesse pelo menu lateral > Usuarios. Voce ve todos os usuarios cadastrados com suas estatisticas.'),
        sp(2),
        Paragraph('Perfis de usuario', S['secao']),
        tabela_info([
            ('Tecnico',        'Acessa OS, clientes e equipamentos. Nao pode gerenciar usuarios.'),
            ('Supervisor',     'Mesmos acessos do tecnico com permissoes expandidas.'),
            ('Administrador',  'Acesso total — gerencia usuarios, pode criar e desativar contas.'),
        ]),
        sp(3),
        Paragraph('Criar Novo Usuario', S['secao']),
        p('Toque no botao verde "Novo Usuario". Preencha:'),
        li('Nome completo do usuario'),
        li('E-mail (sera usado para login)'),
        li('Senha (minimo 6 caracteres)'),
        li('Perfil (Tecnico, Supervisor ou Administrador)'),
        li('Especialidade (opcional — ex: Telecomunicacoes, TI)'),
        sp(2),
        info_box('OBRIGATORIO: Criar usuario exige conexao com internet. Conecte-se ao Wi-Fi ou internet antes de cadastrar novos usuarios.', DANGER),
        sp(3),
        Paragraph('Editar Usuario', S['secao']),
        p('Toque no icone de lapis no card do usuario. Voce pode alterar nome, perfil e especialidade. Edicao funciona offline e sincroniza quando voltar a internet.'),
        sp(3),
        Paragraph('Ativar e Desativar Usuario', S['secao']),
        p('Use o switch (botao deslizante) no card do usuario para ativar ou desativar. Usuarios desativados nao conseguem fazer login.'),
        sp(2),
        info_box('OBRIGATORIO: Ativar e desativar usuarios exige conexao com internet.', DANGER),
        sp(3),
        Paragraph('Fluxo recomendado para novos tecnicos', S['secao']),
        tabela_info([
            ('Passo 1', 'Admin cria o usuario com internet (no escritorio)'),
            ('Passo 2', 'Tecnico instala o app no seu dispositivo'),
            ('Passo 3', 'Tecnico faz o primeiro login com internet'),
            ('Passo 4', 'A partir dai, o tecnico pode usar o app offline em campo'),
        ]),
        sp(4), PageBreak(),
    ]

    # ══ CAP 9 — PERFIL ════════════════════════════════════════
    el += [capitulo_header('9', 'Perfil e Sincronizacao'), sp(4)]
    el += [
        p('Acesse a aba Perfil (ultima aba na navegacao inferior) para ver suas informacoes e gerenciar a sincronizacao.'),
        sp(2),
        Paragraph('Suas Informacoes', S['secao']),
        p('O perfil mostra seu nome, e-mail e tipo de perfil (tecnico/admin). Essas informacoes sao carregadas automaticamente do servidor ou do cache local offline.'),
        sp(3),
        Paragraph('Sincronizacao Manual', S['secao']),
        p('Toque no botao "Sincronizar Agora" para enviar manualmente todas as alteracoes feitas offline para o servidor. O app tambem sincroniza automaticamente sempre que detecta conexao com internet.'),
        sp(2),
        tabela_info([
            ('Automatica', 'O app sincroniza sozinho ao detectar internet'),
            ('Manual',     'Toque em Sincronizar Agora para forcar a sincronizacao'),
            ('Fotos',      'Fotos tiradas offline sao enviadas na sincronizacao'),
            ('OS offline', 'OS criadas/editadas offline sao sincronizadas automaticamente'),
        ]),
        sp(3),
        Paragraph('Sair do Aplicativo (Logout)', S['secao']),
        p('Toque em "Sair" e confirme no dialogo. Ao sair, as credenciais offline sao removidas do dispositivo. O proximo acesso vai precisar de internet para reautenticar.'),
        sp(2),
        info_box('Dica: Nao faca logout antes de ir para campo sem internet. Faca logout somente quando estiver conectado.', WARN),
        sp(4), PageBreak(),
    ]

    # ══ CAP 10 — OFFLINE ══════════════════════════════════════
    el += [capitulo_header('10', 'Uso Offline — Sem Internet'), sp(4)]
    el += [
        info_box('O TECPOINT foi desenvolvido para funcionar 100% em campo, mesmo sem internet. Todos os dados sao carregados instantaneamente do armazenamento local do dispositivo.', GREEN),
        sp(3),
        Paragraph('O que funciona offline', S['secao']),
        tabela_info([
            ('Login',                  'Funciona offline apos o primeiro login online'),
            ('Ver lista de OS',        'Carregamento instantaneo do banco local'),
            ('Criar OS',               'Salva localmente e sincroniza quando conectar'),
            ('Editar OS',              'Salva localmente e sincroniza quando conectar'),
            ('Ver detalhes da OS',     'Carregamento instantaneo'),
            ('Checklist de testes',    'Funciona completamente offline'),
            ('Assinaturas',            'Captura e salva localmente'),
            ('Fotos',                  'Tirar e salvar localmente (envia depois)'),
            ('GPS/Localizacao',        'Funciona offline (usa o GPS do dispositivo)'),
            ('CEP (busca endereco)',   'Nao funciona offline (precisa de internet)'),
            ('Gerar PDF',              'Funciona offline com os dados locais'),
            ('Gerar Word',             'Funciona offline com os dados locais'),
            ('Ver clientes',           'Carregamento instantaneo do banco local'),
            ('Ver equipamentos',       'Carregamento instantaneo do banco local'),
            ('Ver notificacoes',       'Mostra as ultimas 50 do cache local'),
            ('Editar perfil usuario',  'Salva localmente e sincroniza depois'),
        ]),
        sp(3),
        Paragraph('O que NAO funciona offline', S['secao']),
        tabela_info([
            ('Criar usuario',          'Exige internet — Supabase Auth e servidor'),
            ('Ativar/desativar usuario','Exige internet'),
            ('CEP auto-preencher',     'Exige internet — API ViaCEP'),
            ('Upload de fotos',        'Fotos ficam salvas localmente ate reconectar'),
        ]),
        sp(3),
        Paragraph('Sincronizacao automatica', S['secao']),
        p('Quando o dispositivo reconecta a internet, o app detecta automaticamente e envia todas as alteracoes pendentes para o servidor. Voce ve um indicador de sincronizacao na tela.'),
        sp(2),
        Paragraph('Banner de modo offline', S['secao']),
        p('Quando o app detecta que esta sem internet, aparece uma faixa laranja na parte superior da tela indicando "Modo Offline". Isso e apenas informativo — voce pode continuar usando normalmente.'),
        sp(4), PageBreak(),
    ]

    # ══ CAP 11 — FAQ ══════════════════════════════════════════
    el += [capitulo_header('11', 'Perguntas Frequentes'), sp(4)]

    faqs = [
        ('Por que o app demora para abrir as telas sem internet?',
         'O app e offline-first: todos os dados carregam instantaneamente do banco local. Se houver demora, verifique se ja sincronizou ao menos uma vez com internet para ter os dados no dispositivo.'),
        ('Posso usar o app em varios dispositivos ao mesmo tempo?',
         'Sim! O app pode ser instalado em quantos dispositivos quiser. Cada um usa suas proprias credenciais. Todos os dados sao sincronizados pelo servidor Supabase.'),
        ('O que acontece se eu criar uma OS offline e outro tecnico tambem criar uma OS parecida?',
         'Cada OS tem um numero unico gerado automaticamente. Nao ha conflito. Quando ambos sincronizarem, as duas OS aparecerao normalmente na lista.'),
        ('Como eu sei se minhas alteracoes offline foram sincronizadas?',
         'Acesse a aba Perfil e toque em "Sincronizar Agora". Se nao houver erros, tudo foi enviado. OS e fotos pendentes sao sincronizadas automaticamente.'),
        ('As fotos offline ficam salvas no dispositivo?',
         'Sim. Fotos sao copiadas para uma pasta permanente do app e so sao removidas do dispositivo apos o upload bem-sucedido para o servidor.'),
        ('Posso gerar PDF sem internet?',
         'Sim! O PDF e gerado localmente com os dados armazenados no dispositivo. Funciona perfeitamente offline.'),
        ('O que fazer se a assinatura nao aparecer no PDF?',
         'Certifique-se de ter tocado em "Confirmar" na tela de assinatura (nao apenas desenhou). Voce vera um badge verde "Assinado" no campo apos confirmar.'),
        ('Como redefinir a senha de um tecnico?',
         'Somente o administrador pode redefinir senhas, e apenas com internet, pelo menu de Usuarios. O tecnico precisara estar conectado para fazer login com a nova senha.'),
        ('O app funciona em tablets?',
         'Sim! O app e otimizado para tablets Android. A tela de assinatura automaticamente gira para paisagem para facilitar a assinatura.'),
        ('Esqueci de fazer logout e outro tecnico quer usar o mesmo tablet',
         'Faca logout na aba Perfil > Sair. O outro tecnico podera logar com suas proprias credenciais. Lembre-se: o logout remove as credenciais offline, entao o novo login precisara de internet.'),
    ]

    for pergunta, resposta in faqs:
        el.append(Paragraph(f'P: {pergunta}', S['destaque']))
        el.append(Paragraph(f'R: {resposta}', S['corpo']))
        el.append(hr())
        el.append(sp(1))

    el += [sp(8)]

    # ══ RODAPE FINAL ══════════════════════════════════════════
    rodape_final = Table([[
        Paragraph('TECPOINT  |  Gerenciador de Ordens de Servico  |  UniSENAI MT  |  2026',
                  S['rodape']),
    ]], colWidths=[175*mm])
    rodape_final.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), GREEN_D),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    el.append(rodape_final)

    doc.build(el)
    print(f'Manual gerado com sucesso: {caminho}')
    return caminho


if __name__ == '__main__':
    gerar_manual()
