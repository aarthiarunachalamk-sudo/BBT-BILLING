part of 'admin_screens.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen(this.state, {super.key});
  final AdminState state;

  static String userName(Map<String, dynamic> user) {
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    return fullName.isEmpty ? user['username']?.toString() ?? '' : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = state.users.where((user) {
      final active = user['is_active'] == true;
      final matchesStatus =
          state.staffFilter == 'All' ||
          (state.staffFilter == 'Active' ? active : !active);
      final searchable = [
        userName(user),
        user['email'],
        user['username'],
        user['role'],
      ].join(' ').toLowerCase();
      return matchesStatus && searchable.contains(state.staffQuery);
    }).toList();
    final activeCount = state.users
        .where((user) => user['is_active'] == true)
        .length;
    final inactiveCount = state.users.length - activeCount;
    final counts = {
      'All': state.users.length,
      'Active': activeCount,
      'Inactive': inactiveCount,
    };

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
          Padding(
            padding: const EdgeInsets.all(14),
            child: SearchBox(
              'Search users by name, role or email',
              onChanged: state.setStaffQuery,
            ),
          ),
          Row(
            children: counts.entries
                .map(
                  (entry) => Expanded(
                    child: InkWell(
                      onTap: () => state.setStaffFilter(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: state.staffFilter == entry.key
                                  ? blue
                                  : line,
                              width: state.staffFilter == entry.key ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '${entry.key} (${entry.value})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: state.staffFilter == entry.key
                                ? blue
                                : muted,
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
            child: filtered.isEmpty
                ? const _EmptyState(
                    'No staff members found.',
                    icon: Icons.people_outline,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final name = userName(user);
                      final active = user['is_active'] == true;
                      return ListTile(
                        onTap: state.loading
                            ? null
                            : () => state.openUserDetails(user['id'] as int),
                        contentPadding: const EdgeInsets.symmetric(vertical: 3),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDCEAFF),
                          child: Text(
                            name.isEmpty ? '?' : name[0],
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
                          user['email']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 72,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _statusText(user['role']),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: green,
                                    ),
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
                              onChanged: (value) =>
                                  state.toggleStaff(name, value),
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
              onPressed: () => _showAddUserDialog(context, state),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddUserDialog(BuildContext context, AdminState state) async {
  final username = TextEditingController();
  final email = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final password = TextEditingController();
  var role = 'sales';
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: firstName,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastName,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'sales', child: Text('Sales')),
                  DropdownMenuItem(
                    value: 'accountant',
                    child: Text('Accountant'),
                  ),
                  DropdownMenuItem(
                    value: 'inventory',
                    child: Text('Inventory'),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) =>
                    setDialogState(() => role = value ?? role),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await state.createUser({
                  'username': username.text.trim(),
                  'email': email.text.trim(),
                  'first_name': firstName.text.trim(),
                  'last_name': lastName.text.trim(),
                  'password': password.text,
                  'role': role,
                  'is_active': true,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  username.dispose();
  email.dispose();
  firstName.dispose();
  lastName.dispose();
  password.dispose();
}
