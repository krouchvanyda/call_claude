import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/items_repository.dart';
import 'items_list_page.dart';

/// Barcode / QR scanner page (Slice 5.2.1).
///
/// **Two paths** — both return the same `String` (the scanned barcode
/// payload) so the calling page doesn't care how the user produced it:
///
///   1. Live camera scan via [`MobileScanner`] on platforms that support
///      it (iOS / Android). Detected codes pop the route immediately
///      so the next page can react.
///   2. Manual entry — a TextField at the bottom that the user types
///      a barcode into, then taps "Use code". This is the fallback for
///      desktop / web / when camera permission is denied / for tests.
///
/// When the [resolveToItem] flag is `true` (default), the page also
/// looks up the scanned code against [`ItemsRepository.findByBarcode`]
/// before returning — saves the next page a hop and surfaces an inline
/// "not found" error.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, this.resolveToItem = true});

  /// When true, attempt to resolve the scanned code to an item id
  /// before popping. The route pops `String` (the item id) on hit, or
  /// the raw barcode on miss. Set to false when the caller just wants
  /// the raw payload (e.g. cycle count line picker).
  final bool resolveToItem;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _manualCtrl = TextEditingController();
  final _scannerController = MobileScannerController();
  bool _handling = false;
  String? _inlineError;

  @override
  void dispose() {
    _manualCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// True on the two platforms where the live scanner widget actually
  /// runs. Everywhere else (desktop / web / tests) we hide the camera
  /// preview and rely on manual entry.
  bool get _liveScanSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _handlePayload(String raw) async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _inlineError = null;
    });
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final payload = raw.trim();
    if (payload.isEmpty) {
      setState(() {
        _handling = false;
        _inlineError = l10n.inventoryScannerEmpty;
      });
      return;
    }

    if (!widget.resolveToItem) {
      if (!mounted) return;
      context.pop(payload);
      return;
    }

    try {
      final item = await getIt<ItemsRepository>().findByBarcode(payload);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _handling = false;
          _inlineError = l10n.inventoryScannerUnknown(payload);
        });
        return;
      }
      context.pop(item.id);
    } catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.inventoryScannerError(e.toString())),
        ));
      setState(() => _handling = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    HapticFeedback.selectionClick();
    _handlePayload(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.inventoryScannerTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          if (_liveScanSupported)
            Expanded(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            )
          else
            Expanded(
              child: _UnsupportedPlatform(text: l10n.inventoryScannerNoCamera),
            ),
          _ManualEntryBar(
            controller: _manualCtrl,
            inlineError: _inlineError,
            onSubmit: () => _handlePayload(_manualCtrl.text),
            disabled: _handling,
          ),
        ],
      ),
    );
  }
}

class _UnsupportedPlatform extends StatelessWidget {
  const _UnsupportedPlatform({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value14,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualEntryBar extends StatelessWidget {
  const _ManualEntryBar({
    required this.controller,
    required this.inlineError,
    required this.onSubmit,
    required this.disabled,
  });

  final TextEditingController controller;
  final String? inlineError;
  final VoidCallback onSubmit;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabel(
              text: l10n.inventoryScannerManualHeading,
              fontSize: AppFontSize.value12,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: l10n.inventoryScannerManualLabel,
                      hintText: l10n.inventoryScannerManualHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: inlineError,
                    ),
                    onSubmitted: disabled ? null : (_) => onSubmit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: disabled ? null : onSubmit,
                  icon: const Icon(Icons.check),
                  label: AppLabel(
                    text: l10n.inventoryScannerManualUseAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              // Scanner is normally pushed from the items list — pop
              // returns there and keeps the rest of the back stack
              // intact. Fall back to a named navigation if we got here
              // via deep-link (nothing to pop).
              onPressed: () => context.canPop()
                  ? context.pop()
                  : ConfigRouter.pushPageAndRemoveUntilAnimation(
                      context, const ItemsListPage()),
              icon: const Icon(Icons.list_alt_outlined),
              label: AppLabel(
                text: l10n.inventoryScannerBrowseFallback,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
