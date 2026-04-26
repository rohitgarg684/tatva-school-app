import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

int _viewCounter = 0;

class WebIFrame extends StatefulWidget {
  final String src;
  final double? height;
  final String allow;
  final bool allowFullscreen;

  const WebIFrame({
    super.key,
    required this.src,
    this.height,
    this.allow = '',
    this.allowFullscreen = false,
  });

  @override
  State<WebIFrame> createState() => _WebIFrameState();
}

class _WebIFrameState extends State<WebIFrame> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-iframe-${_viewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = widget.src;
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.borderRadius = '12px';
      if (widget.allow.isNotEmpty) iframe.allow = widget.allow;
      if (widget.allowFullscreen) iframe.setAttribute('allowfullscreen', 'true');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}

class WebVideo extends StatefulWidget {
  final String src;
  final double? height;

  const WebVideo({super.key, required this.src, this.height});

  @override
  State<WebVideo> createState() => _WebVideoState();
}

class _WebVideoState extends State<WebVideo> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-video-${_viewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = web.document.createElement('video') as web.HTMLVideoElement;
      video.src = widget.src;
      video.controls = true;
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.borderRadius = '12px';
      video.style.backgroundColor = '#000';
      video.setAttribute('preload', 'metadata');
      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}

class WebAudio extends StatefulWidget {
  final String src;

  const WebAudio({super.key, required this.src});

  @override
  State<WebAudio> createState() => _WebAudioState();
}

class _WebAudioState extends State<WebAudio> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-audio-${_viewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final audio = web.document.createElement('audio') as web.HTMLAudioElement;
      audio.src = widget.src;
      audio.controls = true;
      audio.style.width = '100%';
      return audio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
