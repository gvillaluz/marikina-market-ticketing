# Marikina City Regulatory Ticketing System — Frontend

A feature-based React + TypeScript + Vite frontend for the Marikina City regulatory ticketing system. Manages business tickets, vendor registrations, penalties, and compliance scores.

> **Note:** This is the **frontend only**. The ASP.NET backend is being built by teammates. This app runs fully on **mock data** so it works immediately without a backend.

## Tech Stack

- **React 18** + **TypeScript**
- **Vite** for build tooling
- **React Router v6** for routing & role-based guards
- **Zustand** for auth state (persisted to localStorage)
- **Axios** for the API layer (interceptors for JWT)
- **qrcode.react** for QR code generation
- **CSS Modules** for component styling

## Getting Started

```bash
npm install
npm run dev
```

Open the preview URL (default `http://localhost:5173`).

## Demo Accounts

| Role  | Email                  | Password   |
|-------|------------------------|------------|
| Admin | admin@marikina.gov.ph  | admin123   |
| Vendor| vendor@marikina.gov.ph | vendor123  |

## Project Structure

```
src/
├── api/            # API layer (client, endpoints, types, mock adapters)
├── assets/         # Images, icons, fonts
├── components/     # Reusable UI (ui, layout, feedback)
├── features/       # Feature modules (auth, tickets, vendors, penalties, compliance, dashboard)
├── hooks/          # Global hooks (useDebounce, usePagination, useLocalStorage)
├── context/        # React context (Auth, Theme)
├── store/          # Zustand global state
├── routes/         # Routing & guards
├── utils/          # Formatters, validators, constants
├── styles/         # Global styles & theme
├── config/         # Environment config
├── App.tsx
└── main.tsx
```

## Connecting the Real Backend

When the ASP.NET backend is ready, update `src/config/env.ts`:

```ts
export default {
  apiBaseUrl: 'https://your-backend-url/api',
  useMocks: false, // switch to real API calls
};
```

The API layer (`src/api/endpoints/*.api.ts`) already contains the axios calls mapped to the backend routes. The mock adapter (`src/api/mock/mockAdapter.ts`) mirrors those methods so the swap is seamless.

## Scripts

- `npm run dev` — start dev server
- `npm run build` — type-check & production build
- `npm run preview` — preview production build
