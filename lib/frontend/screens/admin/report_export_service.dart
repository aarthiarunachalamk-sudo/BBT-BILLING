part of 'admin_screens.dart';

const _reportFileChannel = MethodChannel(
  'com.smartbilling360.bbt_billing/invoices',
);
const _reportHistoryKey = 'admin_report_download_history_v1';

class _ReportDownloadRecord {
  const _ReportDownloadRecord({
    required this.title,
    required this.format,
    required this.period,
    required this.path,
    required this.createdAt,
  });

  final String title;
  final String format;
  final String period;
  final String path;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'format': format,
    'period': period,
    'path': path,
    'created_at': createdAt.toIso8601String(),
  };

  factory _ReportDownloadRecord.fromJson(Map<String, dynamic> json) =>
      _ReportDownloadRecord(
        title: json['title']?.toString() ?? 'Report',
        format: json['format']?.toString() ?? 'FILE',
        period: json['period']?.toString() ?? '',
        path: json['path']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

Future<List<_ReportDownloadRecord>> _loadReportHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_reportHistoryKey) ?? const [];
  return raw
      .map((item) {
        try {
          return _ReportDownloadRecord.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          );
        } catch (_) {
          return null;
        }
      })
      .whereType<_ReportDownloadRecord>()
      .toList();
}

Future<List<_ReportDownloadRecord>> _rememberReportDownload(
  _ReportDownloadRecord record,
) async {
  final current = await _loadReportHistory();
  final updated = [record, ...current].take(30).toList();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _reportHistoryKey,
    updated.map((item) => jsonEncode(item.toJson())).toList(),
  );
  return updated;
}

Future<void> _clearReportHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_reportHistoryKey);
}

Future<String> _saveReportBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required bool gallery,
}) async {
  final path = await _reportFileChannel.invokeMethod<String>('saveReportFile', {
    'bytes': bytes,
    'fileName': fileName,
    'mimeType': mimeType,
    'gallery': gallery,
  });
  return path ??
      (gallery
          ? 'Gallery/BBT Billing/$fileName'
          : 'Downloads/BBT Billing/$fileName');
}

Future<Uint8List> _captureReportCard(GlobalKey key) async {
  await WidgetsBinding.instance.endOfFrame;
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw StateError('Report preview is not ready. Please try again.');
  }
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('Unable to create the report image.');
  return data.buffer.asUint8List();
}

