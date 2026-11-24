import AsyncStorage from '@react-native-async-storage/async-storage';
import { getApp, getApps, initializeApp } from 'firebase/app';
import { getAuth, getReactNativePersistence, initializeAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { Platform } from 'react-native';

const firebaseConfig = {
  apiKey: 'AIzaSyC10T8pl7U8w14C73wdcZg_Gsjoxy-USnI',
  appId: '1:1078476335702:web:3ad936cad37eb7cdc829f7',
  authDomain: 'storepro-55dd4.firebaseapp.com',
  projectId: 'storepro-55dd4',
  storageBucket: 'storepro-55dd4.firebasestorage.app',
  messagingSenderId: '1078476335702',
  measurementId: 'G-GJJP2TLCKX',
};

export const app = getApps().length ? getApp() : initializeApp(firebaseConfig);

let authInstance;
if (Platform.OS === 'web') {
  authInstance = getAuth(app);
} else {
  try {
    authInstance = initializeAuth(app, { persistence: getReactNativePersistence(AsyncStorage) });
  } catch {
    // Keep Fast Refresh from failing after Firebase Auth was initialized once.
    authInstance = getAuth(app);
  }
}

export const auth = authInstance;
export const db = getFirestore(app);
