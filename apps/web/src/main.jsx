import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import AppErrorBoundary from './components/AppErrorBoundary.jsx';
import './styles.css';

if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js').then((registration) => {
      const cacheLoadedAssets = () => {
        const urls = performance.getEntriesByType('resource')
          .map((entry) => new URL(entry.name, window.location.href))
          .filter((url) => url.origin === window.location.origin && /\.(?:js|css|woff2?)$/i.test(url.pathname))
          .map((url) => url.pathname);
        const worker = navigator.serviceWorker.controller || registration.active || registration.installing || registration.waiting;
        if (!worker) return;
        const send = () => worker.postMessage({ type: 'CACHE_URLS', urls });
        if (worker.state === 'activated') send();
        else worker.addEventListener('statechange', () => { if (worker.state === 'activated') send(); }, { once: true });
      };
      cacheLoadedAssets();
    }).catch(() => {});
  }, { once: true });
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <AppErrorBoundary><App /></AppErrorBoundary>
  </React.StrictMode>,
);
