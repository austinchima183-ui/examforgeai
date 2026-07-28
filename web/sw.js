// =============================================================================
// ExamForge AI — Service Worker
// =============================================================================
//
// Provides offline-capable caching strategies for the ExamForge AI PWA:
//   - Cache-first for static assets (JS, CSS, fonts, manifest)
//   - Network-first for API calls
//   - Stale-while-revalidate for images
//   - Background sync for queued mutations
//   - Push notification support
//
// Cache versioning: bump CACHE_NAME to invalidate old caches on deploy.
// =============================================================================

const CACHE_NAME = 'examforge-v1';

// ─── Precache Resources ─────────────────────────────────────────────────────
// These assets are fetched and cached during the install phase so the shell
// of the app is available offline immediately.
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/main.dart.js',
];

// ─── Cache Strategy Matchers ────────────────────────────────────────────────

/**
 * Returns true if the request URL points to a static asset that rarely changes.
 */
function isStaticAsset(request) {
  const url = new URL(request.url);
  return (
    url.pathname.endsWith('.js') ||
    url.pathname.endsWith('.css') ||
    url.pathname.endsWith('.woff2') ||
    url.pathname.endsWith('.woff') ||
    url.pathname.endsWith('.ttf') ||
    url.pathname.endsWith('.json') ||
    url.pathname === '/' ||
    url.pathname === '/index.html' ||
    url.pathname === '/manifest.json'
  );
}

/**
 * Returns true if the request URL targets the Supabase / API backend.
 */
function isApiCall(request) {
  const url = new URL(request.url);
  return (
    url.pathname.startsWith('/rest/') ||
    url.pathname.startsWith('/api/') ||
    url.hostname.includes('supabase') ||
    url.hostname.includes('supabase.co')
  );
}

/**
 * Returns true if the request is for an image resource.
 */
function isImageRequest(request) {
  const url = new URL(request.url);
  return (
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('.jpg') ||
    url.pathname.endsWith('.jpeg') ||
    url.pathname.endsWith('.webp') ||
    url.pathname.endsWith('.svg') ||
    url.pathname.endsWith('.gif') ||
    request.destination === 'image'
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// INSTALL EVENT
// ═══════════════════════════════════════════════════════════════════════════════

self.addEventListener('install', (event) => {
  console.log('[ExamForge SW] Installing…');

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ExamForge SW] Precaching shell resources');
      return cache.addAll(PRECACHE_URLS);
    }).then(() => {
      // Skip waiting so the new SW activates immediately.
      return self.skipWaiting();
    }).catch((error) => {
      console.error('[ExamForge SW] Precache failed:', error);
    })
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVATE EVENT
// ═══════════════════════════════════════════════════════════════════════════════

self.addEventListener('activate', (event) => {
  console.log('[ExamForge SW] Activating…');

  event.waitUntil(
    caches.keys().then((cacheNames) => {
      // Remove old caches that don't match the current CACHE_NAME.
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[ExamForge SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => {
      // Take control of all open clients immediately.
      return self.clients.claim();
    })
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// FETCH EVENT — Routing Strategy
// ═══════════════════════════════════════════════════════════════════════════════

self.addEventListener('fetch', (event) => {
  // Only handle GET requests for caching; let others pass through.
  if (event.request.method !== 'GET') return;

  // Skip cross-origin requests that aren't API calls.
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin && !isApiCall(event.request)) return;

  if (isApiCall(event.request)) {
    // ─── Network-first for API calls ────────────────────────────────────
    event.respondWith(networkFirst(event.request));
  } else if (isImageRequest(event.request)) {
    // ─── Stale-while-revalidate for images ──────────────────────────────
    event.respondWith(staleWhileRevalidate(event.request));
  } else if (isStaticAsset(event.request)) {
    // ─── Cache-first for static assets ──────────────────────────────────
    event.respondWith(cacheFirst(event.request));
  } else {
    // ─── Default: try network, fall back to cache ───────────────────────
    event.respondWith(networkFirst(event.request));
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// CACHING STRATEGIES
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Cache-first: return the cached response if available, otherwise fetch
 * from the network and cache the result.
 */
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    // If both cache and network fail, return an offline fallback.
    return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
  }
}

/**
 * Network-first: try the network, fall back to cache if offline.
 * On success, update the cache with the fresh response.
 */
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    if (cached) {
      return cached;
    }
    return new Response(
      JSON.stringify({ error: 'You are offline and no cached data is available.' }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

/**
 * Stale-while-revalidate: return the cached response immediately (if
 * available), then fetch from network in the background and update the
 * cache for the next request.
 */
async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);

  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  }).catch(() => cached);

  return cached || fetchPromise;
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACKGROUND SYNC
// ═══════════════════════════════════════════════════════════════════════════════

self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-queue') {
    console.log('[ExamForge SW] Processing sync queue…');
    event.waitUntil(processSyncQueue());
  }
});

/**
 * Reads pending mutations from IndexedDB and replays them against the API.
 *
 * This relies on the Flutter app writing queued operations to IndexedDB
 * with a known structure. The SW reads them, POSTs each one, and removes
 * successful entries.
 */
async function processSyncQueue() {
  // The sync queue is managed by the Flutter app through the SyncEngine
  // and CacheManager. Here we simply notify all clients that they should
  // process their sync queues.
  const clients = await self.clients.matchAll({ type: 'window' });
  clients.forEach((client) => {
    client.postMessage({
      type: 'SYNC_QUEUE',
      action: 'process',
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUSH NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════

self.addEventListener('push', (event) => {
  console.log('[ExamForge SW] Push notification received');

  let data = {
    title: 'ExamForge AI',
    body: 'You have a new notification.',
    url: '/',
  };

  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data.body = event.data.text();
    }
  }

  const options = {
    body: data.body,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.url || '/',
      clickAction: data.url || '/',
    },
    actions: [
      { action: 'open', title: 'Open' },
      { action: 'dismiss', title: 'Dismiss' },
    ],
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// ─── Notification Click Handler ─────────────────────────────────────────────

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'dismiss') return;

  const targetUrl = event.notification.data?.url || '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Focus an existing window if one is open.
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.navigate(targetUrl);
          return client.focus();
        }
      }
      // Otherwise open a new window.
      return self.clients.openWindow(targetUrl);
    })
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE HANDLING (from Flutter app)
// ═══════════════════════════════════════════════════════════════════════════════

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  if (event.data && event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(
      caches.keys().then((names) => {
        return Promise.all(names.map((name) => caches.delete(name)));
      })
    );
  }
});
