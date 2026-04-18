import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus { active, full, completed, cancelled }

class RideModel {
  final String id;
  final String driverId;
  final String sourceName;
  final GeoPoint sourceLatLng;
  final String destinationName;
  final GeoPoint destinationLatLng;
  final DateTime dateTime;
  final int seatsTotal;
  final int seatsAvailable;
  final double pricePerSeat;
  final RideStatus status;
  final String? otpCode; // Private, usually null in client reads unless filtered
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.driverId,
    required this.sourceName,
    required this.sourceLatLng,
    required this.destinationName,
    required this.destinationLatLng,
    required this.dateTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.status,
    this.otpCode,
    required this.createdAt,
  });

  factory RideModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RideModel(
      id: documentId,
      driverId: map['driver_id'] ?? '',
      sourceName: map['source_name'] ?? '',
      sourceLatLng: map['source_latlng'] as GeoPoint,
      destinationName: map['destination_name'] ?? '',
      destinationLatLng: map['destination_latlng'] as GeoPoint,
      dateTime: (map['date_time'] as Timestamp).toDate(),
      seatsTotal: map['seats_total'] ?? 0,
      seatsAvailable: map['seats_available'] ?? 0,
      pricePerSeat: (map['price_per_seat'] ?? 0.0).toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.name == (map['ride_status'] ?? 'active'),
        orElse: () => RideStatus.active,
      ),
      otpCode: map['otp_code'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'source_name': sourceName,
      'source_latlng': sourceLatLng,
      'destination_name': destinationName,
      'destination_latlng': destinationLatLng,
      'date_time': Timestamp.fromDate(dateTime),
      'seats_total': seatsTotal,
      'seats_available': seatsAvailable,
      'price_per_seat': pricePerSeat,
      'ride_status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
