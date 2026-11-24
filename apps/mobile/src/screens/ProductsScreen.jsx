import React from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import { AppButton, Card, Chip, Screen, SectionTitle } from '../components/Ui';
import MetricCard from '../components/MetricCard';
import ProductRow from '../components/ProductRow';
import ProductWizard from '../components/ProductWizard';
import SearchBox from '../components/SearchBox';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

export default function ProductsScreen() {
  const store = useStore();
  const [query, setQuery] = React.useState('');
  const [category, setCategory] = React.useState('All');
  const [wizardProduct, setWizardProduct] = React.useState(null);
  const products = store.products.filter((product) => (`${product.name} ${product.variantName} ${product.sku} ${product.category}`).toLowerCase().includes(query.toLowerCase()) && (category === 'All' || product.category === category));
  const removeProduct = (product) => Alert.alert('Delete product?', `Remove ${product.name}${product.variantName ? ` · ${product.variantName}` : ''} from the catalog?`, [
    { text: 'Cancel', style: 'cancel' },
    { text: 'Delete', style: 'destructive', onPress: async () => {
      try { await store.deleteProduct(product.id); Alert.alert('Product deleted', `${product.name} was removed from the catalog.`); }
      catch (error) { Alert.alert('Could not delete product', error.message); }
    } },
  ]);
  const saveProduct = async (product) => {
    try {
      if (wizardProduct) await store.updateProduct(wizardProduct.id, product);
      else await store.addProduct(product);
      setWizardProduct(null);
      Alert.alert(wizardProduct ? 'Product updated' : 'Product added', product.name);
    } catch (error) { throw error; }
  };

  return <>
    <Screen title="Products" subtitle="Your catalog, prices, and stock." action={<AppButton title="Add product" icon="add" compact onPress={() => setWizardProduct(false)} />}>
      <View style={styles.metrics}><MetricCard label="Products" value={String(new Set(store.products.map((product) => product.firestoreId || product.id)).size)} note="Catalog items" icon="pricetags-outline" tone="teal" /><MetricCard label="Low stock" value={String(store.products.filter((item) => item.stock <= item.minStock).length)} note="Need attention" icon="alert-circle-outline" tone="gold" /></View>
      <SearchBox value={query} onChangeText={setQuery} placeholder="Search products or SKU" />
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>{['All', ...store.categories].map((item) => <Chip key={item} label={item} selected={category === item} onPress={() => setCategory(item)} />)}</ScrollView>
      <SectionTitle title={`${products.length} variants`} />
      <Card style={styles.productList}>{products.map((product) => <ProductRow key={product.id} product={product} trailing={<View style={styles.productActions}><AppButton title="Edit" compact variant="outline" onPress={() => setWizardProduct(product)} /><AppButton title="Delete" compact variant="danger" onPress={() => removeProduct(product)} /></View>} />)}{!products.length && <Text style={styles.empty}>No products match your search.</Text>}</Card>
    </Screen>
    {wizardProduct !== null && <ProductWizard product={wizardProduct || null} categories={store.categories} lowStockThreshold={store.settings.lowStockThreshold} onClose={() => setWizardProduct(null)} onSave={saveProduct} onAddCategory={(name) => store.addCategory(name)} />}
  </>;
}

const styles = createThemeAwareStyles({
  metrics: { flexDirection: 'row', gap: 9 },
  filters: { gap: 8, paddingVertical: 2 },
  productList: { paddingHorizontal: 12, paddingVertical: 2 },
  productActions: { alignItems: 'stretch', gap: 5 },
  empty: { color: colors.muted, textAlign: 'center', padding: 24, fontSize: 14 },
});
