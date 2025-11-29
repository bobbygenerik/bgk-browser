import 'package:flutter/material.dart';

class UrlBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final double progress;
  final bool isSecure;
  final bool isIncognito;
  final Function(String) onSubmitted;
  final VoidCallback onRefresh;
  final VoidCallback onStop;

  const UrlBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.progress,
    required this.isSecure,
    required this.isIncognito,
    required this.onSubmitted,
    required this.onRefresh,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isIncognito 
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Security indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  isIncognito
                    ? Icons.visibility_off
                    : isSecure 
                      ? Icons.lock 
                      : Icons.lock_open,
                  size: 18,
                  color: isIncognito
                    ? theme.colorScheme.primary
                    : isSecure 
                      ? Colors.green 
                      : Colors.orange,
                ),
              ),
              
              // URL TextField
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    hintText: isIncognito 
                      ? 'Search incognito...'
                      : 'Search or enter URL',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: onSubmitted,
                  onTap: () {
                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    );
                  },
                ),
              ),
              
              // Refresh/Stop button
              IconButton(
                icon: Icon(isLoading ? Icons.close : Icons.refresh),
                iconSize: 20,
                onPressed: isLoading ? onStop : onRefresh,
              ),
            ],
          ),
          
          // Progress indicator
          if (isLoading && progress > 0 && progress < 1)
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
        ],
      ),
    );
  }
}
