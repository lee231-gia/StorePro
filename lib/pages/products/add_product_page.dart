import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../core/services/cloudinary_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../models/product_option_model.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/product_option_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/employee_picker.dart';
import '../../widgets/product_card.dart';

part 'add_product_page_layout.dart';
part 'add_product_page_variants.dart';
part 'add_product_page_stock.dart';
part 'add_product_page_dialogs.dart';
part 'add_product_page_components.dart';
part 'add_product_page_options.dart';

class AddProductPage extends StatefulWidget {
  final String? productId;
  const AddProductPage({super.key, this.productId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // ── STEP CONTROL ──────────────────────────────────────────
  int _step = 0; // 0=basic info, 1=variants/single, 2=stocks

  // ── STEP 1 STATE ──────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _catId = '';
  String _catName = '';
  int _iconIndex = 0;
  int _colorIndex = 0;
  String _imageUrl = '';
  File? _imageFile;
  bool _hasVariants = false;
  List<CategoryModel> _categories = [];
  List<ProductOptionModel> _uomOptions = ProductOptionRepository.defaultOptions(
    ProductOptionRepository.uom,
  );
  List<ProductOptionModel> _packagingOptions =
      ProductOptionRepository.defaultOptions(ProductOptionRepository.packaging);
  bool _loading = true;

  // ── STEP 2 STATE ──────────────────────────────────────────
  List<VariantModel> _variants = [];
  final Map<String, File> _variantImageFiles = {};

  // ── STEP 3 STATE ──────────────────────────────────────────
  // Batches are stored inside each variant

  bool _saving = false;
  bool get isEditing => widget.productId != null;

  void _update(VoidCallback fn) => setState(fn);

  void _previewImage({File? file, String url = ''}) {
    if (file == null && url.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: file != null
                      ? Image.file(file, fit: BoxFit.contain)
                      : CachedNetworkImage(
                          imageUrl: ProductImage.optimizedUrl(url, 1200),
                          fit: BoxFit.contain,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          errorWidget: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 48,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final results =
        await Future.wait([
          CategoryRepository.getAll(),
          ProductOptionRepository.getByType(ProductOptionRepository.uom),
          ProductOptionRepository.getByType(ProductOptionRepository.packaging),
        ]).timeout(
          const Duration(seconds: 3),
          onTimeout: () => [
            <CategoryModel>[],
            ProductOptionRepository.defaultOptions(ProductOptionRepository.uom),
            ProductOptionRepository.defaultOptions(
              ProductOptionRepository.packaging,
            ),
          ],
        );
    var cats = results[0] as List<CategoryModel>;
    final uom = results[1] as List<ProductOptionModel>;
    final packaging = results[2] as List<ProductOptionModel>;
    final editingProductId = widget.productId;
    if (editingProductId != null) {
      final p = await ProductRepository.getOne(
        editingProductId,
      ).timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (p != null && mounted) {
        _nameCtrl.text = p.name;
        _descCtrl.text = p.description;
        _catId = p.categoryId;
        _catName = p.categoryName;
        _iconIndex = p.iconIndex;
        _colorIndex = p.colorIndex;
        _imageUrl = p.imageUrl;
        _hasVariants = p.hasVariants;
        _variants = List<VariantModel>.from(p.variants);
        if (_catId.isNotEmpty && !cats.any((cat) => cat.id == _catId)) {
          cats = [
            ...cats,
            CategoryModel(
              id: _catId,
              storeId: Session.storeId,
              name: _catName.isEmpty ? 'Uncategorized' : _catName,
              colorIndex: _colorIndex,
              updatedAt: AppHelpers.nowStr(),
            ),
          ];
        }
      }
    }
    if (mounted) {
      setState(() {
        _categories = cats;
        _uomOptions = uom;
        _packagingOptions = packaging;
        if (!isEditing && cats.isNotEmpty && _catId.isEmpty) {
          _catId = cats.first.id;
          _catName = cats.first.name;
          _colorIndex = cats.first.colorIndex;
        }
        _loading = false;
      });
    }
  }

  // ── GENERATE SKU ──────────────────────────────────────────
  String _autoSku(String productName, String variantName) {
    String clean(String s) => s
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), '')
        .trim()
        .split(' ')
        .map((w) => w.length > 4 ? w.substring(0, 4) : w)
        .join('-');
    return '${clean(productName)}-${clean(variantName)}';
  }

  // ── SAVE ──────────────────────────────────────────────────
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showSnack(context, 'Product name required.', isError: true);
      return;
    }
    if (_variants.isEmpty) {
      showSnack(context, 'Add at least one variant.', isError: true);
      return;
    }

    final ok = await pickEmployee(context);
    if (!ok || !mounted) return;

    setState(() => _saving = true);

    try {
      String uploadedUrl = _imageUrl;
      if (_imageFile != null) {
        final url = await CloudinaryService.upload(
          _imageFile!,
          'products',
        ).timeout(const Duration(seconds: 15), onTimeout: () => null);
        if (url != null) uploadedUrl = url;
      }

      final uploadedVariants = <VariantModel>[];
      for (final variant in _variants) {
        final imageFile = _variantImageFiles[variant.id];
        var imageUrl = variant.imageUrl;
        if (imageFile != null) {
          final url = await CloudinaryService.upload(
            imageFile,
            'variants',
          ).timeout(const Duration(seconds: 15), onTimeout: () => null);
          if (url != null) imageUrl = url;
        }
        uploadedVariants.add(variant.copyWith(imageUrl: imageUrl));
      }

      final product = ProductModel(
        id: widget.productId ?? '',
        storeId: Session.storeId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryId: _catId,
        categoryName: _catName,
        hasVariants: _hasVariants,
        iconIndex: _iconIndex,
        colorIndex: _colorIndex,
        imageUrl: uploadedUrl,
        variants: uploadedVariants,
        addedOn: AppHelpers.todayStr(),
        updatedAt: AppHelpers.nowStr(),
      );

      await ProductRepository.save(product).timeout(const Duration(seconds: 6));

      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, 'Could not save product: $e', isError: true);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(
        title: isEditing ? 'Edit Product' : 'Add Product',
        context: context,
        showMenu: false,
        showBack: true,
      ),
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(color: cs.primary),
          _buildStepBar(),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── STEP INDICATOR BAR ────────────────────────────────────
}
