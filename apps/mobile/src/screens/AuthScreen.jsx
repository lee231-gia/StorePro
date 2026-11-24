import React from 'react';
import { KeyboardAvoidingView, Platform, Text, View } from 'react-native';
import { sendPasswordResetEmail, signInWithEmailAndPassword } from 'firebase/auth';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppButton, Card, TextField } from '../components/Ui';
import { auth } from '../firebaseClient';
import { colors, createThemeAwareStyles } from '../theme';

function readableError(error) {
  if (error?.code === 'auth/invalid-email') return 'Enter a valid email address.';
  if (['auth/invalid-credential', 'auth/wrong-password', 'auth/user-not-found'].includes(error?.code)) return 'That email and password do not match a StorePro account.';
  if (error?.code === 'auth/network-request-failed') return 'Could not reach StorePro. Check your internet connection.';
  return error?.message || 'Could not connect to your StorePro account.';
}

export default function AuthScreen() {
  const [mode, setMode] = React.useState('signin');
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState('');
  const [success, setSuccess] = React.useState('');

  const submit = async () => {
    setError('');
    setSuccess('');
    setBusy(true);
    try {
      if (mode === 'signin') {
        await signInWithEmailAndPassword(auth, email.trim(), password);
      } else {
        await sendPasswordResetEmail(auth, email.trim());
        setSuccess('If this email belongs to a StorePro account, a reset link has been sent.');
      }
    } catch (reason) {
      setError(readableError(reason));
    } finally {
      setBusy(false);
    }
  };

  return <SafeAreaView style={styles.safe}>
    <KeyboardAvoidingView style={styles.fill} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <View style={styles.container}>
        <View style={styles.brandMark}><Text style={styles.brandInitial}>S</Text></View>
        <Text style={styles.brand}>StorePro</Text>
        <Text style={styles.tagline}>Your store, synced across devices</Text>
        <Card style={styles.card}>
          <Text style={styles.title}>{mode === 'signin' ? 'Sign in' : 'Reset your password'}</Text>
          <Text style={styles.description}>{mode === 'signin' ? 'Use the same email and password as the StorePro app.' : 'Enter the email linked to your StorePro account.'}</Text>
          <TextField label="Email address" placeholder="you@example.com" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} autoFocus />
          {mode === 'signin' && <TextField label="Password" placeholder="Your password" value={password} onChangeText={setPassword} secureTextEntry autoCapitalize="none" autoCorrect={false} />}
          {error ? <Text style={styles.error} accessibilityRole="alert">{error}</Text> : null}
          {success ? <Text style={styles.success} accessibilityRole="alert">{success}</Text> : null}
          <AppButton title={busy ? (mode === 'signin' ? 'Signing in…' : 'Sending…') : (mode === 'signin' ? 'Sign in' : 'Send reset link')} icon="arrow-forward" disabled={busy || !email.trim() || (mode === 'signin' && !password)} onPress={submit} />
          <Text style={styles.link} onPress={() => { setMode(mode === 'signin' ? 'reset' : 'signin'); setError(''); setSuccess(''); }} accessibilityRole="button">
            {mode === 'signin' ? 'Forgot password?' : 'Back to sign in'}
          </Text>
        </Card>
      </View>
    </KeyboardAvoidingView>
  </SafeAreaView>;
}

const styles = createThemeAwareStyles({
  safe: { flex: 1, backgroundColor: colors.background },
  fill: { flex: 1, justifyContent: 'center' },
  container: { width: '100%', maxWidth: 500, alignSelf: 'center', padding: 22 },
  brandMark: { width: 54, height: 54, alignItems: 'center', justifyContent: 'center', alignSelf: 'center', borderRadius: 17, backgroundColor: colors.primary },
  brandInitial: { color: '#FFFFFF', fontSize: 28, fontWeight: '800' },
  brand: { color: colors.text, fontSize: 28, fontWeight: '800', textAlign: 'center', marginTop: 12 },
  tagline: { color: colors.muted, fontSize: 15, textAlign: 'center', marginTop: 4, marginBottom: 22 },
  card: { padding: 20 },
  title: { color: colors.text, fontSize: 23, fontWeight: '800' },
  description: { color: colors.muted, fontSize: 15, lineHeight: 21, marginTop: 5, marginBottom: 20 },
  error: { color: colors.error, fontSize: 14, lineHeight: 20, marginBottom: 12 },
  success: { color: colors.success, fontSize: 14, lineHeight: 20, marginBottom: 12 },
  link: { color: colors.primary, fontSize: 15, fontWeight: '700', textAlign: 'center', paddingVertical: 16 },
});
