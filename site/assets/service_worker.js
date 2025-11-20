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
    let requestToFetch = req;
    try {
      const url = new URL(req.url);
      // If runtime tries to load from /wasm/... (site root), rewrite to /demo/wasm/...
      if (url.pathname.includes("/wasm/") && !url.pathname.includes("/demo/wasm/")) {
        url.pathname = url.pathname.replace("/wasm/", "/demo/wasm/");
        requestToFetch = new Request(url.toString(), {
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

    const upstreamRes = await fetch(requestToFetch);
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



