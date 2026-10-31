import 'package:flutter/material.dart';

/// Shared colours and small building blocks for the new Yaan look.
/// Only visual helpers: no API calls or app logic live here.
class YaanColors {
  static const Color brand = Color(0xFFC0392B);
  static const Color brandTint = Color(0xFFFBEDEB);
  static const Color navy = Color(0xFF1B2433);
  static const Color ink = Color(0xFF14181F);
  static const Color body = Color(0xFF475467);
  static const Color muted = Color(0xFF5B6472);
  static const Color line = Color(0xFFEEF0F3);
  static const Color border = Color(0xFFD5D9E0);
  static const Color ground = Color(0xFFF4F5F7);
  static const Color field = Color(0xFFF9FAFB);
  static const Color headerSub = Color(0xFFC3CBD6);
  static const Color headerKicker = Color(0xFFFFB4A9);

  static const Color green = Color(0xFF157F3D);
  static const Color greenText = Color(0xFF0F5A2B);
  static const Color greenTint = Color(0xFFE8F6EE);
  static const Color amber = Color(0xFFA15C07);
  static const Color amberText = Color(0xFF7A4505);
  static const Color amberTint = Color(0xFFFEF4E2);
  static const Color red = Color(0xFFB42318);
  static const Color redTint = Color(0xFFFEF2F2);
  static const Color blueText = Color(0xFF1D4E89);
  static const Color blueTint = Color(0xFFE6EEF9);
}

/// White rounded card with a soft shadow.
class YaanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const YaanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: YaanColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small grey upper-case title used at the top of cards.
class YaanSectionTitle extends StatelessWidget {
  final String text;
  const YaanSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: YaanColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Input look used by every form field.
InputDecoration yaanInputDecoration({
  String? hint,
  IconData? icon,
  String? prefixText,
  Widget? suffix,
  bool enabled = true,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF8A93A0), fontSize: 14),
    prefixIcon: icon != null ? Icon(icon, color: YaanColors.brand, size: 20) : null,
    prefixText: prefixText,
    prefixStyle: const TextStyle(color: YaanColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
    suffixIcon: suffix,
    counterText: '',
    filled: true,
    fillColor: enabled ? YaanColors.field : const Color(0xFFF1F2F4),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border(YaanColors.border),
    enabledBorder: border(YaanColors.border),
    disabledBorder: border(const Color(0xFFE4E7EC)),
    focusedBorder: border(YaanColors.brand, 2),
    errorBorder: border(Colors.red),
    focusedErrorBorder: border(Colors.red, 2),
  );
}

/// Label above a field.
class YaanFieldLabel extends StatelessWidget {
  final String text;
  const YaanFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: YaanColors.body, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Square back button with a grey background (light screens).
class YaanBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool onDark;
  const YaanBackButton({super.key, this.onTap, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onDark ? Colors.white.withValues(alpha: 0.12) : YaanColors.ground,
      borderRadius: BorderRadius.circular(onDark ? 22 : 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(onDark ? 22 : 14),
        onTap: onTap ?? () => Navigator.maybePop(context),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back,
            color: onDark ? Colors.white : YaanColors.ink,
            size: 20,
            semanticLabel: 'Back',
          ),
        ),
      ),
    );
  }
}

/// Coloured pill with a dot (status chips).
class YaanStatusChip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final bool dot;
  const YaanStatusChip({super.key, required this.label, required this.fg, required this.bg, this.dot = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Label and colours for a booking status from the server.
({String label, Color fg, Color bg}) yaanBookingStatus(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return (label: 'Confirmed', fg: YaanColors.greenText, bg: YaanColors.greenTint);
    case 'completed':
      return (label: 'Checked in', fg: YaanColors.blueText, bg: YaanColors.blueTint);
    case 'cancelled':
      return (label: 'Cancelled', fg: YaanColors.body, bg: const Color(0xFFF1F2F4));
    case 'pending':
      return (label: 'Pending', fg: YaanColors.amberText, bg: YaanColors.amberTint);
    default:
      return (
        label: status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1),
        fg: YaanColors.body,
        bg: const Color(0xFFF1F2F4),
      );
  }
}

/// Initials for an avatar circle ("Suresh Yadav" -> "SY").
String yaanInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Progress bar made of segments (registration steps).
class YaanStepProgress extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const YaanStepProgress({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $current of $total',
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i < current ? YaanColors.brand : const Color(0xFFE4E7EC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Full-width primary button with loading spinner.
class YaanPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color color;
  final double height;

  const YaanPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.color = YaanColors.brand,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Outlined secondary button.
class YaanOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;

  const YaanOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color = YaanColors.ink,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color == YaanColors.ink ? YaanColors.border : color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
