import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

/// Navigation helper that wraps `Navigator` with consistent transitions
/// and decides which `Navigator` to push onto.
///
/// **Bottom-nav visibility rule** (per Slice 2.1.1 AppShell):
/// - Single-page pushes (`pushPageAnimation`, `pushPageNotAnimation`,
///   `pushPageDialog`) target the **root Navigator** — they appear above
///   the shell so the bottom nav HIDES on the pushed page.
/// - Stack-clearing pushes (`pushPageAndRemoveUntilNotAnimation`,
///   `pushPageAndRemoveUntilAnimation`) target the **branch Navigator** —
///   they clear the current tab's stack and plant the new page at the
///   branch root so the bottom nav stays visible (used for deep-link
///   recovery, e.g. scanner → items list fallback).
class ConfigRouter {
  static Future pushPageNotAnimation(BuildContext context, Widget page) async {
    return await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  static Future pushPageAnimation(BuildContext context, Widget page) async {
    return await Navigator.of(context, rootNavigator: true).push(
      PageTransition(
        type: PageTransitionType.rightToLeft,
        isIos: true,
        reverseType: PageTransitionType.fade,
        child: page,
      ),
    );
  }

  static pushPageAndRemoveUntilNotAnimation(BuildContext context, Widget page) async {
    return await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => page), (Route<dynamic> route) => false);
  }

  static Future pushPageAndRemoveUntilAnimation(BuildContext context, Widget page) async {
    return await Navigator.pushAndRemoveUntil(context, PageTransition(type: PageTransitionType.fade, isIos: true, reverseType: PageTransitionType.fade, child: page), (Route<dynamic> route) => false);
  }

  static pushPageDialog(BuildContext context, Widget page) async {
    return await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
        fullscreenDialog: true,
      ),
    );
  }
}
