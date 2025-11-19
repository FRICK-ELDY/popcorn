export async function ensureCOI() {
  if (!crossOriginIsolated && 'serviceWorker' in navigator) {
    try {
      const alreadyReloaded = sessionStorage.getItem('reloadedForCOOPCOEP') === '1';
      await navigator.serviceWorker.register('./assets/service_worker.js', { scope: './' });
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
      // Resolve against the page URL (not this module's URL) to avoid ./assets/wasm/... resolution
      const baseClean = (base || './wasm').replace(/\/$/, '');
      const url = new URL(`${baseClean}/${f}`, document.baseURI).href;
      const mod = await import(url);
      const entry = mod.Popcorn ?? mod.default ?? mod;
      const hasInit = entry && typeof entry.init === 'function';
      const isFn = typeof entry === 'function';
      if (hasInit || isFn) {
        console.debug(`[boot] using ${url}`);
        return entry;
      }
      lastErr = new Error(`Module ${f} loaded but no init function found`);
    } catch (e) {
      console.debug(`[boot] failed to import ${f} from base ${base}`, e);
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


