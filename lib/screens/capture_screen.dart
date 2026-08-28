import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../providers/data_provider.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../theme/palette.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _image;
  bool _loading = false;
  String? _statusMessage;
  String? _error;

  final _picker = ImagePicker();

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
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeAndSave() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
      _statusMessage = 'Analyzing with Gemini AI...';
      _error = null;
    });

    try {
      // 1. Gemini AI analysis
      final ai = await GeminiService.analyzeProductImage(_image!);

      if (mounted) {
        setState(() => _statusMessage = 'Uploading image to Supabase...');
      }

      // 2. Upload photo to Supabase Storage
      String imageUrl = _image!.path;
      try {
        imageUrl = await SupabaseService.uploadProductImage(_image!);
      } catch (uploadErr) {
        // Fallback to local path if storage upload fails
        debugPrint('Supabase storage upload error: $uploadErr');
      }

      if (mounted) {
        setState(() => _statusMessage = 'Saving product to catalog...');
      }

      final nameEn = ai['title_en'] as String? ?? 'Handmade Product';
      final nameHi = ai['title_hi'] as String? ?? 'हस्तनिर्मित उत्पाद';
      final description = ai['description'] as String? ?? '';
      final category = ai['category'] as String? ?? 'Other';
      final priceInRupees = (ai['estimated_price_inr'] as num?)?.toInt() ?? 500;
      final productId = const Uuid().v4();

      // 3. Save to Supabase DB (try/catch to handle offline / table policies)
      try {
        await SupabaseService.insertProduct(
          nameEn: nameEn,
          nameHi: nameHi,
          description: description,
          category: category,
          priceInRupees: priceInRupees,
          imageUrl: imageUrl,
        );
      } catch (dbErr) {
        debugPrint('Supabase DB insert error: $dbErr');
      }

      // 4. Also insert into local DataProvider (SQLite) for instant offline availability & reactive UI update
      final newProduct = Product(
        id: productId,
        nameEn: nameEn,
        nameHi: nameHi,
        priceInRupees: priceInRupees,
        status: ProductStatus.live,
        image: imageUrl,
      );

      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final dataProvider = context.read<DataProvider>();

      await dataProvider.addProduct(newProduct);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green600,
          content: Text('Product "$nameEn" added successfully!'),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? AppColors.ink950 : Colors.white,
      appBar: AppBar(
        title: Text(
          'Snap & AI Catalog',
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
        child: Padding(
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
                              'Take a photo or choose from gallery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white70 : AppColors.ink700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'AI will identify the item and write the title & price',
                              style: TextStyle(fontSize: 13, color: AppColors.ink500),
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
                        'Camera',
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
                        'Gallery',
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Analyze with AI & Save',
                              style: TextStyle(
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
        ),
      ),
    );
  }
}
