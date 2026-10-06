// Browser view preferences are best effort; they never gate operator controls.
function showPersistenceNotice() {
  let notice = document.getElementById('moonmoon-persistence-notice')
  if (!notice) {
    notice = document.createElement('p')
    notice.id = 'moonmoon-persistence-notice'
    notice.className = 'persistence-notice'
    notice.setAttribute('role', 'status')
    const shell = document.querySelector('.moon-shell') || document.body
    shell.prepend(notice)
  }
  notice.textContent = 'Browser storage is unavailable. View changes still work, but may not be restored after reload.'
}

export function readSessionState(key) {
  try {
    return sessionStorage.getItem(key)
  } catch {
    showPersistenceNotice()
    return null
  }
}

export function writeSessionState(key, value) {
  try {
    sessionStorage.setItem(key, value)
  } catch {
    showPersistenceNotice()
  }
}
