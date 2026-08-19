part of 'admin_screens.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Roles & Permissions',
    back: 2,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Role',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                key: ValueKey(state.selectedRole),
                initialValue: state.availableRoles.contains(state.selectedRole)
                    ? state.selectedRole
                    : null,
                items: state.availableRoles
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) state.setRole(v);
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Permissions',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...state.permissions.entries.map(
                (e) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: Icon(
                    _permissionIcon(e.key),
                    size: 19,
                    color: muted,
                  ),
                  title: Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: e.value,
                  onChanged: (v) => state.togglePermission(e.key, v ?? false),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            'Save Permissions',
            onPressed: () async {
              try {
                await state.savePermissions();
                if (context.mounted) {
                  showNotice(
                    context,
                    '${state.selectedRole} permissions saved',
                  );
                }
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
          ),
        ),
      ],
    ),
  );
}

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
