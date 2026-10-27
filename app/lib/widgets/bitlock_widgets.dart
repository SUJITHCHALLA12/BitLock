import 'package:flutter/material.dart';

/// Primary call-to-action button used across BitLock.
///
/// Shows a small progress indicator instead of the label while [busy]
/// is true, and disables itself in that state so an action cannot be
/// submitted twice.
class BitLockPrimaryButton extends StatelessWidget {
  /// Creates a primary button.
  const BitLockPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    super.key,
  });

  /// Text shown on the button.
  final String label;

  /// Called when the button is tapped. Ignored while [busy].
  final VoidCallback? onPressed;

  /// Whether the action is in progress.
  final bool busy;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Search text field with a clear affordance, styled for BitLock lists.
class BitLockSearchField extends StatelessWidget {
  /// Creates a search field.
  const BitLockSearchField({
    required this.onChanged,
    this.hintText = 'Search',
    this.controller,
    super.key,
  });

  /// Called with the current query on every change.
  final ValueChanged<String> onChanged;

  /// Placeholder text shown while the field is empty.
  final String hintText;

  /// Optional external controller.
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
      ),
    );
  }
}

/// Centred empty state: icon, title, message, and an optional action.
class EmptyStateView extends StatelessWidget {
  /// Creates an empty state view.
  const EmptyStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Icon shown above the title.
  final IconData icon;

  /// Short headline, e.g. `No files yet`.
  final String title;

  /// One or two sentences explaining the state.
  final String message;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional action callback, used when [actionLabel] is set.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small pill showing a status, coloured by the caller.
///
/// The label must always be a factual state (for example a share
/// status returned by the server), never a marketing claim.
class StatusChip extends StatelessWidget {
  /// Creates a status chip.
  const StatusChip({required this.label, required this.color, super.key});

  /// Text shown in the chip.
  final String label;

  /// Chip background tint and text colour base.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Dashboard statistic card: icon, big value, small label.
class StatCard extends StatelessWidget {
  /// Creates a stat card.
  const StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    super.key,
  });

  /// Icon shown at the top of the card.
  final IconData icon;

  /// The measured value, derived from real app state by the caller.
  final String value;

  /// What the value counts.
  final String label;

  /// Optional tap handler (for example, jump to the related tab).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader({required this.title, this.actionLabel, this.onAction, super.key});

  /// Heading text.
  final String title;

  /// Optional trailing action label, e.g. `See all`.
  final String? actionLabel;

  /// Optional trailing action callback.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Shows a confirmation dialog and resolves to `true` only when the
/// user explicitly taps the confirm button.
///
/// Use [destructive] for delete/revoke-style actions so the confirm
/// button is coloured as an error action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
