part of '../admin_screens.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen(this.state, {super.key});
  final AdminState state;
  static const logs = [
    ['Rahul Kumar', 'Login', 'Auth', '14 May, 10:03 AM', '192.168.1.10'],
    [
      'Rahul Kumar',
      'Approved PO',
      'Purchase',
      '14 May, 10:24 AM',
      '192.168.1.10',
    ],
    [
      'Anita Sharma',
      'Discount Approved',
      'Discounts',
      '14 May, 10:15 AM',
      '192.168.1.12',
    ],
    [
      'Vikram Singh',
      'Stock Adjusted',
      'Inventory',
      '14 May, 10:10 AM',
      '192.168.1.11',
    ],
    [
      'Neha Joshi',
      'Added Product',
      'Products',
      '14 May, 10:02 AM',
      '192.168.1.10',
    ],
    ['Rahul Kumar', 'Logout', 'Auth', '14 May, 10:00 AM', '192.168.1.10'],
  ];
  List<List<String>> get displayLogs => state.auditLogs.isEmpty
      ? logs
      : state.auditLogs
            .map(
              (log) => <String>[
                (log['user_name']?.toString().trim().isNotEmpty ?? false)
                    ? log['user_name'].toString()
                    : 'System',
                log['action']?.toString() ?? '',
                log['module']?.toString() ?? '',
                log['created_at']
                        ?.toString()
                        .replaceFirst('T', ' ')
                        .split('.')
                        .first ??
                    '',
                log['ip_address']?.toString() ?? '',
              ],
            )
            .toList();
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Audit Log',
    back: 14,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 590,
              child: Column(
                children: [
                  Container(
                    color: page,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 95,
                          child: Text('User', style: _tableStyle),
                        ),
                        SizedBox(
                          width: 105,
                          child: Text('Action', style: _tableStyle),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text('Module', style: _tableStyle),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text('Date & Time', style: _tableStyle),
                        ),
                        Expanded(
                          child: Text('IP / Device', style: _tableStyle),
                        ),
                      ],
                    ),
                  ),
                  ...displayLogs.map(
                    (x) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: line)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 95,
                            child: Text(
                              x[0],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          SizedBox(
                            width: 105,
                            child: Text(
                              x[1],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              x[2],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text(
                              x[3],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              x[4],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              PrimaryAction(
                'Logout',
                color: red,
                onPressed: state.showLogoutConfirmation,
              ),
              if (state.logoutConfirmationVisible) ...[
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Confirm Logout',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: state.hideLogoutConfirmation,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                      const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryAction(
                              'Cancel',
                              outlined: true,
                              color: muted,
                              onPressed: state.hideLogoutConfirmation,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryAction(
                              'Logout',
                              color: red,
                              onPressed: state.logout,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

const _tableStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w800);
