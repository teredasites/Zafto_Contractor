/// ZAFTO PDF Service
/// Sprint P0 - February 2026
/// Professional PDF generation for bids and invoices

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

import '../models/bid.dart';
import '../models/business/invoice.dart';

// ============================================================
// PROVIDERS
// ============================================================

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

// ============================================================
// SERVICE
// ============================================================

class PdfService {
  // Brand colors
  static const _primaryColor = PdfColor.fromInt(0xFFFF9500); // Orange
  static const _darkColor = PdfColor.fromInt(0xFF1A1D21);
  static const _grayColor = PdfColor.fromInt(0xFF6B7280);
  static const _lightGrayColor = PdfColor.fromInt(0xFFE5E7EB);

  /// Generate a professional bid PDF
  Future<Uint8List> generateBidPdf(Bid bid, {String? companyName, String? companyPhone, String? companyEmail}) async {
    final pdf = pw.Document();

    // Load fonts
    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final semiBoldFont = await PdfGoogleFonts.interSemiBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildBidHeader(bid, companyName, companyPhone, companyEmail, boldFont, regularFont),
          pw.SizedBox(height: 30),
          _buildBidCustomerInfo(bid, semiBoldFont, regularFont),
          pw.SizedBox(height: 30),
          _buildBidSummary(bid, semiBoldFont, regularFont),
          pw.SizedBox(height: 20),
          ..._buildBidOptions(bid, semiBoldFont, regularFont, boldFont),
          pw.SizedBox(height: 30),
          if (bid.selectedOptionId != null && bid.selectedOption != null)
            _buildSelectedOptionHighlight(bid, semiBoldFont, regularFont),
          pw.SizedBox(height: 30),
          _buildBidTerms(bid, semiBoldFont, regularFont),
          pw.SizedBox(height: 40),
          _buildSignatureLine(semiBoldFont, regularFont),
        ],
        footer: (context) => _buildFooter(context, regularFont),
      ),
    );

    return pdf.save();
  }

  /// Generate a professional invoice PDF
  Future<Uint8List> generateInvoicePdf(Invoice invoice, {String? companyName, String? companyPhone, String? companyEmail}) async {
    final pdf = pw.Document();

    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final semiBoldFont = await PdfGoogleFonts.interSemiBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildInvoiceHeader(invoice, companyName, companyPhone, companyEmail, boldFont, regularFont),
          pw.SizedBox(height: 30),
          _buildInvoiceBillTo(invoice, semiBoldFont, regularFont),
          pw.SizedBox(height: 30),
          _buildInvoiceLineItems(invoice, semiBoldFont, regularFont),
          pw.SizedBox(height: 20),
          _buildInvoiceTotals(invoice, semiBoldFont, boldFont, regularFont),
          pw.SizedBox(height: 40),
          _buildPaymentInstructions(semiBoldFont, regularFont),
        ],
        footer: (context) => _buildFooter(context, regularFont),
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // BID PDF COMPONENTS
  // ============================================================

  pw.Widget _buildBidHeader(Bid bid, String? companyName, String? companyPhone, String? companyEmail, pw.Font boldFont, pw.Font regularFont) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName ?? 'ZAFTO TRADES',
                style: pw.TextStyle(font: boldFont, fontSize: 24, color: _darkColor),
              ),
              pw.SizedBox(height: 4),
              if (companyPhone != null)
                pw.Text(companyPhone, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
              if (companyEmail != null)
                pw.Text(companyEmail, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _primaryColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'ESTIMATE',
                style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Date: ${_formatDate(bid.createdAt)}',
              style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor),
            ),
            pw.Text(
              'Valid Until: ${_formatDate(bid.validUntil ?? bid.createdAt.add(const Duration(days: 30)))}',
              style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBidCustomerInfo(Bid bid, pw.Font semiBoldFont, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PREPARED FOR', style: pw.TextStyle(font: semiBoldFont, fontSize: 8, color: _grayColor)),
                pw.SizedBox(height: 4),
                pw.Text(bid.customerName, style: pw.TextStyle(font: semiBoldFont, fontSize: 14, color: _darkColor)),
                if (bid.customerAddress != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(bid.customerAddress!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
                ],
                if (bid.customerEmail != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(bid.customerEmail!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
                ],
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROJECT', style: pw.TextStyle(font: semiBoldFont, fontSize: 8, color: _grayColor)),
                pw.SizedBox(height: 4),
                pw.Text(bid.title, style: pw.TextStyle(font: semiBoldFont, fontSize: 14, color: _darkColor)),
                if (bid.projectAddress != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(bid.projectAddress!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBidSummary(Bid bid, pw.Font semiBoldFont, pw.Font regularFont) {
    if (bid.summary == null || bid.summary!.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PROJECT SUMMARY', style: pw.TextStyle(font: semiBoldFont, fontSize: 10, color: _grayColor)),
        pw.SizedBox(height: 8),
        pw.Text(bid.summary!, style: pw.TextStyle(font: regularFont, fontSize: 11, color: _darkColor, lineSpacing: 1.4)),
      ],
    );
  }

  List<pw.Widget> _buildBidOptions(Bid bid, pw.Font semiBoldFont, pw.Font regularFont, pw.Font boldFont) {
    final widgets = <pw.Widget>[];

    for (int i = 0; i < bid.options.length; i++) {
      final option = bid.options[i];
      final isSelected = bid.selectedOptionId == option.id;
      final optionLabel = bid.options.length == 3
          ? ['GOOD', 'BETTER', 'BEST'][i]
          : 'OPTION ${i + 1}';

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: isSelected ? _primaryColor : _lightGrayColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: isSelected ? _primaryColor : PdfColor.fromInt(0xFFF3F4F6),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      optionLabel,
                      style: pw.TextStyle(
                        font: semiBoldFont,
                        fontSize: 9,
                        color: isSelected ? PdfColors.white : _grayColor,
                      ),
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    '\$${_formatMoney(option.total)}',
                    style: pw.TextStyle(font: boldFont, fontSize: 18, color: _darkColor),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text(option.name, style: pw.TextStyle(font: semiBoldFont, fontSize: 13, color: _darkColor)),
              if (option.description != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(option.description!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
              ],
              pw.SizedBox(height: 12),
              // Line items table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: _lightGrayColor)),
                    ),
                    children: [
                      _tableHeaderCell('Description', regularFont),
                      _tableHeaderCell('Qty', regularFont, align: pw.TextAlign.center),
                      _tableHeaderCell('Rate', regularFont, align: pw.TextAlign.right),
                      _tableHeaderCell('Amount', regularFont, align: pw.TextAlign.right),
                    ],
                  ),
                  ...option.lineItems.map((item) => pw.TableRow(
                    children: [
                      _tableCell(item.description, regularFont),
                      _tableCell('${item.quantity}', regularFont, align: pw.TextAlign.center),
                      _tableCell('\$${_formatMoney(item.unitPrice)}', regularFont, align: pw.TextAlign.right),
                      _tableCell('\$${_formatMoney(item.total)}', regularFont, align: pw.TextAlign.right),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildSelectedOptionHighlight(Bid bid, pw.Font semiBoldFont, pw.Font regularFont) {
    final option = bid.selectedOption!;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF7ED),
        border: pw.Border.all(color: _primaryColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SELECTED OPTION', style: pw.TextStyle(font: semiBoldFont, fontSize: 8, color: _primaryColor)),
                pw.SizedBox(height: 4),
                pw.Text(option.name, style: pw.TextStyle(font: semiBoldFont, fontSize: 14, color: _darkColor)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(font: semiBoldFont, fontSize: 8, color: _grayColor)),
              pw.SizedBox(height: 4),
              pw.Text('\$${_formatMoney(option.total)}', style: pw.TextStyle(font: semiBoldFont, fontSize: 18, color: _darkColor)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBidTerms(Bid bid, pw.Font semiBoldFont, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(font: semiBoldFont, fontSize: 10, color: _grayColor)),
        pw.SizedBox(height: 8),
        pw.Text(
          bid.terms ?? _defaultTerms,
          style: pw.TextStyle(font: regularFont, fontSize: 9, color: _grayColor, lineSpacing: 1.3),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureLine(pw.Font semiBoldFont, pw.Font regularFont) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(height: 1, color: _darkColor),
              pw.SizedBox(height: 4),
              pw.Text('Customer Signature', style: pw.TextStyle(font: regularFont, fontSize: 9, color: _grayColor)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.SizedBox(
          width: 120,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(height: 1, color: _darkColor),
              pw.SizedBox(height: 4),
              pw.Text('Date', style: pw.TextStyle(font: regularFont, fontSize: 9, color: _grayColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INVOICE PDF COMPONENTS
  // ============================================================

  pw.Widget _buildInvoiceHeader(Invoice invoice, String? companyName, String? companyPhone, String? companyEmail, pw.Font boldFont, pw.Font regularFont) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName ?? 'ZAFTO TRADES',
                style: pw.TextStyle(font: boldFont, fontSize: 24, color: _darkColor),
              ),
              pw.SizedBox(height: 4),
              if (companyPhone != null)
                pw.Text(companyPhone, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
              if (companyEmail != null)
                pw.Text(companyEmail, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: invoice.status == InvoiceStatus.paid ? PdfColor.fromInt(0xFF34C759) : _primaryColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                invoice.status == InvoiceStatus.paid ? 'PAID' : 'INVOICE',
                style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Invoice #${invoice.invoiceNumber ?? invoice.id.substring(0, 8).toUpperCase()}',
              style: pw.TextStyle(font: boldFont, fontSize: 11, color: _darkColor),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date: ${_formatDate(invoice.createdAt)}',
              style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor),
            ),
            pw.Text(
              'Due: ${_formatDate(invoice.dueDate)}',
              style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceBillTo(Invoice invoice, pw.Font semiBoldFont, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO', style: pw.TextStyle(font: semiBoldFont, fontSize: 8, color: _grayColor)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.customerName, style: pw.TextStyle(font: semiBoldFont, fontSize: 14, color: _darkColor)),
                if (invoice.customerAddress != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.customerAddress!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
                ],
                if (invoice.customerEmail != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.customerEmail!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
                ],
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROJECT', style: pw.TextStyle(font: semiBoldFont, fontSize: 8, color: _grayColor)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.title, style: pw.TextStyle(font: semiBoldFont, fontSize: 14, color: _darkColor)),
                if (invoice.projectAddress != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.projectAddress!, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _grayColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceLineItems(Invoice invoice, pw.Font semiBoldFont, pw.Font regularFont) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF3F4F6),
          ),
          children: [
            _tableHeaderCell('Description', semiBoldFont),
            _tableHeaderCell('Qty', semiBoldFont, align: pw.TextAlign.center),
            _tableHeaderCell('Rate', semiBoldFont, align: pw.TextAlign.right),
            _tableHeaderCell('Amount', semiBoldFont, align: pw.TextAlign.right),
          ],
        ),
        ...invoice.lineItems.map((item) => pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _lightGrayColor)),
          ),
          children: [
            _tableCell(item.description, regularFont),
            _tableCell('${item.quantity}', regularFont, align: pw.TextAlign.center),
            _tableCell('\$${_formatMoney(item.unitPrice)}', regularFont, align: pw.TextAlign.right),
            _tableCell('\$${_formatMoney(item.total)}', regularFont, align: pw.TextAlign.right),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildInvoiceTotals(Invoice invoice, pw.Font semiBoldFont, pw.Font boldFont, pw.Font regularFont) {
    return pw.Row(
      children: [
        pw.Spacer(),
        pw.SizedBox(
          width: 200,
          child: pw.Column(
            children: [
              _totalRow('Subtotal', invoice.subtotal, regularFont),
              if (invoice.taxAmount > 0)
                _totalRow('Tax (${(invoice.taxRate * 100).toStringAsFixed(1)}%)', invoice.taxAmount, regularFont),
              if (invoice.discountAmount > 0)
                _totalRow('Discount', -invoice.discountAmount, regularFont),
              pw.Container(height: 1, color: _darkColor, margin: const pw.EdgeInsets.symmetric(vertical: 8)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Due', style: pw.TextStyle(font: boldFont, fontSize: 14, color: _darkColor)),
                  pw.Text('\$${_formatMoney(invoice.total)}', style: pw.TextStyle(font: boldFont, fontSize: 18, color: _darkColor)),
                ],
              ),
              if (invoice.amountPaid > 0) ...[
                pw.SizedBox(height: 8),
                _totalRow('Amount Paid', invoice.amountPaid, regularFont, color: PdfColor.fromInt(0xFF34C759)),
                _totalRow('Balance Due', invoice.balanceDue, semiBoldFont, color: _primaryColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentInstructions(pw.Font semiBoldFont, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PAYMENT INSTRUCTIONS', style: pw.TextStyle(font: semiBoldFont, fontSize: 10, color: _grayColor)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Payment is due within terms. Please include invoice number with your payment.\n'
            'We accept check, credit card, or bank transfer.',
            style: pw.TextStyle(font: regularFont, fontSize: 10, color: _darkColor, lineSpacing: 1.4),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  pw.Widget _tableHeaderCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9, color: _grayColor),
        textAlign: align,
      ),
    );
  }

  pw.Widget _tableCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10, color: _darkColor),
        textAlign: align,
      ),
    );
  }

  pw.Widget _totalRow(String label, double amount, pw.Font font, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11, color: color ?? _grayColor)),
          pw.Text('\$${_formatMoney(amount)}', style: pw.TextStyle(font: font, fontSize: 11, color: color ?? _darkColor)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _lightGrayColor)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by ZAFTO TRADES',
            style: pw.TextStyle(font: font, fontSize: 8, color: _grayColor),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 8, color: _grayColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Save PDF to temporary file and return path
  Future<String> savePdfToFile(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share PDF using platform share sheet
  Future<void> sharePdf(Uint8List bytes, String filename) async {
    final path = await savePdfToFile(bytes, filename);
    await Share.shareXFiles([XFile(path)], text: 'Sharing $filename');
  }

  /// Print PDF using platform print dialog
  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  /// Preview PDF
  Future<void> previewPdf(Uint8List bytes, String title) async {
    await Printing.sharePdf(bytes: bytes, filename: '$title.pdf');
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  static const String _defaultTerms = '''
1. This estimate is valid for 30 days from the date above.
2. A 50% deposit is required to schedule work.
3. Balance is due upon completion.
4. Any changes to the scope of work may result in additional charges.
5. We are fully licensed and insured.
6. Customer is responsible for obtaining any required permits unless otherwise specified.
''';
}
