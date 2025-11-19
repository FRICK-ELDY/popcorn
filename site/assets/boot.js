export async function ensureCOI() {
  if (!crossOriginIsolated && 'serviceWorker' in navigator) {
    try {
      const alreadyReloaded = sessionStorage.getItem('reloadedForCOOPCOEP') === '1';
      await navigator.serviceWorker.register('./sw.js', { scope: './' });
      await navigator.serviceWorker.ready;
      if (!alreadyReloaded) {
        sessionStorage.setItem('reloadedForCOOPCOEP', '1');
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
      } catch (_) {
        const response = source && typeof source.then === 'function'
          ? await source
          : (source instanceof Response ? source : await fetch(source));
        const bytes = await response.arrayBuffer();
        return await WebAssembly.instantiate(bytes, importObject);
      }
    };
  }
}

export async function loadPopcorn(base) {
  const candidates = ['popcorn.js', 'popcorn.mjs', 'index.js', 'index.mjs', 'popcorn_iframe.js'];
  let lastErr = null;
  for (const f of candidates) {
    try {
      const mod = await import(`${base}/${f}`);
      return mod.Popcorn ?? mod.default ?? mod;
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr || new Error('Popcorn entrypoint not found');
}

export async function startPopcorn({ base = './wasm', onStdout, onStderr, timeoutMs = 20000 }) {
  await ensureCOI();
  installWasmFallback();
  const entry = await loadPopcorn(base);
  const initFn =
    (entry && typeof entry.init === 'function') ? entry.init :
    (typeof entry === 'function') ? entry :
    null;
  if (!initFn) throw new Error('Popcorn init function not found on loaded module');
  await initFn({ onStdout, onStderr, timeoutMs });
  return entry;
}


