import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

enum GestureDialAction {
  none,
  back,
  forward,
  newTab,
  closeTab,
  refresh,
}

class GestureDial extends StatefulWidget {
  final Function(GestureDialAction) onAction;
  final VoidCallback onDismiss;

  const GestureDial({
    super.key,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  State<GestureDial> createState() => _GestureDialState();
}

class _GestureDialState extends State<GestureDial> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  Offset? _startPosition;
  GestureDialAction _currentAction = GestureDialAction.none;
  
  static const double _dialRadius = 120;
  static const double _deadZone = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_startPosition == null) return;
    
    final delta = details.globalPosition - _startPosition!;
    final distance = delta.distance;
    
    if (distance < _deadZone) {
      _updateAction(GestureDialAction.none);
      return;
    }
    
    final angle = math.atan2(delta.dy, delta.dx);
    final degrees = angle * 180 / math.pi;
    
    GestureDialAction action;
    if (degrees >= -45 && degrees < 45) {
      action = GestureDialAction.forward;
    } else if (degrees >= 45 && degrees < 135) {
      action = GestureDialAction.closeTab;
    } else if (degrees >= 135 || degrees < -135) {
      action = GestureDialAction.back;
    } else {
      action = GestureDialAction.newTab;
    }
    
    _updateAction(action);
  }

  void _updateAction(GestureDialAction action) {
    if (action != _currentAction) {
      setState(() => _currentAction = action);
      if (action != GestureDialAction.none) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentAction != GestureDialAction.none) {
      HapticFeedback.heavyImpact();
      widget.onAction(_currentAction);
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black54,
        child: Stack(
          children: [
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: _dialRadius * 2,
                    height: _dialRadius * 2,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        _buildDialOption(
                          icon: Icons.arrow_back,
                          label: 'Back',
                          angle: math.pi,
                          isActive: _currentAction == GestureDialAction.back,
                        ),
                        _buildDialOption(
                          icon: Icons.arrow_forward,
                          label: 'Forward',
                          angle: 0,
                          isActive: _currentAction == GestureDialAction.forward,
                        ),
                        _buildDialOption(
                          icon: Icons.add,
                          label: 'New Tab',
                          angle: -math.pi / 2,
                          isActive: _currentAction == GestureDialAction.newTab,
                        ),
                        _buildDialOption(
                          icon: Icons.close,
                          label: 'Close',
                          angle: math.pi / 2,
                          isActive: _currentAction == GestureDialAction.closeTab,
                        ),
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _currentAction == GestureDialAction.none
                                  ? Colors.grey[300]
                                  : Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentAction == GestureDialAction.none
                                  ? Icons.touch_app
                                  : _getActionIcon(_currentAction),
                              color: _currentAction == GestureDialAction.none
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                _currentAction == GestureDialAction.none
                    ? 'Slide in any direction'
                    : _getActionLabel(_currentAction),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialOption({
    required IconData icon,
    required String label,
    required double angle,
    required bool isActive,
  }) {
    final offset = Offset(
      math.cos(angle) * 70,
      math.sin(angle) * 70,
    );
    
    return Positioned(
      left: _dialRadius + offset.dx - 25,
      top: _dialRadius + offset.dy - 25,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  IconData _getActionIcon(GestureDialAction action) {
    switch (action) {
      case GestureDialAction.back:
        return Icons.arrow_back;
      case GestureDialAction.forward:
        return Icons.arrow_forward;
      case GestureDialAction.newTab:
        return Icons.add;
      case GestureDialAction.closeTab:
        return Icons.close;
      case GestureDialAction.refresh:
        return Icons.refresh;
      case GestureDialAction.none:
        return Icons.touch_app;
    }
  }

  String _getActionLabel(GestureDialAction action) {
    switch (action) {
      case GestureDialAction.back:
        return 'Go Back';
      case GestureDialAction.forward:
        return 'Go Forward';
      case GestureDialAction.newTab:
        return 'New Tab';
      case GestureDialAction.closeTab:
        return 'Close Tab';
      case GestureDialAction.refresh:
        return 'Refresh';
      case GestureDialAction.none:
        return 'Slide to select';
    }
  }
}
