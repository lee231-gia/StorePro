import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'AIzaSyC10T8pl7U8w14C73wdcZg_Gsjoxy-USnI',
  appId: '1:1078476335702:web:3ad936cad37eb7cdc829f7',
  authDomain: 'storepro-55dd4.firebaseapp.com',
  projectId: 'storepro-55dd4',
  storageBucket: 'storepro-55dd4.firebasestorage.app',
  messagingSenderId: '1078476335702',
  measurementId: 'G-GJJP2TLCKX',
};

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

