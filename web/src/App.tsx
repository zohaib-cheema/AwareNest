import { useEffect, useRef, useState } from 'react';
import { ApiError, request, type Day, type Entry, type User } from './api';
import { Auth } from './Auth';
import { Composer } from './Composer';
import { Entries } from './Entries';
import { WeekChart } from './WeekChart';
export function App() {
  const [user, setUser] = useState<User | null>(null),
    [initializing, setInitializing] = useState(true);
  const [entries, setEntries] = useState<Entry[]>([]),
    [days, setDays] = useState<Day[]>([]),
    [next, setNext] = useState<number | null>(null);
  const [filter, setFilter] = useState(''),
    [about, setAbout] = useState(false),
    [error, setError] = useState(''),
    [notice, setNotice] = useState('');
  const generation = useRef(0);
  const selectedFilter = useRef('');
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  function handleError(error: unknown) {
    if (error instanceof ApiError && error.status === 401) {
      setUser(null);
      setEntries([]);
      setDays([]);
    }
    setError(error instanceof Error ? error.message : 'Please try again');
  }
  async function refresh() {
    const current = ++generation.current;
    const filterValue = selectedFilter.current;
    let journal, weekly;
    try {
      [journal, weekly] = await Promise.all([
        request<{ entries: Entry[]; next: number | null }>(
          `/checkins${filterValue ? `?mood=${filterValue}` : ''}`,
        ),
        request<{ days: Day[] }>(`/weekly?timezone=${encodeURIComponent(timezone)}`),
      ]);
    } catch (error) {
      if (current !== generation.current) return;
      throw error;
    }
    if (current !== generation.current) return;
    setEntries(journal.entries);
    setNext(journal.next);
    setDays(weekly.days);
  }
  useEffect(() => {
    request<{ user: User }>('/me')
      .then((result) => setUser(result.user))
      .catch((error) => {
        if (!(error instanceof ApiError && error.status === 401)) handleError(error);
      })
      .finally(() => setInitializing(false));
  }, []);
  useEffect(() => {
    if (user) {
      setError('');
      refresh().catch(handleError);
    }
    return () => {
      generation.current += 1;
    };
  }, [user, filter]);
  async function saved() {
    setError('');
    await refresh();
    setNotice('Your check in was saved.');
  }
  async function remove(id: number) {
    try {
      await request(`/checkins/${id}`, { method: 'DELETE' });
      await refresh();
      setNotice('Check in deleted.');
    } catch (error) {
      handleError(error);
    }
  }
  async function loadMore() {
    const current = generation.current;
    try {
      const result = await request<{ entries: Entry[]; next: number | null }>(
        `/checkins?before=${next}${filter ? `&mood=${filter}` : ''}`,
      );
      if (current === generation.current) {
        setEntries((previous) => [...previous, ...result.entries]);
        setNext(result.next);
      }
    } catch (error) {
      if (current === generation.current) handleError(error);
    }
  }
  async function logout() {
    try {
      await request('/logout', { method: 'POST' });
      generation.current += 1;
      setUser(null);
      setEntries([]);
      setDays([]);
      setNotice('');
      setError('');
    } catch (error) {
      handleError(error);
    }
  }
  return (
    <>
      <a className="skip" href="#main">
        Skip to journal
      </a>
      <header className="topbar">
        <a className="brand" href="#main" onClick={() => setAbout(false)}>
          <span className="brand-mark" aria-hidden="true">
            <i />
            <i />
          </span>
          AwareNest
        </a>
        <nav aria-label="Main navigation">
          <button className={!about ? 'active' : ''} onClick={() => setAbout(false)}>
            Journal
          </button>
          <button className={about ? 'active' : ''} onClick={() => setAbout(true)}>
            About
          </button>
        </nav>
        {user ? (
          <button className="secondary signout" onClick={logout}>
            Sign out
          </button>
        ) : null}
      </header>
      <main id="main" className="container">
        <div className="intro">
          <h1>A little space for yourself.</h1>
          <p>Notice how you feel. One check in at a time.</p>
        </div>
        {error ? (
          <p className="error" role="alert">
            {error}
          </p>
        ) : null}
        <p className="sr-only" role="status" aria-live="polite">
          {notice}
        </p>
        {about ? (
          <section className="about panel">
            <h2>A journal for reflection.</h2>
            <p>
              AwareNest gives you a private place to record your mood and notice patterns over time.
            </p>
            <p>
              The chart shows daily averages from your own check ins. Days without an entry stay
              empty.
            </p>
            <p>
              This companion web app keeps its journal in PostgreSQL. The original Flutter app
              remains available in the same repository.
            </p>
            <p>AwareNest does not diagnose conditions or provide medical advice.</p>
            <button className="primary" onClick={() => setAbout(false)}>
              Back to journal
            </button>
          </section>
        ) : initializing ? (
          <p role="status">Opening your journal…</p>
        ) : user ? (
          <>
            <div className="journal-grid">
              <WeekChart days={days} />
              <Composer onSaved={saved} onError={handleError} />
            </div>
            <Entries
              entries={entries}
              filter={filter}
              setFilter={(value) => {
                selectedFilter.current = value;
                setFilter(value);
              }}
              onDelete={remove}
              next={next}
              loadMore={loadMore}
            />
          </>
        ) : (
          <Auth
            onLogin={(user) => {
              setUser(user);
              selectedFilter.current = '';
              setFilter('');
              setError('');
            }}
          />
        )}
      </main>
      <footer>A journal for reflection. No medical advice.</footer>
    </>
  );
}
