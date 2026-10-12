// Portable browser-reviewed evidence. An archive proves byte integrity only;
// it neither authenticates a reviewer nor replays a scientific calculation.
export const STUDY_ARCHIVE_LIMIT_BYTES = 32 * 1024 * 1024
const encoder = new TextEncoder()
const need = (ok, message) => { if (!ok) throw Error(message) }
const contract = 'moonmoon.reviewed-study-archive.v1'

export async function createStudyArchive(recordText, readRecord, hash) {
  need(typeof recordText === 'string' && encoder.encode(recordText).length <= 24 * 1024 * 1024, 'Saved record exceeds the 24 MiB archive record limit; keep the original browser record')
  const loaded = await readRecord(recordText)
  const text = JSON.stringify({
    contract_id: contract, authority: 'digital-only', physical_readiness: false,
    reviewer_identity: 'unverified', study_id: loaded.study.dossier.study_id,
    revision: loaded.study.dossier.revision, dossier_digest: loaded.study.envelope.dossier_digest,
    record_digest: await hash(recordText), record_text: recordText,
  })
  need(encoder.encode(text).length <= STUDY_ARCHIVE_LIMIT_BYTES, 'Archive exceeds the 32 MiB transfer limit; keep the original browser record')
  return text
}

export async function readStudyArchive(text, readRecord, hash) {
  need(typeof text === 'string' && encoder.encode(text).length <= STUDY_ARCHIVE_LIMIT_BYTES, 'Choose a reviewed-study archive of at most 32 MiB')
  const archive = JSON.parse(text)
  need(archive?.contract_id === contract && archive.authority === 'digital-only' && archive.physical_readiness === false && archive.reviewer_identity === 'unverified', 'Unsupported archive or non-digital authority')
  need(typeof archive.record_text === 'string' && encoder.encode(archive.record_text).length <= 24 * 1024 * 1024, 'Archived record exceeds the 24 MiB record limit')
  need(await hash(archive.record_text) === archive.record_digest, 'Archived record digest changed')
  const loaded = await readRecord(archive.record_text)
  need(archive.study_id === loaded.study.dossier.study_id && archive.revision === loaded.study.dossier.revision && archive.dossier_digest === loaded.study.envelope.dossier_digest, 'Archive identity differs from its frozen dossier')
  return { ...loaded, archive, archiveDigest: await hash(text) }
}