Future<Uint8List> _buildReportPdf({
  required String title,
  required String period,
  required List<Map<String, dynamic>> invoices,
  required bool gst,
}) async {
  final document = pw.Document();
  final total = invoices.fold<double>(0, (sum, row) => sum + _d(row['total']));
  final taxable = invoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['taxable_amount']),
  );
  final cgst = invoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['cgst_amount']),
  );
  final sgst = invoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['sgst_amount']),
  );
  final discount = invoices.fold<double>(
    0,
    (sum, row) => sum + _d(row['discount_amount']),
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'BBT BILLING',
              style: pw.TextStyle(
                color: PdfColors.blue900,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text('Generated ${_dateText(DateTime.now())}'),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
      ),
      build: (context) => [
        pw.SizedBox(height: 16),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(period, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 16,
          runSpacing: 8,
          children: gst
              ? [
                  _pdfMetric('Invoices', '${invoices.length}'),
                  _pdfMetric('Taxable', 'Rs. ${taxable.toStringAsFixed(2)}'),
                  _pdfMetric('CGST', 'Rs. ${cgst.toStringAsFixed(2)}'),
                  _pdfMetric('SGST', 'Rs. ${sgst.toStringAsFixed(2)}'),
                  _pdfMetric('Total', 'Rs. ${total.toStringAsFixed(2)}'),
                ]
              : [
                  _pdfMetric('Invoices', '${invoices.length}'),
                  _pdfMetric('Sales', 'Rs. ${total.toStringAsFixed(2)}'),
                  _pdfMetric('Tax', 'Rs. ${(cgst + sgst).toStringAsFixed(2)}'),
                  _pdfMetric('Discount', 'Rs. ${discount.toStringAsFixed(2)}'),
                ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headers: gst
              ? ['Invoice', 'Date', 'Taxable', 'CGST', 'SGST', 'Total']
              : ['Invoice', 'Date', 'Customer', 'Status', 'Total'],
          data: invoices.map((row) {
            if (gst) {
              return [
                row['number'] ?? '',
                _dateText(row['invoice_date']),
                _d(row['taxable_amount']).toStringAsFixed(2),
                _d(row['cgst_amount']).toStringAsFixed(2),
                _d(row['sgst_amount']).toStringAsFixed(2),
                _d(row['total']).toStringAsFixed(2),
              ];
            }
            return [
              row['number'] ?? '',
              _dateText(row['invoice_date']),
              row['client_name'] ?? 'Walk-in Customer',
              _statusText(row['status']?.toString() ?? ''),
              _d(row['total']).toStringAsFixed(2),
            ];
          }).toList(),
        ),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> _buildInventoryReportPdf({
  required String title,
  required String period,
  required List<Map<String, dynamic>> products,
}) async {
  final document = pw.Document();
  final value = products.fold<double>(
    0,
    (sum, row) => sum + _d(row['purchase_price']) * _d(row['stock_quantity']),
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => _pdfHeader(context),
      footer: (context) => _pdfFooter(context),
      build: (context) => [
        pw.SizedBox(height: 16),
        _pdfTitle(title, period),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 16,
          children: [
            _pdfMetric('Products', '${products.length}'),
            _pdfMetric('Inventory cost', 'Rs. ${value.toStringAsFixed(2)}'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headers: [
            'Product',
            'SKU',
            'Category',
            'Stock',
            'Min',
            'Status',
            'Cost value',
          ],
          data: products
              .map(
                (row) => [
                  row['name'] ?? '',
                  row['sku'] ?? '',
                  row['category_name'] ?? '',
                  row['stock_quantity'] ?? 0,
                  row['reorder_level'] ?? 0,
                  _statusText(row['stock_status']?.toString() ?? ''),
                  (_d(row['purchase_price']) * _d(row['stock_quantity']))
                      .toStringAsFixed(2),
                ],
              )
              .toList(),
        ),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> _buildPurchaseReportPdf({
  required String title,
  required String period,
  required List<Map<String, dynamic>> orders,
}) async {
  final document = pw.Document();
  final value = orders.fold<double>(0, (sum, row) => sum + _d(row['total']));
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => _pdfHeader(context),
      footer: (context) => _pdfFooter(context),
      build: (context) => [
        pw.SizedBox(height: 16),
        _pdfTitle(title, period),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 16,
          children: [
            _pdfMetric('Orders', '${orders.length}'),
            _pdfMetric('Order value', 'Rs. ${value.toStringAsFixed(2)}'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headers: [
            'Order',
            'Date',
            'Supplier',
            'Status',
            'Subtotal',
            'Tax',
            'Total',
          ],
          data: orders
              .map(
                (row) => [
                  row['number'] ?? '',
                  _dateText(row['order_date'] ?? row['created_at']),
                  row['supplier_name'] ?? '',
                  _statusText(row['status']?.toString() ?? ''),
                  _d(row['subtotal']).toStringAsFixed(2),
                  _d(row['tax_amount']).toStringAsFixed(2),
                  _d(row['total']).toStringAsFixed(2),
                ],
              )
              .toList(),
        ),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> _buildProfitLossReportPdf({
  required String title,
  required String period,
  required List<Map<String, dynamic>> invoices,
  required List<Map<String, dynamic>> products,
}) async {
  final document = pw.Document();
  final paid = invoices.where(_isCompletedSale).toList();
  final sales = paid.fold<double>(
    0,
    (sum, row) => sum + _d(row['taxable_amount']),
  );
  final cogs = _estimatedCogs(paid, products);
  final profit = sales - cogs;
  final margins = products.where((row) => _d(row['selling_price']) > 0).map((
    row,
  ) {
    final buy = _d(row['purchase_price']);
    final sell = _d(row['selling_price']);
    return MapEntry(row, (sell - buy) / sell * 100);
  }).toList()..sort((a, b) => b.value.compareTo(a.value));
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: _pdfHeader,
      footer: _pdfFooter,
      build: (context) => [
        pw.SizedBox(height: 16),
        _pdfTitle(title, period),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _pdfMetric('Paid invoices', '${paid.length}'),
            _pdfMetric('Net sales', 'Rs. ${sales.toStringAsFixed(2)}'),
            _pdfMetric('Estimated COGS', 'Rs. ${cogs.toStringAsFixed(2)}'),
            _pdfMetric('Gross profit', 'Rs. ${profit.toStringAsFixed(2)}'),
            _pdfMetric(
              'Gross margin',
              '${(sales == 0 ? 0 : profit / sales * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Current Catalog Product Margins',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headers: ['Product', 'SKU', 'Buy', 'Sell', 'Margin %'],
          data: margins
              .take(30)
              .map(
                (entry) => [
                  entry.key['name'] ?? '',
                  entry.key['sku'] ?? '',
                  _d(entry.key['purchase_price']).toStringAsFixed(2),
                  _d(entry.key['selling_price']).toStringAsFixed(2),
                  entry.value.toStringAsFixed(1),
                ],
              )
              .toList(),
        ),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> _buildStockValuationReportPdf({
  required String title,
  required String period,
  required List<Map<String, dynamic>> products,
}) async {
  final document = pw.Document();
  final stocked = products
      .where((row) => _d(row['stock_quantity']) > 0)
      .toList();
  final costValue = stocked.fold<double>(
    0,
    (sum, row) => sum + _d(row['purchase_price']) * _d(row['stock_quantity']),
  );
  final retailValue = stocked.fold<double>(
    0,
    (sum, row) => sum + _d(row['selling_price']) * _d(row['stock_quantity']),
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: _pdfHeader,
      footer: _pdfFooter,
      build: (context) => [
        pw.SizedBox(height: 16),
        _pdfTitle(title, period),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _pdfMetric('Stock items', '${stocked.length}'),
            _pdfMetric('Cost value', 'Rs. ${costValue.toStringAsFixed(2)}'),
            _pdfMetric('Retail value', 'Rs. ${retailValue.toStringAsFixed(2)}'),
            _pdfMetric(
              'Potential profit',
              'Rs. ${(retailValue - costValue).toStringAsFixed(2)}',
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headers: [
            'Product',
            'Category',
            'Qty',
            'Cost',
            'Retail',
            'Cost value',
            'Retail value',
          ],
          data: stocked.map((row) {
            final qty = _d(row['stock_quantity']);
            final cost = _d(row['purchase_price']);
            final retail = _d(row['selling_price']);
            return [
              row['name'] ?? '',
              row['category_name'] ?? '',
              qty.toStringAsFixed(0),
              cost.toStringAsFixed(2),
              retail.toStringAsFixed(2),
              (cost * qty).toStringAsFixed(2),
              (retail * qty).toStringAsFixed(2),
            ];
          }).toList(),
        ),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> _buildAdminSummaryPdf({
  required String title,
  required String period,
  required AdminState state,
  required List<Map<String, dynamic>> invoices,
}) async {
  final document = pw.Document();
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
  final low = state.products
      .where((row) => row['stock_status'] == 'low_stock')
      .length;
  final out = state.products
      .where((row) => row['stock_status'] == 'out_of_stock')
      .length;
  final pendingOrders = state.purchaseOrders
      .where((row) => row['status'] == 'pending')
      .length;
  final pendingDiscounts = state.discountApprovals
      .where((row) => row['status'] == 'pending')
      .length;
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: _pdfHeader,
      footer: _pdfFooter,
      build: (context) => [
        pw.SizedBox(height: 16),
        _pdfTitle(title, period),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _pdfMetric('Net sales', 'Rs. ${netSales.toStringAsFixed(2)}'),
            _pdfMetric('Bills', '${completed.length}'),
            _pdfMetric(
              'Average bill',
              'Rs. ${(completed.isEmpty ? 0 : billed / completed.length).toStringAsFixed(2)}',
            ),
            _pdfMetric('Tax', 'Rs. ${tax.toStringAsFixed(2)}'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Current Business Snapshot',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['Metric', 'Value'],
          data: [
            ['Products', '${state.products.length}'],
            ['Categories', '${state.categories.length}'],
            ['Suppliers', '${state.suppliers.length}'],
            ['Low stock', '$low'],
            ['Out of stock', '$out'],
            [
              'Outstanding',
              _d(state.dashboard['outstanding_total']).toStringAsFixed(2),
            ],
            [
              'Overdue invoices',
              '${state.dashboard['overdue_invoice_count'] ?? 0}',
            ],
            ['Pending purchase orders', '$pendingOrders'],
            ['Pending discounts', '$pendingDiscounts'],
          ],
        ),
      ],
    ),
  );
  return document.save();
}

pw.Widget _pdfHeader(pw.Context context) => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 10),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800)),
  ),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'BBT BILLING',
        style: pw.TextStyle(
          color: PdfColors.blue900,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Text('Generated ${_dateText(DateTime.now())}'),
    ],
  ),
);

pw.Widget _pdfFooter(pw.Context context) => pw.Align(
  alignment: pw.Alignment.centerRight,
  child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
);

pw.Widget _pdfTitle(String title, String period) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      title,
      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
    ),
    pw.Text(period, style: const pw.TextStyle(color: PdfColors.grey700)),
  ],
);

pw.Widget _pdfMetric(String label, String value) => pw.Container(
  width: 115,
  padding: const pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    color: PdfColors.grey100,
    borderRadius: pw.BorderRadius.circular(6),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      pw.SizedBox(height: 3),
      pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ],
  ),
);
