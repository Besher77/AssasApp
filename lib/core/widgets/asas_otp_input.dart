import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// 6-digit OTP input with auto-advance, backspace-to-previous, and paste support.
class AsasOtpInput extends StatefulWidget {
  const AsasOtpInput({
    super.key,
    required this.onCompleted,
  });

  final void Function(String code) onCompleted;

  @override
  State<AsasOtpInput> createState() => _AsasOtpInputState();
}

class _AsasOtpInputState extends State<AsasOtpInput> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  /// Avoid re-entry when we set [TextEditingController] text programmatically.
  bool _suppressChanged = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _trySubmit() {
    final code = _code;
    if (code.length == 6) {
      widget.onCompleted(code);
    }
  }

  void _setCellText(int index, String char) {
    _suppressChanged = true;
    _controllers[index].value = TextEditingValue(
      text: char,
      selection: TextSelection.collapsed(offset: char.length),
    );
    _suppressChanged = false;
  }

  void _onDigitChanged(int index, String value) {
    if (_suppressChanged) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Cleared this cell
    if (digits.isEmpty) {
      return;
    }

    // Paste / multiple digits: spread from this index
    if (digits.length > 1) {
      var i = index;
      for (var j = 0; j < digits.length && i < 6; j++, i++) {
        _setCellText(i, digits[j]);
      }
      setState(() {});
      if (i >= 6) {
        FocusScope.of(context).unfocus();
      } else {
        _focusNodes[i].requestFocus();
      }
      _trySubmit();
      return;
    }

    // Single digit (normalize length — some keyboards send replacement)
    final ch = digits[0];
    if (_controllers[index].text != ch) {
      _setCellText(index, ch);
    }

    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {});
    _trySubmit();
  }

  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete;

    if (!isBackspace) return KeyEventResult.ignored;

    if (_controllers[index].text.isNotEmpty) return KeyEventResult.ignored;

    if (index > 0) {
      _setCellText(index - 1, '');
      _focusNodes[index - 1].requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[index - 1].requestFocus();
      });
      setState(() {});
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) => _buildDigitBox(context, index)),
      ),
    );
  }

  Widget _buildDigitBox(BuildContext context, int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: Focus(
        onKeyEvent: (node, event) => _onKeyEvent(index, event),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          autofocus: index == 0,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
          maxLength: 1,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
            ),
          ),
          autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => _onDigitChanged(index, value),
          onFieldSubmitted: (_) {
            if (index < 5 && _controllers[index].text.isNotEmpty) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _trySubmit();
            }
          },
        ),
      ),
    );
  }
}
