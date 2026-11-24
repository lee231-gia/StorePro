import React from 'react';
import { Image, Pressable, Text, View } from 'react-native';
import { formatMoney } from '../data/formatters';
import { colors, createThemeAwareStyles } from '../theme';
import { StatusPill } from './Ui';

export default function ProductRow({ product, trailing, onPress, compact = false }) {
  const low = product.stock <= product.minStock;
  const contents = <><View style={[styles.initial, compact && styles.initialCompact]}>{product.imageUrl ? <Image source={{ uri: product.imageUrl }} style={styles.productImage} resizeMode="cover" /> : <Text style={styles.initialText}>{product.name.slice(0, 1).toUpperCase()}</Text>}</View><View style={styles.details}><Text style={styles.name} numberOfLines={1}>{product.name}</Text><Text style={styles.meta} numberOfLines={1}>{product.category} · {product.stock} {product.unit}</Text></View><View style={styles.trailing}>{trailing || <><Text style={styles.price}>{formatMoney(product.price)}</Text>{!compact && <StatusPill tone={low ? 'warning' : 'success'} label={low ? 'Low stock' : 'In stock'} />}</>}</View></>;
  if (onPress) return <Pressable onPress={onPress} style={({ pressed }) => [styles.row, pressed && styles.pressed]} accessibilityRole="button">{contents}</Pressable>;
  return <View style={styles.row}>{contents}</View>;
}

const styles = createThemeAwareStyles({
  row: { minHeight: 68, flexDirection: 'row', alignItems: 'center', gap: 11, paddingVertical: 9, borderBottomWidth: 1, borderBottomColor: '#EDF1EF' },
  pressed: { opacity: .7 },
  initial: { width: 43, height: 43, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: '#E8F0EB' },
  initialCompact: { width: 37, height: 37, borderRadius: 11 },
  productImage: { width: '100%', height: '100%' },
  initialText: { color: colors.primary, fontSize: 16, fontWeight: '800' },
  details: { flex: 1, minWidth: 0, gap: 4 },
  name: { color: colors.text, fontSize: 15, fontWeight: '700' },
  meta: { color: colors.muted, fontSize: 12 },
  trailing: { alignItems: 'flex-end', gap: 5 },
  price: { color: colors.primary, fontSize: 15, fontWeight: '800' },
});
