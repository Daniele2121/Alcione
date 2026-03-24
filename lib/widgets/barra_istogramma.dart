import 'package:flutter/material.dart';

class ValutazioneBar extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;

  const ValutazioneBar({
    super.key,
    required this.label,
    required this.value,
    this.min = -1,
    this.max = 3,
});
  Color get color {
    switch(value){
      case -1:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) {
    final double percent = (value - min) / (max - min);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ($value)"),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

}
