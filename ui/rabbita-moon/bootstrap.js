import '/styles.css'
import '/terrain-canvas.js'
import '/scene-shell.js'
import '/operator-ui.js'

const app = document.getElementById('app')

if (app) {
  app.innerHTML = `
    <main class="boot-shell">
      <div>
        <p class="eyebrow">MoonMoon</p>
        <h1>Loading Rabbita 3D Moon viewer</h1>
      </div>
    </main>
  `
}

await import('/main.js')
