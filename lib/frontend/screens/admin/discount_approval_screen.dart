part of 'admin_screens.dart';

class DiscountApprovalScreen extends StatelessWidget {
  const DiscountApprovalScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.discountApprovals
        .where((approval) => approval['status'] == 'pending')
        .toList();
    final approval = pending.isEmpty ? null : pending.first;
    final cashierLimit = state.storeSettings['max_cashier_discount'];

    return _AdminPage(
      state: state,
      title:
          'Discount Approval${pending.isEmpty ? '' : ' (${pending.length})'}',
      back: 1,
      bottom: false,
      child: approval == null
          ? const _EmptyState(
              'No pending discount approvals.',
              icon: Icons.discount_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      LabeledValue(
                        'Quotation',
                        approval['quotation_number']?.toString() ?? '',
                      ),
                      LabeledValue(
                        'Cashier',
                        approval['requested_by_name']?.toString() ?? '',
                      ),
                      LabeledValue(
                        'Customer',
                        approval['customer_name']?.toString() ?? '',
                      ),
                      LabeledValue(
                        'Bill Amount',
                        _money(approval['bill_amount']),
                      ),
                      LabeledValue(
                        'Requested Discount',
                        _percent(approval['requested_percent'], 0),
                      ),
                      LabeledValue(
                        'Discount Amount',
                        _money(approval['discount_amount']),
                      ),
                      LabeledValue(
                        'Reason',
                        approval['request_note']?.toString() ?? '',
                      ),
                      const SizedBox(height: 22),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Policy',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Cashier Limit: ${_percent(cashierLimit, 0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Requests above the configured limit require admin approval.',
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
                          state.decidingDiscount ? 'Processing…' : 'Approve',
                          color: green,
                          onPressed: state.decidingDiscount
                              ? null
                              : () => _decideDiscount(context, state, true),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: PrimaryAction(
                          'Reject',
                          color: red,
                          onPressed: state.decidingDiscount
                              ? null
                              : () => _decideDiscount(context, state, false),
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

Future<void> _decideDiscount(
  BuildContext context,
  AdminState state,
  bool approved,
) async {
  try {
    await state.decideDiscount(approved);
    if (context.mounted) {
      showNotice(context, approved ? 'Discount approved' : 'Discount rejected');
    }
  } catch (error) {
    if (context.mounted) showNotice(context, error.toString());
  }
}
