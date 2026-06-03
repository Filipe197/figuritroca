const CACHE = 'figuritroca-v3';
const ASSETS = ['/', '/index.html', '/manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => {
        console.log('[SW] Deletando cache antigo:', k);
        return caches.delete(k);
      }))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Nunca cacheia chamadas para Supabase, Nominatim ou Leaflet
  if (e.request.url.includes('supabase.co') ||
      e.request.url.includes('nominatim.openstreetmap.org') ||
      e.request.url.includes('tile.openstreetmap.org') ||
      e.request.url.includes('unpkg.com') ||
      e.request.url.includes('fonts.googleapis.com') ||
      e.request.url.includes('jsdelivr.net')) {
    return;
  }
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (res.ok && e.request.method === 'GET') {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => caches.match('/index.html'));
    })
  );
});
