import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/app_helpers.dart';

// ── WELCOME CARD ──────────────────────────────────────────────
class DashboardWelcomeCard extends StatelessWidget {
  final String firstName;
  final String storeName;

  const DashboardWelcomeCard({
    super.key,
    required this.firstName,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kRed, kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Decorative divider row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            '~WELCOME~',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Hello, $firstName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            storeName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── OVERVIEW CARD ─────────────────────────────────────────────
class DashboardOverviewCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? valueColor;

  const DashboardOverviewCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kRed, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? kDark,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 10, color: kGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── QUICK ACTION BUTTON ───────────────────────────────────────
class DashboardActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const DashboardActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kRed;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: kDark,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── EXPIRY ALERT ROW ──────────────────────────────────────────
class DashboardExpiryRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const DashboardExpiryRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productName = item['productName'] as String;
    final variantName = item['variantName'] as String;
    final expiry = item['expiry'] as String;
    final status = item['status'] as String;
    final days = AppHelpers.daysLeft(expiry);
    final sColor = AppHelpers.statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: sColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$variantName  ·  '
                    '${AppHelpers.formatDate(expiry)}',
                    style: const TextStyle(fontSize: 11, color: kGrey),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Days badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status == 'expired' ? 'EXPIRED' : '${days}d',
                style: TextStyle(
                  color: sColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── LOW STOCK ROW ─────────────────────────────────────────────
class DashboardLowStockRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const DashboardLowStockRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productName = item['productName'] as String;
    final variantName = item['variantName'] as String;
    final stock = item['stock'] as int;
    final color = AppHelpers.stockColor(stock);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kDark,
                    ),
                  ),
                  Text(
                    variantName,
                    style: const TextStyle(fontSize: 11, color: kGrey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stock == 0 ? 'No Stock' : '$stock pcs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ACTIVITY ROW ──────────────────────────────────────────────
class DashboardActivityRow extends StatelessWidget {
  final Map<String, dynamic> log;

  const DashboardActivityRow({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final action = (log['action'] as String? ?? '').replaceAll('_', ' ');
    final empName = log['employeeName'] as String? ?? '';
    final targetName = log['targetName'] as String? ?? '';
    final timestamp = log['timestamp'] as String? ?? '';

    Color dotColor = kGrey;
    if (action.contains('add')) dotColor = kGreen;
    if (action.contains('delete')) dotColor = kRed;
    if (action.contains('sale')) dotColor = kOrange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: kDark),
                    children: [
                      TextSpan(
                        text: empName.isNotEmpty ? empName : 'System',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: action,
                        style: TextStyle(color: dotColor),
                      ),
                      if (targetName.isNotEmpty) ...[
                        const TextSpan(
                          text: '  →  ',
                          style: TextStyle(color: kGrey),
                        ),
                        TextSpan(
                          text: targetName,
                          style: const TextStyle(color: kGrey),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  AppHelpers.formatDateTime(
                    DateTime.tryParse(timestamp) ?? DateTime.now(),
                  ),
                  style: const TextStyle(color: kGrey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
