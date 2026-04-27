import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Payment service using Razorpay in TEST mode.
/// To switch to production, replace the test key with your live key.
class PaymentService {
  static final Razorpay _razorpay = Razorpay();
  
  // Razorpay TEST key — replace with live key for production
  static String get _testKey => dotenv.env['RAZORPAY_TEST_KEY'] ?? '';
  
  static Function(double amount)? _onSuccess;
  static Function(String error)? _onFailure;

  static void init() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  static void dispose() {
    _razorpay.clear();
  }

  /// Opens Razorpay checkout with the given amount and payment method preference.
  /// Amount is in INR (will be converted to paise internally).
  static void openCheckout({
    required double amount,
    required String method, // 'UPI', 'CARD', or 'QR'
    required String description,
    String? email,
    String? phone,
    required Function(double amount) onSuccess,
    required Function(String error) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    var options = {
      'key': _testKey,
      'amount': (amount * 100).toInt(), // Razorpay expects paise
      'name': 'Commuto',
      'description': description,
      'prefill': {
        'email': email ?? 'user@commuto.app',
        'contact': phone ?? '',
      },
      'theme': {
        'color': '#2563EB',
      },
    };

    // In test mode, don't restrict payment methods — let Razorpay show all
    // In production, you can uncomment the method filter below
    // if (method == 'UPI') { options['method'] = {'upi': true, ...}; }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      onFailure('Failed to open payment gateway');
    }
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    if (_onSuccess != null) {
      // The amount will be passed from the calling code
      _onSuccess!(0); // Amount tracked by caller
    }
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _onFailure?.call(response.message ?? 'Payment failed');
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }
}
