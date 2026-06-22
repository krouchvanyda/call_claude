import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../entities/chat_message.dart';

/// Slice 10.1.5 — Full-screen image viewer.
///
/// Opened when the user taps an image bubble in [ChatBubble] or an
/// image tile in [ChatInfoPage] Shared Media. Black background,
/// [InteractiveViewer] for pinch-to-zoom, swipe-down (or back) to
/// dismiss. Caption row at the bottom shows filename + sender +
/// timestamp; a top-right overflow menu can run share / save (stubbed
/// — see [_onShare] / [_onSave]).
///
/// **Source handling** — `fileUrl` may be:
///   * `http(s)://…` → [Image.network]
///   * a local file path returned by `image_picker` → [Image.file]
///     (after a `File.exists()` check)
///   * the seed-data stub `demo://…` → a friendly "Preview not
///     available" placeholder, since no actual bytes exist
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  bool _chromeVisible = true;
  // Drag-to-dismiss vertical offset. Resets if the drag is too small.
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    // Edge-to-edge dark experience while the viewer is up. Restored
    // on dispose so the rest of the app keeps its default chrome.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragOffset += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_dragOffset.abs() > 120) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dismissProgress =
        (_dragOffset.abs() / 300).clamp(0.0, 1.0).toDouble();
    final bgOpacity = 1.0 - dismissProgress * 0.7;
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleChrome,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            behavior: HitTestBehavior.opaque,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  clipBehavior: Clip.none,
                  child: _ImageSurface(message: widget.message),
                ),
              ),
            ),
          ),
          // Top chrome — close + overflow.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _chromeVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _CircleIcon(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      _CircleIcon(
                        icon: Icons.ios_share_rounded,
                        onTap: () => _onShare(context),
                      ),
                      const SizedBox(width: 8),
                      _CircleIcon(
                        icon: Icons.download_rounded,
                        onTap: () => _onSave(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom caption.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _chromeVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _Caption(message: widget.message),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share would open the OS share sheet here.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSave(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save to gallery would run here.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ImageSurface extends StatelessWidget {
  const _ImageSurface({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final url = message.fileUrl ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _Placeholder(
          message: 'Could not load image',
        ),
      );
    }
    if (url.startsWith('demo://')) {
      return _Placeholder(
        message: message.fileName ?? 'Demo asset',
        subtitle: 'No bytes available — this is a seeded message.',
      );
    }
    // Treat anything else as a local file path.
    final file = File(url);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snap.data == true) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _Placeholder(
              message: 'Could not decode image',
            ),
          );
        }
        return _Placeholder(
          message: message.fileName ?? 'Image not found',
          subtitle: 'The file may have been moved or removed.',
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.message, this.subtitle});
  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 56,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          AppLabel(
            text: message,
            fontSize: AppFontSize.value14,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            AppLabel(
              text: subtitle!,
              fontSize: AppFontSize.value12,
              color: Colors.white.withValues(alpha: 0.7),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.circle, color: Colors.transparent),
        ),
      ),
    ).iconShim(icon);
  }
}

extension on Widget {
  // Tiny helper: paint the icon over the circle without dropping the
  // Material splash. Avoids nesting another Stack just for that.
  Widget iconShim(IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        this,
        IgnorePointer(
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLabel(
            text: message.fileName ?? 'Photo',
            fontSize: AppFontSize.value15,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          AppLabel(
            text: 'Sent by ${message.senderName} · ${_formatStamp(message.sentAt)}',
            fontSize: AppFontSize.value12,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static String _formatStamp(DateTime when) {
    final h = when.hour.toString().padLeft(2, '0');
    final m = when.minute.toString().padLeft(2, '0');
    return '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} $h:$m';
  }
}
