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
  await showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final mobile = size.width < 600;
      return Dialog(
        insetPadding: mobile ? EdgeInsets.zero : const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mobile ? 0 : 20),
        ),
        child: SizedBox(
          width: mobile ? size.width : 560,
          height: mobile ? size.height : size.height.clamp(560, 760),
          child: _AddUserForm(state: state),
        ),
      );
    },
  );
}

class _AddUserForm extends StatefulWidget {
  const _AddUserForm({required this.state});
  final AdminState state;

  @override
  State<_AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<_AddUserForm> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final email = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final password = TextEditingController();
  String role = 'cashier';
  bool saving = false;
  bool obscure = true;

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    firstName.dispose();
    lastName.dispose();
    password.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Add User'),
      actions: [
        IconButton(
          tooltip: 'Close',
          onPressed: saving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const Text(
              'Staff information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create an account and assign the correct supermarket role.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: username,
              validator: _required,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: email,
              validator: (value) {
                final required = _required(value);
                if (required != null) return required;
                return value!.contains('@') ? null : 'Enter a valid email.';
              },
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstName,
                    validator: _required,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'First name *',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lastName,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: password,
              validator: (value) {
                final required = _required(value);
                if (required != null) return required;
                return value!.length >= 8 ? null : 'Use at least 8 characters.';
              },
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(
                labelText: 'Role *',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(
                  value: 'manager',
                  child: Text('Store Manager'),
                ),
                DropdownMenuItem(
                  value: 'inventory',
                  child: Text('Inventory Staff'),
                ),
                DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                DropdownMenuItem(value: 'sales', child: Text('Billing Staff')),
                DropdownMenuItem(
                  value: 'accountant',
                  child: Text('Accountant'),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() => role = value ?? role),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(saving ? 'Saving...' : 'Save User'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => saving = true);
    try {
      await widget.state.createUser({
        'username': username.text.trim(),
        'email': email.text.trim(),
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'password': password.text,
        'role': role,
        'is_active': true,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showNotice(context, error.toString());
      setState(() => saving = false);
    }
  }
}
