import React from 'react';
import { browserLocalPersistence, sendPasswordResetEmail, setPersistence, signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebaseClient.js';
import { registerStoreAccount } from '../data/authRepository.js';
import Icon from '../components/Icon.jsx';
import { Button, TextField } from '../components/UI.jsx';

const initialRegistration = {
  firstName: '',
  lastName: '',
  storeName: '',
  username: '',
  email: '',
  password: '',
  confirmPassword: '',
};

function authMessage(error) {
  const messages = {
    'auth/invalid-email': 'Enter a valid email address.',
    'auth/invalid-credential': 'That email and password do not match a StorePro account.',
    'auth/email-already-in-use': 'An account already uses this email address. Try signing in.',
    'auth/weak-password': 'Use a password with at least 6 characters.',
    'auth/operation-not-allowed': 'Email sign-in is not enabled for this Firebase project.',
    'auth/too-many-requests': 'There were too many attempts. Wait a little and try again.',
    'auth/unauthorized-domain': 'This website address is not enabled in Firebase Authentication. Add it to the authorized domains list.',
    'auth/network-request-failed': 'Could not reach Firebase. Check your internet connection.',
    'permission-denied': 'Firebase blocked the store profile write. Check Firestore rules for the signed-in account.',
  };
  return messages[error?.code] || error?.message || 'Could not connect to your StorePro account.';
}

function validateRegistration(form) {
  if (!form.firstName.trim() || !form.lastName.trim()) return 'Enter your first and last name.';
  if (!/^[a-z0-9._-]{3,32}$/i.test(form.username.trim())) return 'Use 3–32 letters, numbers, dots, underscores, or hyphens for your username.';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) return 'Enter a valid email address.';
  if (form.password.length < 6) return 'Use a password with at least 6 characters.';
  if (form.password !== form.confirmPassword) return 'The passwords do not match.';
  return '';
}

export default function AuthPage() {
  const [mode, setMode] = React.useState('signin');
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [registration, setRegistration] = React.useState(initialRegistration);
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState('');
  const [success, setSuccess] = React.useState('');

  const changeMode = (nextMode) => {
    setMode(nextMode);
    setError('');
    setSuccess('');
  };

  const signIn = async (event) => {
    event.preventDefault();
    setError('');
    setSuccess('');
    setBusy(true);
    try {
      await setPersistence(auth, browserLocalPersistence);
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (reason) {
      setError(authMessage(reason));
    } finally {
      setBusy(false);
    }
  };

  const signUp = async (event) => {
    event.preventDefault();
    setError('');
    setSuccess('');
    const validationError = validateRegistration(registration);
    if (validationError) {
      setError(validationError);
      return;
    }

    setBusy(true);
    try {
      await setPersistence(auth, browserLocalPersistence);
      await registerStoreAccount(registration);
    } catch (reason) {
      setError(authMessage(reason));
    } finally {
      setBusy(false);
    }
  };

  const resetPassword = async (event) => {
    event.preventDefault();
    setError('');
    setSuccess('');
    setBusy(true);
    try {
      await sendPasswordResetEmail(auth, email.trim());
      setSuccess('If this email belongs to a StorePro account, a password reset link has been sent.');
    } catch (reason) {
      setError(authMessage(reason));
    } finally {
      setBusy(false);
    }
  };

  const setRegistrationField = (field, value) => setRegistration((current) => ({ ...current, [field]: value }));
  const isSignUp = mode === 'signup';
  const isReset = mode === 'reset';

  return (
    <main className="auth-page">
      <section className={`auth-card${isSignUp ? ' auth-card-signup' : ''}`}>
        <div className="auth-brand"><span className="auth-brand-icon"><Icon name="box" size={25} /></span><div><strong>StorePro</strong><small>STORE MANAGEMENT</small></div></div>
        <h1>{isSignUp ? 'Create your store account' : isReset ? 'Reset your password' : 'Welcome back'}</h1>
        <p className="auth-intro">{isSignUp ? 'Set up your owner account to start managing your store.' : isReset ? 'Enter your email address to receive a password reset link.' : 'Sign in with your StorePro account.'}</p>

        {mode === 'signin' && <form onSubmit={signIn} className="auth-form">
          <TextField label="Email address" type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} required autoFocus />
          <TextField label="Password" type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} required />
          {error && <p className="auth-message auth-error" role="alert">{error}</p>}
          <Button type="submit" icon="check" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</Button>
        </form>}

        {isReset && <form onSubmit={resetPassword} className="auth-form">
          <TextField label="Email address" type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} required autoFocus />
          {error && <p className="auth-message auth-error" role="alert">{error}</p>}
          {success && <p className="auth-message auth-success" role="status">{success}</p>}
          <Button type="submit" icon="check" disabled={busy}>{busy ? 'Sending…' : 'Send reset link'}</Button>
        </form>}

        {isSignUp && <form onSubmit={signUp} className="auth-form">
          <div className="auth-signup-grid">
            <TextField label="First name" autoComplete="given-name" value={registration.firstName} onChange={(event) => setRegistrationField('firstName', event.target.value)} required autoFocus />
            <TextField label="Last name" autoComplete="family-name" value={registration.lastName} onChange={(event) => setRegistrationField('lastName', event.target.value)} required />
            <TextField label="Store name (optional)" autoComplete="organization" value={registration.storeName} onChange={(event) => setRegistrationField('storeName', event.target.value)} />
            <TextField label="Username (for your profile)" autoComplete="username" value={registration.username} onChange={(event) => setRegistrationField('username', event.target.value)} required maxLength={32} />
            <TextField className="auth-signup-wide" label="Email address" type="email" autoComplete="email" value={registration.email} onChange={(event) => setRegistrationField('email', event.target.value)} required />
            <TextField label="Password" type="password" autoComplete="new-password" value={registration.password} onChange={(event) => setRegistrationField('password', event.target.value)} required minLength={6} />
            <TextField label="Confirm password" type="password" autoComplete="new-password" value={registration.confirmPassword} onChange={(event) => setRegistrationField('confirmPassword', event.target.value)} required minLength={6} />
          </div>
          {error && <p className="auth-message auth-error" role="alert">{error}</p>}
          <Button type="submit" icon="check" disabled={busy}>{busy ? 'Creating account…' : 'Create account'}</Button>
        </form>}

        <div className="auth-links">
          {mode === 'signin' ? <>
            <button className="auth-link" type="button" onClick={() => changeMode('reset')}>Forgot password?</button>
            <button className="auth-link" type="button" onClick={() => { setRegistration((current) => ({ ...current, email })); changeMode('signup'); }}>Create an account</button>
          </> : <button className="auth-link" type="button" onClick={() => changeMode('signin')}>Back to sign in</button>}
        </div>
        <div className="auth-footnote"><Icon name="refresh" size={16} /> Your products and sales sync with your signed-in StorePro store.</div>
      </section>
    </main>
  );
}
