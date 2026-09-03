# PadelHub — o Strava do Padel

Plataforma de marcação de placares, ranking ELO e rede social para a comunidade de padel, inspirada no modelo do Strava (rastreamento + rede social + competição) adaptado para um esporte de quadra jogado em duplas.

Ver o conceito completo em `docs/concept.pdf` (anexado pelo usuário) — placar em <30s, validação cruzada anti-fraude, ranking ELO/UTR, patentes dinâmicas e badges colecionáveis.

## Design

O design visual (login, feed, registro de partida, ranking, perfil e arena, mobile + breakpoint desktop) foi criado com o Claude Design e está publicado como um canvas interativo — peça o link ao assistente que gerou esta sessão caso precise reabri-lo. A fonte editável de cada tela vive em `design/*.dc.html` + `design/canvas.json`; o bundle selado (`design/padelhub-design.html`, ~2 MB, gerado a partir dessas fontes) não é versionado — regenere-o com o `seed-canvas.mjs` do skill "design" se precisar dele localmente.

Paleta: verde-petróleo escuro + laranja vibrante (bola de padel). Tipografia: Space Grotesk (títulos/estatísticas) + Manrope (texto).

## Arquitetura

```
Flutter Web (app/)              Firebase Auth           Cloud Functions (backend/)        Cloud SQL
┌─────────────────────┐         ┌───────────┐           ┌─────────────────────────┐      ┌──────────────┐
│ UI + navegação        │──────▶│ email/senha│           │ Express API              │─────▶│ PostgreSQL    │
│ (go_router, riverpod) │        │ Google     │──ID token▶│ valida token, calcula    │      │ (relacional:  │
│                       │◀───────│           │           │ ELO, aplica regras       │◀─────│ ranking, sets,│
└──────────┬────────────┘        └───────────┘           └─────────────────────────┘      │ confirmações) │
           │ HTTPS (Bearer <ID token>)                                                     └──────────────┘
           └──────────────────────────────────────────────────────────────────────────────────────▶
```

- **Frontend — Flutter Web** (`app/`): único cliente, roda no navegador. Não fala com o Postgres diretamente — só com a API.
- **Autenticação — Firebase Auth**: e-mail/senha e Google Sign-In. O client Flutter manda o ID token do Firebase em cada chamada à API (`Authorization: Bearer <token>`).
- **API — Firebase Cloud Functions** (`backend/`, Express + TypeScript): a única camada com acesso ao banco. Verifica o token com `firebase-admin`, roda as regras de negócio (validação cruzada de placar, cálculo de ELO, patentes) e fala com o Postgres via [Cloud SQL Node.js Connector](https://github.com/GoogleCloudPlatform/cloud-sql-nodejs-connector) (sem IP público).
- **Banco de dados — Cloud SQL (PostgreSQL)**, não Firestore: o núcleo do produto é ranking/leaderboard com joins, agregações e integridade transacional (placar → confirmação → atualização de rating em uma transação) — modelo relacional se encaixa melhor que documentos.
- **Firebase Hosting** serve o build web do Flutter e faz rewrite de `/api/**` para a Cloud Function.

### Por que Firebase *e* Cloud SQL?

Firebase é o "hub" — autenticação, hosting e as próprias Cloud Functions. Cloud SQL é o banco de registro para tudo que é relacional por natureza (partidas, sets, confirmações, histórico de rating, ranking por cidade/clube/amigos). Isso evita duplicar/desnormalizar dados de ranking em Firestore, que não é bom em `ORDER BY rating DESC` com filtros combinados.

## Estrutura do repositório

```
app/       Flutter Web (login, feed, registrar partida, ranking, perfil, arena)
backend/   Cloud Functions (TypeScript) — API REST + regras de negócio
  sql/     schema.sql (DDL) e seed.sql (dados de exemplo, iguais ao design)
design/    Fonte do canvas de design (Claude Design) — .dc.html + canvas.json
firebase.json, .firebaserc   Config do projeto Firebase (hosting + functions)
```

## Modelo de dados (Cloud SQL)

`arenas`, `users`, `matches`, `match_sets`, `match_players`, `match_confirmations`, `rating_history`, `player_badges`, `kudos`, `comments`, `court_sessions`. Ver `backend/sql/schema.sql` para o DDL completo com índices e constraints.

## Ranking ELO

`backend/src/services/elo.ts` implementa ELO para duplas: o rating do time é a média dos dois jogadores; o delta (`K=32 × (resultado real − resultado esperado)`) é aplicado igualmente aos dois jogadores do time. Isso implementa a regra do conceito: vencer uma dupla muito mais forte concede pontuação alta; perder para ela custa pouco.

O rating só é atualizado quando a partida passa de `pending_confirmation` para `confirmed` — ou seja, depois que **pelo menos um adversário confirma o placar** (`POST /matches/:id/confirm`), a validação cruzada anti-fraude do conceito original.

## Rodando localmente

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable)
- Node.js 20+
- Um projeto Firebase (Console → criar projeto) com **Authentication** (ative os provedores E-mail/senha e Google) e **Cloud Functions** habilitados
- Uma instância Cloud SQL for PostgreSQL (ou Postgres local para dev)
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup): `dart pub global activate flutterfire_cli`

