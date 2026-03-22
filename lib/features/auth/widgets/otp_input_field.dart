import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// 6-box OTP input with auto-advance, paste support, and backspace handling.
/// Calls [onCompleted] with the 6-digit string when all boxes are filled.
class OtpInputField extends StatefulWidget {
  final void Function(String otp) onCompleted;

  const OtpInputField({super.key, required this.onCompleted});

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  static const int _length = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (i) {
      final fn = FocusNode();
      fn.onKeyEvent = (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[i].text.isEmpty &&
            i > 0) {
          _focusNodes[i - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
      return fn;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Clears all boxes and focuses the first one (call on OTP error / resend).
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= _length) {
        _focusNodes.last.unfocus();
        widget.onCompleted(_controllers.map((c) => c.text).join());
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final otp = _controllers.map((c) => c.text).join();
        if (otp.length == _length) widget.onCompleted(otp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        _length,
        (i) => _OtpBox(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          onChanged: (v) => _onChanged(i, v),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: AppSizes.buttonHeightM,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: onChanged,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
          fontSize: AppSizes.font4XL,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceColor,
          border: _border(AppColors.borderLightColor, AppSizes.borderMedium),
          enabledBorder: _border(AppColors.borderLightColor, AppSizes.borderMedium),
          focusedBorder: _border(AppColors.primaryColor, 2),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: BorderSide(color: color, width: width),
      );
}
