import { initMoonGlobe } from './moon-globe.js'

let adapterModulePromise

function loadAdapterModule() {
  adapterModulePromise ??= import('./scene3d.js')
  return adapterModulePromise
}

globalThis.__moonmoonRenderScene3d = modelJson => {
  const view = JSON.parse(modelJson)
  const moon = document.getElementById('moonmoon-globe-3d')
  const adapterPreview = document.getElementById('moonmoon-adapter-preview')
  const thirdPerson = document.getElementById('moonmoon-third-person-3d')
  if (moon && moon.dataset.sceneBooted !== 'true') {
    moon.dataset.sceneBooted = 'true'
    initMoonGlobe(moon, view)
  }
  if (!adapterPreview || !thirdPerson || adapterPreview.dataset.runtimeBound === 'true') return
  adapterPreview.dataset.runtimeBound = 'true'
  const bootAdapter = async () => {
    if (!adapterPreview.open || thirdPerson.dataset.sceneBooted === 'true') return
    thirdPerson.dataset.adapterRuntime = 'loading-module'
    try {
      const adapter = await loadAdapterModule()
      if (!adapterPreview.open) return
      const sampleIndex = Number(moon?.dataset.lightingSampleIndex || view.lighting?.default_sample_index || 0)
      await adapter.mountAdapterPreview(
        thirdPerson,
        view.lighting,
        sampleIndex,
        moon?.dataset.lightingMode || 'physical',
      )
    } catch (error) {
      thirdPerson.dataset.adapterRuntime = 'failed'
      thirdPerson.dataset.sceneError = error instanceof Error ? error.message : String(error)
    }
  }
  adapterPreview.addEventListener('toggle', bootAdapter)
  bootAdapter()
}
