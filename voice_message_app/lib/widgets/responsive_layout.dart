// ========================================
// レスポンシブデザインユーティリティ
// ========================================
// 役割：異なる画面サイズに対応したレイアウト

import 'package:flutter/material.dart';

/// 画面サイズ分類
enum ScreenSize { mobile, tablet, desktop }

/// レスポンシブデザイン計算ユーティリティ
class ResponsiveUtils {
  /// 画面サイズを判定
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenSize.mobile;
    if (width < 1024) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// 幅がタブレット以上か判定
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// 幅がデスクトップ以上か判定
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// 画面が横向きか判定
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// レスポンシブな値を取得
  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final size = getScreenSize(context);
    if (size == ScreenSize.desktop && desktop != null) return desktop;
    if (size == ScreenSize.tablet && tablet != null) return tablet;
    return mobile;
  }
}

/// レスポンシブレイアウトウィジェット
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.getScreenSize(context);

    switch (size) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}

/// グリッドレイアウト（レスポンシブ対応）
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final EdgeInsets padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.isDesktop(context)
        ? 4
        : ResponsiveUtils.isTablet(context)
        ? 2
        : 1;

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 最大幅制限付きレイアウト
class ConstrainedResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ConstrainedResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 画面向き適応レイアウト
class OrientationLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const OrientationLayout({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return RequestFocusOnViewFinder(
      child: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait ? portrait : landscape;
        },
      ),
    );
  }
}

/// フレックス行/列（レスポンシブ対応）
class ResponsiveFlex extends StatelessWidget {
  final List<Widget> children;
  final bool vertical;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveFlex({
    super.key,
    required this.children,
    this.vertical = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final shouldStack = vertical && !isTablet;

    if (shouldStack) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// テキストスケール（レスポンシブ対応）
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double baseFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.baseFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );

    final fontSize = baseFontSize * textScale;
    final finalStyle = (style ?? const TextStyle()).copyWith(
      fontSize: fontSize,
    );

    return Text(text, style: finalStyle);
  }
}

/// パディングスケール（レスポンシブ対応）
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double mobileHorizontal;
  final double mobileVertical;
  final double? tabletHorizontal;
  final double? tabletVertical;
  final double? desktopHorizontal;
  final double? desktopVertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobileHorizontal = 16,
    this.mobileVertical = 12,
    this.tabletHorizontal,
    this.tabletVertical,
    this.desktopHorizontal,
    this.desktopVertical,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobileHorizontal,
      tablet: tabletHorizontal ?? mobileHorizontal * 1.5,
      desktop: desktopHorizontal ?? mobileHorizontal * 2,
    );

    final verticalPadding = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobileVertical,
      tablet: tabletVertical ?? mobileVertical * 1.5,
      desktop: desktopVertical ?? mobileVertical * 2,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: child,
    );
  }
}

// リクエストフォーカス（ViewFinder用）
class RequestFocusOnViewFinder extends StatelessWidget {
  final Widget child;

  const RequestFocusOnViewFinder({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
