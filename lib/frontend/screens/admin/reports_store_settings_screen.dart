part of 'admin_screens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class ReportsSettingsScreen extends StatefulWidget {
  const ReportsSettingsScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<ReportsSettingsScreen> createState() => _ReportsSettingsScreenState();
}

class _ReportsSettingsScreenState extends State<ReportsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Reports & Settings',
    back: 1,
    bottom: false,
    child: Column(
      children: [
        // ── Top tab bar: Reports | Settings ───────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'Reports'),
              Tab(text: 'Store Settings'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ReportsTab(state: widget.state),
              _SettingsTab(state: widget.state),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports tab — 6 report cards + export row
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        const Text(
          'Tap a report to view and export',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 14),

        // ── 6 report tiles ──────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _ReportTile(
              icon: Icons.bar_chart_rounded,
              label: 'Sales\nReport',
              color: blue,
              onTap: () => _openReport(context, _ReportType.sales),
            ),
            _ReportTile(
              icon: Icons.receipt_long_outlined,
              label: 'GST\nReport',
              color: const Color(0xFF9C27B0),
              onTap: () => _openReport(context, _ReportType.gst),
            ),
            _ReportTile(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory\nReport',
              color: Colors.orange,
              onTap: () => _openReport(context, _ReportType.inventory),
            ),
            _ReportTile(
              icon: Icons.shopping_cart_checkout_outlined,
              label: 'Purchase\nReport',
              color: const Color(0xFF00897B),
              onTap: () => _openReport(context, _ReportType.purchase),
            ),
            _ReportTile(
              icon: Icons.currency_rupee_rounded,
              label: 'Profit\n& Loss',
              color: green,
              onTap: () => _openReport(context, _ReportType.profitLoss),
            ),
            _ReportTile(
              icon: Icons.stacked_line_chart_rounded,
              label: 'Stock\nValuation',
              color: const Color(0xFFE53935),
              onTap: () => _openReport(context, _ReportType.stockValuation),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Export row ──────────────────────────────────────────────────
        const Text(
          'Export Reports',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                icon: Icons.summarize_outlined,
                color: navy,
                label: 'Full Summary',
                onTap: () => _openReport(context, _ReportType.summary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ExportButton(
                icon: Icons.table_chart_outlined,
                color: green,
                label: 'Invoice CSV',
                onTap: () => _exportCsv(context, state),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                icon: Icons.inventory_outlined,
                color: Colors.orange,
                label: 'Products CSV',
                onTap: () => _exportProductsCsv(context, state),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ExportButton(
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF00897B),
                label: 'Purchase CSV',
                onTap: () => _exportPurchaseCsv(context, state),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openReport(BuildContext context, _ReportType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReportDetailPage(state: state, type: type),
      ),
    );
  }

  void _exportCsv(BuildContext context, AdminState state) {
    final csv = _buildInvoiceCsv(state);
    _shareText(
      context,
      csv,
      'invoices.csv',
      '${state.invoices.length} invoice rows copied as CSV',
    );
  }

  void _exportProductsCsv(BuildContext context, AdminState state) {
    final csv = _buildProductsCsv(state);
    _shareText(
      context,
      csv,
      'products.csv',
      '${state.products.length} product rows copied as CSV',
    );
  }

  void _exportPurchaseCsv(BuildContext context, AdminState state) {
    final csv = _buildPurchaseCsv(state);
    _shareText(
      context,
      csv,
      'purchase_orders.csv',
      '${state.purchaseOrders.length} purchase order rows copied as CSV',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report detail page — full screen with tabs and copy/share
// ─────────────────────────────────────────────────────────────────────────────

enum _ReportType {
  sales,
  gst,
  inventory,
  purchase,
  profitLoss,
  stockValuation,
  summary,
}

class _ReportDetailPage extends StatefulWidget {
  const _ReportDetailPage({required this.state, required this.type});
  final AdminState state;
  final _ReportType type;

  @override
  State<_ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<_ReportDetailPage> {
  final _captureKey = GlobalKey();
  late DateTimeRange _range;
  List<_ReportDownloadRecord> _history = const [];
  List<Map<String, dynamic>>? _inventoryTransactions;
  bool _saving = false;
  bool _loadingInventoryHistory = false;

  AdminState get state => widget.state;
  _ReportType get type => widget.type;
  bool get _enhancedReport =>
      type == _ReportType.sales ||
      type == _ReportType.gst ||
      type == _ReportType.inventory ||
      type == _ReportType.purchase ||
      type == _ReportType.profitLoss ||
      type == _ReportType.stockValuation ||
      type == _ReportType.summary;
  bool get _rangeReport =>
      type != _ReportType.inventory && type != _ReportType.stockValuation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = type == _ReportType.inventory || type == _ReportType.stockValuation
        ? DateTimeRange(start: now, end: now)
        : DateTimeRange(start: DateTime(now.year, now.month), end: now);
    _readHistory();
    if (type == _ReportType.inventory || type == _ReportType.stockValuation) {
      _loadInventoryHistory();
    }
  }

  Future<void> _loadInventoryHistory() async {
    setState(() => _loadingInventoryHistory = true);
    try {
      final transactions = await state.api.getList('inventory-transactions');
      if (mounted) setState(() => _inventoryTransactions = transactions);
    } catch (_) {
      // The current snapshot remains usable if the historical ledger is
      // temporarily unavailable.
    } finally {
      if (mounted) setState(() => _loadingInventoryHistory = false);
    }
  }

  Future<void> _readHistory() async {
    final history = await _loadReportHistory();
    if (mounted) setState(() => _history = history);
  }

  String get _title => switch (type) {
    _ReportType.sales => 'Sales Report',
    _ReportType.gst => 'GST Report',
    _ReportType.inventory => 'Inventory Report',
    _ReportType.purchase => 'Purchase Report',
    _ReportType.profitLoss => 'Profit & Loss',
    _ReportType.stockValuation => 'Stock Valuation',
    _ReportType.summary => 'Admin Summary',
  };

  String get _csv => switch (type) {
    _ReportType.sales => _buildSalesCsv(state, _invoices),
    _ReportType.gst => _buildGstCsv(state, _invoices),
    _ReportType.inventory => _buildProductsCsv(state, _inventoryProducts),
    _ReportType.purchase => _buildPurchaseCsv(state, _orders),
    _ReportType.profitLoss => _buildProfitLossCsv(
      state,
      invoices: _invoices,
      products: _inventoryProducts,
    ),
    _ReportType.stockValuation => _buildStockValuationCsv(
      state,
      _inventoryProducts,
    ),
    _ReportType.summary => _buildSummaryCsv(state, _invoices),
  };

  List<Map<String, dynamic>> get _invoices => state.invoices.where((invoice) {
    final date = _parseReportDate(invoice['invoice_date']);
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      _range.start.year,
      _range.start.month,
      _range.start.day,
    );
    final end = DateTime(_range.end.year, _range.end.month, _range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList();

  List<Map<String, dynamic>> get _orders => state.purchaseOrders.where((order) {
    final date = _parseReportDate(order['order_date'] ?? order['created_at']);
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      _range.start.year,
      _range.start.month,
      _range.start.day,
    );
    final end = DateTime(_range.end.year, _range.end.month, _range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList();

  List<Map<String, dynamic>> get _inventoryProducts {
    final products = state.products
        .map((product) => Map<String, dynamic>.from(product))
        .toList();
    if (_isToday || _inventoryTransactions == null) return products;
    final endOfDay = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day,
      23,
      59,
      59,
      999,
    );
    final futureChanges = <int, int>{};
    for (final transaction in _inventoryTransactions!) {
      final created = _parseReportDate(transaction['created_at']);
      final item = int.tryParse(transaction['item']?.toString() ?? '');
      if (created != null && item != null && created.isAfter(endOfDay)) {
        futureChanges[item] =
            (futureChanges[item] ?? 0) +
            (int.tryParse(transaction['quantity']?.toString() ?? '') ?? 0);
      }
    }
    for (final product in products) {
      final id = int.tryParse(product['id']?.toString() ?? '');
      if (id == null) continue;
      final current =
          int.tryParse(product['stock_quantity']?.toString() ?? '') ?? 0;
      final historical = current - (futureChanges[id] ?? 0);
      product['stock_quantity'] = historical < 0 ? 0 : historical;
      final reorder =
          int.tryParse(product['reorder_level']?.toString() ?? '') ?? 0;
      product['stock_status'] = historical <= 0
          ? 'out_of_stock'
          : historical <= reorder
          ? 'low_stock'
          : 'in_stock';
    }
    return products;
  }

  String get _period =>
      type == _ReportType.inventory || type == _ReportType.stockValuation
      ? (_isToday
            ? 'Current stock snapshot · ${_dateText(DateTime.now())}'
            : 'Stock position as of ${_dateText(_range.end)}')
      : '${_dateText(_range.start)} - ${_dateText(_range.end)}';

  String get _description => switch (type) {
    _ReportType.gst => 'Taxable sales, CGST and SGST collection summary',
    _ReportType.inventory =>
      'Stock availability, reorder status and cost value',
    _ReportType.purchase => 'Supplier orders, status and purchase value',
    _ReportType.profitLoss =>
      'Sales, estimated cost, profit and margin performance',
    _ReportType.stockValuation =>
      'Cost, retail value and potential stock profit',
    _ReportType.summary =>
      'Business health, sales, stock and pending actions in one view',
    _ => 'Invoice totals, tax, discounts and payment status',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          if (_enhancedReport)
            IconButton(
              key: const Key('report-download-action'),
              tooltip: 'Download report',
              icon: const Icon(Icons.download_rounded),
              onPressed: _saving ? null : _showDownloadOptions,
            )
          else
            IconButton(
              tooltip: 'Copy as CSV',
              icon: const Icon(Icons.copy_outlined),
              onPressed: () => _shareText(
                context,
                _csv,
                '${_title.toLowerCase().replaceAll(' ', '_')}.csv',
                '$_title copied to clipboard',
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _enhancedReport
            ? Column(
                children: [
                  _reportControls(),
                  Expanded(child: _buildContent()),
                ],
              )
            : _buildContent(),
      ),
    );
  }

  Widget _reportControls() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: _ReportSnapshotCard(
            type: type,
            title: _title,
            description: _description,
            period: _period,
            invoices: _invoices,
            products: _inventoryProducts,
            orders: _orders,
          ),
        ),
        const SizedBox(height: 10),
        if (_rangeReport)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _rangeChip('Today', _isToday, _selectToday),
                _rangeChip(
                  'Last 7 days',
                  _isLastSevenDays,
                  _selectLastSevenDays,
                ),
                _rangeChip('This month', _isThisMonth, _selectThisMonth),
                const SizedBox(width: 7),
                OutlinedButton.icon(
                  key: const Key('report-calendar-button'),
                  onPressed: _pickRange,
                  icon: const Icon(Icons.calendar_month_rounded, size: 17),
                  label: const Text('Custom date'),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _rangeChip(
                  type == _ReportType.stockValuation
                      ? 'Current valuation'
                      : 'Current stock',
                  _isToday,
                  _selectToday,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('report-calendar-button'),
                onPressed:
                    _loadingInventoryHistory || _inventoryTransactions == null
                    ? null
                    : _pickInventoryDate,
                icon: _loadingInventoryHistory
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_available_rounded, size: 17),
                label: Text(
                  type == _ReportType.stockValuation
                      ? 'Valuation as of date'
                      : 'Stock as of date',
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('report-download-button'),
                onPressed: _saving ? null : _showDownloadOptions,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Download report'),
              ),
            ),
            const SizedBox(width: 9),
            OutlinedButton.icon(
              key: const Key('report-history-button'),
              onPressed: _showHistory,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text('History (${_history.length})'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _rangeChip(String label, bool selected, VoidCallback onSelected) =>
      Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
          selectedColor: violet.withValues(alpha: .14),
          labelStyle: TextStyle(
            color: selected ? violet : muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );

  bool get _isToday {
    final now = DateTime.now();
    return _sameDay(_range.start, now) && _sameDay(_range.end, now);
  }

  bool get _isLastSevenDays {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    return _sameDay(_range.start, start) && _sameDay(_range.end, now);
  }

  bool get _isThisMonth {
    final now = DateTime.now();
    return _sameDay(_range.start, DateTime(now.year, now.month)) &&
        _sameDay(_range.end, now);
  }

  void _selectToday() {
    final now = DateTime.now();
    setState(() => _range = DateTimeRange(start: now, end: now));
  }

  void _selectLastSevenDays() {
    final now = DateTime.now();
    setState(
      () => _range = DateTimeRange(
        start: DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6)),
        end: now,
      ),
    );
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    setState(
      () => _range = DateTimeRange(
        start: DateTime(now.year, now.month),
        end: now,
      ),
    );
  }

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
      helpText: 'SELECT REPORT DATE RANGE',
      saveText: 'SHOW REPORT',
    );
    if (selected != null && mounted) setState(() => _range = selected);
  }

  Future<void> _pickInventoryDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _range.end.isAfter(DateTime.now())
          ? DateTime.now()
          : _range.end,
      helpText: 'SELECT INVENTORY AS-OF DATE',
    );
    if (selected != null && mounted) {
      setState(() => _range = DateTimeRange(start: selected, end: selected));
    }
  }

  Future<void> _showDownloadOptions() async {
    final format = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download $_title',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _period,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _DownloadFormatTile(
                  icon: Icons.picture_as_pdf_rounded,
                  color: red,
                  title: 'PDF document',
                  subtitle: 'Full report saved in Downloads / BBT Billing',
                  onTap: () => Navigator.pop(sheetContext, 'PDF'),
                ),
                _DownloadFormatTile(
                  icon: Icons.table_view_rounded,
                  color: green,
                  title: 'CSV spreadsheet',
                  subtitle: 'Open in Excel or Google Sheets',
                  onTap: () => Navigator.pop(sheetContext, 'CSV'),
                ),
                _DownloadFormatTile(
                  icon: Icons.photo_library_rounded,
                  color: violet,
                  title: 'Save report image to Gallery',
                  subtitle: 'PNG summary saved in Pictures / BBT Billing',
                  onTap: () => Navigator.pop(sheetContext, 'PNG'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (format != null) await _download(format);
  }

  Future<void> _download(String format) async {
    setState(() => _saving = true);
    try {
      final stamp = DateTime.now().toIso8601String().replaceAll(
        RegExp(r'[:.]'),
        '-',
      );
      final slug = switch (type) {
        _ReportType.gst => 'GST_Report',
        _ReportType.inventory => 'Inventory_Report',
        _ReportType.purchase => 'Purchase_Report',
        _ReportType.profitLoss => 'Profit_Loss_Report',
        _ReportType.stockValuation => 'Stock_Valuation_Report',
        _ReportType.summary => 'Admin_Summary_Report',
        _ => 'Sales_Report',
      };
      late final Uint8List bytes;
      late final String mime;
      if (format == 'PDF') {
        bytes = switch (type) {
          _ReportType.inventory => await _buildInventoryReportPdf(
            title: _title,
            period: _period,
            products: _inventoryProducts,
          ),
          _ReportType.purchase => await _buildPurchaseReportPdf(
            title: _title,
            period: _period,
            orders: _orders,
          ),
          _ReportType.profitLoss => await _buildProfitLossReportPdf(
            title: _title,
            period: _period,
            invoices: _invoices,
            products: _inventoryProducts,
          ),
          _ReportType.stockValuation => await _buildStockValuationReportPdf(
            title: _title,
            period: _period,
            products: _inventoryProducts,
          ),
          _ReportType.summary => await _buildAdminSummaryPdf(
            title: _title,
            period: _period,
            state: state,
            invoices: _invoices,
          ),
          _ => await _buildReportPdf(
            title: _title,
            period: _period,
            invoices: _invoices,
            gst: type == _ReportType.gst,
          ),
        };
        mime = 'application/pdf';
      } else if (format == 'CSV') {
        bytes = Uint8List.fromList(utf8.encode('\ufeff$_csv'));
        mime = 'text/csv';
      } else {
        bytes = await _captureReportCard(_captureKey);
        mime = 'image/png';
      }
      final fileName = '${slug}_$stamp.${format.toLowerCase()}';
      final path = await _saveReportBytes(
        bytes: bytes,
        fileName: fileName,
        mimeType: mime,
        gallery: format == 'PNG',
      );
      final updated = await _rememberReportDownload(
        _ReportDownloadRecord(
          title: _title,
          format: format,
          period: _period,
          path: path,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => _history = updated);
      showNotice(
        context,
        format == 'PNG'
            ? '$_title saved to Gallery.'
            : '$_title saved to Downloads.',
      );
    } catch (error) {
      if (mounted) showNotice(context, 'Could not save report: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .62,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Download history',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (_history.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          await _clearReportHistory();
                          if (!mounted) return;
                          setState(() => _history = const []);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear history'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _history.isEmpty
                    ? const Center(child: _NoData('No reports downloaded yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                        itemCount: _history.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _ReportHistoryTile(record: _history[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() => switch (type) {
    _ReportType.sales => _SalesReportView(state: state, invoices: _invoices),
    _ReportType.gst => _GstReportView(state: state, invoices: _invoices),
    _ReportType.inventory => _InventoryReportView(
      state: state,
      products: _inventoryProducts,
    ),
    _ReportType.purchase => _PurchaseReportView(state: state, orders: _orders),
    _ReportType.profitLoss => _ProfitLossView(
      state: state,
      invoices: _invoices,
      products: _inventoryProducts,
    ),
    _ReportType.stockValuation => _StockValuationView(
      state: state,
      products: _inventoryProducts,
    ),
    _ReportType.summary => _SummaryView(
      state: state,
      invoices: _invoices,
      onNavigate: (screen) {
        Navigator.of(context).pop();
        state.go(screen);
      },
    ),
  };
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime? _parseReportDate(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return parsed;
  final parts = text.split('/');
  if (parts.length == 3) {
    return DateTime.tryParse(
      '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
    );
  }
  return null;
}

bool _isCompletedSale(Map<String, dynamic> invoice) {
  final status = invoice['status']?.toString().toLowerCase();
  return status == 'paid' || status == 'partial';
}

double _estimatedCogs(
  Iterable<Map<String, dynamic>> invoices,
  List<Map<String, dynamic>> products,
) {
  final productCosts = <int, double>{};
  for (final product in products) {
    final id = int.tryParse(product['id']?.toString() ?? '');
    if (id != null) productCosts[id] = _d(product['purchase_price']);
  }
  var total = 0.0;
  for (final invoice in invoices) {
    final items = invoice['items'];
    if (items is! List) continue;
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = int.tryParse(raw['item']?.toString() ?? '');
      if (item == null) continue;
      total += (productCosts[item] ?? 0) * _d(raw['quantity']);
    }
  }
  return total;
}

class _DownloadFormatTile extends StatelessWidget {
  const _DownloadFormatTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
    ),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5)),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _ReportHistoryTile extends StatelessWidget {
  const _ReportHistoryTile({required this.record});
  final _ReportDownloadRecord record;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: violet.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            record.format == 'PNG'
                ? Icons.photo_rounded
                : record.format == 'PDF'
                ? Icons.picture_as_pdf_rounded
                : Icons.table_view_rounded,
            color: violet,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.title} · ${record.format}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                record.period,
                style: const TextStyle(fontSize: 9.5, color: muted),
              ),
              Text(
                record.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: muted),
              ),
            ],
          ),
        ),
        Text(
          _dateText(record.createdAt),
          style: const TextStyle(fontSize: 9, color: muted),
        ),
      ],
    ),
  );
}

