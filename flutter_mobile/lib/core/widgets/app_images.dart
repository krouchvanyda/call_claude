import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets/app_image_paths.dart';
import '../config/environments.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Centralised image factory.
///
/// One place to swap asset/network image rendering, so a future change
/// (CDN host, image-CDN query params, fallback widget) is a single-file
/// edit instead of grepping the whole tree.
///
/// All methods are static — the class can't be constructed.
abstract final class AppImages {
  /// Default asset for the app logo. Override per call site via
  /// [logoImage]'s implicit constructor.
  static const String logo = AppImagePaths.logo;

  // ── Asset images ─────────────────────────────────────────────
  /// App logo with a `Hero` tag so it animates between routes (splash
  /// → login → loading). Pass a different [tag] to opt out of the
  /// shared hero.
  static Widget logoImage({
    double? width = 200,
    double height = 200,
    String tag = 'app-logo',
  }) {
    return Hero(
      tag: tag,
      child: Image.asset(
        logo,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget assetImage(
    String image, {
    BoxFit? fit,
    double? scale,
    double? width,
    double? height,
    Color? color,
  }) {
    return Image.asset(
      image,
      fit: fit,
      width: width,
      height: height,
      scale: scale,
      color: color,
    );
  }

  /// `flutter_svg` 2.x renamed the tint API to `colorFilter` — wrap the
  /// optional [color] here so call sites stay simple.
  static Widget assetSVG(
    String image, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Color? color,
  }) {
    return SvgPicture.asset(
      image,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  // ── Network images ───────────────────────────────────────────
  /// Avatar with a "default profile" fallback. Falls through to a
  /// Material icon when the bundled default asset hasn't shipped yet
  /// (so a missing file doesn't paint a red asset-404 box).
  static Widget profileImage(
    String imageUrl, {
    double? width,
    BoxFit? fit,
    double? scale,
    Color? color,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: ensureHttp(imageUrl),
      width: width,
      height: height,
      color: color,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => _DefaultProfileFallback(width: width, height: height),
      errorWidget: (_, __, ___) => _DefaultProfileFallback(width: width, height: height),
    );
  }

  /// Banner that pre-asks the image CDN for a 250px-high JPEG at quality
  /// 60 — keeps payloads small for long list scrolls.
  static Widget networkBannerImage(
    String imageUrl, {
    double? width,
    BoxFit? fit,
    double? scale,
    Color? color,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: '${ensureHttp(imageUrl)}?h=250&q=60',
      width: width,
      height: height,
      color: color,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => imagePlaceholder(isBanner: true),
      errorWidget: (_, __, ___) => imagePlaceholder(isBanner: true),
    );
  }

  /// Hero banner inside an item detail page — 512px tall, quality 60.
  static Widget networkItemBannerImage(
    String imageUrl, {
    double? width,
    BoxFit? fit,
    double? scale,
    Color? color,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: '${ensureHttp(imageUrl)}?h=512&q=60',
      width: width,
      height: height,
      color: color,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => imagePlaceholder(),
      errorWidget: (_, __, ___) => imagePlaceholder(),
    );
  }

  /// Generic network image. Pass `isSetSize: true` to opt into a
  /// 168x168 CDN-resized variant for grids/lists.
  static Widget networkImage(
    String imageUrl, {
    bool isSetSize = false,
    double? width,
    BoxFit? fit,
    double? scale,
    Color? color,
    double? height,
  }) {
    final url = isSetSize
        ? '${ensureHttp(imageUrl)}?h=168&w=168&q=60'
        : ensureHttp(imageUrl);
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      color: color,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => imagePlaceholder(),
      errorWidget: (_, __, ___) => imagePlaceholder(),
    );
  }

  /// Brand/vendor logo. Silent placeholder + error — a missing logo
  /// shouldn't leave a grey box in the middle of an otherwise clean row.
  static Widget networkImageLogo(
    String imageUrl, {
    double? width,
    BoxFit? fit,
    double? scale,
    Color? color,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: ensureHttp(imageUrl),
      width: width,
      height: height,
      color: color,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  /// Discount card on the discover screen — 168x168, quality 60.
  static Widget networkDiscoverDiscount(
    String imageUrl, {
    BoxFit? fit,
    double? width,
    double? height,
    Color? color,
  }) {
    return CachedNetworkImage(
      imageUrl: '${ensureHttp(imageUrl)}?h=168&w=168&q=60',
      fit: fit,
      width: width,
      height: height,
      color: color,
      placeholder: (_, __) => imagePlaceholder(),
      errorWidget: (_, __, ___) => imagePlaceholder(),
    );
  }

  /// Tiny category tile (120x120 @ q35) — small payloads for the
  /// horizontal scroll of food/product categories.
  static Widget networkFoodCategoryImage(
    String imageUrl, {
    double? width,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: '${ensureHttp(imageUrl)}?h=120&w=120&q=35',
      width: width,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, __) => imagePlaceholder(),
      errorWidget: (_, __, ___) => imagePlaceholder(),
    );
  }

  /// Full-bleed slider banner — no CDN resize, browser receives the
  /// original (use only for above-the-fold heroes).
  static Widget networkSliderBanner(
    String imageUrl, {
    double? width,
    BoxFit? fit,
    double? scale,
    Color? color,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: ensureHttp(imageUrl),
      width: width,
      height: height,
      color: color,
      fit: fit ?? BoxFit.cover,
      placeholder: (_, __) => imagePlaceholder(isBanner: true),
      errorWidget: (_, __, ___) => imagePlaceholder(isBanner: true),
    );
  }
}

/// Default placeholder painted under network images while they load and
/// when they fail. Uses a Material icon rather than an SVG asset so the
/// helper compiles + paints out-of-the-box without you needing to ship
/// a placeholder file alongside.
Widget imagePlaceholder({bool isBanner = false}) {
  return Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      color: AppColors.neutral200.withValues(alpha: 0.4),
    ),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: isBanner ? 70 : 32,
        color: AppColors.neutral400,
      ),
    ),
  );
}

