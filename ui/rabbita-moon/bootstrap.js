import '/styles.css'
import '/terrain-canvas.js'

const app = document.getElementById('app')

if (app) {
  app.innerHTML = `
    <main class="boot-shell">
      <div>
        <p class="eyebrow">Moonmoon</p>
        <h1>Loading Rabbita terrain viewer</h1>
      </div>
    </main>
  `
}

await import('/main.js')
