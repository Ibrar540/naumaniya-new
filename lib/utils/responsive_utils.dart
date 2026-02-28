import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsivePadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 20,
    double desktop = 24,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 8,
    double tablet = 12,
    double desktop = 16,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 20,
    double tablet = 24,
    double desktop = 28,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getResponsiveEdgeInsets(
    BuildContext context, {
    double mobile = 16,
    double tablet = 20,
    double desktop = 24,
  }) {
    final padding = getResponsivePadding(context,
        mobile: mobile, tablet: tablet, desktop: desktop);
    return EdgeInsets.all(padding);
  }

  static BorderRadius getResponsiveBorderRadius(
    BuildContext context, {
    double mobile = 12,
    double tablet = 16,
    double desktop = 20,
  }) {
    final radius =
        isMobile(context) ? mobile : (isTablet(context) ? tablet : desktop);
    return BorderRadius.circular(radius);
  }

  static int getResponsiveGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  static double getResponsiveGridChildAspectRatio(BuildContext context) {
    if (isMobile(context)) return 0.85;
    if (isTablet(context)) return 1.0;
    return 1.1;
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48;
    if (isTablet(context)) return 52;
    return 56;
  }

  static double getResponsiveCardHeight(BuildContext context) {
    if (isMobile(context)) return 120;
    if (isTablet(context)) return 140;
    return 160;
  }

  static TextStyle getResponsiveTextStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize ?? getResponsiveFontSize(context),
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static BoxShadow getResponsiveBoxShadow(
    BuildContext context, {
    Color? color,
    double? blurRadius,
    Offset? offset,
  }) {
    final isMobileDevice = isMobile(context);
    return BoxShadow(
      color: color ?? Colors.black.withAlpha((0.1 * 255).toInt()),
      blurRadius: blurRadius ?? (isMobileDevice ? 8 : 12),
      offset: offset ?? Offset(0, isMobileDevice ? 2 : 4),
    );
  }

  static Widget getResponsiveContainer({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? getResponsiveEdgeInsets(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }

  static Widget getResponsiveCard({
    required BuildContext context,
    required Widget child,
    Color? color,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? elevation,
  }) {
    return Card(
      color: color,
      elevation: elevation ?? (isMobile(context) ? 2 : 4),
      shape: RoundedRectangleBorder(
        borderRadius: getResponsiveBorderRadius(context),
      ),
      margin: margin ?? EdgeInsets.all(getResponsiveSpacing(context)),
      child: Padding(
        padding: padding ?? getResponsiveEdgeInsets(context),
        child: child,
      ),
    );
  }

  static Widget getResponsiveButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    Color? foregroundColor,
    double? height,
    EdgeInsets? padding,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height ?? getResponsiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: getResponsiveBorderRadius(context),
          ),
          padding: padding,
        ),
        child: child,
      ),
    );
  }

  static Widget getResponsiveTextField({
    required BuildContext context,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      style: getResponsiveTextStyle(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: getResponsiveTextStyle(
          context,
          color: Colors.grey[500],
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
          size: getResponsiveIconSize(context),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(context),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(context),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(context),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(context),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: getResponsivePadding(context),
          vertical: getResponsivePadding(context),
        ),
      ),
    );
  }
}
