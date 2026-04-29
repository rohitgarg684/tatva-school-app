import 'package:flutter/widgets.dart';

class WebIFrame extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      SizedBox(height: height ?? 200, child: const Center(child: Text('Web only')));
}

class WebImage extends StatelessWidget {
  final String src;
  final double? height;
  final BoxFit fit;

  const WebImage({super.key, required this.src, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height ?? 200, child: const Center(child: Text('Web only')));
}

class WebVideo extends StatelessWidget {
  final String src;
  final double? height;

  const WebVideo({super.key, required this.src, this.height});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height ?? 200, child: const Center(child: Text('Web only')));
}

class WebAudio extends StatelessWidget {
  final String src;

  const WebAudio({super.key, required this.src});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 54, child: Center(child: Text('Web only')));
}
