import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class BottomUrlBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final double progress;
  final bool isSecure;
  final bool isIncognito;
  final bool kidModeActive;
  final int tabCount;
  final bool canGoBack;
  final bool canGoForward;
  final Function(String) onSubmitted;
  final VoidCallback onRefresh;
  final VoidCallback onStop;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onTabsPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onLongPress;
  final VoidCallback onReachabilityTap;

  const BottomUrlBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.progress,
    required this.isSecure,
    required this.isIncognito,
    required this.kidModeActive,
    required this.tabCount,
    required this.canGoBack,
    required this.canGoForward,
    required this.onSubmitted,
    required this.onRefresh,
    required this.onStop,
    required this.onBack,
    required this.onForward,
    required this.onTabsPressed,
    required this.onMenuPressed,
    required this.onLongPress,
    required this.onReachabilityTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final isDark = settings.isDarkMode;
    final bgColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              if (isLoading)
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                ),
              
              // URL bar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    _NavButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: canGoBack ? onBack : null,
                      isDark: isDark,
                    ),
                    
                    // Forward button
                    _NavButton(
                      icon: Icons.arrow_forward_ios,
                      onPressed: canGoForward ? onForward : null,
                      isDark: isDark,
                    ),
                    
                    // URL field
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            // Security indicator
                            Icon(
                              kidModeActive
                                  ? Icons.child_care
                                  : isIncognito
                                      ? Icons.visibility_off
                                      : isSecure
                                          ? Icons.lock
                                          : Icons.lock_open,
                              size: 16,
                              color: kidModeActive
                                  ? Colors.green
                                  : isSecure
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            // URL input
                            Expanded(
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: kidModeActive
                                      ? 'Kid Mode Active'
                                      : 'Search or enter URL',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.go,
                                onSubmitted: onSubmitted,
                              ),
                            ),
                            // Reload/Stop button
                            IconButton(
                              icon: Icon(
                                isLoading ? Icons.close : Icons.refresh,
                                size: 18,
                              ),
                              onPressed: isLoading ? onStop : onRefresh,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Tab counter
                    _TabButton(
                      count: tabCount,
                      onPressed: onTabsPressed,
                      isDark: isDark,
                    ),
                    
                    // Menu button
                    _NavButton(
                      icon: Icons.more_vert,
                      onPressed: onMenuPressed,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              // Reachability hint bar
              InkWell(
                onTap: onReachabilityTap,
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;

  const _NavButton({
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 20,
      color: onPressed != null
          ? (isDark ? Colors.white : Colors.black87)
          : Colors.grey,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  final bool isDark;

  const _TabButton({
    required this.count,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white : Colors.black87,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            count > 99 ? ':D' : count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