### 1. Configurar Firebase no app Flutter
```bash
firebase login
flutterfire configure --project=<seu-projeto-firebase>
```
Isso regenera `app/lib/firebase_options.dart` com as chaves reais (o arquivo no repo é um placeholder).

### 2. Banco de dados
```bash
# Local (Postgres via Docker, por exemplo):
createdb padelhub
psql "$DATABASE_URL" -f backend/sql/schema.sql
psql "$DATABASE_URL" -f backend/sql/seed.sql   # dados de exemplo (opcional)
```
Em produção, crie a instância Cloud SQL, o banco `padelhub` e um usuário de app (ex. `padelhub_api`) — pelo Cloud SQL Studio no Console, sem precisar de `psql` local. Depois configure, na raiz de `backend/`:
- `INSTANCE_CONNECTION_NAME`, `DB_USER`, `DB_NAME` — não são segredos, vão em `backend/.env.<project-id>` (ex. `backend/.env.padelhub-prod`), formato `CHAVE=valor` por linha. O Firebase carrega esse arquivo automaticamente no deploy; **não commite** o arquivo com valores reais.
- `DB_PASSWORD` — é segredo, vai pelo Secret Manager: `firebase functions:secrets:set DB_PASSWORD` (cola a senha quando pedir). `backend/src/index.ts` já declara `secrets: ['DB_PASSWORD']` na function, então o valor chega em `process.env.DB_PASSWORD` em runtime sem precisar tocar em código.

### 3. Backend (Cloud Functions)
```bash
cd backend
cp .env.example .env   # ajuste DATABASE_URL para seu Postgres local
npm install
npm run serve          # sobe o emulador de Functions em localhost
```

### 4. App Flutter Web
```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5001/<projeto>/southamerica-east1/api
```

### Deploy
```bash
cd app && flutter build web
cd .. && firebase deploy --only hosting,functions
```

## O que ainda falta (próximos passos)

- Busca/autocomplete de jogadores no fluxo de registrar partida (hoje é um campo de texto simples)
- Grafo de amigos/seguidores (o filtro "Amigos" do ranking hoje cai para "Cidade")
- Upload de foto pós-jogo (Firebase Storage)
- Regras automáticas de desbloqueio de badges (Pneu Furado, Nômade do Padel, Inimigo do Erro) — hoje só a tabela existe, falta o job/trigger que os concede
- Fluxo de torneios e formato "Americano" (troca de duplas por set)
- Integração com smartwatches (distância, passos, frequência cardíaca)
- Notificações push (confirmação de placar pendente, kudos, etc.)
