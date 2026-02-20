// ========================================
// アクセシビリティ改善ユーティリティ
// ========================================
// 役割：スクリーンリーダー対応、タッチターゲット拡大、高コントラスト対応

import 'package:flutter/material.dart';

/// アクセシビリティ対応ボタン
class AccessibleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Widget? icon;
  final String? semanticLabel;
  final bool enabled;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      onTap: enabled ? onPressed : null,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// アクセシビリティ対応テキストフィールド
class AccessibleTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? semanticLabel;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? hintText;

  const AccessibleTextField({
    super.key,
    required this.label,
    required this.controller,
    this.semanticLabel,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.hintText,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? widget.label,
      enabled: true,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}

/// 最小タッチサイズ確保
class MinimumTouchSize extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double minSize;

  const MinimumTouchSize({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.minSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      child: GestureDetector(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(height: minSize, width: minSize),
          child: FractionallySizedBox(
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 高コントラスト対応テキスト
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool enhanceContrast;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.enhanceContrast = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isHighContrast = mediaQuery.highContrast;

    TextStyle finalStyle = style ?? const TextStyle();

    if (enhanceContrast && isHighContrast) {
      finalStyle = finalStyle.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );
    }

    return Semantics(
      label: text,
      child: Text(text, style: finalStyle),
    );
  }
}

/// リーダー向けスキップリンク
class SkipNavigation extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SkipNavigation({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: true,
      onTap: onPressed,
      child: Focus(
        onKey: (node, event) {
          return KeyEventResult.ignored;
        },
        child: Container(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: onPressed,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// スクリーンリーダー専用テキスト
class ScreenReaderOnly extends StatelessWidget {
  final String text;

  const ScreenReaderOnly(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: true,
      label: text,
      child: SizedBox.shrink(child: Text(text)),
    );
  }
}
