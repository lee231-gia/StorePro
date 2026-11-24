import React from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from './firebaseClient.js';
import Icon from './components/Icon.jsx';

const AuthPage = React.lazy(() => import('./pages/AuthPage.jsx'));
const StoreApp = React.lazy(() => import('./StoreApp.jsx'));

export default function App() {
  const [user, setUser] = React.useState(null);
  const [authReady, setAuthReady] = React.useState(false);
  const [theme, setTheme] = React.useState(() => {
    try {
      const saved = window.localStorage.getItem('storepro-theme');
      if (saved === 'system') {
        window.localStorage.setItem('storepro-theme', 'light');
        return 'light';
      }
      return saved === 'dark' ? 'dark' : 'light';
    } catch {
      return 'light';
    }
  });

  React.useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    const applyTheme = () => {
      const resolved = theme === 'system' ? (media.matches ? 'dark' : 'light') : theme;
      document.documentElement.dataset.theme = resolved;
      document.documentElement.dataset.themePreference = theme;
      document.querySelector('meta[name="theme-color"]')?.setAttribute('content', resolved === 'dark' ? '#111a16' : '#3d5a56');
    };
    applyTheme();
    if (theme !== 'system') return undefined;
    media.addEventListener?.('change', applyTheme);
    return () => media.removeEventListener?.('change', applyTheme);
  }, [theme]);

  const changeTheme = React.useCallback((nextTheme) => {
    if (!['system', 'light', 'dark'].includes(nextTheme)) return;
    setTheme(nextTheme);
    try { window.localStorage.setItem('storepro-theme', nextTheme); } catch { /* preference remains available for this session */ }
  }, []);

  React.useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setAuthReady(true);
    });
    return () => unsubscribe();
  }, []);

  if (!authReady) return <LoadingScreen label="Connecting to StorePro…" />;
  return <React.Suspense fallback={<LoadingScreen label={user ? 'Opening your store…' : 'Opening sign in…'} />}>
    {user ? <StoreApp user={user} theme={theme} onThemeChange={changeTheme} /> : <AuthPage />}
  </React.Suspense>;
}

function LoadingScreen({ label }) {
  return <main className="app-loading"><span className="app-loading-mark"><Icon name="box" size={25} /></span><strong>{label}</strong><span className="app-loading-spinner" aria-hidden="true" /></main>;
}

