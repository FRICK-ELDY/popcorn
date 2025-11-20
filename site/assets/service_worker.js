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
    let targetReq = req;
    try {
      const url = new URL(req.url);
      // Rewrite demo-relative wasm paths to site-root wasm
      if (url.pathname.includes("/demo/wasm/")) {
        url.pathname = url.pathname.replace("/demo/wasm/", "/wasm/");
        targetReq = new Request(url.toString(), {
          method: req.method,
          headers: req.headers,
          mode: req.mode,
          credentials: req.credentials,
          cache: req.cache,
          redirect: req.redirect,
          referrer: req.referrer,
          referrerPolicy: req.referrerPolicy,
          integrity: req.integrity
        });
      }
      // Also normalize accidental assets/wasm → wasm
      if (url.pathname.includes("/assets/wasm/")) {
        url.pathname = url.pathname.replace("/assets/wasm/", "/wasm/");
        targetReq = new Request(url.toString(), {
          method: req.method,
          headers: req.headers,
          mode: req.mode,
          credentials: req.credentials,
          cache: req.cache,
          redirect: req.redirect,
          referrer: req.referrer,
          referrerPolicy: req.referrerPolicy,
          integrity: req.integrity
        });
      }
    } catch (_) {}

    const upstreamRes = await fetch(targetReq);
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



