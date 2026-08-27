part of 'admin_screens.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.permissions.values
        .where((value) => value)
        .length;
    return _AdminPage(
      state: state,
      title: 'Roles & Permissions',
      back: 2,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5137C8), Color(0xFF7C5CE5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0x33FFFFFF),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access control',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Choose a role, review access and save.',
                              style: TextStyle(
                                color: Color(0xFFE9E4FF),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Role',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  key: ValueKey(state.selectedRole),
                  initialValue:
                      state.availableRoles.contains(state.selectedRole)
                      ? state.selectedRole
                      : state.availableRoles.first,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'Select a role',
                  ),
                  items: state.availableRoles
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
                  onChanged: (role) => _changeRole(context, role),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Permissions  $selectedCount/${state.permissions.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: state.applyPermissionPreset,
                      icon: const Icon(Icons.auto_awesome_outlined, size: 17),
                      label: const Text('Suggested'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('Select all'),
                      onPressed: () => state.setAllPermissions(true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.remove_done_rounded, size: 16),
                      label: const Text('Clear all'),
                      onPressed: () => state.setAllPermissions(false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...state.permissions.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      child: CheckboxListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Color(0xFFE1E7F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        secondary: CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xFFF0EDFF),
                          child: Icon(
                            _permissionIcon(entry.key),
                            size: 19,
                            color: const Color(0xFF6547D5),
                          ),
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          _permissionDescription(entry.key),
                          style: const TextStyle(fontSize: 9.5, color: muted),
                        ),
                        value: entry.value,
                        onChanged: (value) =>
                            state.togglePermission(entry.key, value ?? false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: PrimaryAction(
              state.savingPermissions
                  ? 'Saving permissions...'
                  : state.permissionsDirty
                  ? 'Save Permissions'
                  : 'Permissions up to date',
              onPressed: !state.permissionsDirty || state.savingPermissions
                  ? null
                  : () => _save(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, String? role) async {
    if (role == null || role == state.selectedRole) return;
    if (state.permissionsDirty) {
      final discard =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Discard permission changes?'),
              content: const Text(
                'You have unsaved checkbox changes for this role.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Keep editing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ) ??
          false;
      if (!discard) return;
    }
    state.setRole(role);
  }

  Future<void> _save(BuildContext context) async {
    try {
      await state.savePermissions();
      if (context.mounted) {
        showNotice(context, '${state.selectedRole} permissions saved');
      }
    } catch (_) {
      if (context.mounted) {
        showNotice(
          context,
          'Could not save permissions. Check the connection and retry.',
        );
      }
    }
  }
}

String _permissionDescription(String value) => switch (value) {
  'Dashboard' => 'View store summary and business activity',
  'Products' => 'Create, edit and manage the product catalogue',
  'Billing' => 'Create bills, collect payment and view invoices',
  'Inventory' => 'View stock levels and inventory alerts',
  'Discounts' => 'Review and approve discount requests',
  'Reports' => 'View, filter and download business reports',
  'Returns' => 'Process returns and refunds',
  _ => 'Manage store configuration and access',
};

IconData _permissionIcon(String value) => switch (value) {
  'Dashboard' => Icons.dashboard_outlined,
  'Products' => Icons.inventory_2_outlined,
  'Billing' => Icons.receipt_long_outlined,
  'Inventory' => Icons.warehouse_outlined,
  'Discounts' => Icons.discount_outlined,
  'Reports' => Icons.assessment_outlined,
  'Returns' => Icons.assignment_return_outlined,
  _ => Icons.settings_outlined,
};
