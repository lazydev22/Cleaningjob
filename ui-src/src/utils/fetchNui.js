export function getParentResourceName() {
  return typeof window.GetParentResourceName === 'function'
    ? window.GetParentResourceName()
    : 'dsml_cleaningjob';
}

export async function fetchNui(eventName, data) {
  const resp = await fetch(`https://${getParentResourceName()}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });

  return resp.json().catch(() => ({}));
}
