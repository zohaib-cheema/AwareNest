import { useState } from 'react';
import { moods, type Entry } from './api';
function dayLabel(date: string) {
  const value = new Date(date),
    today = new Date(),
    yesterday = new Date();
  yesterday.setDate(today.getDate() - 1);
  if (value.toDateString() === today.toDateString()) return 'Today';
  if (value.toDateString() === yesterday.toDateString()) return 'Yesterday';
  return value.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}
export function Entries({
  entries,
  filter,
  setFilter,
  onDelete,
  next,
  loadMore,
}: {
  entries: Entry[];
  filter: string;
  setFilter: (filter: string) => void;
  onDelete: (id: number) => Promise<void>;
  next: number | null;
  loadMore: () => Promise<void>;
}) {
  const [deleting, setDeleting] = useState<number | null>(null),
    [loading, setLoading] = useState(false),
    [confirm, setConfirm] = useState<number | null>(null);
  async function remove(id: number) {
    setDeleting(id);
    try {
      await onDelete(id);
      setConfirm(null);
    } finally {
      setDeleting(null);
    }
  }
  return (
    <section className="entries">
      <div className="section-heading">
        <h2>Recent check ins</h2>
        <label>
          <span className="sr-only">Filter by mood</span>
          <select
            value={filter}
            onChange={(event) => {
              setConfirm(null);
              setFilter(event.target.value);
            }}
          >
            <option value="">All moods</option>
            {moods.map((mood, index) => (
              <option key={mood} value={index + 1}>
                {mood}
              </option>
            ))}
          </select>
        </label>
      </div>
      {entries.length ? (
        <ul className="entry-list">
          {entries.map((entry) => (
            <li key={entry.id}>
              <time dateTime={entry.created_at}>{dayLabel(entry.created_at)}</time>
              <span className="mood-tag">{moods[entry.mood - 1]}</span>
              <p className={entry.note ? '' : 'muted'}>{entry.note || 'A moment to check in.'}</p>
              <div className="entry-actions">
                {confirm === entry.id ? (
                  <>
                    <button
                      className="text-button"
                      disabled={deleting === entry.id}
                      onClick={() => remove(entry.id)}
                    >
                      Confirm delete
                    </button>
                    <button className="text-button" onClick={() => setConfirm(null)}>
                      Keep
                    </button>
                  </>
                ) : (
                  <button
                    className="text-button"
                    aria-label={`Delete check in from ${dayLabel(entry.created_at)}`}
                    onClick={() => setConfirm(entry.id)}
                  >
                    Delete
                  </button>
                )}
              </div>
            </li>
          ))}
        </ul>
      ) : (
        <p className="empty-list">
          {filter
            ? 'No check ins match this mood yet.'
            : 'Your check ins will appear here. Start wherever you are.'}
        </p>
      )}
      {next ? (
        <button
          className="secondary more"
          disabled={loading}
          onClick={async () => {
            setLoading(true);
            try {
              await loadMore();
            } finally {
              setLoading(false);
            }
          }}
        >
          {loading ? 'Loading…' : 'Load earlier entries'}
        </button>
      ) : null}
    </section>
  );
}
