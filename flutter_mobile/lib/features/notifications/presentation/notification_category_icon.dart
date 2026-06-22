import 'package:flutter/material.dart';

/// Maps a free-form notification category string to a Material icon
/// (Slice 2.3.3).
///
/// **Why a function not an enum**: the [`AppNotification.category`] is
/// intentionally a string so the server can introduce new categories
/// without a client schema bump. This lookup is the one place the UI
/// translates string → icon; unknown categories degrade to a generic
/// bell so a new server-side category never renders as a missing icon.
///
/// Pure (no Flutter `BuildContext`, no theme) so the mapping rules are
/// unit-testable in isolation.
IconData notificationCategoryIcon(String category) {
  return switch (category) {
    'invoice' => Icons.receipt_long_outlined,
    'leave-request' => Icons.event_available_outlined,
    'purchase-order' => Icons.shopping_cart_outlined,
    'inventory' => Icons.inventory_2_outlined,
    'project' => Icons.task_alt_outlined,
    'system' => Icons.info_outline,
    _ => Icons.notifications_outlined,
  };
}
