import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool hasError;

  const OtpField({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
  });

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _code;

  @override
  void initState() {
    super.initState();
    _code = List.filled(widget.length, "");
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste if needed, but for simplicity here we just take the last char
      value = value.substring(value.length - 1);
      _controllers[index].text = value;
    }

    _code[index] = value;
    
    if (widget.onChanged != null) {
      widget.onChanged!(_code.join());
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_code.every((element) => element.isNotEmpty)) {
      widget.onCompleted(_code.join());
    }
  }

  void _handleKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.backspace && 
        _controllers[index].text.isEmpty && 
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Container(
          width: widget.length == 6 ? 48 : 64,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.hasError 
                  ? Colors.redAccent 
                  : (_focusNodes[index].hasFocus 
                      ? const Color(0xFF2B7DE9) 
                      : const Color(0xFFD6E4F9)),
              width: 2,
            ),
            boxShadow: _focusNodes[index].hasFocus ? [
              BoxShadow(
                color: const Color(0xFF2B7DE9).withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: KeyboardListener(
            focusNode: FocusNode(), // Wrap each to catch backspace
            onKeyEvent: (event) => _handleKeyEvent(event, index),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              onChanged: (value) => _handleChanged(value, index),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D26),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        );
      }),
    );
  }
}
