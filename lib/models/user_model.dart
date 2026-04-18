import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String collegeOrCompany;
  final String? profilePhotoUrl;
  final double rating;
  final int ratingCount;
  final String gender;
  final bool isStudent;
  final bool isAadharVerified;
  final double walletBalance;
  final double co2Saved;
  final double totalMoneySaved;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.collegeOrCompany,
    this.profilePhotoUrl,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.gender = 'Unspecified',
    this.isStudent = false,
    this.isAadharVerified = false,
    this.walletBalance = 0.0,
    this.co2Saved = 0.0,
    this.totalMoneySaved = 0.0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final createdAt = map['created_at'];

    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      collegeOrCompany: map['college_company'] ?? '',
      profilePhotoUrl: map['profile_photo_url'],
      rating: (map['rating'] ?? 5.0).toDouble(),
      ratingCount: map['rating_count'] ?? 0,
      gender: map['gender'] ?? 'Unspecified',
      isStudent: map['is_student'] ?? false,
      isAadharVerified: map['is_aadhar_verified'] ?? false,
      walletBalance: (map['wallet_balance'] ?? 0.0).toDouble(),
      co2Saved: (map['co2_saved'] ?? 0.0).toDouble(),
      totalMoneySaved: (map['total_money_saved'] ?? 0.0).toDouble(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? name,
    String? phoneNumber,
    String? collegeOrCompany,
    String? profilePhotoUrl,
    double? rating,
    int? ratingCount,
    String? gender,
    bool? isStudent,
    bool? isAadharVerified,
    double? walletBalance,
    double? co2Saved,
    double? totalMoneySaved,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      collegeOrCompany: collegeOrCompany ?? this.collegeOrCompany,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      gender: gender ?? this.gender,
      isStudent: isStudent ?? this.isStudent,
      isAadharVerified: isAadharVerified ?? this.isAadharVerified,
      walletBalance: walletBalance ?? this.walletBalance,
      co2Saved: co2Saved ?? this.co2Saved,
      totalMoneySaved: totalMoneySaved ?? this.totalMoneySaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'college_company': collegeOrCompany,
      'profile_photo_url': profilePhotoUrl,
      'rating': rating,
      'rating_count': ratingCount,
      'gender': gender,
      'is_student': isStudent,
      'is_aadhar_verified': isAadharVerified,
      'wallet_balance': walletBalance,
      'co2_saved': co2Saved,
      'total_money_saved': totalMoneySaved,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
