export default function JobPopup({ status, submitting, message, onGetJob, onFinish, onClose }) {
  if (!status) return null;

  const hasJob = status.active;
  const onCooldown = !hasJob && status.cooldown > 0;
  const isNight = !hasJob && !onCooldown && status.isNight;

  return (
    <div className="cj-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="cj-modal">
        <div className="cj-title">{hasJob ? `${status.townName} Cleaning Job` : 'Cleaning Job'}</div>

        {hasJob ? (
          <p className="cj-lede">
            {status.cleaned}/{status.total} spots cleaned.
          </p>
        ) : onCooldown ? (
          <p className="cj-lede">No job for you right now.</p>
        ) : isNight ? (
          <p className="cj-lede">Too dark to clean right now — come back after dawn.</p>
        ) : (
          <p className="cj-lede">Pick up a cleaning job, then report back here once every spot is done.</p>
        )}

        {message ? (
          <div className={`cj-message ${message.success ? 'is-success' : 'is-error'}`}>{message.text}</div>
        ) : null}

        <div className="cj-actions">
          <button
            type="button"
            className="cj-btn cj-btn-primary"
            disabled={hasJob || onCooldown || isNight || submitting}
            onClick={onGetJob}
          >
            Get a Job
          </button>
          <button
            type="button"
            className="cj-btn cj-btn-primary"
            disabled={!hasJob || submitting}
            onClick={onFinish}
          >
            Finish the Job
          </button>
          <button type="button" className="cj-btn cj-btn-ghost" disabled={submitting} onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
