import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

// ============================================================================
// 1. SOFT PILL BADGE (Emerald, Amber, Rose, Navy, Slate)
// ============================================================================

enum SoftPillVariant {
  emerald, // Sukses / Lunas / Aktif
  amber, // Pending / Menunggu / Peringatan
  rose, // Batal / Bahaya / Terlambat
  navy, // Info / Peran / Modul
  slate, // Netral / Nonaktif / Arsip
}

class SoftPillBadge extends StatelessWidget {
  final String label;
  final SoftPillVariant variant;
  final IconData? icon;
  final bool showDot;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const SoftPillBadge({
    super.key,
    required this.label,
    this.variant = SoftPillVariant.navy,
    this.icon,
    this.showDot = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
    this.fontSize = 11.5,
  });

  factory SoftPillBadge.success({required String label, IconData? icon, bool showDot = false, double fontSize = 11.5}) =>
      SoftPillBadge(label: label, variant: SoftPillVariant.emerald, icon: icon, showDot: showDot, fontSize: fontSize);

  factory SoftPillBadge.warning({required String label, IconData? icon, bool showDot = false, double fontSize = 11.5}) =>
      SoftPillBadge(label: label, variant: SoftPillVariant.amber, icon: icon, showDot: showDot, fontSize: fontSize);

  factory SoftPillBadge.danger({required String label, IconData? icon, bool showDot = false, double fontSize = 11.5}) =>
      SoftPillBadge(label: label, variant: SoftPillVariant.rose, icon: icon, showDot: showDot, fontSize: fontSize);

  factory SoftPillBadge.info({required String label, IconData? icon, bool showDot = false, double fontSize = 11.5}) =>
      SoftPillBadge(label: label, variant: SoftPillVariant.navy, icon: icon, showDot: showDot, fontSize: fontSize);

  factory SoftPillBadge.neutral({required String label, IconData? icon, bool showDot = false, double fontSize = 11.5}) =>
      SoftPillBadge(label: label, variant: SoftPillVariant.slate, icon: icon, showDot: showDot, fontSize: fontSize);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;

    switch (variant) {
      case SoftPillVariant.emerald:
        bg = AppColors.emeraldSoft; // #D1FAE5
        text = AppColors.emeraldText; // #065F46
        border = AppColors.emeraldBorder; // #A7F3D0
        break;
      case SoftPillVariant.amber:
        bg = AppColors.amberSoft; // #FEF3C7
        text = AppColors.amberText; // #92400E
        border = AppColors.amberBorder; // #FDE68A
        break;
      case SoftPillVariant.rose:
        bg = AppColors.roseSoft; // #FFE4E6
        text = AppColors.roseText; // #9F1239
        border = AppColors.roseBorder; // #FECDD3
        break;
      case SoftPillVariant.navy:
        bg = AppColors.primarySoft; // #EFF6FF
        text = AppColors.primary; // #1E40AF
        border = AppColors.primaryBorder; // #BFDBFE
        break;
      case SoftPillVariant.slate:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF334155);
        border = const Color(0xFFE2E8F0);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999), // full pill
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: text,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: text),
            const SizedBox(width: 4.5),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: text,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. MODERN CLEAN SAAS CARD CONTAINER (rounded-3xl, bg-white, border-gray-100)
// ============================================================================

class SaaSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final bool withShadow;

  const SaaSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 24.0, // rounded-3xl
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: withShadow ? AppColors.shadowSm : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

// ============================================================================
// 3. FROSTED GLASS MODAL WITH ESCAPE KEY LISTENER & BACKDROP BLUR
// ============================================================================

Future<T?> showGlassModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  double maxWidth = 560,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss Modal',
    barrierColor: Colors.black.withValues(alpha: 0.60), // bg-black/60
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogCtx, anim1, anim2) {
      return GlassModalContainer(
        maxWidth: maxWidth,
        child: builder(dialogCtx),
      );
    },
    transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
      final curvedValue = Curves.easeOutCubic.transform(anim.value);
      return Transform.scale(
        scale: 0.94 + (0.06 * curvedValue),
        child: Opacity(
          opacity: anim.value,
          child: child,
        ),
      );
    },
  );
}

class GlassModalContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const GlassModalContainer({
    super.key,
    required this.child,
    this.maxWidth = 560,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Frosted glass blur effect: backdrop-blur-md
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24), // rounded-3xl
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: AppColors.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassModalHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;

  const GlassModalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14), // rounded-2xl
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900, // font-black
                    letterSpacing: -0.5, // tracking-tight
                    color: AppColors.textMain,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.textSub,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSub),
            tooltip: 'Tutup (Esc)',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. FORM INPUT BERAWALAN IKON VISUAL DENGAN FOCUS RING BIRU LEMBUT
// ============================================================================

class SaaSInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final String? helperText;
  final TextCapitalization textCapitalization;
  final bool isRequired;

  const SaaSInputField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.helperText,
    this.textCapitalization = TextCapitalization.none,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label form kecil kapital: text-xs uppercase tracking-wider text-gray-400
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: AppColors.textMuted,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSub,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      prefixIcon,
                      size: 20,
                      color: AppColors.primaryLight,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), // rounded-2xl
              borderSide: const BorderSide(color: AppColors.borderMedium, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.borderMedium, width: 1),
            ),
            // Focus ring biru lembut (#2563EB)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. MULTI-STEP STEPPER FORM DENGAN PROGRESS BAR ANIMASI
// ============================================================================

class SaaSStepItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget content;
  final bool Function()? validator;

  const SaaSStepItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.content,
    this.validator,
  });
}

class SaaSStepper extends StatefulWidget {
  final List<SaaSStepItem> steps;
  final Future<void> Function() onComplete;
  final VoidCallback? onCancel;
  final String completeLabel;
  final bool isSubmitting;

  const SaaSStepper({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onCancel,
    this.completeLabel = 'Selesai & Simpan',
    this.isSubmitting = false,
  });

  @override
  State<SaaSStepper> createState() => _SaaSStepperState();
}

class _SaaSStepperState extends State<SaaSStepper> {
  int _currentStep = 0;

  void _nextStep() {
    final step = widget.steps[_currentStep];
    if (step.validator != null && !step.validator!()) {
      return;
    }
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.steps.length;
    final progress = (_currentStep + 1) / totalSteps;
    final activeStepData = widget.steps[_currentStep];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Animated Progress Bar
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: AppColors.primarySoft,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              );
            },
          ),
        ),

        // Stepper Visual Badges
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isActive = index == _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primarySoft
                              : isCompleted
                                  ? AppColors.emeraldSoft
                                  : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primaryBorder
                                : isCompleted
                                    ? AppColors.emeraldBorder
                                    : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : isCompleted
                                        ? AppColors.emeraldText
                                        : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.steps[index].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isActive || isCompleted
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isActive
                                      ? AppColors.primary
                                      : isCompleted
                                          ? AppColors.emeraldText
                                          : AppColors.textSub,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // Step Subtitle / Description
        if (activeStepData.subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Text(
              activeStepData.subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textSub,
                height: 1.4,
              ),
            ),
          ),
        ],

        // Step Content Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: activeStepData.content,
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // Stepper Navigation Footer Buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                OutlinedButton.icon(
                  onPressed: widget.isSubmitting ? null : _prevStep,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Kembali'),
                ),
              ] else if (widget.onCancel != null) ...[
                TextButton(
                  onPressed: widget.isSubmitting ? null : widget.onCancel,
                  child: const Text('Batal'),
                ),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : _nextStep,
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _currentStep == totalSteps - 1
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                label: Text(
                  widget.isSubmitting
                      ? 'Memproses…'
                      : _currentStep == totalSteps - 1
                          ? widget.completeLabel
                          : 'Lanjut ke Tahap ${_currentStep + 2}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 6. TABEL DATA DENGAN ZEBRA STRIPING HALUS, FILTER TOOLBAR, DAN BADGE STATUS
// ============================================================================

class SaaSDataTableToolbar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final Widget? filterDropdown;
  final Widget? actionButton;

  const SaaSDataTableToolbar({
    super.key,
    required this.title,
    this.subtitle,
    required this.searchController,
    this.searchHint = 'Cari data…',
    this.onSearchChanged,
    this.filterDropdown,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900, // font-black
                        letterSpacing: -0.6, // tracking-tight
                        color: AppColors.textMain,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?actionButton,
            ],
          ),
          const SizedBox(height: 16),
          // Filter Toolbar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                    border: Border.all(color: AppColors.borderMedium),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              if (filterDropdown != null) ...[
                const SizedBox(width: 12),
                filterDropdown!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SaaSTableRowItem extends StatelessWidget {
  final int index;
  final List<Widget> cells;
  final VoidCallback? onTap;

  const SaaSTableRowItem({
    super.key,
    required this.index,
    required this.cells,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Zebra striping: Genap putih (#FFFFFF), Ganjil Slate-50 (#F8FAFC)
    final rowColor = index.isEven ? Colors.white : const Color(0xFFF8FAFC);

    final rowWidget = Container(
      decoration: BoxDecoration(
        color: rowColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: cells,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: rowWidget,
      );
    }

    return rowWidget;
  }
}

class SaaSTableHeader extends StatelessWidget {
  final List<Widget> headers;

  const SaaSTableHeader({super.key, required this.headers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9), // Slate 100
        border: Border(
          bottom: BorderSide(color: AppColors.borderMedium, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: headers,
      ),
    );
  }
}

Widget saasHeaderCell(String label, {int flex = 1, TextAlign align = TextAlign.left}) {
  return Expanded(
    flex: flex,
    child: Text(
      label.toUpperCase(),
      textAlign: align,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w800, // font-black / extra bold
        letterSpacing: 0.9, // tracking-wider
        color: const Color(0xFF475569), // text-gray-500
      ),
    ),
  );
}
