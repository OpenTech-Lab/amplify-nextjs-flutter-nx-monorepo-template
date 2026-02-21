'use client';

import { useEffect, useState } from 'react';
import { Amplify } from 'aws-amplify';
import {
  confirmSignUp,
  fetchAuthSession,
  getCurrentUser,
  signIn,
  signOut,
  signUp,
} from 'aws-amplify/auth';
import outputs from '../amplify_outputs.json';

let amplifyConfigured = false;

function configureAmplify() {
  if (!amplifyConfigured) {
    Amplify.configure(outputs);
    amplifyConfigured = true;
  }
}

export function AuthSample({ appName }: { appName: string }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [code, setCode] = useState('');
  const [needsConfirmation, setNeedsConfirmation] = useState(false);
  const [signedInUser, setSignedInUser] = useState<string | null>(null);
  const [status, setStatus] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    configureAmplify();
    void refreshUser();
  }, []);

  async function refreshUser() {
    try {
      const session = await fetchAuthSession();
      if (!session.tokens) {
        setSignedInUser(null);
        return;
      }

      const user = await getCurrentUser();
      setSignedInUser(user.signInDetails?.loginId ?? user.username ?? null);
    } catch {
      setSignedInUser(null);
    }
  }

  async function handleSignUp() {
    setBusy(true);
    setStatus('');

    try {
      const result = await signUp({
        username: email,
        password,
        options: {
          userAttributes: {
            email,
          },
        },
      });

      if (result.nextStep.signUpStep === 'CONFIRM_SIGN_UP') {
        setNeedsConfirmation(true);
        setStatus('Sign-up complete. Check your email for a confirmation code.');
      } else {
        setStatus('Sign-up complete. You can sign in now.');
      }
    } catch (error) {
      setStatus(error instanceof Error ? error.message : 'Sign-up failed');
    } finally {
      setBusy(false);
    }
  }

  async function handleConfirmSignUp() {
    setBusy(true);
    setStatus('');

    try {
      await confirmSignUp({
        username: email,
        confirmationCode: code,
      });

      setNeedsConfirmation(false);
      setStatus('Account confirmed. Sign in now.');
    } catch (error) {
      setStatus(error instanceof Error ? error.message : 'Confirmation failed');
    } finally {
      setBusy(false);
    }
  }

  async function handleSignIn() {
    setBusy(true);
    setStatus('');

    try {
      const result = await signIn({
        username: email,
        password,
      });

      if (result.isSignedIn) {
        await refreshUser();
        setStatus('Signed in successfully.');
        return;
      }

      setStatus(`Sign-in next step: ${result.nextStep.signInStep}`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : 'Sign-in failed');
    } finally {
      setBusy(false);
    }
  }

  async function handleSignOut() {
    setBusy(true);
    setStatus('');

    try {
      await signOut();
      await refreshUser();
      setStatus('Signed out.');
    } catch (error) {
      setStatus(error instanceof Error ? error.message : 'Sign-out failed');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main
      style={{
        maxWidth: 440,
        margin: '40px auto',
        padding: 24,
        fontFamily: 'system-ui, sans-serif',
        border: '1px solid #ddd',
        borderRadius: 12,
      }}
    >
      <h1 style={{ marginTop: 0 }}>Amplify Gen 2 Login Sample ({appName})</h1>
      <p style={{ marginTop: 0 }}>User pool email sign-in with confirm/sign-in/sign-out flow.</p>

      <label htmlFor="email">Email</label>
      <input
        id="email"
        type="email"
        value={email}
        onChange={(event) => setEmail(event.target.value)}
        style={{ width: '100%', padding: 10, marginTop: 6, marginBottom: 12 }}
      />

      <label htmlFor="password">Password</label>
      <input
        id="password"
        type="password"
        value={password}
        onChange={(event) => setPassword(event.target.value)}
        style={{ width: '100%', padding: 10, marginTop: 6, marginBottom: 12 }}
      />

      {needsConfirmation ? (
        <>
          <label htmlFor="code">Confirmation code</label>
          <input
            id="code"
            value={code}
            onChange={(event) => setCode(event.target.value)}
            style={{ width: '100%', padding: 10, marginTop: 6, marginBottom: 12 }}
          />
          <button type="button" onClick={handleConfirmSignUp} disabled={busy || !code}>
            Confirm sign up
          </button>
        </>
      ) : (
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button type="button" onClick={handleSignUp} disabled={busy || !email || !password}>
            Sign up
          </button>
          <button type="button" onClick={handleSignIn} disabled={busy || !email || !password}>
            Sign in
          </button>
          <button type="button" onClick={handleSignOut} disabled={busy || !signedInUser}>
            Sign out
          </button>
        </div>
      )}

      <p style={{ marginTop: 16 }}>
        <strong>Signed in user:</strong> {signedInUser ?? 'none'}
      </p>
      {status ? <p style={{ color: '#0f766e' }}>{status}</p> : null}
    </main>
  );
}
