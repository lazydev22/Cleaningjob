export default function JobHud({ hud }) {
  if (!hud?.active) return null;

  const total = hud.total || 0;
  const cleaned = Math.min(hud.cleaned || 0, total);
  const done = total > 0 && cleaned >= total;
  const pct = total > 0 ? Math.round((cleaned / total) * 100) : 0;

  return (
    <div className="cj-hud">
      <div className="cj-hud-title">{hud.townName ? `${hud.townName} Cleaning Job` : 'Cleaning Job'}</div>

      <div className="cj-hud-row">
        <span className="cj-hud-label">Progress</span>
        <span className="cj-hud-count">
          <span className="cj-hud-count-done">{cleaned}</span>
          <span className="cj-hud-count-sep">{` / ${total}`}</span>
        </span>
      </div>

      <div className={`cj-hud-track${done ? ' is-done' : ''}`}>
        <div className="cj-hud-fill" style={{ width: `${pct}%` }} />
      </div>

      <p className="cj-hud-caption">
        {done ? 'Report back to get paid.' : 'Clean all the spots to finish the job.'}
      </p>
    </div>
  );
}
