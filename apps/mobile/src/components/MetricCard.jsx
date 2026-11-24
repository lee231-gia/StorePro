import React from 'react';
import { Text, View } from 'react-native';
import { AppIcon } from './Ui';
import { colors, createThemeAwareStyles } from '../theme';

const tones = {
  teal: { backgroundColor: '#E5EFEB', color: colors.primary },
  gold: { backgroundColor: '#F8F0D9', color: '#785E17' },
  mint: { backgroundColor: '#E5F2E9', color: '#28674D' },
  coral: { backgroundColor: '#F9E9E4', color: '#A0473D' },
};

export default function MetricCard({ label, value, note, icon, tone = 'teal' }) {
  return <View style={styles.card}><View style={[styles.icon, { backgroundColor: tones[tone].backgroundColor }]}><AppIcon name={icon} size={21} color={tones[tone].color} /></View><View style={styles.copy}><Text style={styles.label}>{label}</Text><Text style={styles.value} numberOfLines={1}>{value}</Text><Text style={styles.note} numberOfLines={1}>{note}</Text></View></View>;
}

const styles = createThemeAwareStyles({
  card: { minHeight: 118, flex: 1, flexDirection: 'row', alignItems: 'flex-start', gap: 10, padding: 13, borderWidth: 1, borderColor: colors.border, borderRadius: 15, backgroundColor: colors.surface },
  icon: { width: 38, height: 38, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  copy: { flex: 1, minWidth: 0, gap: 3 },
  label: { color: colors.muted, fontSize: 14, fontWeight: '700' },
  value: { color: colors.text, fontSize: 23, lineHeight: 29, fontWeight: '800' },
  note: { color: colors.muted, fontSize: 13 },
});
