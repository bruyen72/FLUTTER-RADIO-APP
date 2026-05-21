# TECPOINT — Manual Completo do Aplicativo
**Versão 1.0.0 · UniSENAI MT · 2026**

---

## SUMÁRIO

1. [Visão Geral](#1-visão-geral)
2. [Requisitos e Instalação](#2-requisitos-e-instalação)
3. [Login e Autenticação](#3-login-e-autenticação)
4. [Modo Offline](#4-modo-offline)
5. [Dashboard (Tela Inicial)](#5-dashboard-tela-inicial)
6. [Ordens de Serviço (OS)](#6-ordens-de-serviço-os)
7. [Clientes](#7-clientes)
8. [Equipamentos](#8-equipamentos)
9. [Usuários (Admin)](#9-usuários-admin)
10. [Notificações](#10-notificações)
11. [Relatórios — PDF e Word](#11-relatórios--pdf-e-word)
12. [Perfil e Configurações](#12-perfil-e-configurações)
13. [Sincronização Automática](#13-sincronização-automática)
14. [Permissões do Aplicativo](#14-permissões-do-aplicativo)
15. [Perfis de Acesso](#15-perfis-de-acesso)
16. [Referência Técnica](#16-referência-técnica)

---

## 1. Visão Geral

O **TECPOINT** é um aplicativo Android para gerenciamento de Ordens de Serviço em campo. Desenvolvido para equipes técnicas que precisam trabalhar com ou sem conexão à internet.

### Funcionalidades principais

| Funcionalidade | Online | Offline |
|---|---|---|
| Criar e editar OS | ✅ | ✅ |
| Visualizar lista de OS | ✅ | ✅ |
| Registrar clientes | ✅ | ✅ |
| Cadastrar equipamentos | ✅ | ✅ |
| Tirar fotos e anexar | ✅ | ✅ (sincroniza depois) |
| Assinatura digital | ✅ | ✅ (sincroniza depois) |
| Checklist de testes | ✅ | ✅ |
| Gerar PDF / Word | ✅ | ✅ |
| Gerenciar usuários | ✅ | ❌ (requer internet) |
| Login com múltiplas contas | ✅ | ✅ (até 10 contas salvas) |
| Notificações | ✅ | ✅ (cache local) |

---

## 2. Requisitos e Instalação

### Requisitos mínimos
- **Sistema:** Android 6.0 (API 23) ou superior
- **Armazenamento:** 150 MB livres
- **Conexão:** Wi-Fi ou dados móveis (para login inicial e sincronização)
- **Permissões:** Câmera, Localização GPS, Armazenamento

### Instalação
1. Copie o arquivo `app-release.apk` para o dispositivo
2. Abra o arquivo APK
3. Se solicitado, habilite **"Instalar de fontes desconhecidas"** nas configurações do Android
4. Toque em **Instalar**
5. Após instalado, abra o app **TECPOINT**

---

## 3. Login e Autenticação

### Primeiro acesso (obrigatório online)
O primeiro login **sempre requer internet**. Após isso, a conta fica disponível offline.

1. Abra o aplicativo
2. Digite seu **e-mail** e **senha** cadastrados pelo administrador
3. Toque em **ENTRAR**
4. Aguarde o carregamento do Dashboard

### Login subsequente (online)
Funciona da mesma forma. Se a internet estiver disponível, o app valida as credenciais com o servidor.

### Login offline
Funciona automaticamente após o primeiro login online no dispositivo.

**Condição:** o dispositivo deve ter ficado online pelo menos uma vez com essa conta.

**Comportamento:**
- O app detecta automaticamente que está sem internet
- O banner laranja "Sem conexão" aparece no topo
- O botão muda para **ENTRAR (MODO OFFLINE)**
- A autenticação é feita localmente (hash SHA-256 da senha)
- Um aviso laranja confirma: *"Entrou em modo offline. Dados serão sincronizados ao conectar."*

### Múltiplas contas offline
O app suporta até **10 contas diferentes** no mesmo dispositivo. Cada usuário que já entrou online pode fazer login offline independentemente.

**Exemplo:** Bruno (admin) e João (técnico) podem ambos logar offline no mesmo celular.

### Mensagens de erro no login

| Mensagem | Causa | Solução |
|---|---|---|
| E-mail ou senha inválidos | Credenciais incorretas | Verifique e-mail e senha |
| Senha incorreta para acesso offline | Senha digitada errada offline | Digite a senha correta |
| Conta não registrada offline neste dispositivo | Nunca logou online neste aparelho | Faça login com internet ao menos uma vez |
| E-mail ainda não confirmado | Conta criada mas não ativa | Contate o administrador |
| Sem conexão com a internet | Sem rede e sem conta offline | Conecte à internet |

---

## 4. Modo Offline

### Como funciona
O app usa uma estratégia **Offline-First**: tenta o banco de dados local (SQLite) antes do servidor sempre que não há internet.

### O que é salvo localmente
- Todas as OS abertas
- Lista de clientes (ativos)
- Lista de equipamentos
- Perfis de usuários/técnicos
- Checklist, acessórios, assinaturas de cada OS
- Notificações recentes (últimas 50)
- Fotos pendentes de upload

### Indicadores visuais
- **Banner laranja** no topo de todas as telas: *"Sem conexão — dados salvos localmente"*
- **Fotos** com ícone de sync ♻ laranja: aguardando upload
- **Assinaturas** com aviso: *"Pendente de sincronização"*

### O que NÃO funciona offline
- Criar, editar ou deletar usuários
- Resetar senha de usuário
- Desativar/ativar usuário

### Quando a internet volta
- O app **não expulsa o usuário** — ele continua na tela atual
- O `SyncService` detecta automaticamente a reconexão
- Todos os dados pendentes são enviados ao servidor em background
- Fotos e assinaturas são uploadadas automaticamente

---

## 5. Dashboard (Tela Inicial)

Tela principal após o login. Mostra o resumo do sistema.

### Header de saudação
- Nome do usuário logado
- Perfil (TECNICO / SUPERVISOR / ADMINISTRADOR)

### Resumo de OS (cards de estatísticas)
6 cards com contadores em tempo real:

| Card | O que conta |
|---|---|
| Total | Todas as OS ativas |
| Abertas | OS com status "Aberto" |
| Andamento | OS com status "Em Andamento" |
| Concluídas | OS com status "Concluído" |
| Canceladas | OS com status "Cancelado" |
| Urgentes | OS com prioridade "Urgente" |

*No tablet: 3 colunas. No celular: 2 colunas.*

### Botão Nova OS
Atalho direto para criar uma nova Ordem de Serviço.

### Acesso Rápido
Grade de ícones para navegação rápida:
- **Ordens de Serviço** — lista completa
- **Clientes** — cadastro de clientes
- **Equipamentos** — equipamentos cadastrados
- **Notificações** — alertas do sistema
- **Relatórios** — gerar PDF/Word
- **Usuários** — gerenciar usuários (somente Admin)

### Menu lateral (Drawer)
Aberto pelo ícone ☰ no canto superior esquerdo. Contém:
- Dados do usuário logado (nome + perfil)
- Navegação para todas as seções
- Botão "Nova OS"
- Acesso a Notificações e Usuários (Admin)

### Bottom Navigation Bar
Navegação principal entre as 5 seções:
`Home · OS · Clientes · Equipamentos · Perfil`

---

## 6. Ordens de Serviço (OS)

### Lista de OS

**Filtros disponíveis:**
- Por **Status**: Aberto / Em Andamento / Concluído / Cancelado
- Por **Prioridade**: Baixa / Média / Urgente
- **Busca por texto**: número da OS, nome do cliente ou defeito

**Chips de filtro ativo:** aparecem abaixo da barra de busca e podem ser removidos individualmente.

**Cards da lista mostram:**
- Número da OS (ex: `OS-2026001`)
- Badge de Status e Prioridade
- Nome do cliente
- Defeito relatado
- 🔧 Técnico responsável
- Data de entrada + tipo de ocorrência

**Estatísticas no topo:** Total · Abertas · Em Andamento · Concluídas · Urgentes

---

### Criar nova OS

Acesse por: **+ Nova OS** no dashboard, botão flutuante na lista, ou menu lateral.

**Seção 1 — Identificação do Chamado**

| Campo | Tipo | Obrigatório |
|---|---|---|
| Cliente | Dropdown | ✅ |
| Status | Botões | ✅ (padrão: Aberto) |
| Prioridade | Botões | ✅ (padrão: Baixa) |
| Tipo de Ocorrência | Dropdown | ❌ |
| Data de Entrada | Seletor de data | ✅ |
| Hora de Entrada | Seletor de hora | ❌ |
| Data de Saída | Seletor de data | ❌ |
| Técnico Responsável | Dropdown | ❌ |
| Acompanhou a Execução | Texto | ❌ |

**Status disponíveis:** Aberto · Em Andamento · Concluído · Cancelado

**Prioridades:** Baixa (verde) · Média (amarelo) · Urgente (vermelho)

**Tipos de Ocorrência:** Preventiva · Manutenção · Corretiva

---

**Seção 2 — Acessórios Recebidos**

Chips selecionáveis com opções padrão + campo "Outros acessórios" livre.

**Opções padrão:** Carregador · Capa · Caixa · Cabo USB · Fone de Ouvido · Bateria · Manual · Nota Fiscal · Outros

---

**Seção 3 — Equipamentos Vinculados**

Lista de equipamentos do cliente selecionado. Marcação por checkbox.

*Aparece apenas se o cliente tiver equipamentos cadastrados.*

---

**Seção 4 — Condição e Defeito**

| Campo | Descrição |
|---|---|
| Condições Físicas | Estado físico do equipamento ao receber |
| Defeito Relatado | Problema descrito pelo cliente |
| Status do Equipamento | Funcionando / Em Diagnóstico / Em Reparo / Ag. Retirada / Sem Conserto |

---

**Seção 5 — Checklist de Testes**

Lista de itens de verificação técnica padrão. Para cada item:
- Marcar como **feito** (clique no item)
- Registrar **data de verificação**
- Registrar **técnico verificador**

Barra de progresso mostra `X/Y concluídos`.

---

**Seção 6 — Laudo Técnico e Solução**

| Campo | Descrição |
|---|---|
| Laudo / Diagnóstico | Diagnóstico técnico completo |
| Solução Aplicada | O que foi feito para resolver |
| Peças Utilizadas | Materiais e peças trocadas |
| Termos e Observações | Observações adicionais |
| Descrição Geral | Descrição geral do atendimento |

---

**Seção 7 — Localização GPS**

- **CEP**: preenche logradouro, bairro, cidade e UF automaticamente (via ViaCEP)
- **Botão GPS**: captura coordenadas do dispositivo (latitude/longitude)
- Campos individuais editáveis: Logradouro · Número/Complemento · Bairro · Cidade · UF
- As coordenadas GPS aparecem destacadas em verde quando capturadas

---

**Seção 8 — Fotos**

- Adicionar fotos da câmera ou galeria
- Preview em grade
- Remover fotos individualmente
- Fotos offline ficam salvas localmente e sobem quando conectar

---

**Seção 9 — Assinaturas**

- **Assinatura do Cliente**: campo de desenho livre
- **Assinatura do Técnico**: campo de desenho livre
- Área branca com caneta preta
- Assinaturas offline são sincronizadas automaticamente

---

### Detalhe da OS

Tela completa com todos os dados da OS:

**Header:** Número · Cliente · Badges de Status e Prioridade

**Seções:**
- Datas e Responsável (data entrada/saída, hora, técnico, acompanhante)
- Acessórios Recebidos
- Detalhes do Serviço (defeito, laudo, solução, peças, termos)
- Checklist de Testes
- Localização GPS
- Fotos (galeria horizontal rolável)
- Assinaturas (exibição das imagens)

**Ações disponíveis (menu ⋮):**
- **Editar** — abre formulário de edição
- **Exportar Word (.docx)** — gera documento Word
- **Desativar** — remove a OS da lista (não deleta do banco)

**Botão PDF** (ícone na AppBar): gera e compartilha PDF diretamente.

---

### Editar OS

Mesmo formulário da criação, com campos pré-preenchidos. Funciona online e offline.

**Offline:** o técnico responsável aparece no dropdown mesmo se não estiver na lista de ativos (mantém o valor anterior).

---

## 7. Clientes

### Lista de Clientes

- Busca por nome, telefone ou e-mail
- Cada card mostra: avatar com inicial · nome · telefone · e-mail
- Toque no card para editar

### Cadastrar / Editar Cliente

**Dados do Cliente:**

| Campo | Obrigatório |
|---|---|
| Nome Completo | ✅ |
| Telefone | ❌ |
| E-mail | ❌ |

**Endereço:**

| Campo | Descrição |
|---|---|
| CEP | Auto-preenche os campos abaixo via ViaCEP |
| Logradouro | Rua/Avenida |
| Número / Complemento | Número e complemento |
| Bairro | Bairro |
| Cidade | Cidade |
| UF | Estado (2 letras) |

**Comportamento offline:** clientes criados offline ficam na fila de sincronização e são enviados automaticamente quando a internet voltar.

---

## 8. Equipamentos

### Lista de Equipamentos

- Filtro automático por cliente (ao acessar via OS)
- Busca por tipo, marca, modelo ou número de série
- Cards mostram: tipo · marca/modelo · número de série · cliente · cor/canal

### Cadastrar / Editar Equipamento

| Campo | Obrigatório |
|---|---|
| Tipo | ✅ |
| Marca | ✅ |
| Modelo | ✅ |
| Número de Série | ✅ |
| Cliente | ✅ |
| Cor de Identificação | ❌ |
| Canal / Frequência | ❌ |

---

## 9. Usuários (Admin)

**Acesso:** somente perfil Administrador.

### Lista de Usuários

**Cards mostram:**
- Avatar com inicial do nome
- Nome completo
- Badge de perfil (ADMIN / TECNICO / SUPERVISOR)
- E-mail
- Especialidade (se cadastrada)
- Badge Ativo/Inativo

**Estatísticas no topo:** Total · Admins · Técnicos · Ativos

**Ações por usuário:**
- ✏️ **Editar** — altera nome, perfil e especialidade
- 🔑 **Resetar senha** — define nova senha (mín. 6 caracteres)
- 🗑️ **Deletar** — remove o usuário permanentemente (não disponível para admins)
- **Switch** Ativo/Inativo — desativa sem deletar

**Busca:** por nome ou perfil.

### Criar Usuário

Campos obrigatórios:
- Nome Completo
- E-mail (não pode ser alterado depois)
- Senha (mín. 6 caracteres)
- Perfil: Técnico / Supervisor / Administrador
- Especialidade (opcional)

**Nota:** criação de usuários requer internet. O app mostra aviso claro se estiver offline.

### Perfis de usuário

| Perfil | Criar OS | Ver OS | Gerenciar Usuários | Relatórios |
|---|---|---|---|---|
| Técnico | ✅ | Próprias | ❌ | ✅ |
| Supervisor | ✅ | Todas | ❌ | ✅ |
| Administrador | ✅ | Todas | ✅ | ✅ |

---

## 10. Notificações

### Lista de Notificações

**Filtros:**
- Todas
- Não lidas
- Info
- Urgente
- Sucesso

**Estatísticas:** Total · Não lidas · Lidas

**Tipos de notificação e cores:**

| Tipo | Cor | Ícone |
|---|---|---|
| info | Ciano | ℹ️ |
| warning | Âmbar | ⚠️ |
| success | Verde | ✅ |
| urgente/danger | Vermelho | 🔥 |

**Ações:**
- Toque em uma notificação → marca como lida
- **Marcar todas como lidas** (botão na AppBar, aparece quando há não lidas)

**Offline:** notificações recentes (últimas 50) ficam no cache. Marcar como lida funciona offline e sincroniza depois.

---

## 11. Relatórios — PDF e Word

### Tela de Relatórios

Acesso: **Perfil → Relatórios / Gerar PDF** ou **Acesso Rápido → Relatórios**.

Lista todas as OS com botões para gerar:
- 🔴 **PDF** — formato profissional para compartilhar/imprimir
- 🔵 **Word (.docx)** — documento editável

Cada card mostra: número da OS · cliente · data · status · 🔧 técnico.

---

### Conteúdo do PDF gerado

O PDF segue o layout profissional do sistema. Inclui:

1. **Cabeçalho** — "GERENCIADOR DE OS PARA CAMPO" + número da OS
2. **Faixa de Status** — Status · Prioridade · Tipo de Ocorrência (colorida)
3. **Identificação da OS** — tabela com:
   - Nº OS, Status, Prioridade, Tipo de Ocorrência
   - Data de Entrada, Hora, Data de Saída
   - Cliente, Técnico Responsável, Acompanhou
   - Endereço/Local
4. **Acessórios Recebidos** — chips com nomes
5. **Laudo Técnico e Solução** — campos de texto formatados
6. **Checklist de Testes** — tabela com ✓/✗, datas e técnico verificador
7. **Localização GPS** — coordenadas e endereço
8. **Assinaturas** — imagem real das assinaturas (cliente e técnico)
9. **Rodapé** — "TECPOINT · SURVEY · Gerado em DD/MM/YYYY HH:MM"

---

### Conteúdo do Word (.docx) gerado

Mesmo conteúdo do PDF, em formato Word editável. Inclui:
- Cabeçalho verde com número da OS
- Todas as seções em tabelas formatadas
- Imagens reais das assinaturas embutidas
- Rodapé com data/hora de geração

**Compatível com:** Microsoft Word, LibreOffice Writer, Google Docs.

---

### Compartilhar o arquivo

Após gerar, o app abre o menu padrão do Android para:
- WhatsApp, Telegram, E-mail, Google Drive, Bluetooth, etc.

---

## 12. Perfil e Configurações

### Tela de Perfil

Exibe:
- Avatar com inicial do nome
- Nome completo
- E-mail
- Badge de perfil

**Menu Sistema:**
- **Notificações** — acesso direto
- **Gerenciar Usuários** — somente Admin
- **Relatórios / Gerar PDF** — acesso direto
- **Sincronizar dados offline** — força sincronização manual imediata
- **Versão do app** — 1.0.0

**Menu Conta:**
- **Sair do aplicativo** — encerra a sessão com confirmação

### Logout

Ao tocar em "Sair":
1. Dialog de confirmação aparece
2. Ao confirmar: sessão encerrada, app vai para tela de login
3. **Os dados offline permanecem salvos** — o usuário pode logar offline novamente

**Importante:** o logout NÃO apaga as credenciais offline das outras contas salvas no dispositivo.

---

## 13. Sincronização Automática

### Como funciona

O `SyncService` gerencia toda a sincronização em background:

**Disparadores de sync:**
1. **Ao abrir o app** — sync imediato se houver internet
2. **Quando a internet volta** — detectado automaticamente
3. **A cada 15 minutos** — enquanto o app está aberto
4. **Em background** — via WorkManager (mesmo com app fechado)

### Fila de sincronização

Dados criados/editados offline entram em uma fila (SQLite `sync_queue`). Ao conectar, são enviados ao servidor na ordem de criação.

**O que é sincronizado:**
- OS criadas offline → INSERT no Supabase
- OS editadas offline → UPDATE no Supabase
- Clientes criados/editados offline → INSERT/UPDATE
- Equipamentos → INSERT/UPDATE
- Notificações marcadas como lidas → UPDATE
- Fotos pendentes → upload para Storage

### Sync manual

**Perfil → Sincronizar dados offline** — executa imediatamente e mostra "Sincronização concluída" ao terminar.

### Banner de sync

Enquanto offline, o banner laranja no topo indica que dados estão sendo salvos localmente. Desaparece automaticamente quando a internet volta.

---

## 14. Permissões do Aplicativo

| Permissão | Para que serve | Quando solicitada |
|---|---|---|
| **Câmera** | Tirar fotos para a OS | Ao adicionar foto pela câmera |
| **Galeria** | Selecionar fotos existentes | Ao adicionar foto da galeria |
| **Localização** | Capturar GPS na OS | Ao tocar no botão "GPS" |
| **Internet** | Sincronização e login online | Automático |
| **Armazenamento** | Salvar PDF/Word gerado | Ao gerar relatório |

**Se a permissão de localização for negada:** o app exibe a mensagem "Permissão de localização negada" e o GPS não é capturado. Os outros campos continuam funcionando.

---

## 15. Perfis de Acesso

### Técnico
- Criar e visualizar OS
- Editar clientes e equipamentos
- Visualizar e marcar notificações
- Gerar PDF/Word das OS
- Editar próprio perfil
- **NÃO pode:** gerenciar usuários

### Supervisor
- Tudo que o Técnico pode
- Visualizar todas as OS do sistema
- **NÃO pode:** gerenciar usuários

### Administrador
- Tudo que o Supervisor pode
- **Gerenciar usuários:** criar, editar, resetar senha, deletar, ativar/desativar
- Visualizar tela de Usuários
- **Não pode ser deletado** pelo app (proteção de segurança)

---

## 16. Referência Técnica

### Tecnologias utilizadas

| Componente | Tecnologia |
|---|---|
| Framework | Flutter (Dart) |
| Banco de dados online | Supabase (PostgreSQL) |
| Banco de dados offline | SQLite (sqflite) |
| Autenticação | Supabase Auth + SHA-256 offline |
| Armazenamento de fotos | Supabase Storage |
| Funções do servidor | Supabase Edge Functions (Deno) |
| Sync em background | WorkManager (Android) |
| Credenciais offline | FlutterSecureStorage |
| Geração de PDF | package:pdf |
| Geração de Word | package:archive (DOCX manual) |
| Cache de imagens | CachedNetworkImage |
| GPS | Geolocator |
| Busca de CEP | ViaCEP API |

### Estrutura do banco SQLite local

| Tabela | Conteúdo |
|---|---|
| `clientes` | Dados completos dos clientes |
| `equipamentos` | Equipamentos e vínculo com cliente |
| `ordens_servico` | OS completas com todos os campos |
| `profiles` | Usuários/técnicos para uso offline |
| `os_checklist_local` | Itens do checklist por OS |
| `os_acessorio_local` | Acessórios por OS |
| `os_assinatura_local` | Assinaturas em base64 |
| `os_equipamento_local` | Relação OS ↔ Equipamentos |
| `fotos_pendentes` | Fotos aguardando upload |
| `notificacoes_local` | Cache de notificações |
| `sync_queue` | Fila de operações offline |

### Versão do banco de dados
**v8** — evoluiu de v1 a v8 com migrações automáticas.

### Segurança
- Senhas nunca armazenadas em texto claro — apenas hash SHA-256
- Credenciais offline em `FlutterSecureStorage` (criptografado pelo sistema)
- Operações admin protegidas por Supabase Edge Functions com JWT
- Máximo de 10 contas offline por dispositivo (LRU eviction)
- Administradores não podem ser deletados pelo app

### Numeração de OS
- Gerada pelo servidor via função SQL `gerar_numero_os()`
- Formato online: sequencial (ex: `OS-2026001`)
- Formato offline (fallback): `OS-AAAAMMDD-XXXXX` (timestamp parcial)

### Tamanho do APK
~65 MB (release com tree-shaking de ícones)

---

## SOLUÇÃO DE PROBLEMAS

### App não abre / tela preta
- Aguarde a splash screen (2,6 segundos)
- Reinicie o aplicativo

### Login falha mesmo com senha correta
- Verifique se está com internet
- Confirme o e-mail cadastrado
- Contate o administrador para verificar se a conta está ativa

### Dados não aparecem offline
- O usuário precisa ter acessado a tela pelo menos uma vez com internet
- Os dados são cacheados no primeiro acesso online

### Foto não aparece / ícone de sync
- A foto foi salva localmente
- Conecte à internet — ela sobe automaticamente

### Técnico não aparece no card da OS offline
- Acesse as OS com internet pelo menos uma vez para popular o cache
- O sistema enriquece automaticamente o nome do técnico a partir do cache de perfis

### Sincronização não está funcionando
- Perfil → Sincronizar dados offline (manual)
- Verifique a conexão com a internet
- O WorkManager sincroniza em background a cada 15 minutos

### PDF gerado sem assinatura
- A assinatura precisa ter sido coletada na OS
- Offline: a assinatura aparece na tela de detalhe mas o PDF usa os dados da OS atual

---

*TECPOINT v1.0.0 · Desenvolvido para UniSENAI MT · 2026*
*Todos os direitos reservados.*
