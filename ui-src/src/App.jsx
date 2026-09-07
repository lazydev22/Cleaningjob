import { useCallback, useState } from 'react';
import { useNuiEvent } from './hooks/useNuiEvent.js';
import { fetchNui } from './utils/fetchNui.js';
import JobPopup from './components/JobPopup.jsx';
import JobHud from './components/JobHud.jsx';

const DEV_MODE = false; // flip on to preview in a plain browser (npm run dev)

export default function App() {
  const [visible, setVisible] = useState(DEV_MODE);
  const [status, setStatus] = useState(DEV_MODE ? { active: false, cooldown: 0, isNight: false } : null);
  const [townId, setTownId] = useState(null); // which NPC's town the popup is currently open for
  const [hud, setHud] = useState({ active: DEV_MODE, townName: 'Blackwater', cleaned: 2, total: 5 });
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState(null);

  useNuiEvent(
    'dsml-clean-open',
    useCallback((data) => {
      setStatus(data.status);
      setTownId(data.townId);
      setMessage(null);
      setSubmitting(false);
      setVisible(true);
    }, [])
  );

  useNuiEvent(
    'dsml-clean-hud',
    useCallback((data) => {
      setHud({
        active: !!data.active,
        townName: data.townName || '',
        cleaned: data.cleaned ?? 0,
        total: data.total ?? 0,
      });
    }, [])
  );

  function close() {
    setVisible(false);
    fetchNui('dsml-clean-close');
  }

  async function getJob() {
    setSubmitting(true);
    setMessage(null);
    const result = await fetchNui('dsml-clean-getjob', { townId });
    setSubmitting(false);
    if (result?.success) {
      setStatus({ active: true, townId, townName: result.townName, cleaned: 0, total: result.total });
    } else {
      setMessage({ success: false, text: result?.message || 'Something went wrong.' });
    }
  }

  async function finishJob() {
    setSubmitting(true);
    setMessage(null);
    const result = await fetchNui('dsml-clean-finish');
    setSubmitting(false);
    if (result?.success) {
      setStatus({ active: false, cooldown: 0 });
      setMessage({ success: true, text: result.message });
    } else {
      setMessage({ success: false, text: result?.message || 'Something went wrong.' });
    }
  }

  return (
    <>
      <JobHud hud={hud} />
      {visible ? (
        <JobPopup
          status={status}
          submitting={submitting}
          message={message}
          onGetJob={getJob}
          onFinish={finishJob}
          onClose={close}
        />
      ) : null}
    </>
  );
}
