part of 'user_screens.dart';

class UserVerificationScreen extends StatelessWidget { const UserVerificationScreen(this.state, {super.key}); final UserState state;
  @override Widget build(BuildContext context) { final u = state.user; return Scaffold(backgroundColor: userBg, appBar: AppBar(backgroundColor: userNavy, foregroundColor: Colors.white, title: const Text('Account Verification')), body: SafeArea(top: false, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: UserCard(child: Column(children: [
    const CircleAvatar(radius: 34, backgroundColor: Color(0xFFE7F8EC), child: Icon(Icons.check_circle, color: userGreen, size: 42)), const SizedBox(height: 14), const Text('Login Successful', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 22),
    _row('Employee ID', u['employee_id'] ?? u['username']), _row('Name', '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim()), _row('Role', u['role']), _row('Branch', u['branch']), const SizedBox(height: 18),
    ElevatedButton(onPressed: () => state.go(UserPage.dashboard), child: const Text('Continue to Dashboard')),
  ]))))))); }
  Widget _row(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.blueGrey))), Flexible(child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)))]));
}
