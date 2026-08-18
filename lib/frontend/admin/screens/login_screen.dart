part of '../admin_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;
  bool remember = false;
  final emailController = TextEditingController(text: 'aarthi');
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AdminTopBar(title: 'Admin Login'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Welcome Admin',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to access admin panel',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: emailController,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Username or Email'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
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
          Row(
            children: [
              Checkbox(
                value: remember,
                onChanged: (v) => setState(() => remember = v ?? false),
              ),
              const Text('Remember me', style: TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    showNotice(context, 'Password reset link sent'),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          if (widget.state.error != null) ...[
            Text(
              widget.state.error!,
              style: const TextStyle(color: red, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
          widget.state.loading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryAction(
                  'Login',
                  onPressed: () async {
                    final success = await widget.state.login(
                      emailController.text.trim(),
                      passwordController.text,
                    );
                    if (!success && context.mounted) {
                      showNotice(context, widget.state.error ?? 'Login failed');
                    }
                  },
                ),
          const SizedBox(height: 40),
          const Icon(Icons.lock, color: green, size: 25),
          const SizedBox(height: 7),
          const Text(
            'Secure admin access',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const Text(
            'for authorized personnel only',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    ),
  );
}
