# SmartPaw Backend

## Requirements

- Node.js 18+

## Setup

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Install dependencies:

```bash
npm install
```

## Run

Dev (auto-reload):

```bash
npm run dev
```

Production:

```bash
npm start
```

## Health check

- `GET /health` -> `{ "ok": true }`