class _ReportSnapshotCard extends StatelessWidget {
  const _ReportSnapshotCard({
    required this.type,
    required this.title,
    required this.description,
    required this.period,
    required this.invoices,
    required this.products,
    required this.orders,
  });
  final _ReportType type;
  final String title;
  final String description;
  final String period;
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    final total = invoices.fold<double>(
      0,
      (sum, row) => sum + _d(row['total']),
    );
    final tax = invoices.fold<double>(
      0,
      (sum, row) => sum + _d(row['cgst_amount']) + _d(row['sgst_amount']),
    );
    final inventoryValue = products.fold<double>(
      0,
      (sum, row) => sum + _d(row['purchase_price']) * _d(row['stock_quantity']),
    );
    final purchaseValue = orders.fold<double>(
      0,
      (sum, row) => sum + _d(row['total']),
    );
    final paidInvoices = invoices.where(_isCompletedSale).toList();
    final netSales = paidInvoices.fold<double>(
      0,
      (sum, row) => sum + _d(row['taxable_amount']),
    );
    final grossProfit = netSales - _estimatedCogs(paidInvoices, products);
    final colors = switch (type) {
      _ReportType.gst => const [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
      _ReportType.inventory => const [Color(0xFF047857), Color(0xFF10B981)],
      _ReportType.purchase => const [Color(0xFFB45309), Color(0xFFF59E0B)],
      _ReportType.profitLoss => const [Color(0xFF0F766E), Color(0xFF14B8A6)],
      _ReportType.stockValuation => const [
        Color(0xFF9A3412),
        Color(0xFFF97316),
      ],
      _ReportType.summary => const [Color(0xFF1E3A8A), Color(0xFF4F46E5)],
      _ => const [Color(0xFF075985), Color(0xFF0284C7)],
    };
    final icon = switch (type) {
      _ReportType.gst => Icons.receipt_long_rounded,
      _ReportType.inventory => Icons.inventory_2_rounded,
      _ReportType.purchase => Icons.shopping_cart_checkout_rounded,
      _ReportType.profitLoss => Icons.trending_up_rounded,
      _ReportType.stockValuation => Icons.stacked_line_chart_rounded,
      _ReportType.summary => Icons.dashboard_customize_rounded,
      _ => Icons.bar_chart_rounded,
    };
    final firstMetric = switch (type) {
      _ReportType.inventory => ('Products', '${products.length}'),
      _ReportType.purchase => ('Orders', '${orders.length}'),
      _ReportType.profitLoss => ('Paid invoices', '${paidInvoices.length}'),
      _ReportType.stockValuation => ('Stock items', '${products.length}'),
      _ReportType.summary => ('Bills', '${invoices.length}'),
      _ => ('Invoices', '${invoices.length}'),
    };
    final secondMetric = switch (type) {
      _ReportType.gst => ('GST collected', _money(tax)),
      _ReportType.inventory => ('Inventory cost', _money(inventoryValue)),
      _ReportType.purchase => ('Order value', _money(purchaseValue)),
      _ReportType.profitLoss => ('Gross profit', _money(grossProfit)),
      _ReportType.stockValuation => ('Cost value', _money(inventoryValue)),
      _ReportType.summary => ('Net sales', _money(netSales)),
      _ => ('Sales', _money(total)),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            period,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetric(
                  label: firstMetric.$1,
                  value: firstMetric.$2,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _SnapshotMetric(
                  label: secondMetric.$1,
                  value: secondMetric.$2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 8.5),
        ),
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual report views
// ─────────────────────────────────────────────────────────────────────────────

// ── Sales Report ─────────────────────────────────────────────────────────────
class _SalesReportView extends StatelessWidget {
  const _SalesReportView({required this.state, required this.invoices});
  final AdminState state;
  final List<Map<String, dynamic>> invoices;

  @override
  Widget build(BuildContext context) {
    double totalSales = 0, totalTax = 0, totalDiscount = 0;
    for (final inv in invoices) {
      totalSales += _d(inv['total']);
      totalTax += _d(inv['cgst_amount']) + _d(inv['sgst_amount']);
      totalDiscount += _d(inv['discount_amount']);
    }

    // Group by status
    final statusMap = <String, int>{};
    for (final inv in invoices) {
      final s = inv['status']?.toString() ?? 'unknown';
      statusMap[s] = (statusMap[s] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── KPI row ────────────────────────────────────────────────────
        _KpiRow(
          items: [
            _Kpi('Total Invoices', '${invoices.length}', blue),
            _Kpi('Total Sales', _money(totalSales), green),
            _Kpi('Total Tax', _money(totalTax), const Color(0xFF9C27B0)),
            _Kpi('Discounts', _money(totalDiscount), Colors.orange),
          ],
        ),
        const SizedBox(height: 16),

        // ── Status breakdown ───────────────────────────────────────────
        _SectionHead('Sales by Status'),
        const SizedBox(height: 8),
        ...statusMap.entries.map(
          (e) => _LabelValueRow(_statusText(e.key), '${e.value} invoices'),
        ),
        const SizedBox(height: 16),

        // ── Invoice table ──────────────────────────────────────────────
        _SectionHead('Invoice List (${invoices.length})'),
        const SizedBox(height: 8),
        if (invoices.isEmpty)
          const _NoData('No invoices found.')
        else if (MediaQuery.sizeOf(context).width < 600)
          ...invoices.map((inv) => _MobileInvoiceCard(invoice: inv, gst: false))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Invoice', style: _th)),
                DataColumn(label: Text('Date', style: _th)),
                DataColumn(label: Text('Customer', style: _th)),
                DataColumn(label: Text('Status', style: _th)),
                DataColumn(label: Text('Total', style: _th), numeric: true),
              ],
              rows: invoices
                  .map(
                    (inv) => DataRow(
                      cells: [
                        DataCell(
                          Text(inv['number']?.toString() ?? '', style: _td),
                        ),
                        DataCell(
                          Text(_dateText(inv['invoice_date']), style: _td),
                        ),
                        DataCell(
                          Text(
                            inv['client_name']?.toString() ?? '',
                            style: _td,
                          ),
                        ),
                        DataCell(
                          Text(
                            _statusText(inv['status']?.toString() ?? ''),
                            style: _td,
                          ),
                        ),
                        DataCell(Text(_money(_d(inv['total'])), style: _td)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ── GST Report ───────────────────────────────────────────────────────────────
class _GstReportView extends StatelessWidget {
  const _GstReportView({required this.state, required this.invoices});
  final AdminState state;
  final List<Map<String, dynamic>> invoices;

  @override
  Widget build(BuildContext context) {
    double taxable = 0, cgst = 0, sgst = 0, total = 0;
    for (final inv in invoices) {
      taxable += _d(inv['taxable_amount']);
      cgst += _d(inv['cgst_amount']);
      sgst += _d(inv['sgst_amount']);
      total += _d(inv['total']);
    }

    // Invoice-level effective rate is used because each invoice already stores
    // the final taxable amount and collected CGST/SGST values.
    final slabMap = <String, double>{};
    for (final invoice in invoices) {
      final invoiceTaxable = _d(invoice['taxable_amount']);
      final invoiceTax =
          _d(invoice['cgst_amount']) + _d(invoice['sgst_amount']);
      final rate = invoiceTaxable == 0 ? 0 : invoiceTax / invoiceTaxable * 100;
      final slab =
          '${rate.toStringAsFixed(rate.roundToDouble() == rate ? 0 : 2)}%';
      slabMap[slab] = (slabMap[slab] ?? 0) + invoiceTax;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(
          items: [
            _Kpi('Taxable Amount', _money(taxable), blue),
            _Kpi('CGST Collected', _money(cgst), const Color(0xFF9C27B0)),
            _Kpi('SGST Collected', _money(sgst), const Color(0xFF9C27B0)),
            _Kpi('Invoice Total', _money(total), green),
          ],
        ),
        const SizedBox(height: 16),

        _SectionHead('GST Collected by Effective Rate'),
        const SizedBox(height: 8),
        ...slabMap.entries.map(
          (e) => _LabelValueRow('GST ${e.key}', _money(e.value)),
        ),
        const SizedBox(height: 16),

        _SectionHead('Invoice GST Details (${invoices.length})'),
        const SizedBox(height: 8),
        if (invoices.isEmpty)
          const _NoData('No invoices found.')
        else if (MediaQuery.sizeOf(context).width < 600)
          ...invoices.map((inv) => _MobileInvoiceCard(invoice: inv, gst: true))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Invoice', style: _th)),
                DataColumn(label: Text('Date', style: _th)),
                DataColumn(label: Text('Taxable', style: _th), numeric: true),
                DataColumn(label: Text('CGST', style: _th), numeric: true),
                DataColumn(label: Text('SGST', style: _th), numeric: true),
                DataColumn(label: Text('Total', style: _th), numeric: true),
              ],
              rows: invoices
                  .map(
                    (inv) => DataRow(
                      cells: [
                        DataCell(
                          Text(inv['number']?.toString() ?? '', style: _td),
                        ),
                        DataCell(
                          Text(_dateText(inv['invoice_date']), style: _td),
                        ),
                        DataCell(
                          Text(_money(_d(inv['taxable_amount'])), style: _td),
                        ),
                        DataCell(
                          Text(_money(_d(inv['cgst_amount'])), style: _td),
                        ),
                        DataCell(
                          Text(_money(_d(inv['sgst_amount'])), style: _td),
                        ),
                        DataCell(Text(_money(_d(inv['total'])), style: _td)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _MobileInvoiceCard extends StatelessWidget {
  const _MobileInvoiceCard({required this.invoice, required this.gst});
  final Map<String, dynamic> invoice;
  final bool gst;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice['number']?.toString() ?? 'Invoice',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: navy,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                _money(_d(invoice['total'])),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: green,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_dateText(invoice['invoice_date'])}  ·  ${invoice['client_name'] ?? 'Walk-in Customer'}',
            style: const TextStyle(color: muted, fontSize: 10),
          ),
          const Divider(height: 16),
          if (gst)
            Row(
              children: [
                Expanded(
                  child: _MiniInvoiceValue(
                    'Taxable',
                    _money(_d(invoice['taxable_amount'])),
                  ),
                ),
                Expanded(
                  child: _MiniInvoiceValue(
                    'CGST',
                    _money(_d(invoice['cgst_amount'])),
                  ),
                ),
                Expanded(
                  child: _MiniInvoiceValue(
                    'SGST',
                    _money(_d(invoice['sgst_amount'])),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _MiniInvoiceValue(
                    'Customer',
                    invoice['client_name']?.toString() ?? 'Walk-in',
                  ),
                ),
                Expanded(
                  child: _MiniInvoiceValue(
                    'Status',
                    _statusText(invoice['status']?.toString() ?? ''),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _MiniInvoiceValue extends StatelessWidget {
  const _MiniInvoiceValue(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 8.5, color: muted)),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
    ],
  );
}

// ── Inventory Report ─────────────────────────────────────────────────────────
class _InventoryReportView extends StatelessWidget {
  const _InventoryReportView({required this.state, required this.products});
  final AdminState state;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    final inStock = products
        .where((p) => p['stock_status'] == 'in_stock')
        .length;
    final low = products.where((p) => p['stock_status'] == 'low_stock').length;
    final out = products
        .where((p) => p['stock_status'] == 'out_of_stock')
        .length;
    final value = products.fold<double>(
      0,
      (s, p) => s + _d(p['purchase_price']) * _d(p['stock_quantity']),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(
          items: [
            _Kpi('Total Products', '${products.length}', blue),
            _Kpi('In Stock', '$inStock', green),
            _Kpi('Low Stock', '$low', Colors.orange),
            _Kpi('Out of Stock', '$out', red),
          ],
        ),
        const SizedBox(height: 8),
        _KpiRow(
          items: [
            _Kpi('Inventory Cost', _money(value), const Color(0xFF00897B)),
          ],
        ),
        const SizedBox(height: 16),

        _SectionHead('Product Inventory (${products.length})'),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const _NoData('No products found.')
        else if (MediaQuery.sizeOf(context).width < 600)
          ...products.map((product) => _MobileInventoryCard(product: product))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Product', style: _th)),
                DataColumn(label: Text('SKU', style: _th)),
                DataColumn(label: Text('Category', style: _th)),
                DataColumn(label: Text('Stock', style: _th), numeric: true),
                DataColumn(label: Text('Min', style: _th), numeric: true),
                DataColumn(label: Text('Status', style: _th)),
                DataColumn(
                  label: Text('Cost Value', style: _th),
                  numeric: true,
                ),
              ],
              rows: products.map((p) {
                final stockVal =
                    _d(p['purchase_price']) * _d(p['stock_quantity']);
                return DataRow(
                  cells: [
                    DataCell(Text(p['name']?.toString() ?? '', style: _td)),
                    DataCell(Text(p['sku']?.toString() ?? '', style: _td)),
                    DataCell(
                      Text(p['category_name']?.toString() ?? '', style: _td),
                    ),
                    DataCell(Text('${p['stock_quantity'] ?? 0}', style: _td)),
                    DataCell(Text('${p['reorder_level'] ?? 0}', style: _td)),
                    DataCell(
                      Text(
                        _statusText(p['stock_status']?.toString() ?? ''),
                        style: _td,
                      ),
                    ),
                    DataCell(Text(_money(stockVal), style: _td)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Purchase Report ───────────────────────────────────────────────────────────
class _PurchaseReportView extends StatelessWidget {
  const _PurchaseReportView({required this.state, required this.orders});
  final AdminState state;
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o['status'] == 'pending').length;
    final approved = orders.where((o) => o['status'] == 'approved').length;
    final received = orders.where((o) => o['status'] == 'received').length;
    final totalValue = orders.fold<double>(0, (s, o) => s + _d(o['total']));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(
          items: [
            _Kpi('Total Orders', '${orders.length}', blue),
            _Kpi('Pending', '$pending', Colors.orange),
            _Kpi('Approved', '$approved', const Color(0xFF9C27B0)),
            _Kpi('Received', '$received', green),
          ],
        ),
        const SizedBox(height: 8),
        _KpiRow(
          items: [
            _Kpi(
              'Total Order Value',
              _money(totalValue),
              const Color(0xFF00897B),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionHead('Purchase Orders (${orders.length})'),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          const _NoData('No purchase orders found.')
        else if (MediaQuery.sizeOf(context).width < 600)
          ...orders.map((order) => _MobilePurchaseCard(order: order))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Order #', style: _th)),
                DataColumn(label: Text('Date', style: _th)),
                DataColumn(label: Text('Supplier', style: _th)),
                DataColumn(label: Text('Status', style: _th)),
                DataColumn(label: Text('Total', style: _th), numeric: true),
              ],
              rows: orders
                  .map(
                    (o) => DataRow(
                      cells: [
                        DataCell(
                          Text(o['number']?.toString() ?? '', style: _td),
                        ),
                        DataCell(Text(_dateText(o['order_date']), style: _td)),
                        DataCell(
                          Text(
                            o['supplier_name']?.toString() ?? '',
                            style: _td,
                          ),
                        ),
                        DataCell(
                          Text(
                            _statusText(o['status']?.toString() ?? ''),
                            style: _td,
                          ),
                        ),
                        DataCell(Text(_money(_d(o['total'])), style: _td)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _MobileInventoryCard extends StatelessWidget {
  const _MobileInventoryCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final quantity = _d(product['stock_quantity']);
    final cost = _d(product['purchase_price']) * quantity;
    final status = _statusText(product['stock_status']?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product['name']?.toString() ?? 'Product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: navy,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _money(cost),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${product['sku'] ?? 'No SKU'} · ${product['category_name'] ?? 'Uncategorized'}',
              style: const TextStyle(fontSize: 9.5, color: muted),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniInvoiceValue(
                    'Stock',
                    quantity.toStringAsFixed(0),
                  ),
                ),
                Expanded(
                  child: _MiniInvoiceValue(
                    'Minimum',
                    '${product['reorder_level'] ?? 0}',
                  ),
                ),
                Expanded(child: _MiniInvoiceValue('Status', status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilePurchaseCard extends StatelessWidget {
  const _MobilePurchaseCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['number']?.toString() ?? 'Purchase order',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: navy,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                _money(_d(order['total'])),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: green,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_dateText(order['order_date'] ?? order['created_at'])} · ${order['supplier_name'] ?? 'Supplier'}',
            style: const TextStyle(fontSize: 9.5, color: muted),
          ),
          const Divider(height: 16),
          _MiniInvoiceValue(
            'Status',
            _statusText(order['status']?.toString() ?? ''),
          ),
        ],
      ),
    ),
  );
}

// ── Profit & Loss ─────────────────────────────────────────────────────────────
class _ProfitLossView extends StatelessWidget {
  const _ProfitLossView({
    required this.state,
    required this.invoices,
    required this.products,
  });
  final AdminState state;
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    final paidInvoices = invoices.where(_isCompletedSale).toList();
    final netSales = paidInvoices.fold<double>(
      0,
      (s, inv) => s + _d(inv['taxable_amount']),
    );
    final taxCollected = paidInvoices.fold<double>(
      0,
      (s, inv) => s + _d(inv['cgst_amount']) + _d(inv['sgst_amount']),
    );

    final cogs = _estimatedCogs(paidInvoices, products);
    final discounts = paidInvoices.fold<double>(
      0,
      (s, inv) => s + _d(inv['discount_amount']),
    );
    final grossProfit = netSales - cogs;
    final grossMargin = netSales <= 0 ? 0.0 : grossProfit / netSales * 100;

    // Product-level margin
    final productMargins =
        products.where((p) => _d(p['selling_price']) > 0).map((p) {
          final sell = _d(p['selling_price']);
          final buy = _d(p['purchase_price']);
          final margin = sell > 0 ? ((sell - buy) / sell * 100) : 0.0;
          return MapEntry(p, margin);
        }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(
          items: [
            _Kpi('Net Sales', _money(netSales), green),
            _Kpi('Estimated COGS', _money(cogs), red),
            _Kpi(
              'Gross Profit',
              _money(grossProfit),
              grossProfit >= 0 ? green : red,
            ),
            _Kpi(
              'Gross Margin',
              '${grossMargin.toStringAsFixed(1)}%',
              grossMargin >= 0 ? green : red,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _KpiRow(
          items: [
            _Kpi(
              'Tax Collected',
              _money(taxCollected),
              const Color(0xFF9C27B0),
            ),
            _Kpi('Discounts', _money(discounts), Colors.orange),
          ],
        ),
        const SizedBox(height: 16),

        _SectionHead('Current Catalog Product Margins (Top 20)'),
        const SizedBox(height: 8),
        if (productMargins.isEmpty)
          const _NoData('No products to analyse.')
        else if (MediaQuery.sizeOf(context).width < 600)
          ...productMargins
              .take(20)
              .map((entry) => _MobileMarginCard(entry: entry))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Product', style: _th)),
                DataColumn(label: Text('Buy ₹', style: _th), numeric: true),
                DataColumn(label: Text('Sell ₹', style: _th), numeric: true),
                DataColumn(label: Text('Margin %', style: _th), numeric: true),
              ],
              rows: productMargins.take(20).map((e) {
                final p = e.key;
                final m = e.value;
                return DataRow(
                  cells: [
                    DataCell(Text(p['name']?.toString() ?? '', style: _td)),
                    DataCell(Text(_money(_d(p['purchase_price'])), style: _td)),
                    DataCell(Text(_money(_d(p['selling_price'])), style: _td)),
                    DataCell(
                      Text(
                        '${m.toStringAsFixed(1)}%',
                        style: _td.copyWith(
                          color: m >= 20
                              ? green
                              : m >= 10
                              ? Colors.orange
                              : red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Stock Valuation ───────────────────────────────────────────────────────────
class _StockValuationView extends StatelessWidget {
  const _StockValuationView({required this.state, required this.products});
  final AdminState state;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    final valuedProducts =
        products.where((p) => _d(p['stock_quantity']) > 0).toList()..sort(
          (a, b) => (_d(b['purchase_price']) * _d(b['stock_quantity']))
              .compareTo(_d(a['purchase_price']) * _d(a['stock_quantity'])),
        );

    final totalCost = valuedProducts.fold<double>(
      0,
      (s, p) => s + _d(p['purchase_price']) * _d(p['stock_quantity']),
    );
    final totalRetail = valuedProducts.fold<double>(
      0,
      (s, p) => s + _d(p['selling_price']) * _d(p['stock_quantity']),
    );
    final potentialProfit = totalRetail - totalCost;

    // Group by category
    final catMap = <String, double>{};
    for (final p in valuedProducts) {
      final cat = p['category_name']?.toString() ?? 'Uncategorized';
      catMap[cat] =
          (catMap[cat] ?? 0) +
          _d(p['purchase_price']) * _d(p['stock_quantity']);
    }
    final catList = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(
          items: [
            _Kpi('Stock Items', '${valuedProducts.length}', blue),
            _Kpi('Cost Value', _money(totalCost), red),
            _Kpi('Retail Value', _money(totalRetail), green),
            _Kpi(
              'Potential Profit',
              _money(potentialProfit),
              const Color(0xFF9C27B0),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionHead('Value by Category'),
        const SizedBox(height: 8),
        ...catList.map((e) => _LabelValueRow(e.key, _money(e.value))),
        const SizedBox(height: 16),

        _SectionHead('Stock Valuation Detail'),
        const SizedBox(height: 8),
        if (valuedProducts.isEmpty)
          const _NoData('No stock in hand.')
        else if (MediaQuery.sizeOf(context).width < 600)
          ...valuedProducts.map(
            (product) => _MobileStockValuationCard(product: product),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Product', style: _th)),
                DataColumn(label: Text('Qty', style: _th), numeric: true),
                DataColumn(label: Text('Cost ₹', style: _th), numeric: true),
                DataColumn(label: Text('Retail ₹', style: _th), numeric: true),
                DataColumn(
                  label: Text('Cost Value', style: _th),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Retail Value', style: _th),
                  numeric: true,
                ),
              ],
              rows: valuedProducts.map((p) {
                final qty = _d(p['stock_quantity']);
                final cost = _d(p['purchase_price']);
                final sell = _d(p['selling_price']);
                return DataRow(
                  cells: [
                    DataCell(Text(p['name']?.toString() ?? '', style: _td)),
                    DataCell(Text(qty.toStringAsFixed(0), style: _td)),
                    DataCell(Text(_money(cost), style: _td)),
                    DataCell(Text(_money(sell), style: _td)),
                    DataCell(Text(_money(cost * qty), style: _td)),
                    DataCell(Text(_money(sell * qty), style: _td)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _MobileMarginCard extends StatelessWidget {
  const _MobileMarginCard({required this.entry});
  final MapEntry<Map<String, dynamic>, double> entry;

  @override
  Widget build(BuildContext context) {
    final product = entry.key;
    final margin = entry.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? 'Product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: navy,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Buy ${_money(_d(product['purchase_price']))}  ·  Sell ${_money(_d(product['selling_price']))}',
                    style: const TextStyle(fontSize: 9.5, color: muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: (margin >= 20 ? green : Colors.orange).withValues(
                  alpha: .10,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${margin.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: margin >= 20 ? green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileStockValuationCard extends StatelessWidget {
  const _MobileStockValuationCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final quantity = _d(product['stock_quantity']);
    final cost = _d(product['purchase_price']);
    final retail = _d(product['selling_price']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name']?.toString() ?? 'Product',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: navy,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product['category_name'] ?? 'Uncategorized'} · Qty ${quantity.toStringAsFixed(0)}',
              style: const TextStyle(color: muted, fontSize: 9.5),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniInvoiceValue(
                    'Cost value',
                    _money(cost * quantity),
                  ),
                ),
                Expanded(
                  child: _MiniInvoiceValue(
                    'Retail value',
                    _money(retail * quantity),
                  ),
                ),
                Expanded(
                  child: _MiniInvoiceValue(
                    'Potential',
                    _money((retail - cost) * quantity),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────
class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.state,
    required this.invoices,
    required this.onNavigate,
  });
  final AdminState state;
  final List<Map<String, dynamic>> invoices;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final completed = invoices.where(_isCompletedSale).toList();
    final netSales = completed.fold<double>(
      0,
      (sum, row) => sum + _d(row['taxable_amount']),
    );
    final billed = completed.fold<double>(
      0,
      (sum, row) => sum + _d(row['total']),
    );
    final tax = completed.fold<double>(
      0,
      (sum, row) => sum + _d(row['cgst_amount']) + _d(row['sgst_amount']),
    );
    final discounts = completed.fold<double>(
      0,
      (sum, row) => sum + _d(row['discount_amount']),
    );
    final average = completed.isEmpty ? 0.0 : billed / completed.length;
    final lowStock = state.products
        .where((row) => row['stock_status'] == 'low_stock')
        .length;
    final outOfStock = state.products
        .where((row) => row['stock_status'] == 'out_of_stock')
        .length;
    final pendingOrders = state.purchaseOrders
        .where((row) => row['status'] == 'pending')
        .length;
    final pendingDiscounts = state.discountApprovals
        .where((row) => row['status'] == 'pending')
        .length;
    final overdue =
        int.tryParse(
          state.dashboard['overdue_invoice_count']?.toString() ?? '',
        ) ??
        0;
    final issueCount =
        lowStock + outOfStock + pendingOrders + pendingDiscounts + overdue;
    final health =
        (100 -
                (lowStock > 0 ? 12 : 0) -
                (outOfStock > 0 ? 20 : 0) -
                (pendingOrders > 0 ? 10 : 0) -
                (pendingDiscounts > 0 ? 8 : 0) -
                (overdue > 0 ? 15 : 0))
            .clamp(0, 100);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        SectionCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: health / 100,
                      strokeWidth: 7,
                      backgroundColor: line,
                      color: health >= 80
                          ? green
                          : health >= 55
                          ? Colors.orange
                          : red,
                    ),
                    Text(
                      '$health',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Health',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      issueCount == 0
                          ? 'Everything looks healthy. No pending action.'
                          : '$issueCount items need your attention.',
                      style: const TextStyle(fontSize: 10.5, color: muted),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (issueCount == 0 ? green : Colors.orange)
                            .withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        issueCount == 0 ? 'All clear' : 'Action required',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: issueCount == 0 ? green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHead('Period Performance'),
        const SizedBox(height: 9),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: 2.05,
          children: [
            _SummaryMetricCard(
              'Net Sales',
              _money(netSales),
              Icons.payments_rounded,
              green,
            ),
            _SummaryMetricCard(
              'Bills',
              '${completed.length}',
              Icons.receipt_long_rounded,
              blue,
            ),
            _SummaryMetricCard(
              'Avg Bill',
              _money(average),
              Icons.analytics_outlined,
              violet,
            ),
            _SummaryMetricCard(
              'Tax Collected',
              _money(tax),
              Icons.account_balance_rounded,
              const Color(0xFF9C27B0),
            ),
            _SummaryMetricCard(
              'Discounts',
              _money(discounts),
              Icons.discount_rounded,
              Colors.orange,
            ),
            _SummaryMetricCard(
              'Total Billed',
              _money(billed),
              Icons.currency_rupee_rounded,
              navy,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: _SectionHead('Action Required')),
            Text(
              '$issueCount pending',
              style: const TextStyle(fontSize: 9.5, color: muted),
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (issueCount == 0)
          const _SummaryAllClear()
        else ...[
          if (lowStock + outOfStock > 0)
            _SummaryActionTile(
              icon: Icons.inventory_2_outlined,
              color: red,
              title: 'Stock attention',
              subtitle: '$lowStock low stock · $outOfStock out of stock',
              onTap: () => onNavigate(9),
            ),
          if (pendingOrders > 0)
            _SummaryActionTile(
              icon: Icons.shopping_cart_checkout_rounded,
              color: Colors.orange,
              title: 'Purchase approvals',
              subtitle: '$pendingOrders orders waiting for approval',
              onTap: () => onNavigate(8),
            ),
          if (pendingDiscounts > 0)
            _SummaryActionTile(
              icon: Icons.discount_outlined,
              color: violet,
              title: 'Discount approvals',
              subtitle: '$pendingDiscounts requests waiting for decision',
              onTap: () => onNavigate(11),
            ),
          if (overdue > 0)
            _SummaryActionTile(
              icon: Icons.pending_actions_rounded,
              color: red,
              title: 'Overdue invoices',
              subtitle: '$overdue bills require follow-up',
              onTap: () => onNavigate(13),
            ),
        ],
        const SizedBox(height: 18),
        const _SectionHead('Current Business Snapshot'),
        const SizedBox(height: 9),
        _SummarySectionCard(
          title: 'Catalog & Stock',
          icon: Icons.inventory_2_rounded,
          color: green,
          rows: [
            ('Products', '${state.products.length}'),
            ('Categories', '${state.categories.length}'),
            ('Suppliers', '${state.suppliers.length}'),
            ('Low / Out of stock', '$lowStock / $outOfStock'),
          ],
        ),
        const SizedBox(height: 9),
        _SummarySectionCard(
          title: 'Billing & Collections',
          icon: Icons.account_balance_wallet_rounded,
          color: blue,
          rows: [
            ('All invoices', '${state.invoices.length}'),
            ('Outstanding', _money(state.dashboard['outstanding_total'])),
            ('Overdue invoices', '$overdue'),
            ('Returns total', _money(state.dashboard['returns_total'])),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionHead('Quick Workflow'),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _SummaryQuickAction(
                icon: Icons.add_shopping_cart_rounded,
                label: 'New Bill',
                color: blue,
                onTap: () => onNavigate(10),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryQuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                color: green,
                onTap: () => onNavigate(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryQuickAction(
                icon: Icons.bar_chart_rounded,
                label: 'Sales',
                color: violet,
                onTap: () => onNavigate(17),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(fontSize: 8.5, color: muted),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SummaryActionTile extends StatelessWidget {
  const _SummaryActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SectionCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 9.5)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ),
      ),
    ),
  );
}

class _SummaryAllClear extends StatelessWidget {
  const _SummaryAllClear();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: green.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: green.withValues(alpha: .18)),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle_rounded, color: green),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'No pending approvals, stock alerts or overdue bills.',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: green,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummarySectionCard extends StatelessWidget {
  const _SummarySectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
          ],
        ),
        const Divider(height: 20),
        ...rows.map((row) => _LabelValueRow(row.$1, row.$2)),
      ],
    ),
  );
}

class _SummaryQuickAction extends StatelessWidget {
  const _SummaryQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings tab
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHead('Store Settings'),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: state.settingsDraft['invoice_prefix']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Invoice Prefix',
            prefixIcon: Icon(Icons.tag, size: 18),
          ),
          onChanged: (v) => state.updateSetting('invoice_prefix', v),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['default_gst'] == null
              ? null
              : _percent(state.settingsDraft['default_gst'], 0),
          decoration: const InputDecoration(labelText: 'Default GST'),
          items: [
            '0%',
            '5%',
            '12%',
            '18%',
            '28%',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) =>
              state.updateSetting('default_gst', v?.replaceAll('%', '')),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['max_cashier_discount'] == null
              ? null
              : _percent(state.settingsDraft['max_cashier_discount'], 0),
          decoration: const InputDecoration(labelText: 'Max Cashier Discount'),
          items: [
            '5%',
            '10%',
            '15%',
            '20%',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => state.updateSetting(
            'max_cashier_discount',
            v?.replaceAll('%', ''),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['approval_threshold'] == null
              ? null
              : _percent(state.settingsDraft['approval_threshold'], 0),
          decoration: const InputDecoration(labelText: 'Approval Threshold'),
          items: [
            '5%',
            '10%',
            '15%',
            '20%',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) =>
              state.updateSetting('approval_threshold', v?.replaceAll('%', '')),
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: state.settingsDraft['round_off']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Round Off',
            hintText: '0.01',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => state.updateSetting('round_off', v.trim()),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'WhatsApp Notifications',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Send invoice links via WhatsApp after billing.',
            style: TextStyle(fontSize: 11),
          ),
          value: state.settingsDraft['whatsapp_enabled'] == true,
          onChanged: (v) => state.updateSetting('whatsapp_enabled', v),
        ),

        const SizedBox(height: 20),

        PrimaryAction(
          'Save Settings',
          icon: Icons.save_outlined,
          onPressed: () async {
            try {
              await state.saveStoreSettings(state.settingsDraft);
              if (context.mounted) {
                showNotice(context, 'Store settings saved successfully.');
              }
            } catch (e) {
              if (context.mounted) showNotice(context, e.toString());
            }
          },
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        _SectionHead('Quick Navigation'),
        const SizedBox(height: 10),

        _NavRow(
          Icons.assignment_return_outlined,
          'Returns & Refunds',
          () => state.go(12),
        ),
        _NavRow(
          Icons.receipt_long_outlined,
          'WhatsApp Invoices',
          () => state.go(13),
        ),
        _NavRow(
          Icons.admin_panel_settings_outlined,
          'Roles & Permissions',
          () => state.go(3),
        ),
        _NavRow(
          Icons.security_outlined,
          'Audit Log & Logout',
          () => state.go(15),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV builders
// ─────────────────────────────────────────────────────────────────────────────

String _cell(dynamic v) {
  final t = v?.toString() ?? '';
  return '"${t.replaceAll('"', '""')}"';
}

String _buildInvoiceCsv(AdminState state) {
  final rows = [
    [
      'Invoice',
      'Date',
      'Customer',
      'Status',
      'Taxable',
      'CGST',
      'SGST',
      'Discount',
      'Total',
    ],
    ...state.invoices.map(
      (inv) => [
        inv['number'],
        inv['invoice_date'],
        inv['client_name'],
        inv['status'],
        inv['taxable_amount'],
        inv['cgst_amount'],
        inv['sgst_amount'],
        inv['discount_amount'],
        inv['total'],
      ],
    ),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildProductsCsv(
  AdminState state, [
  List<Map<String, dynamic>>? filteredProducts,
]) {
  final products = filteredProducts ?? state.products;
  final rows = [
    [
      'Name',
      'SKU',
      'Category',
      'Unit',
      'Purchase Price',
      'Selling Price',
      'MRP',
      'GST%',
      'Stock',
      'Min Stock',
      'Status',
    ],
    ...products.map(
      (p) => [
        p['name'],
        p['sku'],
        p['category_name'],
        p['unit'],
        p['purchase_price'],
        p['selling_price'],
        p['mrp'] ?? '',
        p['tax_percent'],
        p['stock_quantity'],
        p['reorder_level'],
        p['stock_status'],
      ],
    ),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildPurchaseCsv(
  AdminState state, [
  List<Map<String, dynamic>>? filteredOrders,
]) {
  final orders = filteredOrders ?? state.purchaseOrders;
  final rows = [
    ['Order #', 'Date', 'Supplier', 'Status', 'Subtotal', 'Tax', 'Total'],
    ...orders.map(
      (o) => [
        o['number'],
        o['order_date'],
        o['supplier_name'],
        o['status'],
        o['subtotal'],
        o['tax_amount'],
        o['total'],
      ],
    ),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildSalesCsv(
  AdminState state, [
  List<Map<String, dynamic>>? filteredInvoices,
]) {
  final invoices = filteredInvoices ?? state.invoices;
  final rows = [
    [
      'Invoice',
      'Date',
      'Customer',
      'Status',
      'Taxable',
      'CGST',
      'SGST',
      'Discount',
      'Total',
    ],
    ...invoices.map(
      (inv) => [
        inv['number'],
        inv['invoice_date'],
        inv['client_name'],
        inv['status'],
        inv['taxable_amount'],
        inv['cgst_amount'],
        inv['sgst_amount'],
        inv['discount_amount'],
        inv['total'],
      ],
    ),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildGstCsv(
  AdminState state, [
  List<Map<String, dynamic>>? filteredInvoices,
]) {
  final invoices = filteredInvoices ?? state.invoices;
  final rows = [
    ['Invoice', 'Date', 'Taxable Amount', 'CGST', 'SGST', 'Total'],
    ...invoices.map(
      (inv) => [
        inv['number'],
        inv['invoice_date'],
        inv['taxable_amount'],
        inv['cgst_amount'],
        inv['sgst_amount'],
        inv['total'],
      ],
    ),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildProfitLossCsv(
  AdminState state, {
  List<Map<String, dynamic>>? invoices,
  List<Map<String, dynamic>>? products,
}) {
  final reportInvoices = (invoices ?? state.invoices)
      .where(_isCompletedSale)
      .toList();
  final reportProducts = products ?? state.products;
  final netSales = reportInvoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['taxable_amount']),
  );
  final cogs = _estimatedCogs(reportInvoices, reportProducts);
  final tax = reportInvoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['cgst_amount']) + _d(row['sgst_amount']),
  );
  final discount = reportInvoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['discount_amount']),
  );
  final rows = [
    ['Profit & Loss Summary', 'Value'],
    ['Paid Invoices', reportInvoices.length],
    ['Net Sales (excluding GST)', netSales.toStringAsFixed(2)],
    ['Estimated COGS', cogs.toStringAsFixed(2)],
    ['Gross Profit', (netSales - cogs).toStringAsFixed(2)],
    ['Tax Collected', tax.toStringAsFixed(2)],
    ['Discounts', discount.toStringAsFixed(2)],
    <dynamic>[],
    ['Product', 'SKU', 'Purchase Price', 'Selling Price', 'Margin %'],
    ...reportProducts.map((p) {
      final sell = _d(p['selling_price']);
      final buy = _d(p['purchase_price']);
      final margin = sell > 0 ? ((sell - buy) / sell * 100) : 0.0;
      return [
        p['name'],
        p['sku'],
        p['purchase_price'],
        p['selling_price'],
        '${margin.toStringAsFixed(2)}%',
      ];
    }),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildStockValuationCsv(
  AdminState state, [
  List<Map<String, dynamic>>? filteredProducts,
]) {
  final products = filteredProducts ?? state.products;
  final rows = [
    [
      'Product',
      'SKU',
      'Category',
      'Qty',
      'Cost Price',
      'Retail Price',
      'Cost Value',
      'Retail Value',
    ],
    ...products.map((p) {
      final qty = _d(p['stock_quantity']);
      final cost = _d(p['purchase_price']);
      final sell = _d(p['selling_price']);
      return [
        p['name'],
        p['sku'],
        p['category_name'],
        p['stock_quantity'],
        p['purchase_price'],
        p['selling_price'],
        (cost * qty).toStringAsFixed(2),
        (sell * qty).toStringAsFixed(2),
      ];
    }),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildSummaryCsv(
  AdminState state, [
  List<Map<String, dynamic>>? filteredInvoices,
]) {
  final invoices = (filteredInvoices ?? state.invoices)
      .where(_isCompletedSale)
      .toList();
  final netSales = invoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['taxable_amount']),
  );
  final billed = invoices.fold<double>(0, (sum, row) => sum + _d(row['total']));
  final tax = invoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['cgst_amount']) + _d(row['sgst_amount']),
  );
  final rows = [
    ['Metric', 'Value'],
    ['Period Net Sales', netSales.toStringAsFixed(2)],
    ['Period Total Billed', billed.toStringAsFixed(2)],
    ['Period Bills', '${invoices.length}'],
    ['Period Tax', tax.toStringAsFixed(2)],
    [
      'Period Average Bill',
      (invoices.isEmpty ? 0 : billed / invoices.length).toStringAsFixed(2),
    ],
    ['Total Products', '${state.products.length}'],
    ['Total Invoices', '${state.invoices.length}'],
    ['Low Stock Items', '${state.dashboard['low_stock_count'] ?? 0}'],
    ['Outstanding Total', _money(state.dashboard['outstanding_total'])],
    [
      'Pending Purchase Orders',
      '${state.purchaseOrders.where((o) => o['status'] == 'pending').length}',
    ],
    [
      'Pending Discount Approvals',
      '${state.discountApprovals.where((d) => d['status'] == 'pending').length}',
    ],
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

// ─────────────────────────────────────────────────────────────────────────────
// Share / copy helper
// ─────────────────────────────────────────────────────────────────────────────

void _shareText(
  BuildContext context,
  String text,
  String filename,
  String successMessage,
) {
  Clipboard.setData(ClipboardData(text: text)).then((_) {
    if (context.mounted) showNotice(context, successMessage);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI helpers
// ─────────────────────────────────────────────────────────────────────────────

const _th = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navy);
final _td = const TextStyle(fontSize: 11, color: ink);

double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.items});
  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) => Row(
    children: items
        .map(
          (k) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SectionCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        k.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: k.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _Kpi {
  const _Kpi(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: navy,
    ),
  );
}

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ],
    ),
  );
}

class _NoData extends StatelessWidget {
  const _NoData(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(message, style: const TextStyle(color: muted, fontSize: 12)),
    ),
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: blue, size: 20),
    title: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.chevron_right, color: muted, size: 20),
    onTap: onTap,
  );
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: SectionCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    icon: Icon(icon, color: color, size: 18),
    label: Text(
      label,
      style: const TextStyle(
        color: ink,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
