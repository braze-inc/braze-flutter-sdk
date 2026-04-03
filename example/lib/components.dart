import 'package:flutter/material.dart';

import 'log_console.dart';
import 'theme.dart';

// --- Snackbar & dialogs (small UX helpers) ---

extension BrazeAppSnackbar on BuildContext {
  void showBrazeAppSnackbar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

void showDeepLinkAlert(BuildContext context, String link) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text('Deep Link Alert'),
        content: Text('Opened with deep link: $link'),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      );
    },
  );
}

// --- Buttons & cards ---

enum BrazeButtonVariant { primary, secondary, danger }

/// Primary action button styled for the Braze sample app.
class BrazeAppButton extends StatelessWidget {
  const BrazeAppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = BrazeButtonVariant.primary,
  });

  final String title;
  final VoidCallback onPressed;
  final BrazeButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    switch (variant) {
      case BrazeButtonVariant.primary:
        bgColor = BrazeAppColors.primary;
        break;
      case BrazeButtonVariant.secondary:
        bgColor = BrazeAppColors.secondary;
        break;
      case BrazeButtonVariant.danger:
        bgColor = BrazeAppColors.danger;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// White elevated card container for grouped controls.
class BrazeAppCard extends StatelessWidget {
  const BrazeAppCard({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrazeAppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrazeAppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Labeled text field matching the sample app input style.
class BrazeAppInput extends StatelessWidget {
  const BrazeAppInput({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BrazeAppColors.textMedium,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            controller: controller,
            style: const TextStyle(
              fontSize: 15,
              color: BrazeAppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: BrazeAppColors.textPlaceholder,
              ),
              filled: true,
              fillColor: BrazeAppColors.backgroundWhite,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: BrazeAppColors.borderGray,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: BrazeAppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Informational callout with blue tint.
class BrazeAppInfoBox extends StatelessWidget {
  const BrazeAppInfoBox({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: BrazeAppColors.infoBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: BrazeAppColors.infoText,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Dropdown for Boolean / Number / … property type selection.
class PropertyTypeDropdown extends StatelessWidget {
  const PropertyTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BrazeAppColors.textMedium,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: BrazeAppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BrazeAppColors.borderGray,
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: const TextStyle(
                fontSize: 15,
                color: BrazeAppColors.textDark,
              ),
              items: const [
                DropdownMenuItem(value: 'Boolean', child: Text('Boolean')),
                DropdownMenuItem(value: 'Number', child: Text('Number')),
                DropdownMenuItem(value: 'String', child: Text('String')),
                DropdownMenuItem(value: 'Timestamp', child: Text('Timestamp')),
                DropdownMenuItem(value: 'Json', child: Text('Json')),
                DropdownMenuItem(value: 'Image', child: Text('Image')),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable scaffold with app bar and hero title/subtitle.
class BrazeAppScreenLayout extends StatelessWidget {
  const BrazeAppScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          LogConsoleToggleButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: BrazeAppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: BrazeAppColors.textGray,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Key/value row for stream or SDK status.
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Color valueColor;
    if (value == 'Enabled') {
      valueColor = BrazeAppColors.success;
    } else if (value == 'Disabled') {
      valueColor = BrazeAppColors.danger;
    } else {
      valueColor = BrazeAppColors.textMedium;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BrazeAppColors.textMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Routes available from the home screen.
enum SampleDestination {
  contentCards,
  banners,
  featureFlags,
  userManagement,
}

/// Data for a home-screen feature row.
class FeatureCardData {
  const FeatureCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.destination,
  });

  final String title;
  final String description;
  final String icon;
  final Color color;
  final SampleDestination destination;
}

/// Tappable card with left accent, icon, and chevron.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final FeatureCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: BrazeAppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: data.color, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: BrazeAppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      data.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: BrazeAppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: BrazeAppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '›',
                  style: TextStyle(
                    fontSize: 28,
                    color: BrazeAppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
