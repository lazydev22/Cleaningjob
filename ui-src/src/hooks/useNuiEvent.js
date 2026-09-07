import { useEffect } from 'react';

/** Subscribes to `window.message` events sent via SendNUIMessage. */
export function useNuiEvent(type, handler) {
  useEffect(() => {
    function onMessage(event) {
      if (event.data?.type === type) {
        handler(event.data);
      }
    }
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, [type, handler]);
}
