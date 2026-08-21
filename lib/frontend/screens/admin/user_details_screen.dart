part of 'admin_screens.dart';

class UserDetailsScreen extends StatelessWidget {
  const UserDetailsScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final user = state.selectedUserDetails;
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    final activity = (user['recent_activity'] as List? ?? const []);
    final bills = (user['recent_bills'] as List? ?? const []);
    final stock = (user['recent_stock_updates'] as List? ?? const []);
    final payments = (user['recent_payments'] as List? ?? const []);
    return _AdminPage(
      state: state,
      title: 'User Details',
      back: 2,
      bottom: false,
      child: user.isEmpty
          ? const _EmptyState(
              'User details are unavailable.',
              icon: Icons.person_off_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                SectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(name.isEmpty ? '?' : name[0]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? user['username'].toString() : name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${user['employee_id'] ?? '—'} • ${_statusText(user['role'])}',
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          user['is_active'] == true ? 'Active' : 'Inactive',
                        ),
                        backgroundColor:
                            (user['is_active'] == true ? green : red)
                                .withValues(alpha: .12),
                        labelStyle: TextStyle(
                          color: user['is_active'] == true ? green : red,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    children: [
                      _detail('Email', user['email']),
                      _detail('Mobile', user['phone']),
                      _detail('Branch', user['branch']),
                      _detail('Last login', user['last_login']),
                      _detail('Last logout', user['last_logout']),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _metric("Today's bills", user['today_bills']),
                    _metric('Total sales', _money(user['today_sales'])),
                    _metric('Cash', _money(user['cash_collection'])),
                    _metric('UPI', _money(user['upi_collection'])),
                    _metric('Card', _money(user['card_collection'])),
                    _metric('Stock updated', user['stock_updated_count']),
                  ],
                ),
                _history(
                  'Recent Bills',
                  bills,
                  (row) => '${row['number']} • ${_money(row['total'])}',
                ),
                _history(
                  'Recent Payments',
                  payments,
                  (row) =>
                      '${_statusText(row['method'])} • ${_money(row['amount'])}',
                ),
                _history(
                  'Recent Stock Updates',
                  stock,
                  (row) => '${row['item_name']} • ${row['quantity']}',
                ),
                _history(
                  'Activity History',
                  activity,
                  (row) => '${row['action']} • ${_dateText(row['created_at'])}',
                ),
              ],
            ),
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: muted)),
        ),
        Expanded(
          child: Text(
            value?.toString().isNotEmpty == true ? value.toString() : '—',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _metric(String label, dynamic value) => SectionCard(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value?.toString() ?? '0',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: muted)),
      ],
    ),
  );

  Widget _history(
    String title,
    List rows,
    String Function(Map<String, dynamic>) text,
  ) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text('No activity found.', style: TextStyle(color: muted))
        else
          SectionCard(
            child: Column(
              children: [
                for (final item in rows.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(text((item as Map).cast<String, dynamic>())),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
