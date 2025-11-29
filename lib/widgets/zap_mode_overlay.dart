import 'package:flutter/material.dart';

class ZapModeOverlay extends StatelessWidget {
  final Function(Offset) onTap;
  final VoidCallback onCancel;

  const ZapModeOverlay({
    super.key,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (details) => onTap(details.localPosition),
            child: Container(
              color: Colors.amber.withOpacity(0.1),
            ),
          ),
        ),
        
        // Instructions banner at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ZAP MODE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Tap any element to hide it permanently',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Crosshair cursor indicator
        IgnorePointer(
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
