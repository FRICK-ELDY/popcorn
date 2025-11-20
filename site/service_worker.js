self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

// Inject COOP/COEP headers so that crossOriginIsolated becomes true on GitHub Pages
// and WASM runtimes that need SharedArrayBuffer can work.
self.addEventListener("fetch", (event) => {
  const req = event.request;
  event.respondWith((async () => {
    const upstreamRes = await fetch(req);
    const newHeaders = new Headers(upstreamRes.headers);
    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");
    newHeaders.set("Cross-Origin-Embedder-Policy", "require-corp");
    return new Response(upstreamRes.body, {
      status: upstreamRes.status,
      statusText: upstreamRes.statusText,
      headers: newHeaders
    });
  })());
});




