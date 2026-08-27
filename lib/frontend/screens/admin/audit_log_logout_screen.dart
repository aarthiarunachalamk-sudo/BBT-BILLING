part of 'admin_screens.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Audit Log',
    back: 14,
    child: Column(
      children: [
        Expanded(
          child: state.auditLogs.isEmpty
              ? const _EmptyState(
                  'No audit records found.',
                  icon: Icons.security_outlined,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 18,
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Module')),
                      DataColumn(label: Text('Date & Time')),
                      DataColumn(label: Text('IP / Device')),
                    ],
                    rows: state.auditLogs
                        .map(
                          (log) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  (log['user_name']
                                              ?.toString()
                                              .trim()
                                              .isNotEmpty ??
                                          false)
                                      ? log['user_name'].toString()
                                      : 'System',
                                ),
                              ),
                              DataCell(Text(log['action']?.toString() ?? '')),
                              DataCell(Text(log['module']?.toString() ?? '')),
                              DataCell(Text(_dateText(log['created_at']))),
                              DataCell(
                                Text(log['ip_address']?.toString() ?? ''),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: PrimaryAction(
            'Logout',
            color: red,
            onPressed: () => _showAdminLogoutDialog(context, state),
          ),
        ),
      ],
    ),
  );
}
