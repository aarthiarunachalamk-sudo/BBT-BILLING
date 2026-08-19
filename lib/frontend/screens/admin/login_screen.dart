part of 'admin_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _rememberKey = 'admin_remember_me';
  static const _identifierKey = 'admin_login_identifier';

  bool obscure = true;
  bool remember = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();
    final shouldRemember = preferences.getBool(_rememberKey) ?? false;
    final identifier = shouldRemember
        ? preferences.getString(_identifierKey) ?? ''
        : '';
    if (!mounted) return;
    setState(() {
      remember = shouldRemember;
      emailController.text = identifier;
    });
  }

  Future<void> _saveRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberKey, remember);
    if (remember) {
      await preferences.setString(_identifierKey, emailController.text.trim());
    } else {
      await preferences.remove(_identifierKey);
    }
  }

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
                onChanged: (value) async {
                  setState(() => remember = value ?? false);
                  await _saveRememberedLogin();
                },
              ),
              const Text('Remember me', style: TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () => widget.state.openChangePassword(
                  emailController.text.trim(),
                ),
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
              ? Semantics(
                  liveRegion: true,
                  label: 'Signing in',
                  child: const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Signing in securely…',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : PrimaryAction(
                  'Login',
                  onPressed: () async {
                    final success = await widget.state.login(
                      emailController.text.trim(),
                      passwordController.text,
                    );
                    if (success) await _saveRememberedLogin();
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
