part of '../admin_screens.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen(this.state, {super.key});
  final AdminState state;
  static const info = {
    'Rahul Kumar': ['admin@hypermart.com', 'Admin'],
    'Anita Sharma': ['anita@supermart.com', 'Cashier'],
    'Vikram Singh': ['vikram@supermart.com', 'Cashier'],
    'Neha Joshi': ['neha@supermart.com', 'Inventory Manager'],
    'Pooja Mehta': ['pooja@supermart.com', 'Cashier'],
  };
  static String userName(Map<String, dynamic> user) {
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    return fullName.isEmpty ? user['username'].toString() : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final staffInfo = state.users.isEmpty
        ? info
        : <String, List<String>>{
            for (final user in state.users)
              userName(user): [
                user['email']?.toString() ?? '',
                user['role']?.toString().replaceAll('_', ' ') ?? '',
              ],
          };
    final names = staffInfo.keys
        .where(
          (n) =>
              state.staffFilter == 'All' ||
              (state.staffFilter == 'Active') == state.staffActive[n]!,
        )
        .toList();
    return _AdminPage(
      state: state,
      title: 'Staff Management',
      back: 1,
      actions: [
        IconButton(
          onPressed: () => state.go(3),
          icon: const Icon(Icons.admin_panel_settings_outlined),
        ),
      ],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: SearchBox('Search users by name, role or email'),
          ),
          Row(
            children: ['All', 'Active', 'Inactive']
                .map(
                  (f) => Expanded(
                    child: InkWell(
                      onTap: () => state.setStaffFilter(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: state.staffFilter == f ? blue : line,
                              width: state.staffFilter == f ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '$f (${f == 'All'
                              ? 12
                              : f == 'Active'
                              ? 9
                              : 3})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: state.staffFilter == f ? blue : muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: names.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final name = names[i];
                final details = staffInfo[name]!;
                final active = state.staffActive[name] ?? true;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 3),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFDCEAFF),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    details[0],
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              details[1],
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 9, color: green),
                            ),
                            Text(
                              active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 9,
                                color: active ? green : red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: active,
                        onChanged: (v) => state.toggleStaff(name, v),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: PrimaryAction(
              'Add User',
              icon: Icons.add,
              onPressed: () => state.go(3),
            ),
          ),
        ],
      ),
    );
  }
}
