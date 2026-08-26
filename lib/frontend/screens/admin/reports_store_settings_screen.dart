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
    _shareText(context, csv, 'invoices.csv',
        '${state.invoices.length} invoice rows copied as CSV');
  }

  void _exportProductsCsv(BuildContext context, AdminState state) {
    final csv = _buildProductsCsv(state);
    _shareText(context, csv, 'products.csv',
        '${state.products.length} product rows copied as CSV');
  }

  void _exportPurchaseCsv(BuildContext context, AdminState state) {
    final csv = _buildPurchaseCsv(state);
    _shareText(context, csv, 'purchase_orders.csv',
        '${state.purchaseOrders.length} purchase order rows copied as CSV');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report detail page — full screen with tabs and copy/share
// ─────────────────────────────────────────────────────────────────────────────

enum _ReportType { sales, gst, inventory, purchase, profitLoss, stockValuation, summary }

class _ReportDetailPage extends StatelessWidget {
  const _ReportDetailPage({required this.state, required this.type});
  final AdminState state;
  final _ReportType type;

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
    _ReportType.sales => _buildSalesCsv(state),
    _ReportType.gst => _buildGstCsv(state),
    _ReportType.inventory => _buildProductsCsv(state),
    _ReportType.purchase => _buildPurchaseCsv(state),
    _ReportType.profitLoss => _buildProfitLossCsv(state),
    _ReportType.stockValuation => _buildStockValuationCsv(state),
    _ReportType.summary => _buildSummaryCsv(state),
  };

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(_title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Copy as CSV',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _shareText(context, _csv, '${_title.toLowerCase().replaceAll(' ', '_')}.csv',
                '$_title copied to clipboard'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _buildContent() => switch (type) {
    _ReportType.sales => _SalesReportView(state: state),
    _ReportType.gst => _GstReportView(state: state),
    _ReportType.inventory => _InventoryReportView(state: state),
    _ReportType.purchase => _PurchaseReportView(state: state),
    _ReportType.profitLoss => _ProfitLossView(state: state),
    _ReportType.stockValuation => _StockValuationView(state: state),
    _ReportType.summary => _SummaryView(state: state),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual report views
// ─────────────────────────────────────────────────────────────────────────────

// ── Sales Report ─────────────────────────────────────────────────────────────
class _SalesReportView extends StatelessWidget {
  const _SalesReportView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final invoices = state.invoices;
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
        _KpiRow(items: [
          _Kpi('Total Invoices', '${invoices.length}', blue),
          _Kpi('Total Sales', _money(totalSales), green),
          _Kpi('Total Tax', _money(totalTax), const Color(0xFF9C27B0)),
          _Kpi('Discounts', _money(totalDiscount), Colors.orange),
        ]),
        const SizedBox(height: 16),

        // ── Status breakdown ───────────────────────────────────────────
        _SectionHead('Sales by Status'),
        const SizedBox(height: 8),
        ...statusMap.entries.map((e) => _LabelValueRow(
              _statusText(e.key),
              '${e.value} invoices',
            )),
        const SizedBox(height: 16),

        // ── Invoice table ──────────────────────────────────────────────
        _SectionHead('Invoice List (${invoices.length})'),
        const SizedBox(height: 8),
        if (invoices.isEmpty)
          const _NoData('No invoices found.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStatePropertyAll(
                const Color(0xFFF0F4FF),
              ),
              columns: const [
                DataColumn(label: Text('Invoice', style: _th)),
                DataColumn(label: Text('Date', style: _th)),
                DataColumn(label: Text('Customer', style: _th)),
                DataColumn(label: Text('Status', style: _th)),
                DataColumn(label: Text('Total', style: _th), numeric: true),
              ],
              rows: invoices.map((inv) => DataRow(cells: [
                DataCell(Text(inv['number']?.toString() ?? '', style: _td)),
                DataCell(Text(_dateText(inv['invoice_date']), style: _td)),
                DataCell(Text(inv['client_name']?.toString() ?? '', style: _td)),
                DataCell(Text(_statusText(inv['status']?.toString() ?? ''), style: _td)),
                DataCell(Text(_money(_d(inv['total'])), style: _td)),
              ])).toList(),
            ),
          ),
      ],
    );
  }
}

// ── GST Report ───────────────────────────────────────────────────────────────
class _GstReportView extends StatelessWidget {
  const _GstReportView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final invoices = state.invoices;
    double taxable = 0, cgst = 0, sgst = 0, total = 0;
    for (final inv in invoices) {
      taxable += _d(inv['taxable_amount']);
      cgst += _d(inv['cgst_amount']);
      sgst += _d(inv['sgst_amount']);
      total += _d(inv['total']);
    }

