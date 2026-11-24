import { createUserWithEmailAndPassword, deleteUser, signOut } from 'firebase/auth';
import { doc, setDoc } from 'firebase/firestore';
import { auth } from '../firebaseClient.js';
import { db } from '../firestoreClient.js';

export async function registerStoreAccount({ email, password, firstName, lastName, username, storeName }) {
  const normalizedEmail = email.trim().toLowerCase();
  const normalizedUsername = username.trim().toLowerCase();
  const credential = await createUserWithEmailAndPassword(auth, normalizedEmail, password);
  const uid = credential.user.uid;
  const createdAt = new Date().toISOString();
  const profile = {
    id: uid,
    email: normalizedEmail,
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    username: normalizedUsername,
    storeName: storeName.trim() || 'My Store',
    avatarColorIndex: '0',
    securityQuestion: '',
    securityAnswerHash: '',
    otpCode: '',
    otpExpiresAt: '',
    trackActivity: true,
    notificationsEnabled: true,
    employeeFeature: true,
    lowStockThreshold: 12,
    currency: 'PHP',
    createdAt,
  };

  try {
    await setDoc(doc(db, 'stores', uid), profile);
  } catch (error) {
    try {
      await deleteUser(credential.user);
    } catch {
      await signOut(auth);
      throw new Error('Firebase created the account, but could not save its store profile. Contact your Firebase administrator before trying again.');
    }
    throw error;
  }

  return credential.user;
}
