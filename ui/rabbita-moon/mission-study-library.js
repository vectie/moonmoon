// Discover browser-saved digital reviews only. This view never executes a
// mission, changes evidence, or reconciles an interrupted save automatically.
export function bindStudyLibrary(document, panel, { catalogue, open }) {
  const element = (tag, text) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    return node
  }
  const host = element('section'); host.id = 'study-library'
  const heading = element('h3', 'Saved studies in this browser')
  const refresh = element('button', 'Find saved studies'); refresh.id = 'study-library-refresh'; refresh.type = 'button'
  const status = element('p', 'Find previously saved dossiers and their exact digital reviews. This list does not run a simulation.')
  status.id = 'study-library-status'; status.role = 'status'; status.ariaLive = 'polite'
  const rows = element('div'); rows.id = 'study-library-rows'
  host.appendChild(heading); host.appendChild(refresh); host.appendChild(status); host.appendChild(rows)
  panel.appendChild(host)
  let generation = 0, loading = false, opening = false
  refresh.addEventListener('click', async () => {
    if (loading || opening) return
    const token = ++generation
    loading = true; refresh.disabled = true; rows.replaceChildren()
    status.textContent = 'Checking saved study identities and evidence…'
    try {
      const result = await catalogue()
      if (token !== generation) return
      for (const entry of result.entries) {
        const row = element('div'); row.className = 'study-comparison'
        row.appendChild(element('p', `${entry.id} / ${entry.revision} · ${entry.state}\n${entry.message}`))
        if (entry.state === 'verified') {
          const button = element('button', `Open ${entry.id} / ${entry.revision}`); button.type = 'button'
          button.addEventListener('click', async () => {
            if (loading || opening || token !== generation) return
            opening = true; refresh.disabled = true; button.disabled = true
            try { await open(entry); status.textContent = `Opened ${entry.id} / ${entry.revision}. Exact saved digital evidence and its own review restored.` }
            catch (error) { status.textContent = `${error.message} Your current study and edits were kept.` }
            finally { opening = false; refresh.disabled = false; button.disabled = false }
          })
          row.appendChild(button)
        }
        rows.appendChild(row)
      }
      status.textContent = `${result.entries.length} saved identit${result.entries.length === 1 ? 'y' : 'ies'} shown. ${result.inventoryChanged ? 'Browser storage inventory changed during inspection; this list may be incomplete. Refresh to discover the current saved studies.' : result.truncated ? 'Inspection limit reached; more saved studies may exist. Use exact-ID controls for omitted revisions.' : result.entries.length ? 'Only verified revisions can be opened here.' : 'No saved study revisions found.'}${result.invalidKeys ? ` ${result.invalidKeys} malformed study storage key(s) were left untouched.` : ''} Interrupted saves require the existing explicit reconciliation controls; no stored data was changed.`
    } catch (error) {
      if (token === generation) { rows.replaceChildren(); status.textContent = `Saved-study library unavailable: ${error.message}. Existing exact-ID controls remain available; nothing was changed.` }
    } finally { loading = false; refresh.disabled = false }
  })
  return host
}
