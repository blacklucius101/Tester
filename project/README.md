# Headless Frontend Template

A Next.js 14 frontend template with authentication, file upload, and dashboard features. This template is designed to work seamlessly with the JustCopy backend API.

## Features

- Next.js 14 with App Router
- TypeScript
- TailwindCSS for styling
- Authentication with JWT tokens
- File upload functionality
- Responsive dashboard
- API integration with backend
- Modern UI components with Framer Motion

## Project Structure

```
headless-frontend/
├── app/
│   ├── components/
│   │   ├── AuthModal.tsx      # Authentication modal component
│   │   ├── Dashboard.tsx      # Main dashboard component
│   │   └── FileUpload.tsx     # File upload component
│   ├── files/
│   │   └── page.tsx           # Files page
│   ├── api/
│   │   └── health/
│   │       └── route.ts       # Health check endpoint
│   ├── lib/
│   │   └── api.ts             # API client for backend communication
│   ├── layout.tsx             # Root layout
│   ├── page.tsx               # Home page
│   └── globals.css            # Global styles
├── lib/
│   ├── auth/                  # Authentication library
│   └── database/              # Database library
├── .env.example               # Environment variables template
├── package.json               # Dependencies and scripts
├── tailwind.config.js         # Tailwind configuration
├── tsconfig.json              # TypeScript configuration
└── next.config.js             # Next.js configuration

```

## Getting Started

### Prerequisites

- Node.js 18.x or higher
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create environment file:
```bash
cp .env.example .env.local
```

3. Update the `.env.local` file with your backend API URL:
```
NEXT_PUBLIC_API_URL=http://localhost:3001
```

### Development

Run the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Production

Build for production:

```bash
npm run build
```

Start the production server:

```bash
npm start
```

## Environment Variables

- `NEXT_PUBLIC_API_URL` - Backend API URL (default: `http://localhost:3001`)

## API Integration

The template includes an API client (`app/lib/api.ts`) that handles:

- JWT token management
- Automatic token refresh
- API request/response handling
- Error handling

Example usage:

```typescript
import { apiClient } from './lib/api';

// Login
const response = await apiClient.login(email, password);

// Make authenticated requests
const data = await apiClient.get('/protected-endpoint');
```

## Components

### AuthModal
Modal component for user authentication (login/signup).

### Dashboard
Main dashboard component displaying user information and navigation.

### FileUpload
Component for uploading files to the backend.

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint

## Tech Stack

- **Framework**: Next.js 14
- **Language**: TypeScript
- **Styling**: TailwindCSS
- **HTTP Client**: Axios
- **Animation**: Framer Motion
- **Icons**: Lucide React

## License

This template is part of the JustCopy project.
