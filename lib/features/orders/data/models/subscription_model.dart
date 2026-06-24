class SubscriptionModel {
  final int id;
  final String productId;
  final String? variantId;
  final String plan; // weekly / biweekly / monthly
  final String status; // active / paused / cancelled
  final String? productName;
  final String? variantName;
  final String? productImageUrl;
  final DateTime? startDate;
  final DateTime? nextDeliveryDate;

  const SubscriptionModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.plan,
    required this.status,
    this.productName,
    this.variantName,
    this.productImageUrl,
    this.startDate,
    this.nextDeliveryDate,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';

  String get planLabel => switch (plan) {
        'weekly' => 'Haftalık',
        'biweekly' => '2 Haftada Bir',
        'monthly' => 'Aylık',
        _ => plan,
      };

  int get discountPercent => switch (plan) {
        'weekly' => 10,
        'biweekly' => 8,
        'monthly' => 5,
        _ => 0,
      };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return SubscriptionModel(
      id: (json['id'] as num).toInt(),
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      plan: json['plan']?.toString() ?? 'monthly',
      status: json['status']?.toString() ?? 'active',
      productName: product?['name']?.toString() ?? json['product_name']?.toString(),
      variantName: json['variant_name']?.toString(),
      productImageUrl: product?['image_url']?.toString() ?? json['product_image_url']?.toString(),
      startDate: _parseDate(json['start_date']),
      nextDeliveryDate: _parseDate(json['next_delivery_date']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
