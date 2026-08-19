part of 'admin_screens.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen(this.state, {super.key});

  final AdminState state;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final identifierController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    identifierController.text = widget.state.passwordChangeIdentifier;
  }

  @override
  void dispose() {
    identifierController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _passwordDecoration(
    String label,
    bool obscure,
    VoidCallback toggle,
  ) => InputDecoration(
    labelText: label,
    suffixIcon: IconButton(
      onPressed: toggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    ),
  );

  Future<void> _submit() async {
    final identifier = identifierController.text.trim();
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmation = confirmPasswordController.text;
    if (identifier.isEmpty || currentPassword.isEmpty || newPassword.isEmpty) {
      showNotice(context, 'Complete all password fields.');
      return;
    }
    if (newPassword != confirmation) {
      showNotice(context, 'New passwords do not match.');
      return;
    }
    final success = await widget.state.changePassword(
      identifier: identifier,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!mounted) return;
    if (success) {
      showNotice(context, 'Password changed successfully.');
      widget.state.go(widget.state.loggedIn ? 15 : 0);
    } else {
      showNotice(context, widget.state.error ?? 'Unable to change password.');
    }
  }

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Change Password',
    back: widget.state.loggedIn ? 15 : 0,
    bottom: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 72, color: navy),
          const SizedBox(height: 18),
          const Text(
            'Change your password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify your current password, then choose a new password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: identifierController,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Username or Email'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: currentPasswordController,
            obscureText: obscureCurrent,
            decoration: _passwordDecoration(
              'Current Password',
              obscureCurrent,
              () => setState(() => obscureCurrent = !obscureCurrent),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: newPasswordController,
            obscureText: obscureNew,
            decoration: _passwordDecoration(
              'New Password',
              obscureNew,
              () => setState(() => obscureNew = !obscureNew),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: obscureConfirm,
            decoration: _passwordDecoration(
              'Confirm New Password',
              obscureConfirm,
              () => setState(() => obscureConfirm = !obscureConfirm),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.state.error != null) ...[
            Text(
              widget.state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: red, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
          widget.state.loading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryAction('Change Password', onPressed: _submit),
        ],
      ),
    ),
  );
}
