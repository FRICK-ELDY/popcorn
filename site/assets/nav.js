export function injectNav() {
  const nav = document.querySelector(".nav");
  if (!nav) return;
  nav.innerHTML = `
      <a href="./hello.html"><button>Hello</button></a>
      <a href="./ticker.html"><button>Ticker</button></a>
      <a href="./parallel.html"><button>Parallel</button></a>
      <a href="./pingpong.html"><button>PingPong</button></a>
      <span id="status" class="muted"></span>
  `;
}