class _DefaultProfileFallback extends StatelessWidget {
  const _DefaultProfileFallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.neutral100,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: width != null ? width! * 0.6 : 32,
        color: AppColors.neutral400,
      ),
    );
  }
}

/// Resolve [url] against the configured API base URL so relative paths
/// returned by the backend (e.g. `/uploads/abc.jpg`) become absolute.
///
/// Idempotent on already-absolute URLs.
String ensureHttp(String url) {
  if (url.trim().isEmpty) return url;
  final trimmed = url.trim();

  // Already absolute — pass through (after cleanup).
  if (trimmed.startsWith(RegExp(r'https?://'))) {
    return cleanUrl(trimmed);
  }

  // Strip the API path prefix when present — static assets are usually
  // served from the host root, not from `/api/v1/...`.
  final base = Environments.localApiBaseUrl
      .replaceAll(RegExp(r'/api/v\d+/?$'), '')
      .replaceAll(RegExp(r'/+$'), '');
  final path = trimmed.replaceAll(RegExp(r'^/+'), '');
  return cleanUrl('$base/$path');
}

/// Normalise duplicated protocols / slashes that can sneak in when
/// concatenating CMS-provided URLs.
String cleanUrl(String url) {
  if (url.isEmpty) return url;

  // Keep only the last `http(s)://` if multiple slipped in via bad concat.
  final protocolRegex = RegExp(r'https?://');
  final matches = protocolRegex.allMatches(url).toList();
  if (matches.length > 1) {
    url = url.substring(matches.last.start);
  }

  // Collapse `//` runs that aren't part of the `://` protocol marker.
  url = url.replaceAllMapped(RegExp(r'(?<!:)//+'), (_) => '/');
  return url;
}
