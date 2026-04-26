import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, cancelled }

class BookingModel {
  final String id;
  final String rideId;
  final String riderId;
  final BookingStatus status;
  final bool otpVerified;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.rideId,
    required this.riderId,
    required this.status,
    this.otpVerified = false,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      rideId: map['ride_id'] ?? '',
      riderId: map['rider_id'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (map['booking_status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      otpVerified: map['otp_verified'] ?? false,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ride_id': rideId,
      'rider_id': riderId,
      'booking_status': status.name,
      'otp_verified': otpVerified,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
