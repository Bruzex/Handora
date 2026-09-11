import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/strings.dart';
import '../models/product.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import '../widgets/success_feedback_widgets.dart';

class CaptureScreen extends StatefulWidget {
  final Product? existingProduct;
  const CaptureScreen({super.key, this.existingProduct});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _image;
  bool _loading = false;
  String? _statusMessage;
  String? _error;
  Product? _createdProduct;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final path = widget.existingProduct!.image;
      if (path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          _image = file;
        } else if (path.startsWith('http://') || path.startsWith('https://')) {
          _downloadExistingImage(path);
        }
      }
    }
  }

  Future<void> _downloadExistingImage(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/draft_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(res.bodyBytes);
        if (mounted) {
          setState(() => _image = tempFile);
        }
      }
    } catch (_) {}
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        _error = null;
        _createdProduct = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeAndSave() async {
    if (_image == null) return;

    final dataProvider = context.read<DataProvider>();
    final appState = context.read<AppState>();
    final isHi = appState.language == Language.hi;
    dataProvider.setProcessingAi(true);

    setState(() {
      _loading = true;
      _statusMessage = isHi
          ? 'Gemini AI से जांच हो रही है...'
          : 'Analyzing with Gemini AI...';
      _error = null;
      _createdProduct = null;
    });

    try {
      // 1. Gemini AI analysis — with optional history-aware pricing
      final ai = await GeminiService.analyzeProductImage(
        _image!,
        userId: appState.currentUserId,
      );

      if (mounted) {
        setState(() => _statusMessage = isHi
            ? 'Supabase Storage पर अपलोड हो रहा है...'
            : 'Uploading image to Supabase Storage...');
      }

      final nameEn = ai['title_en'] as String? ?? 'Handmade Product';
      final nameHi = ai['title_hi'] as String? ?? 'उत्पाद';
      final description = (ai['description_en'] as String?)?.isNotEmpty == true
          ? ai['description_en'] as String
          : (ai['description'] as String? ?? '');
      final category = ai['category'] as String? ?? 'Other';
      final priceInRupees = (ai['price_inr'] as num?)?.toInt() ??
          (ai['estimated_price_inr'] as num?)?.toInt() ??
          500;
      // Retain original product id if updating an existing draft
      final productId = widget.existingProduct?.id ?? const Uuid().v4();

      // 2. Upload photo to Supabase Storage product-images bucket
      String? remoteImageUrl;
      bool isSynced = false;

      try {
        remoteImageUrl = await SupabaseService.uploadProductImage(_image!);
        isSynced = true;
      } catch (uploadErr) {
        debugPrint('❌ Supabase storage upload failed: $uploadErr');
      }

      // 3. If uploaded to Supabase Storage, insert record into Supabase products table with public URL
      if (isSynced && remoteImageUrl != null && remoteImageUrl.isNotEmpty) {
        if (mounted) {
          setState(() => _statusMessage = isHi
              ? 'Supabase और ONDC पर सेव हो रहा है...'
              : 'Saving to Supabase & ONDC...');
        }
        try {
          await SupabaseService.insertProduct(
            id: productId,
            nameEn: nameEn,
            nameHi: nameHi,
            description: description,
            category: category,
            priceInRupees: priceInRupees,
            status: 'live',
            imageUrl: remoteImageUrl,
          );
        } catch (dbErr) {
          debugPrint('❌ Supabase DB insert error: $dbErr');
          isSynced = false;
        }
      }

      // 4. Save to local SQLite via DataProvider (update existing draft or insert new)
      final savedProduct = Product(
        id: productId,
        nameEn: nameEn,
        nameHi: nameHi,
        description: description,
        category: category,
        priceInRupees: priceInRupees,
        status: ProductStatus.live,
        image: remoteImageUrl ?? _image!.path,
        isSynced: isSynced,
        userId: appState.currentUserId ?? '',
      );

      if (widget.existingProduct != null) {
        await dataProvider.updateProduct(savedProduct);
      } else {
        await dataProvider.addProduct(savedProduct);
      }
      dataProvider.setProcessingAi(false);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _statusMessage = null;
        _createdProduct = savedProduct;
      });
    } on SocketException {
      // ── Offline: bypass AI, create draft product ──
      debugPrint('📴 Offline detected (SocketException) — saving draft product');
      await _saveOfflineDraft(dataProvider, appState);
    } on http.ClientException {
      // ── Network error: also treat as offline ──
      debugPrint('📴 Network error (ClientException) — saving draft product');
      await _saveOfflineDraft(dataProvider, appState);
    } catch (e) {
      // ── Other unexpected errors (API key missing, JSON parse, quota 429, etc.) ──
      dataProvider.setProcessingAi(false);
      debugPrint('❌ Capture error: $e');
      if (mounted) {
        final friendlyError = GeminiService.formatGeminiError(e, isHi: isHi);
        setState(() {
          _loading = false;
          _error = friendlyError;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError),
            backgroundColor: AppColors.red600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Creates a draft product from the captured image and saves it locally
  /// when the device is offline. Shows a bilingual SnackBar and navigates
  /// back to the catalog.
  Future<void> _saveOfflineDraft(
    DataProvider dataProvider,
    AppState appState,
  ) async {
    final productId = widget.existingProduct?.id ?? const Uuid().v4();

    final draftProduct = Product(
      id: productId,
      nameEn: widget.existingProduct?.nameEn ?? 'Draft Product (Offline)',
      nameHi: widget.existingProduct?.nameHi ?? 'ड्राफ्ट प्रोडक्ट',
      description: widget.existingProduct?.description ?? 'Pending AI analysis',
      category: widget.existingProduct?.category ?? 'Other',
      priceInRupees: widget.existingProduct?.priceInRupees ?? 0,
      status: ProductStatus.draft,
      image: _image?.path ?? widget.existingProduct?.image ?? '',
      isSynced: false,
      userId: appState.currentUserId ?? '',
    );

    if (widget.existingProduct != null) {
      await dataProvider.updateProduct(draftProduct);
    } else {
      await dataProvider.addProduct(draftProduct);
    }
    dataProvider.setProcessingAi(false);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _statusMessage = null;
      _error = null;
    });

    // Show bilingual offline-save SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'No internet connection. Photo saved offline. '
          'You can edit details manually later.\n'
          'इंटरनेट नहीं है। फोटो सेव हो गई है।',
          style: TextStyle(fontSize: 13),
        ),
        backgroundColor: AppColors.amber600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // Navigate back to catalog
    _goToCatalog();
  }

  void _goToCatalog() {
    context.read<AppState>().setTab(NavTab.catalog);
    Navigator.pop(context);
  }

  void _resetForAnother() {
    setState(() {
      _image = null;
      _createdProduct = null;
      _loading = false;
      _statusMessage = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isHi = app.language == Language.hi;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _createdProduct != null
              ? (widget.existingProduct != null
                  ? (isHi ? 'उत्पाद अपडेट हो गया' : 'Product Updated')
                  : (isHi ? 'उत्पाद जोड़ा गया' : 'Product Added'))
              : (widget.existingProduct != null
                  ? (isHi ? 'लिस्टिंग पूरी करें' : 'Complete Listing')
                  : (isHi ? 'फोटो खींचें और कैटलॉग बनाएं' : 'Snap & AI Catalog')),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : AppColors.ink900,
          ),
        ),
        backgroundColor: dark ? AppColors.ink950 : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: dark ? Colors.white : AppColors.ink900),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _createdProduct != null
              ? _buildSuccessView(isHi, dark)
              : _buildCaptureView(isHi, dark),
        ),
      ),
    );
  }

  Widget _buildCaptureView(bool isHi, bool dark) {
    return Padding(
      key: const ValueKey('capture_view'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image preview area
          Expanded(
            child: _image == null
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: dark ? AppColors.ink800 : AppColors.saffron50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: dark ? AppColors.ink700 : AppColors.saffron200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          size: 64,
                          color: dark ? AppColors.ink500 : AppColors.saffron600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isHi
                              ? 'फोटो खींचें या गैलरी से चुनें'
                              : 'Take a photo or choose from gallery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: dark ? Colors.white70 : AppColors.ink700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isHi
                              ? 'AI वस्तु की पहचान करेगा और नाम व सही दाम तय करेगा'
                              : 'AI will identify the item and write the title & price',
                          style: const TextStyle(fontSize: 13, color: AppColors.ink500),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          // Camera and Gallery buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: dark ? AppColors.ink700 : AppColors.saffron600,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: dark ? Colors.white : AppColors.saffron700,
                  ),
                  label: Text(
                    isHi ? 'कैमरा' : 'Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.saffron700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: dark ? AppColors.ink700 : AppColors.saffron600,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.photo_library_rounded,
                    color: dark ? Colors.white : AppColors.saffron700,
                  ),
                  label: Text(
                    isHi ? 'गैलरी' : 'Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.saffron700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status / Error display
          if (_loading && _statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _statusMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.saffron600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_image == null || _loading) ? null : _analyzeAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron600,
                disabledBackgroundColor: dark ? AppColors.ink800 : AppColors.ink200,
                elevation: _image != null && !_loading ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          widget.existingProduct != null
                              ? (isHi ? 'AI से लिस्टिंग पूरी करें' : 'Complete Listing with AI')
                              : (isHi ? 'AI से जांचें और जोड़ें' : 'Analyze with AI & Save'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isHi, bool dark) {
    final product = _createdProduct!;
    final name = isHi ? product.nameHi : product.nameEn;
    final textColor = dark ? Colors.white : AppColors.ink900;

    return SingleChildScrollView(
      key: const ValueKey('success_product_view'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Animated checkmark badge
          const SuccessCheckAnimation(
            size: 76,
            primaryColor: AppColors.green600,
          ),
          const SizedBox(height: 16),

          // Success heading
          Text(
            isHi
                ? (widget.existingProduct != null
                    ? 'लिस्टिंग सफलतापूर्वक पूरी हुई!'
                    : 'उत्पाद सफलतापूर्वक जोड़ा गया!')
                : (widget.existingProduct != null
                    ? 'Listing Completed Successfully!'
                    : 'Product Added Successfully!'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Live on ONDC pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.green600.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.green600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isHi ? 'ONDC पर लाइव' : 'Live on ONDC',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Product Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? AppColors.ink800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron100),
              boxShadow: kCardShadow,
            ),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.saffron50,
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: AppColors.saffron600,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.saffron600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: dark ? AppColors.ink700 : AppColors.saffron50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white70 : AppColors.saffron700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Primary Button: View in Catalog
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _goToCatalog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron600,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 22),
              label: Text(
                isHi ? 'कैटलॉग में देखें' : 'View in Catalog',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Button: Add Another Product
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _resetForAnother,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: dark ? AppColors.ink700 : AppColors.ink200,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                Icons.add_a_photo_rounded,
                color: dark ? Colors.white70 : AppColors.ink700,
                size: 20,
              ),
              label: Text(
                isHi ? '+ एक और उत्पाद जोड़ें' : '+ Add Another Product',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : AppColors.ink900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
