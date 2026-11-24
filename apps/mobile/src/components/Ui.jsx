import React from 'react';
import { Ionicons } from '@expo/vector-icons';
import { KeyboardAvoidingView, Modal, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { colors, createThemeAwareStyles } from '../theme';

export function AppIcon({ name, size = 20, color = colors.muted }) {
  return <Ionicons name={name} size={size} color={color} />;
}

export function Screen({ title, subtitle, action, children, scroll = true, showHeader = true }) {
  const body = scroll
    ? <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.screenContent} showsVerticalScrollIndicator={false}>{children}</ScrollView>
    : <View style={styles.screenContent}>{children}</View>;
  return (
    <View style={styles.screen}>
      {showHeader && <View style={styles.screenHeader}>
        <View style={styles.headingCopy}><Text style={styles.screenTitle}>{title}</Text>{subtitle ? <Text style={styles.screenSubtitle}>{subtitle}</Text> : null}</View>
        {action || null}
      </View>}
      {body}
    </View>
  );
}

export function Card({ children, style }) {
  return <View style={[styles.card, style]}>{children}</View>;
}

export function SectionTitle({ title, action, style }) {
  return <View style={[styles.sectionHeader, style]}><Text style={styles.sectionTitle}>{title}</Text>{action || null}</View>;
}

export function AppButton({ title, onPress, icon, variant = 'primary', disabled = false, compact = false, style, accessibilityLabel, ...props }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel || title}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [styles.button, compact && styles.buttonCompact, styles[`button_${variant}`], disabled && styles.disabled, pressed && !disabled && styles.pressed, style]}
      {...props}
    >
      {icon ? <AppIcon name={icon} size={18} color={variant === 'primary' ? '#FFFFFF' : variant === 'danger' ? '#9A3029' : colors.primary} /> : null}
      <Text style={[styles.buttonText, variant !== 'primary' && styles.buttonTextAlt, variant === 'danger' && styles.buttonTextDanger]}>{title}</Text>
    </Pressable>
  );
}

export function IconButton({ name, onPress, label, size = 20, style, color = colors.muted }) {
  return <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress} style={({ pressed }) => [styles.iconButton, pressed && styles.pressed, style]}><AppIcon name={name} size={size} color={color} /></Pressable>;
}

export function Chip({ label, selected = false, onPress, style }) {
  return <Pressable accessibilityRole="button" accessibilityState={{ selected }} onPress={onPress} style={[styles.chip, selected && styles.chipSelected, style]}><Text style={[styles.chipText, selected && styles.chipTextSelected]}>{label}</Text></Pressable>;
}

export function SegmentedTabs({ tabs, value, onChange }) {
  return <View accessibilityRole="tablist" style={styles.segmentedTabs}>{tabs.map((tab) => {
    const selected = tab.key === value;
    return <Pressable key={tab.key} accessibilityRole="tab" accessibilityState={{ selected }} onPress={() => onChange(tab.key)} style={[styles.segmentedTab, selected && styles.segmentedTabSelected]}>
      <Text style={[styles.segmentedTabText, selected && styles.segmentedTabTextSelected]}>{tab.label}</Text>
    </Pressable>;
  })}</View>;
}

export function StatusPill({ label, tone = 'neutral' }) {
  return <View style={[styles.pill, styles[`pill_${tone}`]]}><Text style={[styles.pillText, styles[`pillText_${tone}`]]}>{label}</Text></View>;
}

export function TextField({ label, value, onChangeText, placeholder, keyboardType, hint, autoFocus, multiline = false, secureTextEntry = false, autoCapitalize, autoCorrect, editable = true, maxLength }) {
  return <View style={styles.fieldWrap}><Text style={styles.fieldLabel}>{label}</Text><TextInput
    accessibilityLabel={label}
    value={value}
    onChangeText={onChangeText}
    placeholder={placeholder}
    placeholderTextColor={colors.muted}
    keyboardType={keyboardType}
    secureTextEntry={secureTextEntry}
    autoCapitalize={autoCapitalize}
    autoCorrect={autoCorrect}
    editable={editable}
    maxLength={maxLength}
    autoFocus={autoFocus}
    multiline={multiline}
    style={[styles.input, multiline && styles.inputMultiline]}
  />{hint ? <Text style={styles.fieldHint}>{hint}</Text> : null}</View>;
}

export function AppModal({ visible, title, subtitle, onClose, children, actions }) {
  return <Modal visible={visible} transparent animationType="slide" statusBarTranslucent onRequestClose={onClose}>
    <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <Pressable style={StyleSheet.absoluteFill} onPress={onClose} accessibilityLabel="Close dialog" />
      <View style={styles.modalCard}>
        <View style={styles.modalHeading}><View style={styles.headingCopy}><Text style={styles.modalTitle}>{title}</Text>{subtitle ? <Text style={styles.modalSubtitle}>{subtitle}</Text> : null}</View><IconButton name="close" label="Close" onPress={onClose} /></View>
        <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.modalBody} showsVerticalScrollIndicator={false}>{children}</ScrollView>
        {actions ? <View style={styles.modalActions}>{actions}</View> : null}
      </View>
    </KeyboardAvoidingView>
  </Modal>;
}

