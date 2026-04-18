import 'dart:math';

/// Fare calculator based on Mumbai auto-rickshaw rates (effective Feb 2025)
/// Base fare: ₹26 for first 1.5 km
/// Per km after: ₹17.14/km
/// Night surcharge: 25% (12 AM – 5 AM)
/// Split between 3 passengers + ₹2 app fee per user
class FareCalculator {
  static const double baseFare = 26.0; // First 1.5 km
  static const double baseDistance = 1.5; // km
  static const double perKmRate = 17.14; // Per km after base
  static const double perMinuteRate = 2.0; // Waiting/slow traffic
  static const double appFeePerUser = 2.0; // App fee
  static const int defaultPassengers = 3; // Auto sharing split

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371.0; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final straightLineDistance = earthRadius * c;

    // Multiply by road factor (roads aren't straight lines)
    return straightLineDistance * 1.35;
  }

  /// Estimate travel time based on distance
  /// Average speed in Mumbai: ~18 km/h during peak, ~25 km/h off-peak
  static double estimateTimeMinutes(double distanceKm) {
    const avgSpeedKmh = 20.0; // Average Mumbai traffic speed
    return (distanceKm / avgSpeedKmh) * 60;
  }

  /// Calculate total auto fare for the trip
  static double calculateTotalFare(double distanceKm) {
    double fare = baseFare;

    if (distanceKm > baseDistance) {
      fare += (distanceKm - baseDistance) * perKmRate;
    }

    // Add time-based charges
    final timeMinutes = estimateTimeMinutes(distanceKm);
    if (timeMinutes > 5) {
      // Add waiting charges for time beyond 5 minutes
      fare += (timeMinutes - 5) * (perMinuteRate * 0.3);
    }

    return fare;
  }

  /// Calculate fare per person (split + app fee)
  static FareBreakdown calculatePerPersonFare(
    double distanceKm, {
    int passengers = defaultPassengers,
  }) {
    final totalFare = calculateTotalFare(distanceKm);
    final perPerson = totalFare / passengers;
    final perPersonWithApp = perPerson + appFeePerUser;
    final timeEstimate = estimateTimeMinutes(distanceKm);
    final totalSavings = totalFare - perPersonWithApp;

    return FareBreakdown(
      totalAutoFare: totalFare,
      perPersonFare: perPerson,
      appFee: appFeePerUser,
      totalPerPerson: perPersonWithApp,
      distanceKm: distanceKm,
      estimatedMinutes: timeEstimate,
      savings: totalSavings > 0 ? totalSavings : 0,
      passengers: passengers,
    );
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class FareBreakdown {
  final double totalAutoFare;
  final double perPersonFare;
  final double appFee;
  final double totalPerPerson;
  final double distanceKm;
  final double estimatedMinutes;
  final double savings;
  final int passengers;

  FareBreakdown({
    required this.totalAutoFare,
    required this.perPersonFare,
    required this.appFee,
    required this.totalPerPerson,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.savings,
    required this.passengers,
  });
}
