import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineStep {
  final String title;
  final String? subtitle;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final IconData? icon;

  TimelineStep({
    required this.title,
    this.subtitle,
    this.timestamp,
    required this.isCompleted,
    this.isCurrent = false,
    this.icon,
  });
}

class StatusTimeline extends StatelessWidget {
  final List<TimelineStep> steps;

  const StatusTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted || step.isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                  child: Icon(
                    step.icon ?? 
                    (step.isCompleted ? Icons.check : Icons.circle),
                    color: step.isCompleted || step.isCurrent
                        ? Colors.white
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: step.isCompleted
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: step.isCompleted || step.isCurrent
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (step.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (step.timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy - hh:mm a').format(step.timestamp!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
