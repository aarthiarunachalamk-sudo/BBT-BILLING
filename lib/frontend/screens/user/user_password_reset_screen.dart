part of 'user_screens.dart';

class UserPasswordResetScreen extends StatefulWidget {
  const UserPasswordResetScreen(this.state, {super.key});
  final UserState state;

  @override
  State<UserPasswordResetScreen> createState() => _UserPasswordResetScreenState();
}

class _UserPasswordResetScreenState extends State<UserPasswordResetScreen> {
  final formKey = GlobalKey<FormState>();
  final identifier = TextEditingController();
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool submitting = false;

  @override
  void dispose() {
    identifier.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reset Password'),
      backgroundColor: userNavy,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.lock_reset_rounded, size: 62, color: userBlue),
            const SizedBox(height: 12),
            const Text('Change your staff password', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Use your employee ID or registered email, current password, and a new password.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 24),
            TextFormField(
              controller: identifier,
              decoration: const InputDecoration(labelText: 'Employee ID or Email', prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter your employee ID or email.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: currentPassword,
              obscureText: obscureCurrent,
              decoration: InputDecoration(labelText: 'Current Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscureCurrent = !obscureCurrent), icon: Icon(obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
              validator: (value) => value == null || value.isEmpty ? 'Enter your current password.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newPassword,
              obscureText: obscureNew,
              decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Icons.lock_reset_outlined), suffixIcon: IconButton(onPressed: () => setState(() => obscureNew = !obscureNew), icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
              validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.verified_user_outlined)),
              validator: (value) => value != newPassword.text ? 'Passwords do not match.' : null,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: submitting ? null : _submit,
              child: submitting ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update Password'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    final success = await widget.state.changePassword(
      identifier: identifier.text,
      currentPassword: currentPassword.text,
      newPassword: newPassword.text,
    );
    if (!mounted) return;
    setState(() => submitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please sign in with your new password.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.error ?? 'Password update failed.')));
    }
  }
}
