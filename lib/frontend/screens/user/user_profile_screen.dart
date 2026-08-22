part of 'user_screens.dart';

class UserProfileScreen extends StatelessWidget { const UserProfileScreen(this.state, {super.key}); final UserState state;
  @override Widget build(BuildContext context) { final u = state.user; return UserShell(state: state, title: 'Profile', child: ListView(padding: const EdgeInsets.all(16), children: [
    UserCard(child: Column(children: [const CircleAvatar(radius: 34, backgroundColor: userNavy, child: Icon(Icons.person, color: Colors.white, size: 36)), const SizedBox(height: 10), Text('${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text('${u['employee_id'] ?? u['username']} • ${u['role']}'), Text('${u['branch'] ?? ''}', style: const TextStyle(color: Colors.blueGrey))])), const SizedBox(height: 12),
    UserCard(onTap: () => state.go(UserPage.invoice), child: const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.receipt_long, color: userBlue), title: Text('Bill History'), trailing: Icon(Icons.chevron_right))),
    UserCard(onTap: () => _notice(context, 'Stock activity is recorded for your account.'), child: const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.inventory, color: userBlue), title: Text('Stock Activity'), trailing: Icon(Icons.chevron_right))),
    UserCard(onTap: () => _notice(context, 'User activity is available from the audit log.'), child: const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.history, color: userBlue), title: Text('User Activity'), trailing: Icon(Icons.chevron_right))), const SizedBox(height: 14),
    OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: userRed), onPressed: () => _confirmLogout(context), icon: const Icon(Icons.logout), label: const Text('Logout')),
  ])); }
  Future<void> _confirmLogout(BuildContext context) async { final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Logout?'), content: const Text('Your local staff session will be cleared.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout'))])) ?? false; if (ok) await state.logout(); }
}
