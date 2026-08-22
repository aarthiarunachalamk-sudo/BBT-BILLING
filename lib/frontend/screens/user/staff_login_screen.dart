part of 'user_screens.dart';

class StaffLoginScreen extends StatefulWidget { const StaffLoginScreen(this.state, {super.key}); final UserState state; @override State<StaffLoginScreen> createState() => _StaffLoginScreenState(); }
class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final id = TextEditingController(), password = TextEditingController(); bool obscure = true;
  @override void dispose() { id.dispose(); password.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Column(children: [
    const CircleAvatar(radius: 34, backgroundColor: userNavy, child: Icon(Icons.storefront, color: Colors.white, size: 34)), const SizedBox(height: 16),
    const Text('STAFF LOGIN', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: userNavy)), const Text('Supermarket Billing & Inventory', style: TextStyle(color: Colors.blueGrey)), const SizedBox(height: 30),
    TextField(controller: id, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Employee ID / Mobile Number', prefixIcon: Icon(Icons.badge_outlined))), const SizedBox(height: 14),
    TextField(controller: password, obscureText: obscure, onSubmitted: (_) => _login(), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact your manager to reset your password.'))), child: const Text('Forgot Password?'))),
    if (widget.state.error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(widget.state.error!, style: const TextStyle(color: userRed))),
    ElevatedButton(onPressed: widget.state.loading ? null : _login, child: widget.state.loading ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login')),
    const SizedBox(height: 10), OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP login is not enabled by the server.'))), child: const Text('Login with OTP')),
    const SizedBox(height: 24), const Text('App Version 1.0.4', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
  ]))))));
  Future<void> _login() async { if (id.text.trim().isEmpty || password.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your employee ID and password.'))); return; } await widget.state.login(id.text, password.text); }
}
