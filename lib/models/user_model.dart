class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String preferredLanguage;
  final String socialCategory;
  final String district;
  final String subDistrict;
  final String village;
  final String state;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber = '',
    this.preferredLanguage = 'en',
    this.socialCategory = 'general',
    this.district = '',
    this.subDistrict = '',
    this.village = '',
    this.state = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName:
          json['full_name']?.toString() ?? json['username']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      preferredLanguage: json['preferred_language']?.toString() ?? 'en',
      socialCategory: json['social_category']?.toString() ?? 'general',
      district: json['district']?.toString() ?? '',
      subDistrict: json['sub_district']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}
