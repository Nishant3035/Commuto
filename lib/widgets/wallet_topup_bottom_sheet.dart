import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletTopupBottomSheet extends StatefulWidget {
  final Function(double) onTopup;
  const WalletTopupBottomSheet({super.key, required this.onTopup});

  @override
  State<WalletTopupBottomSheet> createState() => _WalletTopupBottomSheetState();
}

class _WalletTopupBottomSheetState extends State<WalletTopupBottomSheet> {
  final TextEditingController _amountController = TextEditingController(text: '500');
  String _selectedMethod = 'UPI';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handlePay() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    // Show success animation
    setState(() => _isProcessing = false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
            ),
            const SizedBox(height: 20),
            Text('Payment Successful!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('₹${amount.toInt()} added to your wallet via $_selectedMethod',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('TXN: SIM${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  widget.onTopup(amount);
                  Navigator.pop(context); // Close bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Done', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        top: 20, left: 24, right: 24,
        bottom: 32 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Top up Wallet',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text('Add money to your Commuto wallet',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Quick amount buttons
            Row(
              children: [
                _quickAmountChip(100),
                const SizedBox(width: 8),
                _quickAmountChip(200),
                const SizedBox(width: 8),
                _quickAmountChip(500),
                const SizedBox(width: 8),
                _quickAmountChip(1000),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text('₹', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('PAYMENT METHOD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.5)),
            const SizedBox(height: 12),

            _buildPaymentMethod(id: 'UPI', icon: Icons.account_balance_wallet_rounded, title: 'UPI / GPay / PhonePe'),
            const SizedBox(height: 10),
            _buildPaymentMethod(id: 'CARD', icon: Icons.credit_card_rounded, title: 'Credit / Debit Card'),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                          const SizedBox(width: 12),
                          Text('Processing...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      )
                    : Text('Pay ₹${_amountController.text}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountChip(int amount) {
    final isSelected = _amountController.text == amount.toString();
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _amountController.text = amount.toString()),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text('₹$amount', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF64748B))),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({required String id, required IconData icon, required String title}) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isSelected ? Colors.white : const Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)))),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }
}
