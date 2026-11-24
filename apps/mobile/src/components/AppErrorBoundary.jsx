import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { colors, createThemeAwareStyles } from '../theme';

export default class AppErrorBoundary extends React.Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error('StorePro could not render the signed-in app.', error, info.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return <View style={styles.screen} accessibilityRole="alert">
      <View style={styles.card}>
        <Text style={styles.title}>StorePro could not open this screen</Text>
        <Text style={styles.message}>{this.state.error.message || 'A display error stopped the app from loading.'}</Text>
        <Pressable accessibilityRole="button" onPress={() => this.setState({ error: null })} style={styles.button}>
          <Text style={styles.buttonText}>Try again</Text>
        </Pressable>
      </View>
    </View>;
  }
}

const styles = createThemeAwareStyles({
  screen: { flex: 1, justifyContent: 'center', padding: 22, backgroundColor: colors.background },
  card: { width: '100%', maxWidth: 520, alignSelf: 'center', gap: 14, padding: 22, borderWidth: 1, borderColor: colors.border, borderRadius: 18, backgroundColor: colors.surface },
  title: { color: colors.text, fontSize: 22, fontWeight: '800' },
  message: { color: colors.muted, fontSize: 15, lineHeight: 22 },
  button: { minHeight: 50, alignItems: 'center', justifyContent: 'center', borderRadius: 12, backgroundColor: colors.primary },
  buttonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '800' },
});
