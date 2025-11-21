import { startPopcorn } from "./boot.js";

export async function runDemo({
  base = "./wasm",
  filter,
  transform,
  statusId = "status",
  logsId = "logs",
  timeoutMs = 20000
} = {}) {
  const logsEl = document.getElementById(logsId);
  if (logsEl) logsEl.textContent = "";

  const statusEl = document.getElementById(statusId);
  function setStatus(text, ok) {
    if (!statusEl) return;
    statusEl.textContent = text;
    statusEl.className = ok ? "ok" : "err";
  }

  function shouldSuppressGenericAtomVm(line) {
    return /AtomVM\.mjs:.*Uncaught RuntimeError/.test(line);
  }
  function isWantedErr(line) {
    return line.includes("Aborted()") || line.includes("worker sent an error!");
  }

  function appendLog(line, isErr) {
    if (isErr) {
      if (!isWantedErr(line) && shouldSuppressGenericAtomVm(line)) {
        return;
      }
    } else if (typeof filter === "function" && !filter(line)) {
      return;
    }

    const text = isErr
      ? `[err] ${line}`
      : (typeof transform === "function" ? transform(line) : line);
    if (logsEl) logsEl.textContent += text + "\n";
  }

  try {
    const entry = await startPopcorn({
      base,
      onStdout: (s) => appendLog(s, false),
      onStderr: (s) => appendLog(s, true),
      timeoutMs
    });
    setStatus("ready", true);
    return entry;
  } catch (err) {
    console.error("Popcorn initialization failed:", err);
    setStatus("failed to init", false);
    if (logsEl) {
      const msg = (err && err.message) ? err.message : String(err);
      logsEl.textContent += `[js err] ${msg}\n`;
    }
  }
}


