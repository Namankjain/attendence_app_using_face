import 'package:flutter/material.dart';

class GradientElevatedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const GradientElevatedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  State<GradientElevatedButton> createState() => _GradientElevatedButtonState();
}

class _GradientElevatedButtonState extends State<GradientElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t, -1),
                end: Alignment(1 - 2 * t, 1),
                colors: const [Color(0xFF7B61FF), Color(0xFF00D1B2)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}
