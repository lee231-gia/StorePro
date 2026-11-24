# StorePro mobile

StorePro's Expo and React Native app lives here. It signs into the same Firebase Authentication project and reads and writes the same `stores/{ownerUid}` Firestore records as the web client in `../web`.

## Run on a phone with Expo Go

From the repository root:

```powershell
npm run mobile:install
npm run mobile:start
```

Install Expo Go on the phone and scan the QR code shown in the terminal. Keep both devices on the same Wi-Fi network. If the network blocks device discovery, run this from the repository root:

```powershell
cd apps/mobile
npx expo start --tunnel
```

## Build an Android app

For an installable test APK:

```powershell
npm run mobile:preview:android
```

For a Google Play-ready Android App Bundle:

```powershell
npm run mobile:build:android
```

The first EAS build requires an Expo account and project association. From `apps/mobile`, run `npx eas-cli@latest build:configure` once and sign in when prompted. The existing Android application id is `com.storepro.mobile`. EAS handles the cloud build and signing setup; the production profile uses a Play Store App Bundle, while preview produces an installable APK.
