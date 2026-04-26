import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus { active, full, completed, cancelled }

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String driverGender;
  final String sourceName;
  final GeoPoint sourceLatLng;
  final String destinationName;
  final GeoPoint destinationLatLng;
  final DateTime dateTime;
  final int seatsTotal;
  final int seatsAvailable;
  final double pricePerSeat;
  final RideStatus status;
  final bool isWomenOnly;
  final String? otpCode;
  final GeoPoint? liveLocation;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.driverId,
    this.driverName = '',
    this.driverGender = 'Unspecified',
    required this.sourceName,
    required this.sourceLatLng,
    required this.destinationName,
    required this.destinationLatLng,
    required this.dateTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.status,
    this.isWomenOnly = false,
    this.otpCode,
    this.liveLocation,
    required this.createdAt,
  });

  factory RideModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Null-safe GeoPoint parsing
    final sourceGeo = map['source_latlng'];
    final destGeo = map['destination_latlng'];
    final dateTimeField = map['date_time'];
    final createdAtField = map['created_at'];

    return RideModel(
      id: documentId,
      driverId: map['driver_id'] ?? '',
      driverName: map['driver_name'] ?? '',
      driverGender: map['driver_gender'] ?? 'Unspecified',
      sourceName: map['source_name'] ?? '',
      sourceLatLng: sourceGeo is GeoPoint ? sourceGeo : const GeoPoint(19.0760, 72.8777),
      destinationName: map['destination_name'] ?? '',
      destinationLatLng: destGeo is GeoPoint ? destGeo : const GeoPoint(19.0760, 72.8777),
      dateTime: dateTimeField is Timestamp ? dateTimeField.toDate() : DateTime.now(),
      seatsTotal: map['seats_total'] ?? 0,
      seatsAvailable: map['seats_available'] ?? 0,
      pricePerSeat: (map['price_per_seat'] ?? 0.0).toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.name == (map['ride_status'] ?? 'active'),
        orElse: () => RideStatus.active,
      ),
      isWomenOnly: map['is_women_only'] ?? false,
      otpCode: map['otp_code'],
      liveLocation: map['live_location'] as GeoPoint?,
      createdAt: createdAtField is Timestamp ? createdAtField.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_gender': driverGender,
      'source_name': sourceName,
      'source_latlng': sourceLatLng,
      'destination_name': destinationName,
      'destination_latlng': destinationLatLng,
      'date_time': Timestamp.fromDate(dateTime),
      'seats_total': seatsTotal,
      'seats_available': seatsAvailable,
      'price_per_seat': pricePerSeat,
      'ride_status': status.name,
      'is_women_only': isWomenOnly,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
