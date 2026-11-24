import { getFirestore, initializeFirestore, persistentLocalCache, persistentMultipleTabManager } from 'firebase/firestore';
import { app } from './firebaseClient.js';

let firestore;
try {
  firestore = initializeFirestore(app, {
    localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
  });
} catch {
  // Keep StorePro usable in private browsing and browsers without IndexedDB.
  firestore = getFirestore(app);
}

export const db = firestore;
