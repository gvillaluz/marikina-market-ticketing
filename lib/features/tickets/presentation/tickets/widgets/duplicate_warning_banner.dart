import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';

class DuplicateWarningBanner extends StatelessWidget {
  final List<DuplicateOrdinance> duplicateOrdinances;

  const DuplicateWarningBanner({
    required this.duplicateOrdinances,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (duplicateOrdinances.isEmpty) return const SizedBox.shrink();

    final count = duplicateOrdinances.length;
    final titleText = '$count ${count == 1 ? 'ordinance was' : 'ordinances were'} already ticketed for this vendor and was excluded.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C08), // Dark amber/brown background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE65100).withValues(alpha: 0.3), // Amber border highlight
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF57C00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    color: Color(0xFFF57C00),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                ...duplicateOrdinances.map(
                  (ord) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ord.ordinanceNo,
                      style: const TextStyle(
                        color: Color(0xFFD7CCC8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}