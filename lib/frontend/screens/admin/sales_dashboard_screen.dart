part of 'admin_screens.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    final trend = (dashboard['sales_trend'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final values = trend
        .map((row) => double.tryParse(row['total']?.toString() ?? '') ?? 0)
        .toList();
    final payments = (dashboard['payment_breakdown'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final paymentTotal = payments.fold<double>(
      0,
      (sum, row) =>
          sum + (double.tryParse(row['total']?.toString() ?? '') ?? 0),
    );
    final rangeStart = _dateText(dashboard['range_start']);
    final rangeEnd = _dateText(dashboard['range_end']);

    return _AdminPage(
      state: state,
      title: '$rangeStart - $rangeEnd',
      back: 1,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.25,
            children: [
              _Metric(
                'Total Sales',
                _money(dashboard['today_sales']),
                _growth(dashboard['sales_growth']),
                green,
              ),
              _Metric(
                'Bills',
                '${dashboard['total_bills'] ?? 0}',
                _growth(dashboard['bills_growth']),
                green,
              ),
              _Metric(
                'Avg. Bill Value',
                _money(dashboard['average_bill_value']),
                '',
                muted,
              ),
              _Metric('Profit', _money(dashboard['profit']), '', green),
              _Metric('Returns', _money(dashboard['returns_total']), '', red),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Sales Trend (Last 7 Days)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: SizedBox(
              height: 170,
              child: values.isEmpty
                  ? const _EmptyState('No sales data available.')
                  : CustomPaint(
                      painter: _SalesChartPainter(values),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          trend
                              .map((row) => _dateText(row['date']))
                              .join('   '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 8, color: muted),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Payment Method Breakup',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (payments.isEmpty)
            const _EmptyState('No verified payment data.')
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: payments.map((row) {
                  final total =
                      double.tryParse(row['total']?.toString() ?? '') ?? 0;
                  final flex = paymentTotal == 0
                      ? 1
                      : ((total / paymentTotal) * 1000).round().clamp(1, 1000);
                  return Expanded(
                    flex: flex,
                    child: ColoredBox(
                      color: _paymentColor(row['method']?.toString()),
                      child: const SizedBox(height: 18),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: payments.map((row) {
                final total =
                    double.tryParse(row['total']?.toString() ?? '') ?? 0;
                final percent = paymentTotal == 0
                    ? 0
                    : total * 100 / paymentTotal;
                return Text(
                  '${_statusText(row['method'])}\n${percent.toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

String _growth(dynamic value) {
  final number = double.tryParse(value?.toString() ?? '') ?? 0;
  final arrow = number < 0 ? '↓' : '↑';
  return '$arrow ${number.abs().toStringAsFixed(1)}%';
}

Color _paymentColor(String? method) => switch (method) {
  'cash' => blue,
  'upi' => green,
  'card' => const Color(0xFF8B5CC7),
  _ => Colors.orange,
};

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : index * size.width / (values.length - 1);
      final y = maximum <= 0
          ? size.height * .8
          : size.height * (.9 - values[index] / maximum * .75);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = blue);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = blue
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
