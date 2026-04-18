import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ride_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../utils/fare_calculator.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // -- Users --
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    return null;
  }

  // -- Rides --

  Future<String> createRide(RideModel ride) async {
    final docRef = await _db.collection('rides').add(ride.toMap());
    
    // Generate 4-digit OTP and store in private sub-collection
    final otp = (1000 + Random().nextInt(9000)).toString();
    await docRef.collection('private').doc('data').set({
      'otp_code': otp,
      'created_at': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  /// End a ride — marks it as completed so it disappears from Find a Ride
  Future<void> endRide(String rideId) async {
    await _db.collection('rides').doc(rideId).update({
      'ride_status': 'completed',
    });
  }

  Stream<List<RideModel>> getActiveRides() {
    return _db.collection('rides')
        .where('ride_status', isEqualTo: 'active')
        .orderBy('date_time', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data(), doc.id))
            .where((ride) => ride.seatsAvailable > 0)
            .toList());
  }

  /// Search logic: Simplified query to avoid composite index requirements.
  /// Date filtering and text matching are done locally.
  Stream<List<RideModel>> searchRides({
    String? source,
    String? destination,
    DateTime? date,
  }) {
    // Simple query: just filter by status. Avoid compound inequalities.
    return _db.collection('rides')
        .where('ride_status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      List<RideModel> rides = snapshot.docs.map((doc) => 
        RideModel.fromMap(doc.data(), doc.id)
      ).toList();

      // Local filter: seats available
      rides = rides.where((r) => r.seatsAvailable > 0).toList();

      // Local filter: date (same day)
      if (date != null) {
        rides = rides.where((r) =>
          r.dateTime.year == date.year &&
          r.dateTime.month == date.month &&
          r.dateTime.day == date.day
        ).toList();
      }

      // Local fuzzy filter for names if provided
      if (source != null && source.isNotEmpty) {
        rides = rides.where((r) => r.sourceName.toLowerCase().contains(source.toLowerCase())).toList();
      }
      if (destination != null && destination.isNotEmpty) {
        rides = rides.where((r) => r.destinationName.toLowerCase().contains(destination.toLowerCase())).toList();
      }

      // Sort by time
      rides.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return rides;
    });
  }

  Stream<RideModel> streamRide(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Ride not found');
      return RideModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Fetch OTP from the private sub-collection (only readable by driver)
  Future<String?> getRideOtp(String rideId) async {
    try {
      final doc = await _db.collection('rides').doc(rideId)
          .collection('private').doc('data').get();
      if (doc.exists) {
        return doc.data()?['otp_code']?.toString();
      }
    } catch (e) {
      debugPrint('Error fetching ride OTP: $e');
    }
    return null;
  }

  /// Get all rides offered by a specific driver
  Stream<List<RideModel>> getDriverRides(String driverId) {
    return _db.collection('rides')
        .where('driver_id', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => RideModel.fromMap(doc.data(), doc.id))
              .toList();
          rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rides;
        });
  }

  // -- Bookings --

  Future<String> createBooking(BookingModel booking) async {
    // Check if user is already in the ride or is the driver (handled in join logic UI usually)
    final docRef = await _db.collection('bookings').add(booking.toMap());
    return docRef.id;
  }

  Stream<List<BookingModel>> getBookingsForRide(String rideId) {
    return _db.collection('bookings')
        .where('ride_id', isEqualTo: rideId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<BookingModel>> getMyBookings(String userId) {
    return _db.collection('bookings')
        .where('rider_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  /// Verifies OTP directly against Firestore (no Cloud Functions needed)
  /// Also transfers fare from rider's wallet to driver's wallet
  Future<bool> verifyOtp(String bookingId, String otp) async {
    try {
      final bookingRef = _db.collection('bookings').doc(bookingId);
      final bookingDoc = await bookingRef.get();
      if (!bookingDoc.exists) return false;

      final rideId = bookingDoc.data()!['ride_id'];
      final riderId = bookingDoc.data()!['rider_id'];
      
      // Read the private OTP
      final privateDoc = await _db.collection('rides').doc(rideId)
          .collection('private').doc('data').get();
      if (!privateDoc.exists) return false;

      final actualOtp = privateDoc.data()?['otp_code']?.toString();
      if (otp != actualOtp) return false;

      // OTP matches — update booking, decrement seats, and transfer fare
      final rideRef = _db.collection('rides').doc(rideId);
      final riderRef = _db.collection('users').doc(riderId);

      await _db.runTransaction((transaction) async {
        final rideDoc = await transaction.get(rideRef);
        if (!rideDoc.exists) throw Exception('Ride not found');

        final rideData = rideDoc.data()!;
        final seatsAvailable = rideData['seats_available'] as int;
        if (seatsAvailable <= 0) throw Exception('No seats available');

        final pricePerSeat = (rideData['price_per_seat'] ?? 0.0).toDouble();
        final driverId = rideData['driver_id'] as String;
        final driverRef = _db.collection('users').doc(driverId);

        // Read rider and driver wallets
        final riderDoc = await transaction.get(riderRef);
        final driverDoc = await transaction.get(driverRef);

        final riderBalance = (riderDoc.data()?['wallet_balance'] ?? 0.0).toDouble();
        final driverBalance = (driverDoc.data()?['wallet_balance'] ?? 0.0).toDouble();
        
        final riderMoneySaved = (riderDoc.data()?['total_money_saved'] ?? 0.0).toDouble();
        final driverMoneySaved = (driverDoc.data()?['total_money_saved'] ?? 0.0).toDouble();
        final riderCo2Saved = (riderDoc.data()?['co2_saved'] ?? 0.0).toDouble();
        final driverCo2Saved = (driverDoc.data()?['co2_saved'] ?? 0.0).toDouble();

        // Calculate savings using FareCalculator
        final sourcePoint = rideData['source_latlng'] as GeoPoint;
        final destPoint = rideData['destination_latlng'] as GeoPoint;
        final distanceKm = FareCalculator.calculateDistance(
          sourcePoint.latitude, sourcePoint.longitude,
          destPoint.latitude, destPoint.longitude,
        );

        final fareInfo = FareCalculator.calculatePerPersonFare(distanceKm);
        final rideMoneySaved = fareInfo.savings;
        final rideCo2Saved = distanceKm * 0.150; // Approximating 150g CO2 saved per km avoided by carpooling

        // Update booking
        transaction.update(bookingRef, {
          'booking_status': 'confirmed',
          'otp_verified': true,
        });

        // Update ride seats
        final newSeats = seatsAvailable - 1;
        transaction.update(rideRef, {
          'seats_available': newSeats,
          'ride_status': newSeats == 0 ? 'full' : 'active',
        });

        // Transfer fare and update savings logic
        transaction.update(riderRef, {
          'wallet_balance': (riderBalance - pricePerSeat).clamp(0, double.infinity),
          'total_money_saved': riderMoneySaved + rideMoneySaved,
          'co2_saved': riderCo2Saved + rideCo2Saved,
        });
        transaction.update(driverRef, {
          'wallet_balance': driverBalance + pricePerSeat,
          'total_money_saved': driverMoneySaved + rideMoneySaved,
          'co2_saved': driverCo2Saved + rideCo2Saved,
        });
      });

      return true;
    } catch (e) {
      debugPrint('OTP Verification Error: $e');
      return false;
    }
  }

  // -- Chat --

  /// Send a message in a ride's group chat
  Future<void> sendMessage({
    required String rideId,
    required String senderId,
    required String senderName,
    required String text,
    bool isDriver = false,
  }) async {
    await _db.collection('rides').doc(rideId)
        .collection('messages').add({
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'is_driver': isDriver,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream messages for a ride's group chat, ordered by time
  Stream<List<Map<String, dynamic>>> getMessages(String rideId) {
    return _db.collection('rides').doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'sender_id': data['sender_id'] ?? '',
            'sender_name': data['sender_name'] ?? 'Unknown',
            'text': data['text'] ?? '',
            'is_driver': data['is_driver'] ?? false,
            'timestamp': data['timestamp'],
          };
        }).toList());
  }

  // -- Ratings --

  /// Submit a rating for a user (driver or rider)
  Future<void> submitRating(String targetUserId, double rating) async {
    try {
      final userRef = _db.collection('users').doc(targetUserId);

      await _db.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final currentRating = (doc.data()?['rating'] ?? 5.0).toDouble();
        final currentCount = doc.data()?['rating_count'] ?? 0;

        // Calculate new moving average
        final newCount = currentCount + 1;
        final newRating = ((currentRating * currentCount) + rating) / newCount;

        transaction.update(userRef, {
          'rating': newRating,
          'rating_count': newCount,
        });
      });
    } catch (e) {
      debugPrint('Rating Submission Error: $e');
    }
  }
}
