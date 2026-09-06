class BusinessCategory {
  final String id;
  final String name;
  final String code;

  BusinessCategory({required this.id, required this.name, required this.code});

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id']?.toString() ?? '',
      name: json['name_en'] ?? json['name'] ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class BusinessTemplate {
  final String id;
  final String name;
  final String code;
  final String categoryId;
  final int defaultScale;
  final String unitLabel;

  BusinessTemplate({
    required this.id,
    required this.name,
    required this.code,
    required this.categoryId,
    required this.defaultScale,
    required this.unitLabel,
  });

  factory BusinessTemplate.fromJson(Map<String, dynamic> json) {
    final defaultScaleRaw = json['default_scale'];
    final defaultScale = defaultScaleRaw is num
        ? defaultScaleRaw.toInt()
        : int.tryParse(defaultScaleRaw?.toString() ?? '') ?? 1;

    return BusinessTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name_en'] ?? json['name'] ?? '',
      code: json['code']?.toString() ?? '',
      categoryId:
          json['sector_id']?.toString() ?? json['category_id']?.toString() ?? '',
      defaultScale: defaultScale,
      unitLabel: json['unit_label']?.toString() ?? 'units',
    );
  }
}
