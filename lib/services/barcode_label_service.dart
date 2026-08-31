import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum BarcodeLabelFormat { compact50x25, square40x30, roll58mm, a4Sheet }

extension BarcodeLabelFormatDetails on BarcodeLabelFormat {
  String get title => switch (this) {
    BarcodeLabelFormat.compact50x25 => '50 × 25 mm label',
    BarcodeLabelFormat.square40x30 => '40 × 30 mm label',
    BarcodeLabelFormat.roll58mm => '58 mm thermal roll',
    BarcodeLabelFormat.a4Sheet => 'A4 sheet (24 labels)',
  };

  String get description => switch (this) {
    BarcodeLabelFormat.compact50x25 => 'Standard shelf and packet sticker',
    BarcodeLabelFormat.square40x30 => 'Compact product sticker',
    BarcodeLabelFormat.roll58mm => 'Thermal receipt or label printer',
    BarcodeLabelFormat.a4Sheet => '3 × 8 labels on regular A4 paper',
  };

  PdfPageFormat get pageFormat => switch (this) {
    BarcodeLabelFormat.compact50x25 => PdfPageFormat(
      50 * PdfPageFormat.mm,
      25 * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    ),
    BarcodeLabelFormat.square40x30 => PdfPageFormat(
      40 * PdfPageFormat.mm,
      30 * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    ),
    BarcodeLabelFormat.roll58mm => PdfPageFormat(
      58 * PdfPageFormat.mm,
      35 * PdfPageFormat.mm,
      marginAll: 2 * PdfPageFormat.mm,
    ),
    BarcodeLabelFormat.a4Sheet => PdfPageFormat.a4,
  };
}

String generateEan13Barcode(Iterable<Map<String, dynamic>> products) {
  final existing = products
      .expand((product) => [product['barcode'], product['sku']])
      .map((value) => value?.toString().trim() ?? '')
      .toSet();
  var seed = DateTime.now().microsecondsSinceEpoch;
  while (true) {
    final body = '29${(seed % 10000000000).toString().padLeft(10, '0')}';
    final barcode = '$body${_ean13CheckDigit(body)}';
    if (!existing.contains(barcode)) return barcode;
    seed++;
  }
}

int _ean13CheckDigit(String twelveDigits) {
  var sum = 0;
  for (var index = 0; index < twelveDigits.length; index++) {
    final digit = int.parse(twelveDigits[index]);
    sum += index.isEven ? digit : digit * 3;
  }
  return (10 - (sum % 10)) % 10;
}

bool isValidEan13(String value) {
  if (!RegExp(r'^\d{13}$').hasMatch(value)) return false;
  return int.parse(value[12]) == _ean13CheckDigit(value.substring(0, 12));
}

Future<Uint8List> buildBarcodeLabelPdf({
  required String productName,
  required String barcode,
  required String price,
  String pricePrefix = 'MRP',
  String department = '',
  String sellingPrice = '',
  int discountPercent = 0,
  required BarcodeLabelFormat format,
  required int copies,
}) async {
  final document = pw.Document();
  final safeCopies = copies.clamp(
    1,
    format == BarcodeLabelFormat.a4Sheet ? 96 : 20,
  );

  if (format == BarcodeLabelFormat.a4Sheet) {
    for (var offset = 0; offset < safeCopies; offset += 24) {
      final pageCount = (safeCopies - offset).clamp(0, 24);
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (_) => pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(
              pageCount,
              (_) => pw.SizedBox(
                width: 54 * PdfPageFormat.mm,
                height: 31 * PdfPageFormat.mm,
                child: _barcodeLabel(
                  productName,
                  barcode,
                  price,
                  pricePrefix: pricePrefix,
                  department: department,
                  sellingPrice: sellingPrice,
                  discountPercent: discountPercent,
                  compact: true,
                ),
              ),
            ),
          ),
        ),
      );
    }
  } else {
    for (var index = 0; index < safeCopies; index++) {
      document.addPage(
        pw.Page(
          pageFormat: format.pageFormat,
          build: (_) => _barcodeLabel(
            productName,
            barcode,
            price,
            pricePrefix: pricePrefix,
            department: department,
            sellingPrice: sellingPrice,
            discountPercent: discountPercent,
            compact: format == BarcodeLabelFormat.compact50x25,
          ),
        ),
      );
    }
  }

  return document.save();
}

Future<bool> printBarcodeLabels({
  required String productName,
  required String barcode,
  required String price,
  String pricePrefix = 'MRP',
  String department = '',
  String sellingPrice = '',
  int discountPercent = 0,
  required BarcodeLabelFormat format,
  required int copies,
}) async {
  final bytes = await buildBarcodeLabelPdf(
    productName: productName,
    barcode: barcode,
    price: price,
    pricePrefix: pricePrefix,
    department: department,
    sellingPrice: sellingPrice,
    discountPercent: discountPercent,
    format: format,
    copies: copies,
  );
  return Printing.layoutPdf(
    name: 'BBT-${barcode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '-')}-labels.pdf',
    format: format.pageFormat,
    dynamicLayout: false,
    onLayout: (_) async => bytes,
  );
}

pw.Widget _barcodeLabel(
  String productName,
  String barcode,
  String price, {
  required String pricePrefix,
  required String department,
  required String sellingPrice,
  required int discountPercent,
  required bool compact,
}) {
  final type = isValidEan13(barcode)
      ? pw.Barcode.ean13()
      : pw.Barcode.code128();
  return pw.Container(
    padding: const pw.EdgeInsets.all(4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: .5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                productName.trim().isEmpty ? 'BBT Product' : productName.trim(),
                maxLines: 1,
                style: pw.TextStyle(
                  fontSize: compact ? 6.8 : 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (price.trim().isNotEmpty)
              pw.Text(
                '${pricePrefix.trim().isEmpty ? 'MRP' : pricePrefix.trim()} Rs $price',
                style: pw.TextStyle(
                  fontSize: compact ? 7 : 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 2),
        if (department.trim().isNotEmpty || sellingPrice.trim().isNotEmpty)
          pw.Row(
            children: [
              if (department.trim().isNotEmpty)
                pw.Expanded(
                  child: pw.Text(
                    department.trim(),
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: compact ? 5.5 : 6.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                )
              else
                pw.Spacer(),
              if (sellingPrice.trim().isNotEmpty)
                pw.Text(
                  'Price Rs ${sellingPrice.trim()}',
                  style: pw.TextStyle(
                    fontSize: compact ? 5.7 : 6.8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (discountPercent > 0) ...[
                pw.SizedBox(width: 3),
                pw.Text(
                  '$discountPercent% OFF',
                  style: pw.TextStyle(
                    fontSize: compact ? 5.5 : 6.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ],
          ),
        pw.Expanded(
          child: pw.BarcodeWidget(
            barcode: type,
            data: barcode,
            drawText: false,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2),
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          barcode,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: compact ? 6 : 7, letterSpacing: 1),
        ),
      ],
    ),
  );
}
