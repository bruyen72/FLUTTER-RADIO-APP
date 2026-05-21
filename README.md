# TECPOINT - Gerenciador de OS para Campo

Aplicativo mobile em Flutter para gerenciamento de Ordens de Servico da TECPOINT.
O app foi criado para tecnicos em campo registrarem atendimentos, clientes,
equipamentos, laudos, fotos, localizacao, assinaturas e documentos gerados em
PDF/Word, com funcionamento offline e sincronizacao posterior com Supabase.

## Recursos principais

- Login com Supabase Auth e suporte a credenciais offline.
- Cadastro e consulta de clientes, equipamentos, usuarios e Ordens de Servico.
- Fluxo completo de OS com status, prioridade, tipo de ocorrencia, checklist,
  acessorios, defeito relatado, laudo tecnico, solucao aplicada e pecas usadas.
- Captura de fotos, assinatura digital e localizacao GPS.
- Armazenamento local com SQLite para uso sem internet.
- Fila de sincronizacao para enviar dados pendentes quando a conexao voltar.
- Exportacao/compartilhamento de OS em PDF e Word.
- Edge Functions do Supabase para criacao de usuarios e reset de senha.

## Tecnologias

- Flutter 3 / Dart
- Supabase Auth, Database, Storage e Edge Functions
- SQLite local com `sqflite`
- `connectivity_plus`, `workmanager`, `image_picker`, `geolocator`
- Geracao de documentos com `pdf`, `printing` e `archive`

## Como executar

```bash
flutter pub get
flutter test
flutter run
```

## Validacao local

Em 21/05/2026:

- `flutter test` passou.
- `flutter analyze` executou e retornou apenas avisos de lint/depreciacao,
  sem erros bloqueantes.

## Observacao de seguranca

Nao publique chaves privadas do Supabase. A chave `anon` usada pelo app cliente
e publica, mas `service_role`, tokens `sbp_` e credenciais pessoais devem ficar
fora do GitHub.
