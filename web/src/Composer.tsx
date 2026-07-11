import { useState, type FormEvent } from 'react';
import { moods, request } from './api';
export function Composer({
  onSaved,
  onError,
}: {
  onSaved: () => Promise<void>;
  onError: (error: unknown) => void;
}) {
  const [mood, setMood] = useState(4),
    [note, setNote] = useState(''),
    [busy, setBusy] = useState(false);
  async function save(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await request('/checkins', { method: 'POST', body: JSON.stringify({ mood, note }) });
      setNote('');
      await onSaved();
    } catch (error) {
      onError(error);
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="composer panel">
      <h2>How are you feeling?</h2>
      <form onSubmit={save}>
        <fieldset className="moods">
          <legend className="sr-only">Choose your mood</legend>
          {moods.map((label, index) => (
            <label className="mood-option" key={label}>
              <input
                type="radio"
                name="mood"
                value={index + 1}
                checked={mood === index + 1}
                onChange={() => setMood(index + 1)}
              />
              <span className="mood-number">{index + 1}</span>
              <span>{label}</span>
            </label>
          ))}
        </fieldset>
        <label htmlFor="note">
          <strong>Notes</strong> (optional)
        </label>
        <textarea
          id="note"
          value={note}
          onChange={(event) => setNote(event.target.value)}
          placeholder="What is on your mind?"
          maxLength={2000}
          rows={3}
        />
        <button className="primary" disabled={busy}>
          {busy ? 'Saving…' : 'Save check in'}
        </button>
      </form>
    </section>
  );
}
