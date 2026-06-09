import { useState, type FormEvent } from 'react';
import { request, type User } from './api';
export function Auth({ onLogin }: { onLogin: (user: User) => void }) {
  const [signup, setSignup] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    const form = new FormData(event.currentTarget);
    const username = String(form.get('username')),
      password = String(form.get('password'));
    try {
      if (signup)
        await request('/signup', {
          method: 'POST',
          body: JSON.stringify({ username, password, email: form.get('email') }),
        });
      const { user } = await request<{ user: User }>('/login', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      });
      onLogin(user);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Please try again');
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="auth panel">
      <h2>{signup ? 'Make room for reflection.' : 'Welcome back.'}</h2>
      <p>
        {signup
          ? 'Create your account to begin a private journal.'
          : 'Sign in to your private journal.'}
      </p>
      <form onSubmit={submit}>
        <label htmlFor="username">Name</label>
        <input
          id="username"
          name="username"
          autoComplete="username"
          minLength={3}
          maxLength={40}
          required
        />
        {signup ? (
          <>
            <label htmlFor="email">Email</label>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              maxLength={254}
              required
            />
          </>
        ) : null}
        <label htmlFor="password">Password</label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete={signup ? 'new-password' : 'current-password'}
          minLength={signup ? 10 : undefined}
          required
        />
        {signup ? (
          <p className="hint">
            Use at least 10 characters. Passwords can contain at most 72 bytes.
          </p>
        ) : null}
        {error ? (
          <p role="alert" className="error">
            {error}
          </p>
        ) : null}
        <button className="primary" disabled={busy}>
          {busy ? 'Please wait…' : signup ? 'Create account' : 'Sign in'}
        </button>
      </form>
      <button
        className="text-button"
        onClick={() => {
          setSignup(!signup);
          setError('');
        }}
      >
        {signup ? 'Already have an account? Sign in' : 'New here? Create an account'}
      </button>
    </section>
  );
}
