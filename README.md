# StorePro

StorePro has a responsive React website and an Expo React Native phone app. Both clients use the same Firebase Authentication and Cloud Firestore project and the same `stores/{ownerUid}` data structure.

## Project layout

```text
apps/
  web/       React + Vite website
  mobile/    Expo + React Native app
firebase.json
firestore.rules
.firebaserc
package.json
```

The clients have separate user interfaces because browsers and native phones use different UI runtimes; they share Firebase Authentication and Firestore. Keeping both under `apps/` is a standard monorepo layout.

## Run the website

```powershell
npm run web:install
npm run web:dev
```

Vite prints the local address, usually `http://localhost:5173`.

## Run on a phone

```powershell
npm run mobile:install
npm run mobile:start
```

Open Expo Go and scan the QR code. Keep the phone and computer on the same Wi-Fi network. If local network discovery is blocked, run `npx expo start --tunnel` from `apps/mobile`.

## Firebase setup and deployment

The configured Firebase project is `storepro-55dd4`. Enable Email/Password in Firebase Authentication and add the deployed website domain to Authorized domains. Firestore records are scoped under each signed-in owner's UID.

Build and deploy the website plus Firestore rules from the repository root:

```powershell
npm run deploy:web
```

This runs the production Vite build, then `firebase deploy --only hosting,firestore:rules`. To build the website without deploying, run `npm run web:build`.

The phone app runs in Expo Go during development. For Android distribution, first associate the project with your Expo account from `apps/mobile` using `npx eas-cli@latest build:configure`; then use `npm run mobile:preview:android` for an installable APK or `npm run mobile:build:android` for a Google Play App Bundle.

## Store and employee access

Sign in with the store owner's email. Employees are in-store work identities for recording sales and stock activity; they do not have separate Firebase login accounts.


