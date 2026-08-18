part of '../admin_screens.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: '14 May 2025 - 14 May 2025',
    back: 1,
    bottom: false,
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.calendar_month_outlined),
      ),
    ],
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
          children: const [
            _Metric('Total Sales', 'â‚¹ 45,320', 'â†‘ 8.5%', green),
            _Metric('Bills', '256', 'â†‘ 6.3%', green),
            _Metric('Avg. Bill Value', 'â‚¹ 177.03', '', muted),
            _Metric('Profit', 'â‚¹ 12,850', 'â†‘ 7.2%', green),
            _Metric('Returns', 'â‚¹ 1,250', 'â†“ 2.1%', red),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Sales Trend (Last 7 Days)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const SectionCard(
          child: SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _SalesChartPainter(),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '08 May       10 May       12 May       14 May',
                    style: TextStyle(fontSize: 8, color: muted),
                  ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const Row(
            children: [
              Expanded(
                flex: 40,
                child: ColoredBox(color: blue, child: SizedBox(height: 18)),
              ),
              Expanded(
                flex: 35,
                child: ColoredBox(color: green, child: SizedBox(height: 18)),
              ),
              Expanded(
                flex: 15,
                child: ColoredBox(
                  color: Color(0xFF8B5CC7),
                  child: SizedBox(height: 18),
                ),
              ),
              Expanded(
                flex: 10,
                child: ColoredBox(
                  color: Colors.orange,
                  child: SizedBox(height: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Cash\n40%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'UPI\n35%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'Card\n15%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'Other\n10%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final pts = [
      const Offset(.02, .76),
      const Offset(.15, .42),
      const Offset(.28, .28),
      const Offset(.41, .48),
      const Offset(.54, .31),
      const Offset(.67, .52),
      const Offset(.80, .39),
      const Offset(.88, .17),
      const Offset(.98, .25),
    ];
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = blue
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (final point in pts) {
      final p = Offset(point.dx * size.width, point.dy * size.height);
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
