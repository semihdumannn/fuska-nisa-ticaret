class ApiCampaignModel {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String typeLabel;
  final double value;
  final double? minPurchaseAmount;
  final double? maxDiscountAmount;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final bool isCurrentlyActive;
  final int? usageLimit;
  final int usageCount;
  final String? imageUrl;

  const ApiCampaignModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.typeLabel,
    required this.value,
    this.minPurchaseAmount,
    this.maxDiscountAmount,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.isCurrentlyActive,
    this.usageLimit,
    required this.usageCount,
    this.imageUrl,
  });

  factory ApiCampaignModel.fromJson(Map<String, dynamic> json) {
    return ApiCampaignModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      typeLabel: json['type_label'] as String? ?? json['type'] as String,
      value: (json['value'] as num).toDouble(),
      minPurchaseAmount: json['min_purchase_amount'] != null
          ? (json['min_purchase_amount'] as num).toDouble()
          : null,
      maxDiscountAmount: json['max_discount_amount'] != null
          ? (json['max_discount_amount'] as num).toDouble()
          : null,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isCurrentlyActive: json['is_currently_active'] as bool? ?? false,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? json['banner_image'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type,
        'type_label': typeLabel,
        'value': value,
        'min_purchase_amount': minPurchaseAmount,
        'max_discount_amount': maxDiscountAmount,
        'start_date': startDate,
        'end_date': endDate,
        'is_active': isActive,
        'is_currently_active': isCurrentlyActive,
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'image_url': imageUrl,
      };

  /// Kampanya yüzde indirim mi, sabit miktar mı?
  bool get isPercentage => type == 'percentage';

  /// İndirim metnini formatla ("10%" veya "₺20")
  String get formattedValue =>
      isPercentage ? '%${value.toStringAsFixed(0)}' : '₺${value.toStringAsFixed(2)}';
}
