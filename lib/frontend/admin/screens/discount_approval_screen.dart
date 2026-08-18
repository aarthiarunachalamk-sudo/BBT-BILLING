part of '../admin_screens.dart';

class DiscountApprovalScreen extends StatelessWidget {
  const DiscountApprovalScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Discount Approval',
    back: 1,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              LabeledValue('Bill Number', 'BILL-2025-0145'),
              LabeledValue('Cashier', 'Anita Sharma'),
              LabeledValue('Customer', 'Walk-in Customer'),
              LabeledValue('Bill Amount', 'â‚¹ 3,650.00'),
              LabeledValue('Requested Discount', '18%'),
              LabeledValue('Discount Amount', 'â‚¹ 657.00'),
              LabeledValue('Reason', 'Festival offer for regular customer'),
              SizedBox(height: 22),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Policy',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Cashier Limit: 10%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Discount above 10% require admin approval.',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Approve',
                  color: green,
                  onPressed: () async {
                    await state.decideDiscount(true);
                    if (context.mounted) {
                      showNotice(context, 'Discount approved');
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: PrimaryAction(
                  'Reject',
                  color: red,
                  onPressed: () async {
                    await state.decideDiscount(false);
                    if (context.mounted) {
                      showNotice(context, 'Discount rejected');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
