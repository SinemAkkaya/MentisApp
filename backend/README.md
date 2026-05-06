# Mentis Backend

Node.js + Express + Prisma + PostgreSQL (Supabase) backend for the Mentis
mobile therapy application.

## Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **ORM**: Prisma
- **Database**: PostgreSQL (Supabase)
- **Auth**: JWT (jsonwebtoken)
- **NLP**: Mentis Insight Engine — kendi yazdığımız Türkçe duygu / risk / kelime
  frekansı analizi (lexicon tabanlı, harici LLM çağrısı YOK).

## Run locally

```bash
cd backend
cp .env.example .env
# .env dosyasını DATABASE_URL ile doldur

npm install
npx prisma migrate dev --name init
npm run dev
```

Server `http://localhost:3000` adresinde çalışır.

## API Endpoints

### Auth
- `POST /auth/therapist/login` — { name, password } → token
- `POST /auth/client/login` — { username, password } → token

### Clients (therapist only)
- `GET    /clients`
- `POST   /clients` — { name, username, password }
- `DELETE /clients/:id`

### Journals
- `POST /journals` (client) — { content, mood, dayOfWeek, date }
- `GET  /journals?clientId=&limit=` (client/therapist)

### Appointments
- `POST  /appointments` (client) — { timeSlot, dayOfWeek, note }
- `GET   /appointments?dayOfWeek=`
- `PATCH /appointments/:id/confirm` (therapist)

### Insight (Mentis Score)
- `POST /insight` (therapist) — { clientId?, limit? }
  - Yerel motor; harici servis çağırmaz.
  - Döner: `{ mentisScore, sentiment, risk, topWords, recommendation }`

## Deploy

Render veya Railway free tier üzerinden GitHub push ile deploy edilir.
DATABASE_URL, JWT_SECRET, THERAPIST_MASTER_PASSWORD environment
variable olarak ayarlanır.
