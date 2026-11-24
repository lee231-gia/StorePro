import React from 'react';
import { Alert, Image, Platform, Pressable, ScrollView, Text, View } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { AppButton, AppModal, Chip, TextField } from './Ui';
import { uploadProductImage } from '../services/productImageUpload';
import { colors, createThemeAwareStyles } from '../theme';

const LIFE_TYPES = ['Expiry Date', 'Best Before', 'Best if Used By', 'Use-By', 'Manufacturing Date (MFG)', 'Production Date', 'Packed On', 'Sell By', 'Period After Opening'];
const newId = (prefix) => `${prefix}-${globalThis.crypto?.randomUUID?.() || Math.random().toString(36).slice(2)}`;
const blankVariant = () => ({ id: newId('variant'), name: '', sku: '', unit: 'piece', packaging: 'Solo', pcsPerUnit: '1', price: '', originalPrice: '', costPrice: '', imageUrl: '', imageFile: null, conditions: [], discounts: [], batches: [] });
const today = () => { const date = new Date(); return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`; };
const blankProduct = (categories, threshold) => ({ name: '', description: '', category: categories[0] || '', hasVariants: false, imageUrl: '', imageFile: null, minStock: String(threshold ?? 12), variants: [blankVariant()] });

function existingProduct(row, categories, threshold) {
  if (!row) return blankProduct(categories, threshold);
  const raw = row.__raw || {};
  const variants = (raw.variants || []).map((variant, index) => ({
    ...blankVariant(), ...variant, id: String(variant.id || `variant-${index}`), imageFile: null,
    name: variant.name || '', sku: variant.sku || '', unit: variant.unit || 'piece', packaging: variant.packaging || '',
    pcsPerUnit: String(variant.pcsPerUnit || 1), price: String(variant.price ?? ''), originalPrice: String(variant.originalPrice ?? variant.price ?? ''),
    costPrice: String(variant.costPrice ?? ''), imageUrl: variant.imageUrl || '',
    batches: (variant.batches || []).map((batch) => ({ ...batch, indicators: (batch.indicators || []).map((item) => ({ ...item })) })),
  }));
  return {
    name: raw.name || row.name || '', description: raw.description || '', category: raw.categoryName || row.category || categories[0] || '',
    hasVariants: Boolean(raw.hasVariants || variants.length > 1), imageUrl: raw.imageUrl || '', imageFile: null,
    minStock: String(raw.minStock ?? row.minStock ?? threshold ?? 12),
    variants: variants.length ? variants : [{ ...blankVariant(), name: row.variantName || '', sku: row.sku || '', unit: row.unit || 'piece', price: String(row.price ?? ''), costPrice: String(row.cost ?? '') }],
  };
}

function PhotoPicker({ label, imageFile, imageUrl, onChange, onRemove }) {
  const pick = async (source = 'gallery') => {
    try {
      if (source === 'camera') {
        const permission = await ImagePicker.requestCameraPermissionsAsync();
        if (!permission.granted) return Alert.alert('Camera permission needed', 'Allow camera access to take a product photo.');
      }
      const launch = source === 'camera' ? ImagePicker.launchCameraAsync : ImagePicker.launchImageLibraryAsync;
      const result = await launch({ mediaTypes: ['images'], allowsEditing: true, aspect: [1, 1], quality: 0.82 });
      if (!result.canceled && result.assets?.[0]) onChange(result.assets[0]);
    } catch (error) { Alert.alert('Could not open photos', error.message || 'Choose an image and try again.'); }
  };
  const uri = imageFile?.uri || imageUrl;
  return <View style={styles.photoBox}><View style={styles.preview}>{uri ? <Image source={{ uri }} style={styles.previewImage} resizeMode="cover" /> : <Text style={styles.noPhoto}>Image</Text>}</View><View style={styles.photoActions}><Text style={styles.photoTitle}>{label}</Text><Text style={styles.photoHint}>JPG or PNG · up to 10 MB</Text><View style={styles.photoButtons}>{Platform.OS !== 'web' && <AppButton compact variant="outline" title="Camera" icon="camera-outline" onPress={() => pick('camera')} />}<AppButton compact variant="outline" title={uri ? 'Change photo' : 'Gallery'} icon="image-outline" onPress={() => pick('gallery')} /><Pressable onPress={onRemove} disabled={!uri} accessibilityRole="button" accessibilityLabel="Remove image"><Text style={[styles.removePhoto, !uri && styles.disabledText]}>Remove</Text></Pressable></View></View></View>;
}

export default function ProductWizard({ product, categories, lowStockThreshold, onClose, onSave, onAddCategory }) {
  const [form, setForm] = React.useState(() => existingProduct(product, categories, lowStockThreshold));
  const [step, setStep] = React.useState(0);
  const [saving, setSaving] = React.useState(false);
  const [batchTarget, setBatchTarget] = React.useState(-1);
  const [batchDraft, setBatchDraft] = React.useState(null);
  const [categoryDraft, setCategoryDraft] = React.useState('');
  const [categoryOpen, setCategoryOpen] = React.useState(false);
  const [advancedOptions, setAdvancedOptions] = React.useState({});
  const setVariant = (index, variant) => setForm((current) => ({ ...current, variants: current.variants.map((item, at) => at === index ? variant : item) }));
  const openBatch = (index) => { setBatchTarget(index); setBatchDraft({ batchNumber: '', qty: '', costPrice: String(form.variants[index].costPrice || ''), indicators: [] }); };
  const next = () => {
    if (step === 0 && !form.name.trim()) return Alert.alert('Product name required', 'Enter a product name before continuing.');
    if (step === 1 && !form.variants.length) return Alert.alert('Add a variant', 'This product needs at least one variant.');
    if (step === 1 && form.variants.some((variant) => variant.price === '' || Number(variant.price) < 0)) return Alert.alert('Check selling prices', 'Enter a valid selling price for every variant.');
    setStep((value) => Math.min(2, value + 1));
  };
  const addCategory = async () => {
    const name = categoryDraft.trim();
    if (!name) return;
    try { await onAddCategory(name); setForm((current) => ({ ...current, category: name })); setCategoryDraft(''); setCategoryOpen(false); }
    catch (error) { Alert.alert('Could not add category', error.message); }
  };
  const addBatch = () => {
    const qty = Number(batchDraft?.qty);
    if (!Number.isFinite(qty) || qty <= 0) return Alert.alert('Quantity required', 'Enter a stock quantity greater than zero.');
    const indicators = (batchDraft.indicators || []).filter((indicator) => indicator.type && indicator.date);
    const batch = { id: newId('batch'), batchNumber: batchDraft.batchNumber.trim(), qty, costPrice: Number(batchDraft.costPrice) || 0, indicators, addedOn: today() };
    setVariant(batchTarget, { ...form.variants[batchTarget], batches: [...form.variants[batchTarget].batches, batch] });
    setBatchTarget(-1); setBatchDraft(null);
  };
  const submit = async () => {
    setSaving(true);
    try {
      const imageUrl = form.imageFile ? await uploadProductImage(form.imageFile, 'products') : form.imageUrl;
      const variants = await Promise.all(form.variants.map(async (variant) => ({
        id: variant.id, name: variant.name.trim() || form.name.trim(), sku: variant.sku.trim(), unit: variant.unit.trim() || 'piece',
        packaging: variant.packaging.trim(), pcsPerUnit: Math.max(1, Number(variant.pcsPerUnit) || 1), price: Number(variant.price) || 0,
        originalPrice: Number(variant.originalPrice || variant.price) || 0, costPrice: Number(variant.costPrice) || 0,
        hasDiscount: Boolean(variant.discounts?.length), discounts: variant.discounts || [], conditions: variant.conditions || [],
        imageUrl: variant.imageFile ? await uploadProductImage(variant.imageFile, 'variants') : variant.imageUrl,
        batches: variant.batches.map((batch) => ({ ...batch, qty: Number(batch.qty) || 0, costPrice: Number(batch.costPrice) || 0 })),
      })));
      await onSave({ name: form.name.trim(), description: form.description.trim(), category: form.category || 'Uncategorized', hasVariants: form.hasVariants, imageUrl, minStock: Number(form.minStock) || 0, variants });
    } catch (error) { Alert.alert('Could not save product', error.message || 'Please try again.'); }
    finally { setSaving(false); }
  };
  const actionTitle = step === 2 ? (product ? 'Save changes' : 'Add product') : `Next: ${['Variants', 'Stocks'][step]}`;
  const actions = <><AppButton title={step === 0 ? 'Cancel' : 'Back'} variant="outline" style={styles.actionButton} disabled={saving} onPress={step === 0 ? onClose : () => setStep((value) => value - 1)} /><AppButton title={saving ? 'Saving…' : actionTitle} icon={step === 2 ? 'checkmark' : 'arrow-forward'} style={styles.actionButton} disabled={saving} onPress={step === 2 ? submit : next} /></>;
  return <AppModal visible title={product ? 'Edit product' : 'Add product'} subtitle="Basic Info  ·  Variants  ·  Stocks" onClose={onClose} actions={actions}>
    <View style={styles.steps}>{['Basic Info', 'Variants', 'Stocks'].map((label, index) => <Pressable key={label} accessibilityState={{ selected: step === index }} onPress={() => index < step && setStep(index)} style={[styles.step, step === index && styles.stepActive, index < step && styles.stepDone]}><Text style={[styles.stepNumber, (step === index || index < step) && styles.stepNumberActive]}>{index < step ? '✓' : `${index + 1}`}</Text><Text style={[styles.stepLabel, step === index && styles.stepLabelActive]}>{label}</Text></Pressable>)}</View>
    <Text style={styles.stepCaption}>Step {step + 1} of 3</Text>
    {step === 0 && <View style={styles.stepBody}>
      <PhotoPicker label="Product photo" imageFile={form.imageFile} imageUrl={form.imageUrl} onChange={(imageFile) => setForm((current) => ({ ...current, imageFile }))} onRemove={() => setForm((current) => ({ ...current, imageFile: null, imageUrl: '' }))} />
      <TextField label="Product name" placeholder="e.g. Coca-Cola" value={form.name} onChangeText={(name) => setForm((current) => ({ ...current, name }))} autoFocus />
      <TextField label="Description (optional)" placeholder="Brief product description" value={form.description} onChangeText={(description) => setForm((current) => ({ ...current, description }))} multiline />
      <View><Text style={styles.fieldLabel}>Category</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>{categories.map((item) => <Chip key={item} label={item} selected={form.category === item} onPress={() => setForm((current) => ({ ...current, category: item }))} />)}<AppButton compact variant="outline" title="Add category" icon="add" onPress={() => setCategoryOpen((value) => !value)} /></ScrollView>{categoryOpen && <View style={styles.categoryEditor}><TextField label="New category" value={categoryDraft} onChangeText={setCategoryDraft} /><AppButton title="Save category" compact icon="checkmark" onPress={addCategory} /></View>}</View>
      <TextField label="Low stock alert at" keyboardType="number-pad" value={form.minStock} onChangeText={(minStock) => setForm((current) => ({ ...current, minStock }))} />
      <Text style={styles.fieldLabel}>Product type</Text><View style={styles.typeChoices}>{[[false, 'Single product', 'One size or option'], [true, 'Has variants', 'Sizes, packs, or types']].map(([hasVariants, title, caption]) => <Pressable key={String(hasVariants)} onPress={() => setForm((current) => ({ ...current, hasVariants, variants: hasVariants ? current.variants : [current.variants[0] || blankVariant()] }))} style={[styles.typeChoice, form.hasVariants === hasVariants && styles.typeChoiceSelected]}><View style={[styles.radio, form.hasVariants === hasVariants && styles.radioSelected]} /><View style={styles.typeCopy}><Text style={styles.typeTitle}>{title}</Text><Text style={styles.typeCaption}>{caption}</Text></View></Pressable>)}</View>
    </View>}
    {step === 1 && <View style={styles.stepBody}><View style={styles.sectionHeading}><View style={styles.typeCopy}><Text style={styles.variantHeading}>{form.hasVariants ? 'Product variants' : 'Product details'}</Text><Text style={styles.typeCaption}>{form.hasVariants ? 'Set prices and units for each option.' : 'Set the price and unit for this product.'}</Text></View>{form.hasVariants && <AppButton compact variant="outline" title="Add" icon="add" onPress={() => setForm((current) => ({ ...current, variants: [...current.variants, blankVariant()] }))} />}</View>
      {form.variants.map((variant, index) => <View style={styles.variantCard} key={variant.id}><View style={styles.variantCardHead}><Text style={styles.variantHeading}>{variant.name || `Variant ${index + 1}`}</Text>{form.hasVariants && form.variants.length > 1 && <Pressable onPress={() => setForm((current) => ({ ...current, variants: current.variants.filter((_, at) => at !== index) }))}><Text style={styles.removePhoto}>Remove</Text></Pressable>}</View><PhotoPicker label="Variant photo (optional)" imageFile={variant.imageFile} imageUrl={variant.imageUrl} onChange={(imageFile) => setVariant(index, { ...variant, imageFile })} onRemove={() => setVariant(index, { ...variant, imageFile: null, imageUrl: '' })} />
        <TextField label={form.hasVariants ? 'Variant name' : 'Variant name (optional)'} placeholder="e.g. 1 liter, Family pack" value={variant.name} onChangeText={(name) => setVariant(index, { ...variant, name })} />
        <TextField label="SKU (optional)" placeholder="Stock code" value={variant.sku} onChangeText={(sku) => setVariant(index, { ...variant, sku })} />
        <View style={styles.formRow}><View style={styles.formCell}><TextField label="Unit" placeholder="piece, bottle, kg" value={variant.unit} onChangeText={(unit) => setVariant(index, { ...variant, unit })} /></View><View style={styles.formCell}><TextField label="Packaging" placeholder="Solo, pack" value={variant.packaging} onChangeText={(packaging) => setVariant(index, { ...variant, packaging })} /></View></View>
        <View style={styles.formRow}><View style={styles.formCell}><TextField label="Pieces per unit" keyboardType="number-pad" value={variant.pcsPerUnit} onChangeText={(pcsPerUnit) => setVariant(index, { ...variant, pcsPerUnit })} /></View><View style={styles.formCell}><TextField label="Selling price (₱)" keyboardType="decimal-pad" value={variant.price} onChangeText={(price) => setVariant(index, { ...variant, price })} /></View></View>
        <View style={styles.formRow}><View style={styles.formCell}><TextField label="Original price (₱)" keyboardType="decimal-pad" value={variant.originalPrice} onChangeText={(originalPrice) => setVariant(index, { ...variant, originalPrice })} /></View><View style={styles.formCell}><TextField label="Cost price (₱)" keyboardType="decimal-pad" value={variant.costPrice} onChangeText={(costPrice) => setVariant(index, { ...variant, costPrice })} /></View></View>
        <Pressable accessibilityRole="button" accessibilityState={{ expanded: Boolean(advancedOptions[variant.id]) }} onPress={() => setAdvancedOptions((current) => ({ ...current, [variant.id]: !current[variant.id] }))}><Text style={styles.advancedToggle}>{advancedOptions[variant.id] ? 'Hide optional conditions and discounts' : 'Optional conditions and discounts'}</Text></Pressable>
        {advancedOptions[variant.id] && <View style={styles.advancedOptions}><View style={styles.sectionHeading}><Text style={styles.fieldLabel}>Conditions</Text><AppButton compact variant="outline" title="Add" icon="add" onPress={() => setVariant(index, { ...variant, conditions: [...(variant.conditions || []), { name: '', additionalPrice: 0 }] })} /></View>{(variant.conditions || []).map((condition, at) => <View style={styles.advancedRow} key={`condition-${at}`}><View style={styles.formCell}><TextField label="Condition" placeholder="e.g. Chilled" value={condition.name} onChangeText={(name) => setVariant(index, { ...variant, conditions: variant.conditions.map((item, itemAt) => itemAt === at ? { ...item, name } : item) })} /></View><View style={styles.formCell}><TextField label="Extra price (₱)" keyboardType="decimal-pad" value={String(condition.additionalPrice ?? 0)} onChangeText={(value) => setVariant(index, { ...variant, conditions: variant.conditions.map((item, itemAt) => itemAt === at ? { ...item, additionalPrice: Number(value) || 0 } : item) })} /></View><Pressable accessibilityRole="button" accessibilityLabel="Remove condition" onPress={() => setVariant(index, { ...variant, conditions: variant.conditions.filter((_, itemAt) => itemAt !== at) })}><Text style={styles.removePhoto}>Remove</Text></Pressable></View>)}
          <View style={styles.sectionHeading}><Text style={styles.fieldLabel}>Discounts</Text><AppButton compact variant="outline" title="Add" icon="add" onPress={() => setVariant(index, { ...variant, discounts: [...(variant.discounts || []), { title: '', type: '%', value: 0 }] })} /></View>{(variant.discounts || []).map((discount, at) => <View style={styles.discountCard} key={`discount-${at}`}><TextField label="Discount name" placeholder="e.g. Senior" value={discount.title} onChangeText={(title) => setVariant(index, { ...variant, discounts: variant.discounts.map((item, itemAt) => itemAt === at ? { ...item, title } : item) })} /><View style={styles.sectionHeading}><Text style={styles.fieldLabel}>Discount type</Text><View style={styles.chips}>{[['%', 'Percent'], ['₱', 'Peso amount']].map(([type, label]) => <Chip key={type} label={label} selected={(discount.type || '%') === type} onPress={() => setVariant(index, { ...variant, discounts: variant.discounts.map((item, itemAt) => itemAt === at ? { ...item, type } : item) })} />)}</View></View><View style={styles.advancedRow}><View style={styles.formCell}><TextField label="Value" keyboardType="decimal-pad" value={String(discount.value ?? 0)} onChangeText={(value) => setVariant(index, { ...variant, discounts: variant.discounts.map((item, itemAt) => itemAt === at ? { ...item, value: Number(value) || 0 } : item) })} /></View><Pressable accessibilityRole="button" accessibilityLabel="Remove discount" onPress={() => setVariant(index, { ...variant, discounts: variant.discounts.filter((_, itemAt) => itemAt !== at) })}><Text style={styles.removePhoto}>Remove</Text></Pressable></View></View>)}</View>}
      </View>)}
    </View>}
    {step === 2 && <View style={styles.stepBody}><View style={styles.sectionHeading}><View style={styles.typeCopy}><Text style={styles.variantHeading}>Add stock batches</Text><Text style={styles.typeCaption}>Track opening stock and expiry dates. You can add batches later.</Text></View></View>
      {form.variants.map((variant, index) => <View style={styles.stockCard} key={variant.id}><View style={styles.stockHead}><View style={styles.stockThumb}>{variant.imageFile?.uri || variant.imageUrl ? <Image source={{ uri: variant.imageFile?.uri || variant.imageUrl }} style={styles.stockThumbImage} /> : <Text style={styles.stockThumbText}>{(variant.name || form.name).slice(0, 1).toUpperCase()}</Text>}</View><View style={styles.typeCopy}><Text style={styles.variantHeading}>{variant.name || form.name || `Variant ${index + 1}`}</Text><Text style={styles.typeCaption}>{variant.unit} · ₱{Number(variant.price || 0).toFixed(2)}</Text></View><Text style={styles.stockCount}>{variant.batches.reduce((sum, batch) => sum + (Number(batch.qty) || 0), 0)} {variant.unit}</Text></View>
        {variant.batches.map((batch, batchIndex) => <View style={styles.batchRow} key={batch.id || batchIndex}><View style={styles.typeCopy}><Text style={styles.typeTitle}>{batch.qty} {variant.unit}{batch.batchNumber ? ` · ${batch.batchNumber}` : ''}</Text>{(batch.indicators || []).filter((indicator) => indicator.date).map((indicator, at) => <Text style={styles.typeCaption} key={`${indicator.type}-${at}`}>{indicator.type}: {indicator.date}</Text>)}</View><Pressable onPress={() => setVariant(index, { ...variant, batches: variant.batches.filter((_, at) => at !== batchIndex) })}><Text style={styles.removePhoto}>Remove</Text></Pressable></View>)}
        {batchTarget === index && batchDraft ? <View style={styles.batchEditor}><View style={styles.formRow}><View style={styles.formCell}><TextField label="Quantity *" keyboardType="number-pad" value={batchDraft.qty} onChangeText={(qty) => setBatchDraft((current) => ({ ...current, qty }))} /></View><View style={styles.formCell}><TextField label="Batch number" value={batchDraft.batchNumber} onChangeText={(batchNumber) => setBatchDraft((current) => ({ ...current, batchNumber }))} /></View></View><TextField label="Cost per unit (₱)" keyboardType="decimal-pad" value={batchDraft.costPrice} onChangeText={(costPrice) => setBatchDraft((current) => ({ ...current, costPrice }))} /><View style={styles.sectionHeading}><Text style={styles.fieldLabel}>Product life indicators</Text><AppButton compact title="Add date" variant="outline" icon="add" onPress={() => setBatchDraft((current) => ({ ...current, indicators: [...current.indicators, { type: 'Expiry Date', date: '' }] }))} /></View>{batchDraft.indicators.map((indicator, indicatorIndex) => <View style={styles.indicatorEditor} key={`indicator-${indicatorIndex}`}><View><Text style={styles.fieldLabel}>Date type</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>{LIFE_TYPES.map((type) => <Chip key={type} label={type} selected={indicator.type === type} onPress={() => setBatchDraft((current) => ({ ...current, indicators: current.indicators.map((item, at) => at === indicatorIndex ? { ...item, type } : item) }))} />)}</ScrollView></View><View style={styles.formRow}><View style={styles.formCell}><TextField label="Date (YYYY-MM-DD)" placeholder="2026-12-31" value={indicator.date} onChangeText={(date) => setBatchDraft((current) => ({ ...current, indicators: current.indicators.map((item, at) => at === indicatorIndex ? { ...item, date } : item) }))} /></View><Pressable accessibilityRole="button" accessibilityLabel="Remove product life date" onPress={() => setBatchDraft((current) => ({ ...current, indicators: current.indicators.filter((_, at) => at !== indicatorIndex) }))}><Text style={styles.removePhoto}>Remove</Text></Pressable></View></View>)}<View style={styles.batchActions}><AppButton compact title="Cancel" variant="outline" onPress={() => { setBatchTarget(-1); setBatchDraft(null); }} /><AppButton compact title="Add batch" icon="checkmark" onPress={addBatch} /></View></View> : <AppButton title="Add stock batch" variant="outline" icon="add" style={styles.addBatch} onPress={() => openBatch(index)} />}
      </View>)}
    </View>}
  </AppModal>;
}

const styles = createThemeAwareStyles({
  actionButton: { flex: 1 },
  steps: { flexDirection: 'row', gap: 6, paddingBottom: 12, borderBottomWidth: 1, borderBottomColor: colors.border },
  step: { flex: 1, minHeight: 58, alignItems: 'center', justifyContent: 'center', gap: 4, borderRadius: 11 },
  stepActive: { backgroundColor: colors.primarySoft }, stepDone: { backgroundColor: colors.successSoft },
  stepNumber: { width: 25, height: 25, borderRadius: 13, overflow: 'hidden', textAlign: 'center', textAlignVertical: 'center', color: colors.muted, backgroundColor: colors.surfaceSoft, fontSize: 13, fontWeight: '800' },
  stepNumberActive: { color: '#FFFFFF', backgroundColor: colors.primary },
  stepLabel: { color: colors.muted, fontSize: 12, fontWeight: '600' }, stepLabelActive: { color: colors.primary, fontWeight: '800' },
  stepCaption: { color: colors.muted, fontSize: 13, textAlign: 'right', marginTop: 8, marginBottom: 3 },
  stepBody: { gap: 10, paddingBottom: 10 },
  photoBox: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 11, borderWidth: 1, borderColor: colors.border, borderRadius: 13, backgroundColor: colors.surfaceSoft },
  preview: { width: 78, height: 78, borderWidth: 1, borderColor: colors.border, borderRadius: 12, alignItems: 'center', justifyContent: 'center', overflow: 'hidden', backgroundColor: colors.surface },
  previewImage: { width: '100%', height: '100%' }, noPhoto: { color: colors.muted, fontSize: 12 },
  photoActions: { flex: 1, minWidth: 0, gap: 4 }, photoTitle: { color: colors.text, fontSize: 14, fontWeight: '800' }, photoHint: { color: colors.muted, fontSize: 12 },
  photoButtons: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 9, marginTop: 3 },
  removePhoto: { color: colors.error, fontSize: 13, fontWeight: '700', padding: 8 }, disabledText: { opacity: 0.38 },
  fieldLabel: { color: colors.text, fontSize: 14, fontWeight: '700', marginBottom: 7 }, chips: { gap: 7, paddingBottom: 6 },
  categoryEditor: { gap: 7, padding: 11, borderWidth: 1, borderColor: colors.border, borderRadius: 11, backgroundColor: colors.surfaceSoft },
  typeChoices: { gap: 8 }, typeChoice: { minHeight: 64, flexDirection: 'row', alignItems: 'center', gap: 10, padding: 11, borderWidth: 1, borderColor: colors.border, borderRadius: 12, backgroundColor: colors.surface },
  typeChoiceSelected: { borderColor: colors.primary, backgroundColor: colors.primarySoft }, radio: { width: 19, height: 19, borderWidth: 2, borderColor: colors.border, borderRadius: 10 }, radioSelected: { borderColor: colors.primary, backgroundColor: colors.primary },
  typeCopy: { flex: 1, minWidth: 0, gap: 3 }, typeTitle: { color: colors.text, fontSize: 14, fontWeight: '700' }, typeCaption: { color: colors.muted, fontSize: 12, lineHeight: 17 },
  sectionHeading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 9, marginBottom: 3 }, variantHeading: { color: colors.text, fontSize: 15, fontWeight: '800' },
  advancedToggle: { color: colors.primary, fontSize: 14, fontWeight: '700', paddingVertical: 10 },
  advancedOptions: { gap: 10, padding: 11, borderWidth: 1, borderColor: colors.border, borderRadius: 12, backgroundColor: colors.surfaceSoft },
  advancedRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  discountCard: { gap: 7, padding: 10, borderWidth: 1, borderColor: colors.border, borderRadius: 11, backgroundColor: colors.surface },
  variantCard: { gap: 2, padding: 12, borderWidth: 1, borderColor: colors.border, borderRadius: 13, backgroundColor: colors.surface },
  variantCardHead: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginBottom: 7 },
  formRow: { flexDirection: 'row', gap: 9 }, formCell: { flex: 1, minWidth: 0 },
  stockCard: { gap: 9, padding: 12, borderWidth: 1, borderColor: colors.border, borderRadius: 13, backgroundColor: colors.surface },
  stockHead: { flexDirection: 'row', alignItems: 'center', gap: 10 }, stockThumb: { width: 42, height: 42, alignItems: 'center', justifyContent: 'center', overflow: 'hidden', borderRadius: 11, backgroundColor: colors.primarySoft },
  stockThumbImage: { width: '100%', height: '100%' }, stockThumbText: { color: colors.primary, fontSize: 16, fontWeight: '800' }, stockCount: { color: colors.primary, fontSize: 13, fontWeight: '800' },
  batchRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8, paddingTop: 8, borderTopWidth: 1, borderTopColor: colors.border },
  batchEditor: { gap: 9, padding: 11, borderWidth: 1, borderColor: colors.border, borderRadius: 12, backgroundColor: colors.surfaceSoft },
  indicatorEditor: { gap: 5, paddingTop: 8, borderTopWidth: 1, borderTopColor: colors.border },
  batchActions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 8 }, addBatch: { marginTop: 3 },
});
