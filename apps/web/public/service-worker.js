const CACHE_NAME = 'storepro-shell-v1';

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.add('/')));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((key) => key.startsWith('storepro-shell-') && key !== CACHE_NAME).map((key) => caches.delete(key)))),
  );
  self.clients.claim();
});

self.addEventListener('message', (event) => {
  if (event.data?.type !== 'CACHE_URLS' || !Array.isArray(event.data.urls)) return;
  event.waitUntil(caches.open(CACHE_NAME).then(async (cache) => {
    await Promise.all(event.data.urls.map(async (url) => {
      try {
        const response = await fetch(url, { cache: 'reload' });
        if (response.ok) await cache.put(url, response);
      } catch {}
    }));
  }));
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    try {
      const response = await fetch(request);
      if (response.ok && (request.mode === 'navigate' || /\.(?:js|css|woff2?)$/i.test(new URL(request.url).pathname))) {
        cache.put(request.mode === 'navigate' ? '/' : request, response.clone()).catch(() => {});
      }
      return response;
    } catch {
      return (await cache.match(request)) || (request.mode === 'navigate' ? (await cache.match('/')) : undefined) || Response.error();
    }
  })());
});
