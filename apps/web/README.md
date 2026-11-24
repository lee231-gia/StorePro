# StorePro Web

Responsive React website for StorePro. This client uses the Firebase Authentication and Firestore project shared with the Expo app in `../mobile`.

## Start locally

```powershell
npm ci
npm run dev
```

Vite prints the local URL, usually `http://localhost:5173`.

## Production build

```powershell
npm run build
npm run preview
```

The build is written to `dist/`. Firebase Hosting is configured from the repository root to serve `apps/web/dist` and route application paths back to `index.html`.

The sign-in page supports existing owner accounts, new store registration, and email password resets. Firestore records remain in the existing `stores/{uid}` structure.
