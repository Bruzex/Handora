import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/order.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../services/whatsapp_service.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

class OrderDetailsModal extends StatefulWidget {
  final Order order;

  const OrderDetailsModal({super.key, required this.order});

  @override
  State<OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  late String _currentStatus;
  final TextEditingController _noteController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_currentStatus == newStatus && widget.order.status == newStatus) return;
    setState(() {
      _currentStatus = newStatus;
      _isUpdating = true;
    });

    final dataProvider = context.read<DataProvider>();
    await dataProvider.updateOrderStatus(
      widget.order.dbId,
      newStatus,
      orderId: widget.order.id,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    final isHi = context.read<AppState>().language == Language.hi;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHi
              ? 'ऑर्डर स्थिति अपडेट की गई: ${WhatsAppService.formatStatusLabel(newStatus, Language.hi)}'
              : 'Order status updated to ${WhatsAppService.formatStatusLabel(newStatus, Language.en)}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final app = context.read<AppState>();
    final isHi = app.language == Language.hi;

    // If status was changed, ensure database update is persisted
    if (_currentStatus != widget.order.status) {
      await _updateStatus(_currentStatus);
      if (!mounted) return;
    }

    final updatedOrder = widget.order.copyWith(status: _currentStatus);

    final result = await WhatsAppService.sendWhatsAppOrderUpdate(
      order: updatedOrder,
      customNote: _noteController.text,
      language: app.language,
    );

    if (!mounted) return;

    final message = WhatsAppService.buildOrderMessage(
      order: updatedOrder,
      customNote: _noteController.text,
      language: app.language,
    );

    switch (result) {
      case WhatsAppResult.success:
        break;

      case WhatsAppResult.invalidPhone:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHi
                  ? 'खरीदार का फ़ोन नंबर अमान्य या अनुपलब्ध है।'
                  : 'Buyer phone number is missing or invalid.',
            ),
            backgroundColor: AppColors.amber600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: isHi ? 'संदेश कॉपी करें' : 'Copy Message',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isHi
                          ? 'संदेश क्लिपबोर्ड पर कॉपी हो गया!'
                          : 'Message copied to clipboard!',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        );
        break;

      case WhatsAppResult.launchFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHi
                  ? 'WhatsApp नहीं खोला जा सका। कृपया जांचें कि WhatsApp इंस्टॉल है।'
                  : 'Could not launch WhatsApp. Please check if WhatsApp is installed.',
            ),
            backgroundColor: AppColors.red600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: isHi ? 'कॉपी करें' : 'Copy',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
              },
            ),
          ),
        );
        break;
    }
  }

  Widget _buildProductThumbnail(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(image, fit: BoxFit.cover);
    } else if (image.startsWith('assets/')) {
      return Image.asset(image, fit: BoxFit.cover);
    } else {
      return Container(
        color: AppColors.saffron50,
        child: const Icon(Icons.inventory_2_rounded, color: AppColors.saffron600),
      );
    }
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'new' || 'new_order' => AppColors.amber600,
      'processing' => const Color(0xFF2563EB),
      'shipped' => const Color(0xFF9333EA),
      'delivered' => AppColors.green600,
      'cancelled' => AppColors.red600,
      _ => AppColors.ink500,
    };
  }

  Color _getStatusBg(String status, bool dark) {
    final base = _getStatusColor(status);
    return dark ? base.withAlpha(50) : base.withAlpha(25);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isHi = app.language == Language.hi;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.ink800 : Colors.white;
    final textColor = dark ? Colors.white : AppColors.ink900;
    final productName = isHi ? widget.order.productHi : widget.order.productEn;

    final statuses = [
      {'key': 'new', 'label': isHi ? 'नया ऑर्डर' : 'New Order', 'icon': Icons.shopping_bag_outlined},
      {'key': 'processing', 'label': isHi ? 'तैयारी में' : 'Processing', 'icon': Icons.handyman_outlined},
      {'key': 'shipped', 'label': isHi ? 'भेज दिया' : 'Shipped', 'icon': Icons.local_shipping_outlined},
      {'key': 'delivered', 'label': isHi ? 'डिलीवर हुआ' : 'Delivered', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'cancelled', 'label': isHi ? 'रद्द करें' : 'Cancelled', 'icon': Icons.cancel_outlined},
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron200),
          boxShadow: kLiftShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.ink700 : AppColors.ink200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header: Order ID & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.saffron600.withAlpha(dark ? 40 : 25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.saffron600.withAlpha(80)),
                        ),
                        child: Text(
                          '#${widget.order.id}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.saffron600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isHi ? 'ऑर्डर विवरण' : 'Order Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.ink700 : AppColors.ink200.withAlpha(100),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: dark ? Colors.white70 : AppColors.ink700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Buyer Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark ? AppColors.ink900 : AppColors.saffron50.withAlpha(120),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron100),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.saffron600,
                      child: Text(
                        widget.order.buyerName.isNotEmpty
                            ? widget.order.buyerName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.buyerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android_rounded,
                                size: 14,
                                color: AppColors.ink500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.order.formattedPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink500,
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
              const SizedBox(height: 16),

              // Product & Pricing Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark ? AppColors.ink900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? AppColors.ink700 : AppColors.ink200),
                  boxShadow: kCardShadow,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: _buildProductThumbnail(widget.order.thumbnail),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isHi ? "मात्रा" : "Quantity"}: ${widget.order.quantity} • ${widget.order.placedAt}',
                            style: const TextStyle(fontSize: 13, color: AppColors.ink500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.order.formattedAmount,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.saffron600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Selector Section
              Text(
                isHi ? 'ऑर्डर की स्थिति बदलें' : 'Update Order Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white70 : AppColors.ink700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((st) {
                  final key = st['key'] as String;
                  final label = st['label'] as String;
                  final icon = st['icon'] as IconData;
                  final isSelected = _currentStatus.toLowerCase() == key;
                  final statusColor = _getStatusColor(key);

                  return GestureDetector(
                    onTap: _isUpdating ? null : () => _updateStatus(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? statusColor
                            : _getStatusBg(key, dark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? statusColor : statusColor.withAlpha(90),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.white : statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Custom Note for WhatsApp (Optional)
              TextField(
                controller: _noteController,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: isHi ? 'विशेष संदेश (वैकल्पिक)' : 'Custom message for buyer (optional)',
                  labelStyle: const TextStyle(fontSize: 13, color: AppColors.ink500),
                  hintText: isHi ? 'उदा. पार्सल स्पीड पोस्ट से भेजा गया है' : 'e.g. Dispatched via Speed Post',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.ink500),
                  filled: true,
                  fillColor: dark ? AppColors.ink900 : AppColors.saffron50.withAlpha(80),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: dark ? AppColors.ink700 : AppColors.saffron200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: dark ? AppColors.ink700 : AppColors.saffron200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.saffron600, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // WhatsApp Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Brand Green
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 22, color: Colors.white),
                  label: Text(
                    isHi ? 'WhatsApp पर अपडेट भेजें' : 'Send WhatsApp Update',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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
