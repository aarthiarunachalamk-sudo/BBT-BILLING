import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdfService {
  static const _downloads = MethodChannel('com.smartbilling360.bbt_billing/invoices');

  static Future<String> save(Map<String, dynamic> invoice) async {
    final document = pw.Document();
    final items = (invoice['items'] as List?)?.whereType<Map>().toList() ?? const [];
    final number = '${invoice['number'] ?? invoice['id'] ?? 'invoice'}';
    final total = _amount(invoice['total']);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text('BBT BILLING', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('TAX INVOICE', style: const pw.TextStyle(fontSize: 12)),
          pw.Divider(),
          _line('Invoice ID', number),
          _line('Date', '${invoice['invoice_date'] ?? invoice['created_at'] ?? '-'}'),
          _line('Status', '${invoice['status'] ?? 'paid'}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['Product', 'Qty', 'Rate', 'Amount'],
            data: items.map((item) => [
              '${item['name'] ?? 'Product'}',
              '${item['quantity'] ?? 0}',
              'Rs. ${_amount(item['unit_price'])}',
              'Rs. ${_amount(item['amount'])}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Total: Rs. $total', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 28),
          pw.Text('Thank you for shopping with us.', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
    final safeNumber = number.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final bytes = await document.save();
    final path = await _downloads.invokeMethod<String>('saveInvoicePdf', {
      'fileName': 'Invoice_$safeNumber.pdf',
      'bytes': Uint8List.fromList(bytes),
    });
    return path ?? 'Downloads/BBT Billing/Invoice_$safeNumber.pdf';
  }

  static pw.Widget _line(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [pw.Expanded(child: pw.Text(label)), pw.Text(value)]),
      );

  static String _amount(dynamic value) => (double.tryParse('$value') ?? 0).toStringAsFixed(2);
}
