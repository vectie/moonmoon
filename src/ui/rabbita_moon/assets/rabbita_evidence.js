(function () {
  const gapEvidenceIds = [
    'moonclaw/first-trusted-square/moonrobo-gap-remediation-task',
    'moonclaw/first-trusted-square/moonrobo-gap-remediation-receipt'
  ];

  const selectedRouteRemediationIds = [
    'terrain-remediation/first-trusted-square/northeast-stepout',
    'local-horizon/first-trusted-square/northeast-stepout',
    'energy-remediation/first-trusted-square/northeast-stepout'
  ];

  const familyOptions = [
    ['all', 'All'],
    ['blocker', 'Blockers'],
    ['remediation', 'Work'],
    ['receipt', 'Receipts'],
    ['simulation', 'Simulation'],
    ['review', 'Review'],
  ];

  function isMissionEvidenceEntry(entry) {
    return entry.entry_id.includes('/remediation-margin-') ||
      entry.entry_id.includes('/regenerated-receipt-readiness-') ||
      entry.entry_id.endsWith('/noetix-dynamics') ||
      entry.entry_id.endsWith('/noetix-review-task');
  }

  function missionEvidenceFamily(entry) {
    const id = entry.entry_id;
    if (
      id.includes('projection') ||
      id.includes('cycle-closeout') ||
      id.includes('action-receipt-closeout') ||
      id.endsWith('/remediation-margin-regenerated-receipt-readiness')
    ) return 'blocker';
    if (id.endsWith('/noetix-dynamics')) return 'simulation';
    if (id.includes('modeling')) return 'simulation';
    if (
      id.includes('reviewed-action-plan') ||
      id.includes('reviewed-work-items') ||
      id.endsWith('/noetix-review-task')
    ) return 'review';
    if (id.includes('fresh-evidence-task') || id.endsWith('-task')) return 'remediation';
    if (
      id.includes('receipt') ||
      id.includes('receipts') ||
      id.includes('action-receipts')
    ) return 'receipt';
    return 'remediation';
  }

  function missionEvidenceLabel(entry) {
    return entry.title
      .replace(' for First Trusted Square / Shackleton Rim rehearsal tile', '')
      .replace('MoonClaw ', '')
      .replace('MoonRobo ', '');
  }

  function evidenceFamilyCounts(rows) {
    return rows.reduce((counts, row) => {
      counts[row.family] = (counts[row.family] || 0) + 1;
      counts.all += 1;
      return counts;
    }, { all: 0, blocker: 0, remediation: 0, receipt: 0, simulation: 0, review: 0 });
  }

  function create(book) {
    const entryMap = new Map(book.entries.map(entry => [entry.entry_id, entry]));

    function entryById(id) {
      return entryMap.get(id);
    }

    function entriesByIds(ids) {
      return ids.map(entryById).filter(Boolean);
    }

    function missionEvidenceRows() {
      return book.entries
        .filter(isMissionEvidenceEntry)
        .map(entry => ({
          family: missionEvidenceFamily(entry),
          label: missionEvidenceLabel(entry),
          entry
        }));
    }

    return {
      familyOptions,
      entryById,
      evidenceFamilyCounts,
      gapEvidenceEntries: () => entriesByIds(gapEvidenceIds),
      selectedRouteRemediationEntries: () => entriesByIds(selectedRouteRemediationIds),
      missionEvidenceRows,
    };
  }

  window.RabbitaEvidence = { create };
}());
