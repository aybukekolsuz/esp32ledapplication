import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LedSwitchWidget extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const LedSwitchWidget({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<LedSwitchWidget> createState() => _LedSwitchWidgetState();
}

class _LedSwitchWidgetState extends State<LedSwitchWidget> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.6),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ]
                    : [],
              ),
            ),
            Icon(
              isOn ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 64,
              color: isOn ? Colors.yellow[700] : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Transform.scale(
          scale: 1.8,
          child: Switch(
            value: isOn,
            onChanged: (bool value) {
              setState(() {
                isOn = value;
              });
              HapticFeedback.mediumImpact(); // Haptic feedback
              widget.onChanged(value);
            },
            activeColor: Colors.yellow[700],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isOn ? Colors.yellow[700] : Colors.grey,
          ),
          child: Text(isOn ? "LED Açık" : "LED Kapalı"),
        ),
        const SizedBox(height: 4),
        Text(
          isOn ? "Işık yanıyor!" : "Işık kapalı.",
          style: TextStyle(
            color: isOn ? Colors.amber[800] : Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
