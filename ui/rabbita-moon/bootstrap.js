import '@fontsource/inter/300.css'
import '@fontsource/inter/400.css'
import '@fontsource/inter/500.css'
import '@fontsource/inter/600.css'
import '@fontsource/ibm-plex-mono/400.css'
import '@fontsource/ibm-plex-mono/500.css'
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
