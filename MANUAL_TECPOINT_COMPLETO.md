# 📱 TECPOINT
## Manual Completo do Aplicativo
### Gerenciador de Ordens de Serviço para Campo

---

> **Versão:** 1.0.0  
> **Plataforma:** Android 6.0 ou superior  
> **Instituição:** UniSENAI MT — 2026  
> **Público:** Técnicos, Supervisores e Administradores

---

## 📋 ÍNDICE GERAL

| # | Seção | Página |
|---|---|---|
| 1 | [Introdução e Visão Geral](#1--introdução-e-visão-geral) | — |
| 2 | [Instalação do Aplicativo](#2--instalação-do-aplicativo) | — |
| 3 | [Login com Internet — Passo a Passo](#3--login-com-internet--passo-a-passo) | — |
| 4 | [Login Offline — Passo a Passo](#4--login-offline--passo-a-passo) | — |
| 5 | [Múltiplas Contas no Mesmo Celular](#5--múltiplas-contas-no-mesmo-celular) | — |
| 6 | [Dashboard — Tela Principal](#6--dashboard--tela-principal) | — |
| 7 | [Ordens de Serviço (OS)](#7--ordens-de-serviço-os) | — |
| 8 | [Clientes](#8--clientes) | — |
| 9 | [Equipamentos](#9--equipamentos) | — |
| 10 | [Usuários — Criação e Gestão](#10--usuários--criação-e-gestão) | — |
| 11 | [Notificações](#11--notificações) | — |
| 12 | [Relatórios — PDF e Word](#12--relatórios--pdf-e-word) | — |
| 13 | [Perfil e Conta](#13--perfil-e-conta) | — |
| 14 | [Sincronização Automática](#14--sincronização-automática) | — |
| 15 | [Permissões do Sistema](#15--permissões-do-sistema) | — |
| 16 | [Perfis de Acesso](#16--perfis-de-acesso) | — |
| 17 | [Cenários Reais de Uso](#17--cenários-reais-de-uso) | — |
| 18 | [Perguntas Frequentes — FAQ](#18--perguntas-frequentes--faq) | — |
| 19 | [Solução de Problemas](#19--solução-de-problemas) | — |
| 20 | [Referência Técnica](#20--referência-técnica) | — |

---

## 1 · Introdução e Visão Geral

O **TECPOINT** é um aplicativo Android desenvolvido para equipes de assistência técnica que atuam em campo. Ele permite registrar, acompanhar e fechar **Ordens de Serviço** diretamente pelo celular ou tablet, com ou sem conexão à internet.

### 🎯 Para quem é este aplicativo?

| Perfil | Uso principal |
|---|---|
| **Técnico** | Registra atendimentos, preenche laudos, coleta assinaturas e fotos em campo |
| **Supervisor** | Acompanha todas as OS da equipe, analisa status e gera relatórios |
| **Administrador** | Gerencia toda a operação, incluindo criação de usuários e configurações |

### 🌟 Principais recursos

- **Trabalha offline** — sem internet, o app continua funcionando normalmente
- **Sincronização automática** — quando a internet volta, tudo é enviado ao servidor
- **PDF e Word profissional** — relatório completo com assinaturas, checklist e fotos
- **GPS integrado** — registra a localização exata do atendimento
- **Assinatura digital** — cliente e técnico assinam diretamente na tela
- **Múltiplas contas** — até 10 usuários diferentes no mesmo celular

### 🔄 Como o app funciona resumidamente

```
┌─────────────────────────────────────────────────────────┐
│                    COM INTERNET                          │
│  App ──► Servidor (Supabase) ──► Salva em nuvem         │
│          Também salva cópia local (SQLite)               │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    SEM INTERNET                          │
│  App ──► Banco local (SQLite) ──► Salva no celular       │
│          Quando voltar: envia tudo ao servidor           │
└─────────────────────────────────────────────────────────┘
```

---

## 2 · Instalação do Aplicativo

### Requisitos mínimos

| Item | Requisito |
|---|---|
| Sistema Android | 6.0 (Marshmallow) ou superior |
| Processador | Qualquer ARM ou x86 moderno |
| Memória RAM | 2 GB ou mais (recomendado) |
| Armazenamento | 200 MB livres |
| Internet | Necessária apenas para primeiro login e sincronização |

### Passo a passo de instalação

**Passo 1** — Transfira o arquivo `app-release.apk` para o celular via:
- Cabo USB
- WhatsApp ou e-mail
- Google Drive / pendrive

**Passo 2** — No celular, abra o gerenciador de arquivos e localize o arquivo `.apk`

**Passo 3** — Se aparecer a mensagem _"Instalar de fontes desconhecidas não permitido"_:
1. Toque em **Configurações**
2. Ative **"Permitir desta fonte"** ou **"Fontes desconhecidas"**
3. Volte e toque em **Instalar**

**Passo 4** — Aguarde a instalação e toque em **Abrir**

**Passo 5** — O app exibe a **tela de splash** (logo TECPOINT) por ~2,6 segundos

> ⚠️ **Importante:** O primeiro login obrigatoriamente precisa de internet. Após esse primeiro acesso, o celular fica habilitado para funcionar sem conexão.

---

## 3 · Login com Internet — Passo a Passo

### Quando usar este tipo de login?

Use o login **com internet** quando:
- É a **primeira vez** que você abre o app
- Você quer garantir que seus dados estão atualizados
- O administrador resetou sua senha e você precisa usar a nova
- Você está em um celular **novo** onde nunca logou antes

### Como fazer o login online

**Tela de login — o que você vê:**

```
┌──────────────────────────────────┐
│           [LOGO TECPOINT]        │
│              TECPOINT            │
│   Gerenciador de Ordens de       │
│           Serviço                │
│                                  │
│  Bem-vindo de volta              │
│  Entre com suas credenciais      │
│                                  │
│  E-MAIL                          │
│  [ seu@email.com              ]  │
│                                  │
│  SENHA                           │
│  [ ••••••••               👁  ]  │
│                                  │
│       [ ENTRAR ]                 │
└──────────────────────────────────┘
```

**Passo 1** — Digite seu **e-mail** cadastrado

**Passo 2** — Digite sua **senha**
- Toque no ícone 👁 para mostrar/ocultar a senha

**Passo 3** — Toque em **ENTRAR**

**Passo 4** — Aguarde (ícone de carregamento aparece)

**Passo 5** — App vai direto para o **Dashboard**

### O que acontece em segundo plano quando você loga com internet?

Ao fazer login com sucesso, o app automaticamente:

1. Autentica no servidor (Supabase)
2. **Salva suas credenciais offline** no celular (hash da senha, criptografado)
3. Baixa seu nome e perfil do banco de dados
4. Habilita seu acesso offline futuro neste dispositivo

> ✅ Após o primeiro login online, você **já pode usar o app offline** neste celular sempre que precisar.

### Exemplos de erros e como resolver

**Erro:** _"E-mail ou senha inválidos"_
```
Causa:   Você digitou o e-mail ou senha incorretos
Solução: Verifique cuidadosamente os dados digitados
         Se esqueceu a senha, peça ao administrador para resetá-la
```

**Erro:** _"E-mail ainda não confirmado. Contate o administrador."_
```
Causa:   Conta criada pelo admin mas com algum problema de ativação
Solução: Contate o administrador do sistema
```

**Erro:** _"Falha ao fazer login. Verifique suas credenciais."_
```
Causa:   Problema de conexão ou servidor temporariamente indisponível
Solução: Verifique se está conectado à internet
         Aguarde alguns minutos e tente novamente
```

---

## 4 · Login Offline — Passo a Passo

### Quando o login offline está disponível?

O login offline **só funciona se** você já tiver feito pelo menos **um login com internet** neste celular com esta conta.

### Como o app detecta que está sem internet?

Automaticamente. Quando você abre a tela de login sem conexão:
- Aparece o **banner laranja** no topo
- O subtítulo muda para **"Modo offline"**
- O botão muda para **"ENTRAR (MODO OFFLINE)"**

```
┌──────────────────────────────────┐
│ 📶 Sem conexão — dados salvos   │  ← banner laranja
│      localmente                  │
├──────────────────────────────────┤
│           [LOGO TECPOINT]        │
│                                  │
│  Bem-vindo de volta              │
│  🟠 Modo offline · seu@email.com │  ← indicador offline
│                                  │
│  ┌─────────────────────────────┐ │
│  │ 📶 Modo offline disponível  │ │  ← aviso laranja
│  └─────────────────────────────┘ │
│                                  │
│  E-MAIL                          │
│  [ seu@email.com              ]  │
│                                  │
│  SENHA                           │
│  [ ••••••••               👁  ]  │
│                                  │
│  [ ENTRAR (MODO OFFLINE) ]       │  ← botão offline
└──────────────────────────────────┘
```

### Como fazer o login offline

**Passo 1** — A tela de login já mostra que está offline (banner laranja)

**Passo 2** — O campo de e-mail pode estar **pré-preenchido** com o último usuário que logou. Se for você, não precisa digitar novamente.

**Passo 3** — Digite sua **senha**

**Passo 4** — Toque em **ENTRAR (MODO OFFLINE)**

**Passo 5** — Se a senha estiver correta, o app exibe uma mensagem laranja:

> _"Entrou em modo offline. Dados serão sincronizados ao conectar."_

**Passo 6** — App vai para o **Dashboard** normalmente

### O que funciona no modo offline?

| Funcionalidade | Offline |
|---|---|
| Ver lista de OS | ✅ Instantâneo do cache local |
| Criar nova OS | ✅ Salva localmente, sincroniza depois |
| Editar OS existente | ✅ Salva localmente, sincroniza depois |
| Ver detalhes da OS | ✅ |
| Ver clientes | ✅ |
| Criar/editar cliente | ✅ Sincroniza depois |
| Ver equipamentos | ✅ |
| Tirar e salvar fotos | ✅ Sobe quando conectar |
| Coletar assinatura | ✅ Sincroniza depois |
| Gerar PDF | ✅ |
| Ver notificações | ✅ (cache das últimas 50) |
| Criar usuário | ❌ Requer internet |
| Gerenciar usuários | ❌ Requer internet |

### O que acontece quando a internet volta enquanto o app está aberto?

1. O banner laranja **desaparece** automaticamente
2. O `SyncService` detecta a reconexão em segundos
3. Todos os dados criados offline são **enviados automaticamente** ao servidor
4. O usuário **não é redirecionado para o login** — permanece onde estava
5. Fotos e assinaturas pendentes sobem em background

> ✅ O app **nunca expulsa o usuário** quando a internet volta. Ele apenas sincroniza em segundo plano, de forma silenciosa.

### Cenário real — Técnico em campo sem sinal

**Situação:** João é técnico e vai atender um cliente em área rural sem sinal de celular.

```
08:00 — João sai do escritório com sinal Wi-Fi
         → Login online realizado normalmente
         → App sincronizado, todos os dados baixados

09:30 — João chega no cliente (sem sinal)
         → Banner laranja aparece: "Sem conexão"
         → App continua funcionando normalmente

09:35 — João abre a OS do cliente no celular
         → Dados carregam do cache local (instantâneo)

10:00 — João preenche o laudo técnico
         → Dados salvos localmente

10:30 — João coleta assinatura do cliente
         → Salva localmente, marcada como "pendente"

10:45 — João tira 3 fotos do equipamento
         → Salvas localmente com ícone 🔄

11:00 — João finaliza e muda status para "Concluído"
         → Salvo localmente

12:00 — João volta para a cidade (sinal restaurado)
         → App detecta internet automaticamente
         → Tudo sincronizado: laudo, assinatura, fotos, status
         → Servidor atualizado sem João precisar fazer nada
```

---

## 5 · Múltiplas Contas no Mesmo Celular

### O que é este recurso?

Permite que **diferentes usuários** façam login offline no mesmo celular. Muito útil quando um técnico pega emprestado o celular do colega ou quando há revezamento de equipamentos.

### Limite

O app armazena até **10 contas diferentes** por dispositivo. Se a décima primeira conta logar online, a conta mais antiga (por tempo de acesso) é removida do armazenamento offline.

### Como configurar múltiplas contas

**Cada usuário precisa fazer login online pelo menos uma vez no dispositivo.**

Exemplo com dois usuários: Bruno (admin) e João (técnico).

```
CONFIGURAÇÃO:
─────────────────────────────────────────────
Passo 1: Bruno loga COM INTERNET no celular
         → Credenciais do Bruno salvas offline
         → Bruno usa o app normalmente

Passo 2: Bruno toca em "Sair" (Perfil → Sair)
         → Bruno deslogado

Passo 3: João loga COM INTERNET no mesmo celular
         → Credenciais do João salvas offline
         → João usa o app normalmente

Passo 4: João toca em "Sair"
         → João deslogado

AGORA FUNCIONA OFFLINE:
─────────────────────────────────────────────
Situação: Celular sem internet

Bruno quer logar:
 → Digita e-mail do Bruno + senha do Bruno
 → Login offline OK → entra como Bruno
 → Vê perfil, OS e dados de Bruno

João quer logar (no mesmo celular):
 → Digita e-mail do João + senha do João
 → Login offline OK → entra como João
 → Vê perfil, OS e dados de João
```

### Por que os perfis aparecem corretos?

Quando João loga offline, o app:
1. Identifica o e-mail digitado no mapa de contas
2. Verifica o hash da senha (nunca armazena a senha em texto)
3. Recupera o nome e perfil salvos para aquele e-mail
4. Atualiza o menu lateral e o avatar com os dados do João

### Erros comuns com múltiplas contas

**Erro:** _"Conta não registrada offline neste dispositivo. Faça login com internet ao menos uma vez."_
```
Causa:   Este usuário nunca logou com internet neste celular
Solução: Conecte à internet e faça o login uma vez
         Após isso, o login offline estará disponível
```

**Erro:** _"Senha incorreta para acesso offline."_
```
Causa:   A senha digitada não corresponde à que foi salva offline
         (pode ter sido alterada depois do último login online)
Solução: Faça login com internet para atualizar as credenciais
```

---

## 6 · Dashboard — Tela Principal

### O que é o Dashboard?

É a primeira tela após o login. Apresenta um resumo geral do sistema e atalhos para todas as funcionalidades.

### Estrutura da tela

```
┌─────────────────────────────────────────────┐
│ ☰  Dashboard                        [+ OS]  │  ← AppBar
├─────────────────────────────────────────────┤
│ 📶 Sem conexão — dados salvos localmente    │  ← banner offline
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │  Olá,                               │    │
│  │  Bruno Ruthes              [📡]     │    │  ← saudação
│  │  [ADMINISTRADOR]                    │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  RESUMO DE OS                               │
│  ┌─────────┐  ┌─────────┐                  │
│  │Total: 8 │  │Abertas:3│                  │  ← cards stats
│  └─────────┘  └─────────┘                  │
│  ┌─────────┐  ┌─────────┐                  │
│  │Andamento│  │Concluíd.│                  │
│  │    2    │  │    3    │                  │
│  └─────────┘  └─────────┘                  │
│                                             │
│  [ + Nova Ordem de Serviço ]                │  ← botão principal
│                                             │
│  ACESSO RÁPIDO                              │
│  [OS] [Clientes] [Equip.] [Notif.] [PDF]   │  ← atalhos
└─────────────────────────────────────────────┘
│  Home  │  OS  │  Clientes  │  Equip.  │  Perfil  │  ← bottom nav
```

### Cards de estatísticas

| Card | O que conta | Cor |
|---|---|---|
| **Total** | Todas as OS ativas no sistema | Verde claro |
| **Abertas** | OS com status "Aberto" | Ciano |
| **Andamento** | OS com status "Em Andamento" | Âmbar |
| **Concluídas** | OS com status "Concluído" | Verde |
| **Canceladas** | OS com status "Cancelado" | Vermelho |
| **Urgentes** | OS com prioridade "Urgente" | Laranja |

> 📱 **Tablet:** exibe 3 colunas. **Celular:** exibe 2 colunas. Altura fixa — nunca ficam desproporcionais.

### Menu lateral (☰)

Aberto pelo ícone ☰ no canto superior esquerdo. Contém:

```
┌───────────────────────────────┐
│  [B]  Bruno Ruthes            │  ← avatar + nome
│       [ADMINISTRADOR]         │  ← badge de perfil
├───────────────────────────────┤
│  Dashboard                    │
│  Ordens de Serviço            │
│  Clientes                     │
│  Equipamentos                 │
├───────────────────────────────┤
│  + Nova OS                    │
│  🔔 Notificações              │
│  👥 Usuários (somente Admin)  │
├───────────────────────────────┤
│  👤 Perfil                    │
└───────────────────────────────┘
│  TECPOINT · v1.0.0            │
```

---

## 7 · Ordens de Serviço (OS)

### 7.1 Lista de OS

Acesse por: **Bottom Nav → OS** ou **Menu lateral → Ordens de Serviço**.

#### O que cada card mostra

```
┌──────────────────────────────────────────┐
│ OS-2026001          [Aberto] [Urgente]   │  ← número + badges
│ 🏢 Empresa XYZ Ltda                      │  ← cliente
│ ⚠️ Equipamento não liga após queda       │  ← defeito
│ 🔧 Técnico: João Silva                   │  ← técnico
│ 📅 15/05/2026  🔧 Corretiva             │  ← data + tipo
└──────────────────────────────────────────┘
```

#### Filtros disponíveis

Toque no ícone **⋮ (filtros)** no canto superior direito:

| Filtro | Opções |
|---|---|
| **Status** | Todos / Aberto / Em Andamento / Concluído / Cancelado |
| **Prioridade** | Todas / Baixa / Média / Urgente |

Chips de filtro ativo aparecem abaixo da barra de busca. Toque no **✕** do chip para remover.

#### Busca por texto

Busca por:
- Número da OS (ex: `OS-2026001`)
- Nome do cliente
- Defeito relatado

#### Atualizar a lista

Puxe a lista para baixo (**pull-to-refresh**) para recarregar.

---

### 7.2 Criar Nova OS

Acesse por: **Botão "+" no dashboard**, **Botão flutuante "Nova OS"** na lista, ou **Menu lateral → + Nova OS**.

O formulário é dividido em **9 seções** numeradas:

---

#### Seção 1 — Identificação do Chamado

**Cliente** *(obrigatório)*
- Dropdown com todos os clientes cadastrados
- Após selecionar, os equipamentos desse cliente aparecem na Seção 3

**Status** *(padrão: Aberto)*

| Opção | Quando usar |
|---|---|
| **Aberto** | OS recebida, ainda não iniciada |
| **Em Andamento** | Técnico já está trabalhando |
| **Concluído** | Serviço finalizado |
| **Cancelado** | OS cancelada por qualquer motivo |

**Prioridade** *(padrão: Baixa)*

| Opção | Cor | Quando usar |
|---|---|---|
| **Baixa** | Verde | Atendimento normal, sem urgência |
| **Média** | Amarelo | Precisa de atenção mas não é crítico |
| **Urgente** | Vermelho | Problema crítico, atender imediatamente |

**Tipo de Ocorrência**
- Preventiva
- Manutenção
- Corretiva

**Datas**
- **Data de Entrada** *(obrigatório)* — data que o equipamento/chamado foi recebido
- **Hora de Entrada** — hora exata do recebimento
- **Data de Saída** — quando o equipamento foi devolvido/serviço concluído

**Técnico Responsável**
- Dropdown com todos os técnicos ativos
- Se você for técnico, seu nome aparece pré-selecionado

**Acompanhou a Execução**
- Nome da pessoa do cliente que acompanhou o serviço

---

#### Seção 2 — Acessórios Recebidos

Marque os itens que o cliente entregou junto com o equipamento:

| Opção padrão |
|---|
| Carregador |
| Capa |
| Caixa |
| Cabo USB |
| Fone de Ouvido |
| Bateria |
| Manual |
| Nota Fiscal |
| Outros |

Campo **"Outros acessórios"** para itens não listados (texto livre).

---

#### Seção 3 — Equipamentos Vinculados

Aparece automaticamente após selecionar o cliente (se ele tiver equipamentos cadastrados).

Marque com checkbox os equipamentos relacionados à OS:
```
☑ Notebook Dell Inspiron — Série: ABC12345
☐ Monitor LG 24" — Série: XYZ98765
```

---

#### Seção 4 — Condição e Defeito

| Campo | Descrição | Exemplo |
|---|---|---|
| **Condições Físicas** | Estado do equipamento ao receber | _"Apresenta amassado na lateral direita"_ |
| **Defeito Relatado** | O que o cliente disse | _"Não liga. Tela piscando. Derramou água."_ |
| **Status do Equipamento** | Estado atual para diagnóstico | — |

**Status do Equipamento:**
- Funcionando
- Em Diagnóstico
- Em Reparo
- Ag. Retirada (aguardando retirada)
- Sem Conserto

---

#### Seção 5 — Checklist de Testes

Lista padrão de verificação técnica. Para **marcar um item como feito**, toque nele.

Ao marcar:
- Item recebe fundo verde
- Aparece campo de **data de verificação**
- Aparece campo **técnico verificador**

Barra de progresso no topo: `5/12 concluídos ████░░░░░░░░`

---

#### Seção 6 — Laudo Técnico e Solução

| Campo | Descrição |
|---|---|
| **Laudo / Diagnóstico Técnico** | Resultado da análise técnica completa |
| **Solução Aplicada** | O que foi feito para resolver |
| **Peças Utilizadas** | Materiais, peças e componentes trocados |
| **Termos e Observações** | Condições de garantia, avisos ao cliente |
| **Descrição Geral** | Resumo geral do atendimento |

---

#### Seção 7 — Localização GPS

**CEP (auto-preenche):**
Digite o CEP de 8 dígitos. O app consulta a API ViaCEP e preenche automaticamente:
- Logradouro
- Bairro
- Cidade
- UF

**Botão GPS:**
Captura as coordenadas geográficas atuais do celular. Requer permissão de localização.

Quando capturado, aparece:
```
📍 Lat: -15.60123  |  Lng: -56.09456
```

---

#### Seção 8 — Fotos

- Botão **"Adicionar Foto"** — abre câmera ou galeria
- Fotos aparecem em grade
- Toque e segure para remover
- Offline: fotos ficam no celular e sobem quando conectar (ícone 🔄 laranja)

---

#### Seção 9 — Assinaturas

Dois painéis brancos com caneta digital:
- **Assinatura do Cliente** — cliente assina na tela
- **Assinatura do Técnico** — técnico assina na tela

Após assinar: a imagem fica salva na OS.

---

#### Salvar a OS

Toque em **CRIAR OS** (em azul/verde no final).

- **Com internet:** salva no servidor e localmente. Retorna para a lista.
- **Sem internet:** salva apenas localmente. Envia ao servidor automaticamente quando conectar.

---

### 7.3 Detalhe da OS

Toque em qualquer OS da lista para ver os detalhes completos.

**Seções exibidas:**
- Cabeçalho: número, cliente, status, prioridade
- Datas e Responsável (data entrada/saída, hora, técnico, acompanhante)
- Acessórios recebidos
- Detalhes do serviço (defeito, laudo, solução, peças, termos)
- Checklist de testes
- Coordenadas GPS
- Fotos (galeria horizontal)
- Assinaturas (imagens)

**Ações disponíveis:**

| Ação | Como acessar |
|---|---|
| **Gerar PDF** | Ícone 📄 na barra superior |
| **Editar** | Menu ⋮ → Editar |
| **Exportar Word** | Menu ⋮ → Exportar Word |
| **Desativar** | Menu ⋮ → Desativar (confirmar) |

---

### 7.4 Editar OS

Mesmo formulário da criação, com todos os campos já preenchidos.

**Diferença:** o botão final é **"SALVAR ALTERAÇÕES"**.

> ⚠️ **Offline:** Se o técnico da OS foi desativado mas o celular está offline, o nome dele **ainda aparece** no dropdown. O app mantém o valor anterior automaticamente.

---

## 8 · Clientes

### 8.1 Lista de Clientes

Acesse por: **Bottom Nav → Clientes**.

Mostra todos os clientes ativos em ordem alfabética. Busca por:
- Nome
- Telefone
- E-mail

Cada card:
```
┌─────────────────────────────────────┐
│  [B]  Bruno Ruthes             >    │
│       (65) 9 9999-9999              │
│       bruno@email.com               │
└─────────────────────────────────────┘
```

### 8.2 Cadastrar Novo Cliente

Toque no botão **+ (verde)** no canto inferior direito.

**Dados do Cliente:**

| Campo | Obrigatório | Exemplo |
|---|---|---|
| Nome Completo | ✅ | `Bruno Ruthes` |
| Telefone | ❌ | `(65) 9 9999-9999` |
| E-mail | ❌ | `bruno@email.com` |

**Endereço:**

| Campo | Preenchimento |
|---|---|
| CEP | Manual → auto-preenche abaixo |
| Logradouro | Automático pelo CEP ou manual |
| Número / Complemento | Manual |
| Bairro | Automático pelo CEP ou manual |
| Cidade | Automático pelo CEP ou manual |
| UF | Automático pelo CEP ou manual |

**Exemplo de uso do CEP:**
```
1. Digite "78045100" no campo CEP
2. App consulta: viacep.com.br/ws/78045100/json/
3. Preenche automaticamente:
   Logradouro: Rua das Flores
   Bairro:     Centro
   Cidade:     Cuiabá
   UF:         MT
4. Você preenche apenas o Número
```

### 8.3 Editar Cliente

Toque no card do cliente na lista. O formulário abre já preenchido. Faça as alterações e toque em **SALVAR ALTERAÇÕES**.

---

## 9 · Equipamentos

### 9.1 Lista de Equipamentos

Acesse por: **Bottom Nav → Equip.**

Exibe todos os equipamentos ativos. Busca por tipo, marca, modelo ou número de série.

### 9.2 Cadastrar Equipamento

Toque no botão **+**.

| Campo | Obrigatório | Exemplo |
|---|---|---|
| Tipo | ✅ | `Notebook` |
| Marca | ✅ | `Dell` |
| Modelo | ✅ | `Inspiron 15 3000` |
| Número de Série | ✅ | `ABC123XYZ` |
| Cliente | ✅ | Selecione da lista |
| Cor de Identificação | ❌ | `Preto` |
| Canal / Frequência | ❌ | `Canal 3 — 2.4GHz` |

---

## 10 · Usuários — Criação e Gestão

> ⚠️ **Acesso restrito:** somente perfil **Administrador** pode gerenciar usuários.

### 10.1 Acessar a tela de Usuários

Caminhos de acesso:
- **Menu lateral → 👥 Usuários**
- **Dashboard → Acesso Rápido → Usuários**
- **Perfil → Gerenciar Usuários**

### 10.2 Lista de Usuários

Exibe todos os usuários do sistema com:

```
┌───────────────────────────────────────────────────┐
│ [B]  Bruno Ruthes         [ADMIN]           ✏ 🔑  │
│      📧 bruyen72@gmail.com                  🗑     │
│      [● Ativo]            ── switch ──       ◯    │
└───────────────────────────────────────────────────┘
```

**Estatísticas no topo:**

| Card | O que mostra |
|---|---|
| Total | Quantidade total de usuários |
| Admins | Quantos são administradores |
| Técnicos | Quantos são técnicos |
| Ativos | Quantos estão ativos |

**Busca:** por nome ou perfil (admin/tecnico/supervisor).

### 10.3 Criar Novo Usuário

> ⚠️ **Requer internet.** Não é possível criar usuários offline.

Toque no botão **"+ Novo Usuário"** (parte inferior direita).

Se o celular estiver sem internet, uma janela de aviso aparece:

```
┌─────────────────────────────────┐
│  📶  Sem Conexão                │
│                                  │
│  Para criar usuários é           │
│  necessário estar conectado.     │
│                                  │
│         [ Entendido ]            │
└─────────────────────────────────┘
```

**Campos do formulário de criação:**

| Campo | Obrigatório | Observações |
|---|---|---|
| **Nome Completo** | ✅ | Nome que aparece no app |
| **E-mail** | ✅ | Usado para login. **Não pode ser alterado depois.** |
| **Senha** | ✅ | Mínimo 6 caracteres |
| **Perfil** | ✅ | Técnico / Supervisor / Administrador |
| **Especialidade** | ❌ | Ex: "Redes", "Hardware", "Impressoras" |

**Toque em CRIAR USUÁRIO.** O app:
1. Envia os dados para o servidor via Edge Function segura
2. Cria a conta com **confirmação automática** (sem e-mail de verificação)
3. Cria o perfil no banco de dados
4. Exibe confirmação: _"Usuário criado!"_

### 10.4 Editar Usuário

Toque no ícone ✏️ no card do usuário.

**O que pode ser editado:**

| Campo | Editável |
|---|---|
| Nome Completo | ✅ |
| E-mail | ❌ (apenas visualização) |
| Perfil | ✅ |
| Especialidade | ✅ |

O e-mail aparece com **cadeado 🔒** indicando que não pode ser alterado.

### 10.5 Resetar Senha

Toque no ícone **🔑** no card do usuário.

Aparece um diálogo:
```
┌─────────────────────────────────────┐
│  🔑 Resetar senha                   │
│     João Silva                       │
│                                      │
│  Digite a nova senha para este       │
│  usuário:                            │
│                                      │
│  [ Nova senha (mín. 6 caracteres) ] │
│                                      │
│  [Cancelar]          [Resetar]       │
└─────────────────────────────────────┘
```

Digite a nova senha (mínimo 6 caracteres) e toque em **Resetar**.

> ℹ️ O usuário precisará usar a nova senha no próximo login.

### 10.6 Deletar Usuário

Toque no ícone **🗑️** no card do usuário.

> ⚠️ **Administradores não podem ser deletados.** O botão 🗑️ não aparece para usuários com perfil `admin`.

Aparece confirmação:
```
┌──────────────────────────────────┐
│  🗑️  Deletar Usuário             │
│                                   │
│  Deletar "João Silva"             │
│  permanentemente?                 │
│                                   │
│  Esta ação não pode ser          │
│  desfeita.                        │
│                                   │
│  [Cancelar]      [Deletar]        │
└──────────────────────────────────┘
```

### 10.7 Ativar / Desativar Usuário

O **switch** ao lado de cada usuário ativa ou desativa a conta:

- **Ativo (verde):** usuário pode fazer login normalmente
- **Inativo (cinza):** usuário não pode mais logar no sistema

> ⚠️ Requer internet. Se offline, aparece a janela de aviso.

> ℹ️ Desativar é diferente de deletar. O usuário e seus dados continuam no banco, apenas o acesso é bloqueado.

---

## 11 · Notificações

### 11.1 Acessar

- **Menu lateral → 🔔 Notificações**
- **Acesso Rápido → Notificações**
- **Perfil → Notificações**

### 11.2 Tipos de notificação

| Tipo | Cor | Ícone | Quando aparece |
|---|---|---|---|
| **info** | Ciano | ℹ️ | Informações gerais do sistema |
| **warning** | Âmbar | ⚠️ | Alertas que precisam de atenção |
| **success** | Verde | ✅ | Ações concluídas com sucesso |
| **urgente** | Vermelho | 🔥 | Situações críticas que precisam de ação imediata |

### 11.3 Filtros

| Filtro | O que mostra |
|---|---|
| Todas | Todas as notificações |
| Não lidas | Apenas as não lidas (ponto colorido) |
| Info | Apenas tipo informação |
| Urgente | Apenas urgentes |
| Sucesso | Apenas sucessos |

### 11.4 Marcar como lida

- **Uma notificação:** toque nela
- **Todas de uma vez:** botão **"Marcar lidas"** na barra superior (aparece quando há não lidas)

### 11.5 Offline

As últimas **50 notificações** ficam em cache local. Marcar como lida funciona offline e é sincronizado automaticamente quando conectar.

---

## 12 · Relatórios — PDF e Word

### 12.1 Acessar

- **Perfil → Relatórios / Gerar PDF**
- **Acesso Rápido → Relatórios**

### 12.2 Lista de relatórios

Mostra todas as OS disponíveis. Cada card exibe:
```
┌──────────────────────────────────────────────────┐
│  📋  OS-2026001                                   │
│      Empresa XYZ Ltda          [Concluído]        │
│      📅 15/05/2026             🔧 Técnico: João   │
│                                                    │
│   [🔴 PDF]              [🔵 Word (.docx)]          │
└──────────────────────────────────────────────────┘
```

### 12.3 Gerar PDF

Toque em **🔴 PDF**. O app:
1. Busca todos os dados da OS (checklist, acessórios, assinaturas)
2. Monta o documento (leva alguns segundos)
3. Abre o **menu de compartilhamento** do Android

**Conteúdo completo do PDF:**

```
┌─────────────────────────────────────────────────┐
│  GERENCIADOR DE OS PARA CAMPO      Nº OS-2026001 │  ← cabeçalho verde
├─────────────────────────────────────────────────┤
│  STATUS: Concluído  │  PRIO: Baixa  │  Corretiva │  ← faixa colorida
├─────────────────────────────────────────────────┤
│  IDENTIFICAÇÃO DA OS                             │  ← seção verde escuro
│  Nº OS:          OS-2026001                      │
│  Status:         Concluído                       │
│  Prioridade:     Baixa                           │
│  Tipo:           Corretiva                       │
│  Data Entrada:   15/05/2026                      │
│  Hora Entrada:   09:30                           │
│  Data Saída:     15/05/2026                      │
│  Cliente:        Empresa XYZ Ltda                │
│  Técnico:        João Silva                      │
│  Acompanhou:     Carlos (supervisor)             │
│  Endereço:       Rua das Flores, 123 - Centro    │
├─────────────────────────────────────────────────┤
│  ACESSÓRIOS RECEBIDOS                            │
│  [Carregador]  [Capa]  [Cabo USB]                │
├─────────────────────────────────────────────────┤
│  LAUDO TÉCNICO E SOLUÇÃO                         │
│  Condições Físicas: Arranhões na tampa...        │
│  Defeito Relatado:  Não liga após queda...       │
│  Laudo Técnico:     Conector de carga quebrado.. │
│  Solução Aplicada:  Troca do conector...         │
│  Peças Utilizadas:  1x Conector USB-C...         │
├─────────────────────────────────────────────────┤
│  CHECKLIST DE TESTES                             │
│  #  │ Item de Verificação  │ Feito │ Data  │ Téc │
│  1  │ Liga normalmente     │ Sim   │ 15/05 │ João│
│  2  │ Carrega normalmente  │ Sim   │ 15/05 │ João│
│  3  │ Wi-Fi funcionando    │ Nao   │  —    │  —  │
├─────────────────────────────────────────────────┤
│  LOCALIZAÇÃO GPS                                 │
│  Lat: -15.601234  |  Lng: -56.094567            │
│  Endereço: Rua das Flores, 123, Centro, Cuiabá  │
├─────────────────────────────────────────────────┤
│  ASSINATURAS                                     │
│  ┌──────────────┐  ┌──────────────────────────┐ │
│  │[imagem real] │  │    [imagem real]          │ │
│  │da assinatura │  │   da assinatura           │ │
│  │  do cliente  │  │    do técnico             │ │
│  └──────────────┘  └──────────────────────────┘ │
├─────────────────────────────────────────────────┤
│  TECPOINT · SURVEY · Gerado em 15/05/2026 11:45  │
└─────────────────────────────────────────────────┘
```

### 12.4 Gerar Word (.docx)

Mesmo conteúdo do PDF em formato Word editável.

**Compatível com:**
- Microsoft Word (Windows / Mac / Android / iOS)
- LibreOffice Writer
- Google Docs
- WPS Office

### 12.5 Compartilhar o arquivo

Após gerar, o menu padrão do Android abre:
```
Compartilhar via:
[WhatsApp] [Telegram] [Gmail] [Drive] [Bluetooth] [...]
```

O arquivo é salvo em: `/storage/emulated/0/Android/data/.../files/OS_2026001.pdf`

---

## 13 · Perfil e Conta

### 13.1 Tela de Perfil

Acesse por: **Bottom Nav → Perfil (último ícone)**.

Exibe:
```
┌────────────────────────────────────────┐
│  [B]  Bruno Ruthes                     │
│       bruyen72@gmail.com               │
│       [ADMINISTRADOR]                  │
└────────────────────────────────────────┘
```

### 13.2 Menu Sistema

| Opção | Descrição |
|---|---|
| 🔔 Notificações | Abre a lista de notificações |
| 👥 Gerenciar Usuários | Somente para Admin |
| 📄 Relatórios / Gerar PDF | Acesso à tela de relatórios |
| 🔄 Sincronizar dados offline | Força sincronização manual |
| ℹ️ Versão do app | Exibe: 1.0.0 |

### 13.3 Sincronização manual

Toque em **"Sincronizar dados offline"**.

- Spinner aparece enquanto sincroniza
- Ao concluir: _"Sincronização concluída"_ (snackbar verde)
- Útil quando você quer garantir que tudo foi enviado

### 13.4 Sair do aplicativo

Toque em **"Sair do aplicativo"**.

Aparece confirmação:
```
┌──────────────────────────┐
│  Sair                    │
│  Deseja sair do app?     │
│                          │
│  [Cancelar]   [Sair]     │
└──────────────────────────┘
```

**Ao confirmar:**
- Sessão encerrada no servidor
- App redireciona para a tela de login
- **As credenciais offline são mantidas** — você pode logar offline depois

---

## 14 · Sincronização Automática

### 14.1 Como o sistema decide o que sincronizar?

Tudo criado ou editado offline fica em uma **fila de sincronização** (tabela `sync_queue` no banco local).

Cada item da fila contém:
- Tabela afetada (OS, cliente, equipamento...)
- Tipo de operação (INSERT, UPDATE)
- Dados completos da operação
- Horário de criação

### 14.2 Quando a sincronização acontece?

| Gatilho | Descrição |
|---|---|
| **App abre** | Sync imediato se houver internet |
| **Internet volta** | Detectado automaticamente pelo sistema |
| **A cada 15 min** | Timer automático enquanto app está aberto |
| **Background** | WorkManager a cada 15 min mesmo com app fechado |
| **Manual** | Perfil → Sincronizar dados offline |

### 14.3 Ordem de sincronização

Os itens são processados **na ordem em que foram criados** (fila FIFO):

```
Fila atual:
1. OS-OFFLINE-001 criada às 09:15 → INSERT no Supabase
2. Cliente "Maria" editado às 09:32 → UPDATE no Supabase
3. Foto da OS-OFFLINE-001 → upload para Storage
4. Assinatura da OS-OFFLINE-001 → salva no servidor
```

### 14.4 O que acontece se falhar?

Se um item da fila falhar (ex: servidor offline, erro de rede):
- O item **permanece na fila**
- Os outros itens continuam sendo processados
- Na próxima tentativa de sync, tenta novamente

### 14.5 Dados que são sincronizados

| Dado | Operação |
|---|---|
| OS criada offline | INSERT com todos os campos |
| OS editada offline | UPDATE com campos alterados |
| Cliente criado offline | INSERT |
| Cliente editado offline | UPDATE |
| Equipamento criado/editado | INSERT/UPDATE |
| Fotos | Upload para Supabase Storage |
| Assinaturas | Upload via payload do sync |
| Notificações marcadas | UPDATE (lida = true) |

---

## 15 · Permissões do Sistema

Ao usar algumas funcionalidades, o Android pedirá permissão:

| Permissão | Por que o app precisa | Quando pergunta |
|---|---|---|
| **Câmera** | Tirar fotos para a OS | Primeira vez que adiciona foto pela câmera |
| **Galeria / Fotos** | Selecionar fotos existentes | Primeira vez que abre a galeria |
| **Localização** | Capturar GPS do atendimento | Ao tocar no botão "GPS" na OS |
| **Internet** | Sincronização e login online | Concedida automaticamente pelo sistema |
| **Armazenamento** | Salvar PDF/Word gerado | Ao gerar o primeiro relatório |

### Se a permissão for negada

**Câmera/Galeria negada:**
```
O app não consegue tirar fotos.
A funcionalidade de fotos fica desabilitada.
Você pode ativar nas configurações do Android:
Configurações → Apps → TECPOINT → Permissões → Câmera → Permitir
```

**Localização negada:**
```
Mensagem: "Permissão de localização negada"
O campo GPS na OS não é preenchido automaticamente.
Os outros campos do formulário continuam normais.
```

---

## 16 · Perfis de Acesso

### Comparativo completo

| Funcionalidade | Técnico | Supervisor | Admin |
|---|---|---|---|
| Criar OS | ✅ | ✅ | ✅ |
| Editar OS | ✅ | ✅ | ✅ |
| Ver todas as OS | Próprias* | ✅ | ✅ |
| Desativar OS | ✅ | ✅ | ✅ |
| Criar cliente | ✅ | ✅ | ✅ |
| Editar cliente | ✅ | ✅ | ✅ |
| Criar equipamento | ✅ | ✅ | ✅ |
| Ver notificações | ✅ | ✅ | ✅ |
| Gerar PDF/Word | ✅ | ✅ | ✅ |
| **Criar usuário** | ❌ | ❌ | ✅ |
| **Editar usuário** | ❌ | ❌ | ✅ |
| **Resetar senha** | ❌ | ❌ | ✅ |
| **Deletar usuário** | ❌ | ❌ | ✅ |
| **Ativar/desativar usuário** | ❌ | ❌ | ✅ |
| **Acessar tela Usuários** | ❌ | ❌ | ✅ |

\* *O filtro por técnico responsável pode ser implementado futuramente.*

### Regras de segurança

- **Administrador não pode ser deletado** pelo app (proteção contra acidente)
- **Usuário não pode desativar a própria conta** (evita bloqueio acidental)
- **E-mail não pode ser alterado** depois que a conta é criada

---

## 17 · Cenários Reais de Uso

### Cenário 1 — Técnico atende cliente em área sem sinal

```
SITUAÇÃO: João é técnico. Cliente fica em fazenda, sem sinal.

ANTES DE SAIR:
  09:00 — João abre o app no escritório (Wi-Fi)
           → Login online realizado
           → OS do cliente sincronizada

NO CLIENTE (sem sinal):
  10:00 — João abre o app
           → Banner laranja: "Sem conexão"
           → OS carrega normalmente do cache

  10:30 — João preenche laudo: "Placa de rede queimada"
           → Salvo localmente

  10:45 — João marca 8 itens do checklist
           → Salvo localmente

  11:00 — João coleta assinatura do cliente
           → Ícone 🔄 aparece na assinatura (pendente)

  11:15 — João tira 4 fotos do equipamento
           → Ícone 🔄 nas fotos (aguardando upload)

  11:30 — João muda status para "Concluído"
           → Salvo localmente

DE VOLTA AO ESCRITÓRIO:
  13:00 — Wi-Fi reconectado automaticamente
           → App detecta em segundos
           → SyncService processa a fila:
              ✓ OS atualizada no servidor
              ✓ Checklist sincronizado
              ✓ Assinatura uploadada
              ✓ 4 fotos uploadadas
           → João não precisou fazer nada manualmente
```

---

### Cenário 2 — Admin cria conta para novo técnico

```
SITUAÇÃO: Bruno (admin) precisa cadastrar Maria, nova técnica.

  1. Bruno abre: Menu lateral → 👥 Usuários

  2. Toca no botão "+ Novo Usuário"

  3. Preenche:
     Nome: Maria Santos
     E-mail: maria@tecpoint.com
     Senha: maria123
     Perfil: Técnico
     Especialidade: Redes

  4. Toca em "CRIAR USUÁRIO"

  5. Confirmação: "Usuário criado!"

  6. Maria recebe as credenciais por WhatsApp:
     E-mail: maria@tecpoint.com
     Senha: maria123

  7. Maria abre o app → Login com internet → Senha inicial
     → App sincroniza dados
     → Maria já pode usar todas as funcionalidades de técnico
```

---

### Cenário 3 — Admin reseta senha esquecida

```
SITUAÇÃO: Pedro esqueceu a senha. Não consegue logar.

  1. Bruno (admin) abre Usuários

  2. Localiza Pedro na lista

  3. Toca no ícone 🔑 no card do Pedro

  4. Digita a nova senha: "novaSenha456"

  5. Toca em "Resetar"

  6. Confirmação: "Senha de Pedro resetada com sucesso!"

  7. Bruno avisa Pedro da nova senha

  8. Pedro faz login → com internet → nova senha funciona
     → Pedro pode usar o app normalmente
```

---

### Cenário 4 — Dois técnicos compartilham o mesmo celular

```
SITUAÇÃO: João e Carlos compartilham um celular corporativo.

CONFIGURAÇÃO INICIAL (feita uma vez):
  1. João loga com internet → usa o app → faz logout
  2. Carlos loga com internet → usa o app → faz logout
  Agora os dois têm credenciais offline no mesmo celular.

USO DIÁRIO SEM INTERNET:
  Manhã — João pega o celular:
    → Digita e-mail do João + senha do João
    → Login offline OK → Menu mostra "João Silva"
    → Trabalha normalmente

  Tarde — Carlos pega o celular:
    → João já saiu (logout)
    → Carlos digita seu e-mail + sua senha
    → Login offline OK → Menu mostra "Carlos Pereira"
    → Cada um vê seu próprio perfil
```

---

### Cenário 5 — Internet cai durante o uso

```
SITUAÇÃO: Ana está editando uma OS quando o sinal cai.

  14:00 — Ana abre a OS 2026-089 (carregou do servidor)
  
  14:10 — Internet cai
           → Banner laranja aparece no topo
           → Ana continua editando normalmente

  14:15 — Ana salva o laudo técnico
           → Mensagem: "OS atualizada!"
           → Dados salvos localmente com synced=0

  14:30 — Ana fecha o app
           → Dados continuam salvos no celular

  16:00 — Internet volta
           → App estava fechado, mas WorkManager detecta
           → Sync em background executado automaticamente
           → OS atualizada no servidor sem Ana precisar abrir o app
```

---

### Cenário 6 — Técnico desativado mas app offline

```
SITUAÇÃO: Roberto foi desativado mas seu celular está offline.

  Roberto abre o app offline → Login com suas credenciais
  → Acesso funcionando (credenciais offline ainda válidas)
  → Roberto cria uma OS atribuída a ele mesmo

  [Quando internet voltar:]
  → A OS é sincronizada com o servidor
  → O servidor registra a OS normalmente
  → Na próxima vez que Roberto tentar logar ONLINE:
     → Conta inativa → acesso negado no servidor
  → O admin pode reativar quando necessário
```

---

## 18 · Perguntas Frequentes — FAQ

### 🔐 Sobre Login e Acesso

---

**P: Posso usar o app sem internet?**

R: Sim, desde que você tenha feito ao menos um login **com internet** nesse celular. Após isso, você pode entrar e trabalhar completamente offline. Quando a internet voltar, tudo é sincronizado automaticamente.

---

**P: Esqueci minha senha. O que faço?**

R: Entre em contato com o administrador do sistema. Ele pode acessar **Usuários → 🔑 Resetar senha** e definir uma nova para você. Após isso, faça login com a nova senha usando internet.

---

**P: Posso mudar meu próprio e-mail?**

R: Não. O e-mail é definido na criação da conta e **não pode ser alterado** pelo app. Se precisar trocar o e-mail, o administrador deve criar uma nova conta.

---

**P: Por que minha conta offline parou de funcionar?**

R: Pode ter acontecido uma das situações:
- Sua senha foi alterada pelo administrador → faça login online com a nova senha
- Sua conta foi desativada → contate o administrador
- Faz mais de 6 meses sem usar → as credenciais offline podem ter sido substituídas por contas mais recentes (limite de 10)

---

**P: O app pode ter mais de um usuário logado ao mesmo tempo?**

R: Não. Apenas um usuário fica ativo por vez. Para trocar de usuário: o primeiro faz logout, o segundo faz login.

---

**P: O que é o limite de 10 contas offline?**

R: O celular guarda credenciais offline de até 10 usuários diferentes. Se um 11º usuário logar com internet, as credenciais do usuário que faz mais tempo sem acessar são removidas do armazenamento offline. Os dados das OS e histórico não são afetados.

---

### 📋 Sobre Ordens de Serviço

---

**P: Posso criar uma OS sem selecionar um cliente?**

R: Não. O campo **Cliente** é obrigatório para criar uma OS.

---

**P: A OS criada offline recebe um número correto?**

R: O número é gerado pelo servidor. Quando offline, o app usa um número temporário no formato `OS-AAAAMMDD-XXXXX`. Quando a internet voltar e a OS for sincronizada, o número pode ser atualizado pelo servidor.

---

**P: Posso editar uma OS que foi criada por outro técnico?**

R: Sim, qualquer usuário com acesso ao sistema pode editar qualquer OS.

---

**P: O checklist é obrigatório?**

R: Não. O checklist é opcional. Você pode salvar a OS sem marcar nenhum item.

---

**P: Posso excluir uma OS permanentemente?**

R: Não pelo app. A ação disponível é **Desativar**, que remove a OS da lista mas mantém o registro no banco de dados. Isso é uma proteção de auditoria.

---

**P: Como tirar fotos pela OS?**

R: Na Seção 8 do formulário, toque em **"Adicionar Foto"**. Escolha entre câmera ou galeria. As fotos são salvas na OS. Offline, ficam no celular com ícone 🔄 e sobem quando conectar.

---

**P: As assinaturas aparecem no PDF?**

R: Sim. Se assinaturas foram coletadas (cliente e/ou técnico), elas aparecem como **imagens reais** no final do PDF e do Word.

---

**P: O GPS captura minha localização em tempo real?**

R: O GPS captura a localização **no momento em que você toca no botão GPS**. As coordenadas ficam registradas na OS. Não há rastreamento contínuo.

---

### 👥 Sobre Usuários

---

**P: Quem pode criar usuários?**

R: Somente o **Administrador**. Técnicos e Supervisores não têm acesso à tela de usuários.

---

**P: Por que não consigo criar usuário offline?**

R: A criação de usuários usa uma função segura no servidor (Edge Function) que precisa de internet para autenticar e criar a conta corretamente. É uma medida de segurança necessária.

---

**P: Posso deletar um administrador?**

R: Não. O botão de deletar não aparece para contas de perfil `admin`. Isso é uma proteção para evitar que o sistema fique sem administrador.

---

**P: Qual a diferença entre desativar e deletar um usuário?**

R: 
- **Desativar** → conta bloqueada, usuário não consegue logar, mas todos os dados (OS, histórico) continuam no sistema
- **Deletar** → conta e dados removidos permanentemente. **Ação irreversível.**

---

**P: Posso ter dois usuários com o mesmo e-mail?**

R: Não. O e-mail é único por conta. Se tentar criar um usuário com e-mail já cadastrado, o servidor retorna erro.

---

### 📄 Sobre PDF e Word

---

**P: O PDF funciona offline?**

R: Sim. O PDF é gerado localmente no celular usando os dados cacheados. Não precisa de internet.

---

**P: Por que o técnico não aparece no PDF?**

R: O PDF usa o nome do técnico registrado na OS. Se a OS foi criada quando o cache de perfis estava vazio (primeiro uso offline), o nome pode não ter sido salvo. Solução: abra a OS com internet para atualizar os dados.

---

**P: Posso personalizar o layout do PDF?**

R: Não pela versão atual do app. O layout é padronizado e profissional.

---

**P: Onde o arquivo PDF é salvo?**

R: Na pasta de documentos internos do app: `Android/data/com.tecpoint.app/files/`. Para acessá-lo após compartilhar, use o app de arquivos do celular ou o gerenciador de arquivos.

---

### 🔄 Sobre Sincronização

---

**P: Como saber se tudo foi sincronizado?**

R: 
- O banner laranja some quando a internet volta
- Fotos com ícone 🔄 indicam pendência
- Assinaturas com aviso laranja indicam pendência
- **Perfil → Sincronizar dados offline** → toque e aguarde a mensagem de conclusão

---

**P: E se eu fechar o app antes de sincronizar?**

R: Os dados continuam salvos no celular. O WorkManager tenta sincronizar automaticamente a cada 15 minutos, mesmo com o app fechado. Ao abrir o app com internet, o sync também ocorre imediatamente.

---

**P: O que acontece se criar a mesma OS duas vezes (online e offline)?**

R: O app usa IDs únicos gerados no momento da criação. Mesmo offline, cada OS tem um ID diferente. Não há duplicação acidental.

---

### 📱 Sobre o App em Geral

---

**P: O app funciona em tablet?**

R: Sim. O layout é responsivo e se adapta automaticamente para telas maiores. Os grids de estatísticas e acesso rápido usam mais colunas em telas de tablet.

---

**P: O app consome muita bateria?**

R: O WorkManager usa estratégias eficientes de bateria do Android. A sincronização em background ocorre em intervalos de 15 minutos, sem afetar significativamente a bateria.

---

**P: O app precisa de atualização?**

R: Quando houver uma nova versão, o administrador disponibilizará um novo arquivo APK para instalação manual (o mesmo processo da instalação inicial).

---

## 19 · Solução de Problemas

### 🔴 Problemas críticos

---

**PROBLEMA: App trava na tela de splash (logo)**

```
Possíveis causas:
  1. Primeira abertura — aguarde a tela de login aparecer (~2,6 segundos)
  2. App travado — feche pelo gerenciador de apps e abra novamente
  3. Memória insuficiente — reinicie o celular

Se persistir:
  Desinstale e reinstale o app
  Os dados offline são perdidos, mas as OS online continuam no servidor
```

---

**PROBLEMA: Login falha com "E-mail ou senha inválidos" mas tenho certeza que está correto**

```
Verifique:
  ✓ CapsLock desativado
  ✓ Espaços extras no e-mail (copiar/colar pode incluir)
  ✓ Conexão com internet estável
  ✓ Tente desativar o preenchimento automático do Android

Se persistir:
  Peça ao admin para verificar se a conta está ativa
```

---

**PROBLEMA: Dados não aparecem após login offline**

```
Causa: O app nunca baixou os dados com internet neste celular

Solução:
  1. Conecte à internet
  2. Faça login normalmente
  3. Navegue pelas principais telas (OS, Clientes, Equipamentos)
     → Isso força o cache local a ser populado
  4. A partir daí, os dados ficam disponíveis offline
```

---

**PROBLEMA: Foto tirada não aparece na OS**

```
Verificar:
  ✓ Permissão de câmera concedida
  ✓ Espaço de armazenamento disponível

Se offline:
  A foto aparece com ícone 🔄 (laranja)
  Só sobe para o servidor quando tiver internet
  Enquanto isso, fica visível localmente
```

---

**PROBLEMA: GPS não captura localização**

```
Verificar:
  ✓ GPS do celular ativado (configurações → localização)
  ✓ Permissão de localização concedida para o TECPOINT
  ✓ Celular ao ar livre ou próximo a janela (sinal GPS)

Mensagem "GPS falhou":
  O celular não conseguiu captura as coordenadas em 15 segundos
  Tente novamente em local com melhor sinal
  Os campos de endereço podem ser preenchidos manualmente via CEP
```

---

**PROBLEMA: PDF gerado sem assinatura**

```
Verificar:
  ✓ A assinatura foi coletada? (Seção 9 do formulário)
  ✓ Se offline, a assinatura ficou como "pendente de sincronização"

O PDF usa as assinaturas salvas na OS:
  - Online: usa dados do servidor
  - Offline: usa dados locais (pode estar pendente)

Solução:
  Aguarde a sincronização e gere o PDF novamente
```

---

**PROBLEMA: Sincronização não acontece automaticamente**

```
Verificar:
  ✓ Internet ativa no celular
  ✓ App não está em modo de economia de bateria
     (pode bloquear o WorkManager)

Forçar manualmente:
  Perfil → Sincronizar dados offline → toque e aguarde

Configurar bateria:
  Configurações Android → Apps → TECPOINT
  → Bateria → "Sem restrições" ou "Permitir atividade em segundo plano"
```

---

**PROBLEMA: Técnico não aparece no card da OS**

```
Causa: Nome do técnico não estava no cache quando a OS foi criada offline

Solução:
  1. Conecte à internet
  2. Abra a lista de OS
  3. O sistema enriquece automaticamente o nome do técnico
  4. Na próxima abertura offline, o nome aparece corretamente
```

---

**PROBLEMA: Usuário criado mas não consegue logar**

```
Verificar com o admin:
  ✓ A conta foi criada com sucesso? (admin verifica na lista de usuários)
  ✓ O e-mail usado no login é exatamente o mesmo cadastrado?
  ✓ A senha tem mínimo 6 caracteres?
  ✓ A conta está ativa (switch verde)?
  ✓ O primeiro login está sendo feito com internet?
```

---

## 20 · Referência Técnica

### Stack tecnológico

| Camada | Tecnologia | Versão |
|---|---|---|
| Framework | Flutter / Dart | 3.x |
| Backend | Supabase (PostgreSQL) | — |
| Auth | Supabase Auth | — |
| Storage | Supabase Storage | — |
| Edge Functions | Deno (TypeScript) | — |
| Banco local | SQLite (sqflite) | v8 |
| Credenciais seguras | FlutterSecureStorage | — |
| Sync background | WorkManager Android | — |
| GPS | Geolocator | — |
| PDF | package:pdf | — |
| Word | package:archive (DOCX) | — |
| Cache de imagens | CachedNetworkImage | — |
| CEP | API ViaCEP | — |
| Hash de senha | SHA-256 (crypto) | — |

### Tabelas do banco SQLite local

| Tabela | Descrição | Versão adicionada |
|---|---|---|
| `clientes` | Dados de clientes com endereço completo | v1 |
| `equipamentos` | Equipamentos vinculados a clientes | v1 |
| `ordens_servico` | OS completas com todos os campos | v1 |
| `profiles` | Usuários e técnicos para offline | v2 |
| `fotos_pendentes` | Caminhos de fotos aguardando upload | v2 |
| `os_checklist_local` | Itens de checklist por OS | v3 |
| `os_acessorio_local` | Acessórios por OS | v3 |
| `os_assinatura_local` | Assinaturas em base64 | v4 |
| `os_equipamento_local` | Relação N:N entre OS e equipamentos | v5 |
| `notificacoes_local` | Cache das últimas 50 notificações | v7 |
| `sync_queue` | Fila de operações pendentes | v1 |

### Versão do banco de dados

**v8** — evolução desde v1 com migrações automáticas e não destrutivas.

### Segurança implementada

| Medida | Descrição |
|---|---|
| Senha nunca em texto claro | Armazenada apenas como hash SHA-256 |
| Credenciais criptografadas | FlutterSecureStorage (criptografia do SO) |
| JWT para API | Toda comunicação autenticada com token |
| Edge Functions protegidas | Verificam perfil admin antes de executar |
| Proteção de admin | Administradores não podem ser deletados |
| Limite de contas | Máximo 10 contas offline (LRU eviction) |
| Usuário não bloqueia a si mesmo | Não pode desativar a própria conta |

### Numeração das OS

| Situação | Formato | Exemplo |
|---|---|---|
| Online | Sequencial gerado pelo servidor | `OS-2026001` |
| Offline (fallback) | Timestamp parcial | `OS-20260515-12345` |

---

> ---
>
> **TECPOINT v1.0.0**
>
> *Desenvolvido para UniSENAI MT — Cuiabá, MT — 2026*
>
> *Manual elaborado com base na versão completa do aplicativo instalado.*
>
> *Todos os direitos reservados.*
>
> ---
