export async function ensureCOI() {
  if (!crossOriginIsolated && 'serviceWorker' in navigator) {
    try {
      const alreadyReloaded = sessionStorage.getItem("reloadedForCOOPCOEP") === "1";
      const reg = await navigator.serviceWorker.register("./sw.js", { scope: "./" });
      await navigator.serviceWorker.ready;
      if (!alreadyReloaded) {
        sessionStorage.setItem("reloadedForCOOPCOEP", "1");
        location.reload();
      }
    } catch (_) {}
  }
}

export function installWasmFallback() {
  if (WebAssembly.instantiateStreaming) {
    const _inst = WebAssembly.instantiateStreaming.bind(WebAssembly);
    WebAssembly.instantiateStreaming = async (source, importObject) => {
      try {
        return await _inst(source, importObject);
      } catch (e) {
        const response = source && typeof source.then === "function"
          ? await source
          : (source instanceof Response ? source : await fetch(source));
        const bytes = await response.arrayBuffer();
        return await WebAssembly.instantiate(bytes, importObject);
      }
    };
  }
}

export async function loadPopcorn(base, logFn) {
  const candidates = ["popcorn.js", "popcorn.mjs", "index.js", "index.mjs"];
  let lastErr = null;
  for (const f of candidates) {
    try {
      const mod = await import(`${base}/${f}`);
      const Popcorn = mod.Popcorn ?? mod.default ?? mod;
      if (Popcorn && typeof Popcorn.init === "function") {
        logFn && logFn(`[js] loaded ${base}/${f}`);
        return Popcorn;
      }
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr || new Error("Popcorn entrypoint not found");
}

export async function startPopcorn({ base = "./wasm", onStdout, onStderr, timeoutMs = 20000, logFn }) {
  await ensureCOI();
  installWasmFallback();
  const Popcorn = await loadPopcorn(base, logFn);
  await Popcorn.init({ onStdout, onStderr, timeoutMs });
  return Popcorn;
}


