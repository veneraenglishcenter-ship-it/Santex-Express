const CACHE_NAME = 'santex-express-v3';
const APP_SHELL = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).catch(()=>{})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(
      keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Faqat o'z saytimizdagi (same-origin) fayllarni keshlaymiz.
  // Supabase, CDN va boshqa tashqi so'rovlarga tegmaymiz - ular doim tarmoqdan yuklanadi.
  if (url.origin !== self.location.origin) return;

  // Asosiy HTML sahifa uchun: har doim AVVAL tarmoqdan yangisini olishga
  // harakat qilamiz (network-first) - shunda yangi deploy darhol ko'rinadi.
  // Faqat internet yo'q bo'lgandagina eski (keshdagi) nusxa ko'rsatiladi.
  const isHTML = event.request.mode === 'navigate' || event.request.destination === 'document';
  if (isHTML) {
    // { cache: 'no-store' } - brauzerning o'zining oddiy HTTP keshini ham
    // butunlay chetlab o'tib, har doim serverdan chinakam yangi nusxani
    // so'raymiz. Aks holda "network-first" mantiqimiz bo'lsa ham, brauzer
    // ba'zan hali muddati o'tmagan eski nusxani (Service Worker'dan
    // butunlay tashqarida) o'zi qaytarib yuborishi mumkin edi.
    event.respondWith(
      fetch(event.request.url, { cache: 'no-store' }).then((response) => {
        if (response && response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => caches.match(event.request))
    );
    return;
  }

  // Boshqa fayllar (ikonka, manifest...) uchun avvalgidek: kesh + fon rejimida yangilash
  event.respondWith(
    caches.match(event.request).then((cached) => {
      const network = fetch(event.request).then((response) => {
        if (response && response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => cached);
      return cached || network;
    })
  );
});
