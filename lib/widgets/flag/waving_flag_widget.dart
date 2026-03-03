import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WavingFlagWidget extends StatefulWidget {
  final Widget child;
  const WavingFlagWidget({required this.child, super.key});

  @override
  State<WavingFlagWidget> createState() => _WavingFlagWidgetState();
}

class _WavingFlagWidgetState extends State<WavingFlagWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C0A08))
      ..loadFlutterAsset('assets/flag/flag.html');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 3D flag layer (bottom)
        WebViewWidget(controller: _controller),
        
        // Gradient overlay — keeps content readable
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x550C0A08), // 33% dark at top
                Color(0x880C0A08), // 53% dark middle  
                Color(0xDD0C0A08), // 87% dark bottom
              ],
            ),
          ),
        ),
        
        // Dashboard content (top)
        widget.child,
      ],
    );
  }
}
