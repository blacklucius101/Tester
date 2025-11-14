# Next.js 14 Headless Frontend Template

## Tech Stack
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: TailwindCSS
- **Animation**: Framer Motion
- **HTTP**: Axios
- **Icons**: Lucide React

## File Structure
```
app/
├── components/
│   ├── AuthModal.tsx       # Login/signup modal with JWT
│   ├── Dashboard.tsx       # User dashboard layout
│   └── FileUpload.tsx      # S3 file upload component
├── files/
│   └── page.tsx            # Files management page
├── lib/
│   └── api.ts              # API client (JWT, auth, requests)
├── layout.tsx              # Root layout with providers
├── page.tsx                # Home/landing page
└── globals.css             # Global styles + Tailwind

lib/
├── auth/                   # Auth utilities
└── database/               # JustCopyDB/Drizzle client

.env.example                # NEXT_PUBLIC_API_URL
package.json                # Dependencies
```

## What's Pre-Built
- **Authentication**: JWT-based auth with token refresh
- **API Client**: `app/lib/api.ts` - handles all backend requests
- **Components**: Modal, Dashboard, File Upload
- **Styling**: TailwindCSS configured, dark mode ready
- **Database**: JustCopyDB integration ready

## API Client Usage
```typescript
import { apiClient } from './lib/api';

// Login (stores JWT automatically)
await apiClient.login(email, password);

// Authenticated requests
const data = await apiClient.get('/endpoint');
await apiClient.post('/endpoint', { data });
```

## Philosophy
**REUSE → EXTEND → CREATE**
1. Use existing components (AuthModal, Dashboard, FileUpload)
2. Extend components when close match exists
3. Create new components only when necessary

## Best For
Todo apps, dashboards, admin panels, content management, file managers, user portals

## Not Included
- Backend API (use separate template)
- Real-time features (WebSockets)
- Complex state management (Redux, Zustand)
- Server-side auth (use JWT flow)

## Quick Start
1. Clone template to project
2. Update `.env.local` with API URL
3. Reuse `app/components/` for UI
4. Extend `app/lib/api.ts` for new endpoints
5. Add new pages in `app/[page-name]/page.tsx`

## Key Patterns
- **New Page**: Create `app/[name]/page.tsx`
- **New Component**: Add to `app/components/[Name].tsx`
- **API Call**: Use `apiClient.get/post/put/delete`
- **Auth**: Components auto-access auth state via API client
