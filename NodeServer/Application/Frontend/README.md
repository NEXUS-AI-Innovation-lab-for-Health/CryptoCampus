# CryptoCampus Frontend - Vue.js

Modern SPA (Single Page Application) built with Vue 3 and Vite.

## Setup

### Install dependencies
```bash
npm install
```

### Development
```bash
npm run dev
```

The dev server will run at `http://localhost:5173` with proxy to `http://localhost:3000/api`

### Build
```bash
npm run build
```

This creates a production build in the `dist` folder. The backend Express server will serve this folder.

## Project Structure

```
src/
  ├── pages/          # Page components (Home, Login, Balance, Shop, etc.)
  ├── App.vue         # Root component with navbar and router-view
  ├── main.js         # Entry point
  ├── router.js       # Vue Router configuration
  └── style.css       # Global styles
```

## Features

- **Vue 3 Composition API** - Modern reactive components
- **Vue Router** - Client-side routing
- **Vite** - Fast development and production builds
- **API Integration** - Communicates with Express backend
- **Responsive Design** - Mobile-friendly UI
- **Authentication** - Session-based auth with Express backend

## Building for Production

1. Run `npm run build` in the Frontend directory
2. The backend will serve the `dist` folder automatically when accessing `http://localhost:3000`

## API Endpoints

The Vue app communicates with these API endpoints:

- `POST /api/login` - User login
- `POST /api/logout` - User logout
- `POST /api/register` - User registration
- `GET /api/check-auth` - Check authentication status
- `GET /api/balance` - Get user balance
- `GET /api/requests` - Get help requests
- `GET /api/shop` - Get shop products
- `POST /api/create-request` - Create help request
- `POST /api/purchase` - Purchase from shop
