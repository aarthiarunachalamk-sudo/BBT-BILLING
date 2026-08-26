part of 'admin_screens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// History Screen  (screen 20)
// Shows audit logs grouped by module with tabs + search + detail drawer
// ─────────────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  static const _tabs = ['All', 'Products', 'Billing', 'Inventory', 'Staff', 'Auth'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    // Reload audit logs so the page always shows fresh data.
    if (widget.state.loggedIn) {
      widget.state.refreshAuditLogs();
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(String module) {
    final logs = widget.state.auditLogs;
    final q = _search.trim().toLowerCase();
    return logs.where((log) {
      final matchesModule = module == 'All' ||
          (log['module']?.toString().toLowerCase().contains(
                module.toLowerCase(),
              ) ??
              false);
      if (!matchesModule) return false;
      if (q.isEmpty) return true;
      return [log['action'], log['module'], log['user_name'], log['ip_address']]
          .any((v) => v?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'History',
    back: 1,
    bottom: false,
    actions: [
      IconButton(
        tooltip: 'Refresh',
        icon: widget.state.refreshing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.refresh_rounded),
        onPressed: widget.state.refreshing
            ? null
            : () => widget.state.refreshAuditLogs(),
      ),
    ],
    child: Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: SearchBox(
            'Search by action, user or module…',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),

        // ── Module tabs ───────────────────────────────────────────────────
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),

        // ── Log list per tab ──────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: _tabs
                .map((module) => _LogList(logs: _filtered(module)))
                .toList(),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Log list widget
// ─────────────────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({required this.logs});
  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyState(
        'No history records for this filter.',
        icon: Icons.history,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _LogCard(log: logs[index]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single log card
// ─────────────────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});
  final Map<String, dynamic> log;

  Color get _moduleColor {
    final m = log['module']?.toString().toLowerCase() ?? '';
    if (m.contains('item') || m.contains('product') || m.contains('inventory')) {
      return Colors.orange;
    }
    if (m.contains('invoice') || m.contains('billing') || m.contains('payment')) {
      return blue;
    }
    if (m.contains('auth') || m.contains('login') || m.contains('password')) {
      return green;
    }
    if (m.contains('staff') || m.contains('user')) {
      return const Color(0xFF9C27B0);
    }
    if (m.contains('purchase') || m.contains('supplier')) {
      return const Color(0xFF00897B);
    }
    return muted;
  }

  IconData get _moduleIcon {
    final m = log['module']?.toString().toLowerCase() ?? '';
    if (m.contains('item') || m.contains('product')) return Icons.inventory_2_outlined;
    if (m.contains('inventory')) return Icons.bar_chart;
    if (m.contains('invoice') || m.contains('billing')) return Icons.receipt_long_outlined;
    if (m.contains('payment')) return Icons.payments_outlined;
    if (m.contains('auth') || m.contains('login')) return Icons.lock_outlined;
    if (m.contains('password')) return Icons.key_outlined;
    if (m.contains('user') || m.contains('staff')) return Icons.person_outline;
    if (m.contains('purchase')) return Icons.shopping_cart_outlined;
    if (m.contains('return')) return Icons.assignment_return_outlined;
    if (m.contains('category')) return Icons.category_outlined;
    if (m.contains('supplier')) return Icons.local_shipping_outlined;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor;
    final user = log['user_name']?.toString().trim();
    final hasUser = user != null && user.isNotEmpty;
    final time = log['created_at']?.toString() ?? '';
    final dt = DateTime.tryParse(time);
    final timeLabel = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : time;

    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ────────────────────────────────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_moduleIcon, size: 18, color: color),
          ),
          const SizedBox(width: 12),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log['action']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Module chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        log['module']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      hasUser ? user : 'System',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 12, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                if (log['ip_address'] != null &&
                    log['ip_address'].toString().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.router_outlined, size: 12, color: muted),
                      const SizedBox(width: 4),
                      Text(
                        log['ip_address'].toString(),
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
