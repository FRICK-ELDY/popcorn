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
    const url = new URL(req.url);
    // Allow embedding upstream demo page without COOP/COEP on our /eval.html
    const isEvalEmbed = url.pathname.endsWith("/eval.html");
    const res = await fetch(req);
    if (isEvalEmbed) {
      return res;
    }
    const newHeaders = new Headers(res.headers);
    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");
    newHeaders.set("Cross-Origin-Embedder-Policy", "require-corp");
    return new Response(res.body, { status: res.status, statusText: res.statusText, headers: newHeaders });
  })());
});