    // Group by tax slab from products
    final slabMap = <String, double>{};
    for (final p in state.products) {
      final slab = '${_d(p['tax_percent']).toStringAsFixed(0)}%';
      final val = _d(p['selling_price']) * _d(p['stock_quantity']);
      slabMap[slab] = (slabMap[slab] ?? 0) + val;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(items: [
          _Kpi('Taxable Amount', _money(taxable), blue),
          _Kpi('CGST Collected', _money(cgst), const Color(0xFF9C27B0)),
          _Kpi('SGST Collected', _money(sgst), const Color(0xFF9C27B0)),
          _Kpi('Invoice Total', _money(total), green),
        ]),
        const SizedBox(height: 16),

        _SectionHead('GST by Slab (Catalog Value)'),
        const SizedBox(height: 8),
        ...slabMap.entries.map((e) => _LabelValueRow(
              'GST ${e.key}',
              _money(e.value),
            )),
        const SizedBox(height: 16),

        _SectionHead('Invoice GST Details (${invoices.length})'),
        const SizedBox(height: 8),
        if (invoices.isEmpty)
          const _NoData('No invoices found.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor:
                  WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Invoice', style: _th)),
                DataColumn(label: Text('Date', style: _th)),
                DataColumn(label: Text('Taxable', style: _th), numeric: true),
                DataColumn(label: Text('CGST', style: _th), numeric: true),
                DataColumn(label: Text('SGST', style: _th), numeric: true),
                DataColumn(label: Text('Total', style: _th), numeric: true),
              ],
              rows: invoices.map((inv) => DataRow(cells: [
                DataCell(Text(inv['number']?.toString() ?? '', style: _td)),
                DataCell(Text(_dateText(inv['invoice_date']), style: _td)),
                DataCell(Text(_money(_d(inv['taxable_amount'])), style: _td)),
                DataCell(Text(_money(_d(inv['cgst_amount'])), style: _td)),
                DataCell(Text(_money(_d(inv['sgst_amount'])), style: _td)),
                DataCell(Text(_money(_d(inv['total'])), style: _td)),
              ])).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Inventory Report ─────────────────────────────────────────────────────────
class _InventoryReportView extends StatelessWidget {
  const _InventoryReportView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    final inStock = products.where((p) => p['stock_status'] == 'in_stock').length;
    final low = products.where((p) => p['stock_status'] == 'low_stock').length;
    final out = products.where((p) => p['stock_status'] == 'out_of_stock').length;
    final value = products.fold<double>(0, (s, p) =>
        s + _d(p['purchase_price']) * _d(p['stock_quantity']));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(items: [
          _Kpi('Total Products', '${products.length}', blue),
          _Kpi('In Stock', '$inStock', green),
          _Kpi('Low Stock', '$low', Colors.orange),
          _Kpi('Out of Stock', '$out', red),
        ]),
        const SizedBox(height: 8),
        _KpiRow(items: [
          _Kpi('Inventory Cost', _money(value), const Color(0xFF00897B)),
        ]),
        const SizedBox(height: 16),

        _SectionHead('Product Inventory (${products.length})'),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const _NoData('No products found.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor:
                  WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Product', style: _th)),
                DataColumn(label: Text('SKU', style: _th)),
                DataColumn(label: Text('Category', style: _th)),
                DataColumn(label: Text('Stock', style: _th), numeric: true),
                DataColumn(label: Text('Min', style: _th), numeric: true),
                DataColumn(label: Text('Status', style: _th)),
                DataColumn(label: Text('Cost Value', style: _th), numeric: true),
              ],
              rows: products.map((p) {
                final stockVal = _d(p['purchase_price']) * _d(p['stock_quantity']);
                return DataRow(cells: [
                  DataCell(Text(p['name']?.toString() ?? '', style: _td)),
                  DataCell(Text(p['sku']?.toString() ?? '', style: _td)),
                  DataCell(Text(p['category_name']?.toString() ?? '', style: _td)),
                  DataCell(Text('${p['stock_quantity'] ?? 0}', style: _td)),
                  DataCell(Text('${p['reorder_level'] ?? 0}', style: _td)),
                  DataCell(Text(_statusText(p['stock_status']?.toString() ?? ''), style: _td)),
                  DataCell(Text(_money(stockVal), style: _td)),
                ]);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Purchase Report ───────────────────────────────────────────────────────────
class _PurchaseReportView extends StatelessWidget {
  const _PurchaseReportView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final orders = state.purchaseOrders;
    final pending = orders.where((o) => o['status'] == 'pending').length;
    final approved = orders.where((o) => o['status'] == 'approved').length;
    final received = orders.where((o) => o['status'] == 'received').length;
    final totalValue = orders.fold<double>(0, (s, o) => s + _d(o['total']));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(items: [
          _Kpi('Total Orders', '${orders.length}', blue),
          _Kpi('Pending', '$pending', Colors.orange),
          _Kpi('Approved', '$approved', const Color(0xFF9C27B0)),
          _Kpi('Received', '$received', green),
        ]),
        const SizedBox(height: 8),
        _KpiRow(items: [
          _Kpi('Total Order Value', _money(totalValue), const Color(0xFF00897B)),
        ]),
        const SizedBox(height: 16),

        _SectionHead('Purchase Orders (${orders.length})'),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          const _NoData('No purchase orders found.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor:
                  WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Order #', style: _th)),
                DataColumn(label: Text('Date', style: _th)),
                DataColumn(label: Text('Supplier', style: _th)),
                DataColumn(label: Text('Status', style: _th)),
                DataColumn(label: Text('Total', style: _th), numeric: true),
              ],
              rows: orders.map((o) => DataRow(cells: [
                DataCell(Text(o['number']?.toString() ?? '', style: _td)),
                DataCell(Text(_dateText(o['order_date']), style: _td)),
                DataCell(Text(o['supplier_name']?.toString() ?? '', style: _td)),
                DataCell(Text(_statusText(o['status']?.toString() ?? ''), style: _td)),
                DataCell(Text(_money(_d(o['total'])), style: _td)),
              ])).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Profit & Loss ─────────────────────────────────────────────────────────────
class _ProfitLossView extends StatelessWidget {
  const _ProfitLossView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    // Revenue from paid invoices
    final paidInvoices = state.invoices
        .where((inv) => inv['status'] == 'paid' || inv['status'] == 'partial');
    final revenue = paidInvoices.fold<double>(0, (s, inv) => s + _d(inv['total']));
    final taxCollected = paidInvoices.fold<double>(
        0, (s, inv) => s + _d(inv['cgst_amount']) + _d(inv['sgst_amount']));

    // Cost of goods from purchase orders received
    final cogs = state.purchaseOrders
        .where((o) => o['status'] == 'received')
        .fold<double>(0, (s, o) => s + _d(o['total']));

    // Inventory holding cost
    final inventoryCost = state.products.fold<double>(
        0, (s, p) => s + _d(p['purchase_price']) * _d(p['stock_quantity']));

    final grossProfit = revenue - cogs;
    final netProfit = _d(state.dashboard['profit']);

    // Product-level margin
    final productMargins = state.products
        .where((p) => _d(p['selling_price']) > 0)
        .map((p) {
          final sell = _d(p['selling_price']);
          final buy = _d(p['purchase_price']);
          final margin = sell > 0 ? ((sell - buy) / sell * 100) : 0.0;
          return MapEntry(p, margin);
        })
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(items: [
          _Kpi('Revenue', _money(revenue), green),
          _Kpi('COGS', _money(cogs), red),
          _Kpi('Gross Profit', _money(grossProfit),
              grossProfit >= 0 ? green : red),
          _Kpi("Today's Profit", _money(netProfit),
              netProfit >= 0 ? green : red),
        ]),
        const SizedBox(height: 8),
        _KpiRow(items: [
          _Kpi('Tax Collected', _money(taxCollected), const Color(0xFF9C27B0)),
          _Kpi('Inventory Value', _money(inventoryCost), Colors.orange),
        ]),
        const SizedBox(height: 16),

        _SectionHead('Product Margin (Top 20)'),
        const SizedBox(height: 8),
        if (productMargins.isEmpty)
          const _NoData('No products to analyse.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor:
                  WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Product', style: _th)),
                DataColumn(label: Text('Buy ₹', style: _th), numeric: true),
                DataColumn(label: Text('Sell ₹', style: _th), numeric: true),
                DataColumn(label: Text('Margin %', style: _th), numeric: true),
              ],
              rows: productMargins.take(20).map((e) {
                final p = e.key;
                final m = e.value;
                return DataRow(cells: [
                  DataCell(Text(p['name']?.toString() ?? '', style: _td)),
                  DataCell(Text(_money(_d(p['purchase_price'])), style: _td)),
                  DataCell(Text(_money(_d(p['selling_price'])), style: _td)),
                  DataCell(Text('${m.toStringAsFixed(1)}%',
                      style: _td.copyWith(
                          color: m >= 20 ? green : m >= 10 ? Colors.orange : red))),
                ]);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Stock Valuation ───────────────────────────────────────────────────────────
class _StockValuationView extends StatelessWidget {
  const _StockValuationView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products
        .where((p) => _d(p['stock_quantity']) > 0)
        .toList()
      ..sort((a, b) =>
          (_d(b['purchase_price']) * _d(b['stock_quantity']))
              .compareTo(_d(a['purchase_price']) * _d(a['stock_quantity'])));

    final totalCost = products.fold<double>(
        0, (s, p) => s + _d(p['purchase_price']) * _d(p['stock_quantity']));
    final totalRetail = products.fold<double>(
        0, (s, p) => s + _d(p['selling_price']) * _d(p['stock_quantity']));
    final potentialProfit = totalRetail - totalCost;

    // Group by category
    final catMap = <String, double>{};
    for (final p in products) {
      final cat = p['category_name']?.toString() ?? 'Uncategorized';
      catMap[cat] = (catMap[cat] ?? 0) +
          _d(p['purchase_price']) * _d(p['stock_quantity']);
    }
    final catList = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiRow(items: [
          _Kpi('Stock Items', '${products.length}', blue),
          _Kpi('Cost Value', _money(totalCost), red),
          _Kpi('Retail Value', _money(totalRetail), green),
          _Kpi('Potential Profit', _money(potentialProfit), const Color(0xFF9C27B0)),
        ]),
        const SizedBox(height: 16),

        _SectionHead('Value by Category'),
        const SizedBox(height: 8),
        ...catList.map((e) => _LabelValueRow(e.key, _money(e.value))),
        const SizedBox(height: 16),

        _SectionHead('Stock Valuation Detail'),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const _NoData('No stock in hand.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor:
                  WidgetStatePropertyAll(const Color(0xFFF0F4FF)),
              columns: const [
                DataColumn(label: Text('Product', style: _th)),
                DataColumn(label: Text('Qty', style: _th), numeric: true),
                DataColumn(label: Text('Cost ₹', style: _th), numeric: true),
                DataColumn(label: Text('Retail ₹', style: _th), numeric: true),
                DataColumn(label: Text('Cost Value', style: _th), numeric: true),
                DataColumn(label: Text('Retail Value', style: _th), numeric: true),
              ],
              rows: products.map((p) {
                final qty = _d(p['stock_quantity']);
                final cost = _d(p['purchase_price']);
                final sell = _d(p['selling_price']);
                return DataRow(cells: [
                  DataCell(Text(p['name']?.toString() ?? '', style: _td)),
                  DataCell(Text(qty.toStringAsFixed(0), style: _td)),
                  DataCell(Text(_money(cost), style: _td)),
                  DataCell(Text(_money(sell), style: _td)),
                  DataCell(Text(_money(cost * qty), style: _td)),
                  DataCell(Text(_money(sell * qty), style: _td)),
                ]);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────
class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHead('Business Overview'),
        const SizedBox(height: 10),
        _LabelValueRow("Today's Sales", _money(state.dashboard['today_sales'])),
        _LabelValueRow('Total Bills Today', '${state.dashboard['total_bills'] ?? 0}'),
        _LabelValueRow("Today's Profit", _money(state.dashboard['profit'])),
        _LabelValueRow('Avg Bill Value', _money(state.dashboard['average_bill_value'])),
        const Divider(height: 24),
        _SectionHead('Catalog'),
        const SizedBox(height: 10),
        _LabelValueRow('Total Products', '${state.products.length}'),
        _LabelValueRow('Categories', '${state.categories.length}'),
        _LabelValueRow('Suppliers', '${state.suppliers.length}'),
        _LabelValueRow('Low Stock Items', '${state.dashboard['low_stock_count'] ?? 0}'),
        const Divider(height: 24),
        _SectionHead('Billing'),
        const SizedBox(height: 10),
        _LabelValueRow('Total Invoices', '${state.invoices.length}'),
        _LabelValueRow('Outstanding Total', _money(state.dashboard['outstanding_total'])),
        _LabelValueRow('Overdue Invoices', '${state.dashboard['overdue_invoice_count'] ?? 0}'),
        _LabelValueRow('Returns Total', _money(state.dashboard['returns_total'])),
        const Divider(height: 24),
        _SectionHead('Approvals'),
        const SizedBox(height: 10),
        _LabelValueRow('Pending Purchase Orders', '${state.purchaseOrders.where((o) => o['status'] == 'pending').length}'),
        _LabelValueRow('Pending Discount Approvals', '${state.discountApprovals.where((d) => d['status'] == 'pending').length}'),
        const Divider(height: 24),
        const Text(
          'Generated by BBT Billing',
          style: TextStyle(fontSize: 10, color: muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _dateText(DateTime.now()),
          style: const TextStyle(fontSize: 10, color: muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
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
          initialValue:
              state.settingsDraft['invoice_prefix']?.toString() ?? '',
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
          items: ['0%', '5%', '12%', '18%', '28%']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) =>
              state.updateSetting('default_gst', v?.replaceAll('%', '')),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['max_cashier_discount'] == null
              ? null
              : _percent(state.settingsDraft['max_cashier_discount'], 0),
          decoration:
              const InputDecoration(labelText: 'Max Cashier Discount'),
          items: ['5%', '10%', '15%', '20%']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => state.updateSetting(
              'max_cashier_discount', v?.replaceAll('%', '')),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['approval_threshold'] == null
              ? null
              : _percent(state.settingsDraft['approval_threshold'], 0),
          decoration:
              const InputDecoration(labelText: 'Approval Threshold'),
          items: ['5%', '10%', '15%', '20%']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => state.updateSetting(
              'approval_threshold', v?.replaceAll('%', '')),
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: state.settingsDraft['round_off']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Round Off',
            hintText: '0.01',
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
    ['Invoice', 'Date', 'Customer', 'Status', 'Taxable', 'CGST', 'SGST', 'Discount', 'Total'],
    ...state.invoices.map((inv) => [
          inv['number'],
          inv['invoice_date'],
          inv['client_name'],
          inv['status'],
          inv['taxable_amount'],
          inv['cgst_amount'],
          inv['sgst_amount'],
          inv['discount_amount'],
          inv['total'],
        ]),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildProductsCsv(AdminState state) {
  final rows = [
    ['Name', 'SKU', 'Category', 'Unit', 'Purchase Price', 'Selling Price', 'MRP', 'GST%', 'Stock', 'Min Stock', 'Status'],
    ...state.products.map((p) => [
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
        ]),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildPurchaseCsv(AdminState state) {
  final rows = [
    ['Order #', 'Date', 'Supplier', 'Status', 'Subtotal', 'Tax', 'Total'],
    ...state.purchaseOrders.map((o) => [
          o['number'],
          o['order_date'],
          o['supplier_name'],
          o['status'],
          o['subtotal'],
          o['tax_amount'],
          o['total'],
        ]),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildSalesCsv(AdminState state) => _buildInvoiceCsv(state);

String _buildGstCsv(AdminState state) {
  final rows = [
    ['Invoice', 'Date', 'Taxable Amount', 'CGST', 'SGST', 'Total'],
    ...state.invoices.map((inv) => [
          inv['number'],
          inv['invoice_date'],
          inv['taxable_amount'],
          inv['cgst_amount'],
          inv['sgst_amount'],
          inv['total'],
        ]),
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}

String _buildProfitLossCsv(AdminState state) {
  final rows = [
    ['Product', 'SKU', 'Purchase Price', 'Selling Price', 'Margin %'],
    ...state.products.map((p) {
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

String _buildStockValuationCsv(AdminState state) {
  final rows = [
    ['Product', 'SKU', 'Category', 'Qty', 'Cost Price', 'Retail Price', 'Cost Value', 'Retail Value'],
    ...state.products.map((p) {
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

String _buildSummaryCsv(AdminState state) {
  final rows = [
    ['Metric', 'Value'],
    ["Today's Sales", _money(state.dashboard['today_sales'])],
    ['Total Bills Today', '${state.dashboard['total_bills'] ?? 0}'],
    ["Today's Profit", _money(state.dashboard['profit'])],
    ['Total Products', '${state.products.length}'],
    ['Total Invoices', '${state.invoices.length}'],
    ['Low Stock Items', '${state.dashboard['low_stock_count'] ?? 0}'],
    ['Outstanding Total', _money(state.dashboard['outstanding_total'])],
    ['Pending Purchase Orders', '${state.purchaseOrders.where((o) => o['status'] == 'pending').length}'],
    ['Pending Discount Approvals', '${state.discountApprovals.where((d) => d['status'] == 'pending').length}'],
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
                    Text(k.label,
                        style: const TextStyle(
                            fontSize: 9, color: muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(k.value,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: k.color)),
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
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: muted)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
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
      child: Text(message,
          style: const TextStyle(color: muted, fontSize: 12)),
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
    title: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ),
    icon: Icon(icon, color: color, size: 18),
    label: Text(
      label,
      style: const TextStyle(
          color: ink, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
