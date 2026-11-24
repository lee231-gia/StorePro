import React from 'react';
import { TextInput, View } from 'react-native';
import { AppIcon } from './Ui';
import { colors, createThemeAwareStyles } from '../theme';

export default function SearchBox({ value, onChangeText, placeholder = 'Search' }) {
  return <View style={styles.box}><AppIcon name="search-outline" size={19} color="#718078" /><TextInput value={value} onChangeText={onChangeText} placeholder={placeholder} placeholderTextColor="#78877F" style={styles.input} returnKeyType="search" accessibilityLabel={placeholder} /></View>;
}

const styles = createThemeAwareStyles({
  box: { minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 10, paddingHorizontal: 13, borderWidth: 1, borderColor: '#B9CAC2', borderRadius: 12, backgroundColor: '#FFFFFF' },
  input: { flex: 1, minWidth: 0, color: colors.text, fontSize: 15, paddingVertical: 10 },
});