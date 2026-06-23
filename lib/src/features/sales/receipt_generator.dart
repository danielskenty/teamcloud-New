import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../features/sales/models/sale.dart';

class ReceiptGenerator {
  static Future<Uint8List> generatePdf(Sale sale) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.simpleCurrency(decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TeamCloud Retail POS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Sale: ${sale.id}'),
              pw.Text('Tenant: ${sale.tenantId}'),
              pw.Text('Branch: ${sale.branchId}'),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Unit', 'Total'],
                data: sale.items.map((it) => [it.productName, it.quantity.toString(), formatter.format(it.unitPrice), formatter.format(it.total)]).toList(),
              ),
              pw.SizedBox(height: 12),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Subtotal: ${formatter.format(sale.subtotal)}')]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Tax: ${formatter.format(sale.tax)}')]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Total: ${formatter.format(sale.total)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))]),
              pw.SizedBox(height: 12),
              pw.Text('Payment Method: ${sale.paymentMethod}'),
              pw.Text('Status: ${sale.status}'),
              pw.SizedBox(height: 20),
              pw.Text('Thank you for your purchase!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPdf(Sale sale) async {
    final bytes = await generatePdf(sale);
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }
}
