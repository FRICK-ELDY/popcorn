export function injectNav() {
  const nav = document.querySelector(".nav");
  if (!nav) return;
  const parts = location.pathname.split("/").filter(Boolean);
  const basePath = "/" + (parts.length ? (parts[0] + "/") : "");
  const demoPath = `${basePath}demo/`;
  nav.innerHTML = `
      <a href="${demoPath}hello.html"><button>Hello</button></a>
      <a href="${demoPath}ticker.html"><button>Ticker</button></a>
      <a href="${demoPath}parallel.html"><button>Parallel</button></a>
      <a href="${demoPath}pingpong.html"><button>PingPong</button></a>
      <a href="${demoPath}ring.html"><button>Ring</button></a>
      <a href="${demoPath}supervisor.html"><button>supervisor</button></a>
      <a href="${demoPath}pi.html"><button>pi</button></a>
      <span id="status" class="muted"></span>
  `;
}