export function EmptyState({ title, message, icon = 'file-tray-outline' }) {
  return <View style={styles.emptyState}><View style={styles.emptyIcon}><AppIcon name={icon} size={24} color={colors.primary} /></View><Text style={styles.emptyTitle}>{title}</Text><Text style={styles.emptyMessage}>{message}</Text></View>;
}

const styles = createThemeAwareStyles({
  screen: { flex: 1, backgroundColor: colors.background },
  screenHeader: { width: '100%', maxWidth: 1320, alignSelf: 'center', minHeight: 86, paddingHorizontal: 20, paddingTop: 12, paddingBottom: 14, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  headingCopy: { flex: 1, minWidth: 0 },
  screenTitle: { color: colors.text, fontSize: 25, lineHeight: 32, fontWeight: '700', letterSpacing: -0.35 },
  screenSubtitle: { color: colors.muted, fontSize: 15, lineHeight: 21, marginTop: 4 },
  screenContent: { width: '100%', maxWidth: 1320, alignSelf: 'center', paddingHorizontal: 16, paddingTop: 4, paddingBottom: 30, gap: 15 },
  card: { borderRadius: 16, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, padding: 16 },
  sectionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginTop: 5 },
  sectionTitle: { color: colors.text, fontSize: 18, fontWeight: '700' },
  button: { minHeight: 50, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, paddingHorizontal: 16, borderRadius: 12, borderWidth: 1 },
  buttonCompact: { minHeight: 42, paddingHorizontal: 13 },
  button_primary: { backgroundColor: colors.primary, borderColor: colors.primary },
  button_outline: { backgroundColor: colors.surface, borderColor: colors.border },
  button_soft: { backgroundColor: colors.primarySoft, borderColor: colors.primarySoft },
  button_danger: { backgroundColor: '#FBE9E6', borderColor: '#F0D1CB' },
  buttonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '800' },
  buttonTextAlt: { color: colors.primary },
  buttonTextDanger: { color: '#9A3029' },
  disabled: { opacity: 0.5 },
  pressed: { opacity: 0.82 },
  iconButton: { width: 46, height: 46, borderRadius: 13, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface, alignItems: 'center', justifyContent: 'center' },
  chip: { minHeight: 42, paddingHorizontal: 14, borderRadius: 22, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface, justifyContent: 'center', alignItems: 'center' },
  chipSelected: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipText: { color: colors.muted, fontSize: 14, fontWeight: '700' },
  chipTextSelected: { color: '#FFFFFF' },
  segmentedTabs: { flexDirection: 'row', alignSelf: 'flex-start', padding: 4, gap: 4, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.surface },
  segmentedTab: { minHeight: 44, minWidth: 82, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 12, borderRadius: 10, backgroundColor: colors.surface },
  segmentedTabSelected: { backgroundColor: colors.primary },
  segmentedTabText: { color: colors.text, fontSize: 15, fontWeight: '700' },
  segmentedTabTextSelected: { color: '#FFFFFF' },
  pill: { paddingHorizontal: 10, minHeight: 28, borderRadius: 14, justifyContent: 'center' },
  pill_success: { backgroundColor: colors.successSoft },
  pill_warning: { backgroundColor: colors.warningSoft },
  pill_neutral: { backgroundColor: colors.primarySoft },
  pillText: { fontSize: 12, fontWeight: '800' },
  pillText_success: { color: colors.success },
  pillText_warning: { color: colors.warning },
  pillText_neutral: { color: colors.primary },
  fieldWrap: { gap: 7, marginBottom: 14 },
  fieldLabel: { color: colors.text, fontSize: 15, fontWeight: '700' },
  input: { minHeight: 50, borderWidth: 1, borderColor: '#B9CAC2', borderRadius: 11, paddingHorizontal: 13, paddingVertical: 12, color: colors.text, backgroundColor: '#FFFFFF', fontSize: 16 },
  inputMultiline: { minHeight: 86, textAlignVertical: 'top' },
  fieldHint: { color: colors.muted, fontSize: 14, lineHeight: 19 },
  modalOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#10211B77', paddingTop: 30 },
  modalCard: { maxHeight: '92%', borderTopLeftRadius: 22, borderTopRightRadius: 22, overflow: 'hidden', backgroundColor: colors.surface, paddingBottom: Platform.OS === 'ios' ? 24 : 12 },
  modalHeading: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 10, paddingHorizontal: 18, borderBottomWidth: 1, borderBottomColor: colors.border },
  modalTitle: { color: colors.text, fontSize: 20, fontWeight: '800' },
  modalSubtitle: { color: colors.muted, fontSize: 13, marginTop: 4 },
  modalBody: { paddingHorizontal: 18, paddingTop: 18, paddingBottom: 10 },
  modalActions: { flexDirection: 'row', gap: 10, paddingHorizontal: 18, paddingTop: 10 },
  emptyState: { alignItems: 'center', paddingVertical: 28, paddingHorizontal: 20 },
  emptyIcon: { width: 50, height: 50, borderRadius: 16, backgroundColor: colors.primarySoft, alignItems: 'center', justifyContent: 'center', marginBottom: 10 },
  emptyTitle: { fontSize: 16, color: colors.text, fontWeight: '800' },
  emptyMessage: { fontSize: 14, lineHeight: 20, color: colors.muted, textAlign: 'center', marginTop: 5 },
});