export function bindStudyArchive(document, panel, actions) {
  const element = (tag, text, suffix) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    if (suffix) node.id = 'study-archive-' + suffix
    return node
  }
  const host = element('section', undefined, 'panel')
  host.appendChild(element('h3', 'Move a reviewed study between browsers'))
  host.appendChild(element('p', 'Download the saved dossier, digital review and review history together. Inspect a local archive before restoring its exact study/revision into an unused browser slot. Reviewer names are unauthenticated claims; no simulation or physical authority is transferred.'))
  const download = element('button', 'Download saved reviewed-study archive', 'download'); download.type = 'button'; host.appendChild(download)
  const label = element('label', 'Local reviewed-study archive JSON (up to 32 MiB)')
  const file = element('input', undefined, 'file'); file.type = 'file'; file.accept = '.json,application/json'; label.appendChild(file); host.appendChild(label)
  const preview = element('pre', '', 'preview'); host.appendChild(preview)
  const restore = element('button', 'Restore reviewed archive into unused slot', 'restore'); restore.type = 'button'; restore.disabled = true; host.appendChild(restore)
  const clear = element('button', 'Clear archive preview', 'clear'); clear.type = 'button'; host.appendChild(clear)
  const status = element('p', 'No archive selected. Downloads and restores require an explicit action.', 'status'); status.role = 'status'; status.ariaLive = 'polite'; host.appendChild(status)
  panel.appendChild(host)
  let staged = null, generation = 0, exporting = false, restoring = false
  const reset = () => { generation++; staged = null; preview.textContent = ''; restore.disabled = true; file.value = '' }
  clear.addEventListener('click', () => { if (restoring) return; reset(); status.textContent = 'Archive preview cleared. Open study and saved evidence are unchanged.' })
  file.addEventListener('change', async () => {
    if (restoring) return
    const chosen = file.files?.[0]; reset(); const token = generation
    try {
      need(chosen && chosen.size <= STUDY_ARCHIVE_LIMIT_BYTES, 'Choose a local reviewed-study archive JSON of at most 32 MiB')
      status.textContent = 'Checking retained dossier, review history and exact archive identity…'
      const text = await chosen.text(), checked = await actions.inspect(text)
      if (token !== generation) return
      staged = { text, checked }; restore.disabled = false
      const review = checked.review
      preview.textContent = [
        `Study ${checked.study.dossier.study_id} / ${checked.study.dossier.revision}`,
        `Archive bytes: ${checked.archiveDigest}`, `Record bytes: ${checked.archive.record_digest}`,
        `Frozen dossier: ${checked.study.envelope.dossier_digest}`,
        `Site ${checked.study.dossier.site.site_id}; frame ${checked.study.dossier.site.frame}; coverage ${checked.study.dossier.site.coverage}; uncertainty ${checked.study.dossier.site.uncertainty}`,
        `${checked.study.alternatives.length} alternatives; ${checked.reviewHistory.length} earlier review claims`,
        review ? `Current digital review claim: ${review.reviewer}\nChoice: ${review.choice}\nReason: ${review.rationale}` : 'No current named review; review remains required.',
        `Earlier review claims (retained order): ${JSON.stringify(checked.reviewHistory, null, 2)}`,
        ...checked.study.alternatives.map(item => `${item.session_id}: ${item.result.result}; energy margin ${item.result.energy.margin_wh} Wh; blockers: ${item.result.blockers.join('; ') || 'none in this bounded simulation'}`),
        'Integrity checked only. Reviewer identity is unverified. Missing coverage and negative-energy blockers remain. Restore does not rerun, approve or replace the open study.',
      ].join('\n\n')
      status.textContent = 'Archive inspected. Review the identity and named claims, then restore explicitly. Existing study/revision slots cannot be overwritten or merged.'
    } catch (error) { if (token === generation) status.textContent = `Archive unavailable: ${error.message}. No stored evidence changed.` }
  })
  download.addEventListener('click', async () => {
    if (exporting || restoring) return
    exporting = true; download.disabled = true
    try {
      const result = await actions.export()
      const url = URL.createObjectURL(new Blob([result.text], { type: 'application/json' }))
      try { const link = document.createElement('a'); link.href = url; link.download = result.filename; link.click() }
      finally { URL.revokeObjectURL(url) }
      status.textContent = 'Prepared reviewed-study archive download. It includes all frozen sources and private review text; choose recipients yourself. Download completion and receiving-browser persistence are not confirmed.'
    } catch (error) { status.textContent = `Archive download unavailable: ${error.message}` }
    finally { exporting = false; download.disabled = false }
  })
  restore.addEventListener('click', async () => {
    if (!staged || restoring || exporting) return
    const selected = staged
    restoring = true; restore.disabled = true; clear.disabled = true; file.disabled = true
    try {
      const identity = await actions.restore(selected.text)
      reset()
      status.textContent = `Restored and read back ${identity}, including the exact digital review history. Use Find saved studies to open it. The current study is unchanged; reviewer identity remains unverified.`
    } catch (error) {
      status.textContent = `Archive restore not confirmed: ${error.message}. Keep the archive. If a save journal remains, reconcile the previewed identity before retrying. For a different identity than the open study, preserve open work and reload first, then enter its Study ID and Revision and choose Reconcile interrupted save. No existing record was intentionally replaced.`
    } finally { restoring = false; restore.disabled = !staged; clear.disabled = false; file.disabled = false }
  })
}
