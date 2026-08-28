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

  bool get _isWakingUp => widget.state.wakingServer;

  Future<void> _doLogin() async {
    // Detach EditableText/keyboard inherited dependencies before a successful
    // login replaces this entire Scaffold with the dashboard.
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await widget.state.login(
      emailController.text.trim(),
      passwordController.text,
    );
    if (success) await _saveRememberedLogin();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AdminTopBar(title: 'Admin Login'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          // ── Logo ────────────────────────────────────────────────────────
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'BBT Billing',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sign in to access the admin panel',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 30),

          // ── Credentials ─────────────────────────────────────────────────
          TextFormField(
            controller: emailController,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Username or Email',
              prefixIcon: Icon(Icons.person_outline, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordController,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
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

          // ── Remember me / forgot ─────────────────────────────────────────
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
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      widget.state.openChangePassword(
                        emailController.text.trim(),
                      );
                    }
                  });
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Error / wakeup status ────────────────────────────────────────
          if (widget.state.error != null && !widget.state.loading)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.state.error!,
                      style: const TextStyle(
                        color: Color(0xFF8A1720),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Login button / wakeup progress ──────────────────────────────
          if (widget.state.loading)
            Column(
              children: [
                const CircularProgressIndicator(),
                if (!_isWakingUp) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Logging in...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            )
          else
            PrimaryAction('Login', onPressed: _doLogin),

          const SizedBox(height: 32),

          // ── Footer ───────────────────────────────────────────────────────
          const Icon(Icons.lock, color: green, size: 22),
          const SizedBox(height: 6),
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
