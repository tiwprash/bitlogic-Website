import 'package:flutter/material.dart';

class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });
}

class TutorialOverlayWidget extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;
  final ValueChanged<int>? onStepChanged;

  const TutorialOverlayWidget({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.onSkipped,
    this.onStepChanged,
  });

  @override
  State<TutorialOverlayWidget> createState() => _TutorialOverlayWidgetState();
}

class _TutorialOverlayWidgetState extends State<TutorialOverlayWidget> {
  int _currentStepIndex = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    // Allow the first frame to paint so we can measure layout positions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToStep(0);
    });
  }

  Future<void> _navigateToStep(int index) async {
    if (index < 0 || index >= widget.steps.length) return;

    if (widget.onStepChanged != null) {
      widget.onStepChanged!(index);
      // Give Flutter time to rebuild the widget tree for the tab change
      await Future.delayed(const Duration(milliseconds: 150));
    }

    setState(() {
      _currentStepIndex = index;
      _targetRect = null; // Hide hole cutout during scroll animation
    });

    final step = widget.steps[index];
    final targetContext = step.targetKey.currentContext;

    if (targetContext != null && targetContext.mounted) {
      try {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5, // Scroll to center the target widget
        );
      } catch (e) {
        debugPrint('Could not scroll to tutorial element: $e');
      }
    }

    // Wait for the scrolling animation to finish and layout to settle
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      _updateTargetRect();
    }
  }

  void _updateTargetRect() {
    final step = widget.steps[_currentStepIndex];
    final context = step.targetKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _targetRect = offset & renderBox.size;
        });
        return;
      }
    }
    setState(() {
      _targetRect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final step = widget.steps[_currentStepIndex];
    final screenHeight = MediaQuery.of(context).size.height;

    // Card placement logic:
    // Try to place the explanation card near the target, keeping a safe margin.
    double? cardTop;
    double? cardBottom;

    if (_targetRect != null) {
      final spaceAbove = _targetRect!.top;
      final spaceBelow = screenHeight - _targetRect!.bottom;

      if (spaceBelow >= 260.0) {
        // Place below the target
        cardTop = _targetRect!.bottom + 16.0;
      } else if (spaceAbove >= 260.0) {
        // Place above the target
        cardBottom = (screenHeight - _targetRect!.top) + 16.0;
      } else {
        // Fallback: place where there is more space
        if (spaceBelow > spaceAbove) {
          cardTop = _targetRect!.bottom + 12.0;
        } else {
          cardBottom = (screenHeight - _targetRect!.top) + 12.0;
        }
      }
    } else {
      // Centered fallback if context is not available
      cardTop = screenHeight / 2 - 120.0;
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // Solid Translucent Dark Overlay (Unblurred cutout)
          Positioned.fill(
            child: CustomPaint(
              painter: HolePainter(targetRect: _targetRect),
            ),
          ),

          // Floating Tutorial Card
          AnimatedPositionedDirectional(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            start: 20.0,
            end: 20.0,
            top: cardTop,
            bottom: cardBottom,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Premium dark gray slate
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30.0,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Step Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WELCOME TOUR',
                          style: TextStyle(
                            color: const Color(0xFF828DF8),
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Step ${_currentStepIndex + 1} of ${widget.steps.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    // Title
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    // Description
                    Text(
                      step.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Skip Tour
                        TextButton(
                          onPressed: widget.onSkipped,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.3),
                          ),
                          child: const Text(
                            'Skip Tour',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                          ),
                        ),

                        // Next / Got It Button
                        ElevatedButton(
                          onPressed: () {
                            if (_currentStepIndex < widget.steps.length - 1) {
                              _navigateToStep(_currentStepIndex + 1);
                            } else {
                              widget.onCompleted();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF828DF8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: Text(
                            _currentStepIndex == widget.steps.length - 1 ? 'Got it!' : 'Next Step',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HolePainter extends CustomPainter {
  final Rect? targetRect;
  final double borderRadius;

  HolePainter({this.targetRect, this.borderRadius = 16.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Premium translucent dark overlay matching the dark background
    final paint = Paint()..color = const Color(0xFF0B1120).withOpacity(0.82);

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    // Outer path is the full screen size
    final outerPath = Path()..addRect(Offset.zero & size);

    // Inner path is the target cutout rectangle inflated by 8px padding
    final paddedRect = targetRect!.inflate(8.0);
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(paddedRect, Radius.circular(borderRadius)));

    // Subtract the inner hole cutout path from the full screen overlay path
    final path = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(path, paint);

    // Draw premium glowing border stroke around the highlighted target
    final borderPaint = Paint()
      ..color = const Color(0xFF828DF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(paddedRect, Radius.circular(borderRadius)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.borderRadius != borderRadius;
  }
}
