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

    // Rewrite /wasm/* to page-specific variant: /wasm-home|/wasm-ticker|/wasm-parallel/*
    let rewritten = null;
    const wasmIdx = url.pathname.indexOf("/wasm/");
    if (wasmIdx !== -1) {
      const base = url.pathname.slice(0, wasmIdx); // e.g. /popcorn
      const suffix = url.pathname.slice(wasmIdx + "/wasm".length); // e.g. /popcorn.js or /AtomVM.mjs ...

      let pagePath = "";
      let refPath = "";
      // 1) Prefer page cookie (set by each page)
      let variantFromCookie = "";
      try {
        const cookie = req.headers.get("Cookie") || "";
        // simple parse
        cookie.split(";").forEach(kv => {
          const [k, v] = kv.split("=");
          if (k && k.trim() === "popcornVariant" && v) {
            variantFromCookie = decodeURIComponent(v.trim());
          }
        });
      } catch (_) {}

      if (event.clientId) {
        try {
          const c = await self.clients.get(event.clientId);
          if (c && c.url) {
            pagePath = new URL(c.url).pathname;
          }
        } catch (_) {}
      }
      if (!pagePath && req.referrer) {
        try {
          const u = new URL(req.referrer);
          pagePath = u.pathname;
          refPath = u.pathname;
        } catch (_) {}
      }
      if (!pagePath) {
        try {
          const ref = req.headers.get("Referer");
          if (ref) {
            const u = new URL(ref);
            pagePath = u.pathname;
            refPath = u.pathname;
          }
        } catch (_) {}
      }
      let variant = "/wasm-home";
      const anyPath = `${pagePath} ${refPath}`;
      if (variantFromCookie === "ticker") {
        variant = "/wasm-ticker";
      } else if (variantFromCookie === "parallel") {
        variant = "/wasm-parallel";
      } else if (pagePath.endsWith("/ticker.html") || anyPath.includes("/wasm-ticker/")) {
        variant = "/wasm-ticker";
      } else if (pagePath.endsWith("/parallel.html") || anyPath.includes("/wasm-parallel/")) {
        variant = "/wasm-parallel";
      }

      const newPath = `${base}${variant}${suffix}`;
      const newUrl = new URL(newPath, url.origin);
      rewritten = new Request(newUrl.toString(), {
        method: req.method,
        headers: req.headers,
        mode: req.mode,
        credentials: req.credentials,
        cache: req.cache,
        redirect: req.redirect,
        referrer: req.referrer,
        referrerPolicy: req.referrerPolicy,
        integrity: req.integrity,
      });
    }

    const upstreamRes = await fetch(rewritten || req);
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


