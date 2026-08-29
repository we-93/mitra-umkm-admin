import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> downloadInvoicePdf({
    required String packageName,
    required String price,
    required String invoiceNumber,
    required String storeName,
    required String email,
    required String status,
  }) async {
    final pdf = pw.Document();

    // Load Logo
    final ByteData bytes = await rootBundle.load('assets/images/Mitra UMKM Logo App.png');
    final Uint8List logoData = bytes.buffer.asUint8List();
    
    // Status color and text
    PdfColor statusColor = PdfColor.fromHex('#F97416');
    String statusText = 'PENDING';
    if (status == 'paid' || status == 'success') {
      statusColor = PdfColor.fromHex('#0F766E'); // Green/Teal for success
      statusText = 'LUNAS';
    } else if (status == 'failed') {
      statusColor = PdfColors.red;
      statusText = 'GAGAL';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(pw.MemoryImage(logoData), width: 150),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                        pw.Text('No: $invoiceNumber', style: const pw.TextStyle(color: PdfColors.grey700)),
                        pw.Text('Tanggal: ${_formatDate(DateTime.now())}', style: const pw.TextStyle(color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 48),

                // Customer Info
                pw.Text('Ditagihkan Kepada:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(storeName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text(email),
                pw.SizedBox(height: 32),

                // Table
                pw.TableHelper.fromTextArray(
                  headers: ['Deskripsi Layanan', 'Kuantitas', 'Total'],
                  data: [
                    ['Upgrade Kategori: $packageName', '1', price],
                  ],
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F766E')),
                  cellHeight: 40,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 16),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total Pembayaran: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(price, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F97416'))),
                  ],
                ),
                pw.SizedBox(height: 48),

                // Footer / Stamp
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(statusText, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: statusColor)),
                      pw.SizedBox(height: 8),
                      pw.Text('Terima kasih telah menggunakan layanan Mitra UMKM.', style: const pw.TextStyle(color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save and download PDF via printing package (works natively on Flutter Web to trigger browser download)
    final pdfBytes = await pdf.save();
    await Printing.sharePdf(bytes: pdfBytes, filename: '$invoiceNumber.pdf');
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
