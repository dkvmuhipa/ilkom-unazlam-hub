import 'package:flutter/material.dart';


import '../../../core/constants/app_colors.dart';

/// Keeps related content in a row on wide panels and stacks it on small ones.
class AdminAdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  const AdminAdaptiveRow({super.key, required this.children, this.breakpoint = 560,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (constraints.maxWidth >= breakpoint * scale) {
      return Row(mainAxisAlignment: mainAxisAlignment, mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment, children: children);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8,
      mainAxisSize: MainAxisSize.min, children: children.where((child) => child is! Spacer).map((child) {
        if (child is Flexible) return child.child;
        if (child is SizedBox && child.width != null) {
          return child.child == null ? SizedBox(height: child.width) : child.child!;
        }
        return Align(alignment: Alignment.centerLeft, child: child);
      }).toList());
  });
}

class AdminAppBar extends StatelessWidget {
  final String title;
  final bool showSearch;
  final VoidCallback? onSearch;
  final VoidCallback? onBack;

  const AdminAppBar({
    super.key,
    required this.title,
    this.showSearch = true,
    this.onSearch,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (showSearch && onSearch != null)
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: onSearch,
            ),
          if (!showSearch && onSearch != null)
            IconButton(
              tooltip: 'Muat ulang',
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: onSearch,
            ),
        ],
      ),
    );
  }
}

class AdminSearchBox extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AdminSearchBox({super.key, required this.hintText, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
        boxShadow: AppColors.shadowSm,
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryLight,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class AdminFormLabel extends StatelessWidget {
  final String label;

  const AdminFormLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class AdminFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  const AdminFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class AdminDropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const AdminDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 13.5,
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(value: item, child: Text('$item')),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
