export function canvasRenderActive(canvas) {
  if (!canvas.isConnected) return false
  const rect = canvas.getBoundingClientRect()
  if (rect.width < 2 || rect.height < 2) return false
  const style = getComputedStyle(canvas)
  return style.display !== 'none' && style.visibility !== 'hidden'
}

export function markCanvasRenderPaused(canvas) {
  canvas.dataset.renderPaused = 'true'
  canvas.dataset.pausedFrames = String(Number(canvas.dataset.pausedFrames || 0) + 1)
}

export function markCanvasRenderActive(canvas) {
  if (canvas.dataset.renderPaused === 'true') {
    canvas.dataset.renderResumedCount = String(Number(canvas.dataset.renderResumedCount || 0) + 1)
  }
  canvas.dataset.renderPaused = 'false'
}

export function startCanvasRenderLoop(canvas, renderFrame, dispose) {
  let frameId = 0
  let stopped = false
  const stop = () => {
    if (stopped) return
    stopped = true
    cancelAnimationFrame(frameId)
    dispose?.()
    canvas.dataset.renderDisposed = 'true'
  }
  const draw = time => {
    if (!canvas.isConnected) {
      stop()
      return
    }
    if (!canvasRenderActive(canvas)) {
      markCanvasRenderPaused(canvas)
      frameId = requestAnimationFrame(draw)
      return
    }
    markCanvasRenderActive(canvas)
    renderFrame(time)
    frameId = requestAnimationFrame(draw)
  }
  frameId = requestAnimationFrame(draw)
  return stop
}
