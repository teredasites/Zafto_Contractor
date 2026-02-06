/// Invoice PDF Generator - Design System v2.6
/// Creates stunning, professional PDF invoices
/// 
/// Features:
/// - Clean, modern design
/// - Proper business formatting
/// - Itemized line items with alternating rows
/// - Tax breakdown
/// - Payment terms
/// - Professional typography

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/invoice.dart';

class InvoicePdfGenerator {
  // Brand colors
  static const PdfColor _primary = PdfColor.fromInt(0xFFFF9500); // ZAFTO Orange
  static const PdfColor _dark = PdfColor.fromInt(0xFF1C1C1E);
  static const PdfColor _gray = PdfColor.fromInt(0xFF8E8E93);
  static const PdfColor _lightGray = PdfColor.fromInt(0xFFF2F2F7);
  static const PdfColor _white = PdfColors.white;

  /// Generate PDF bytes from invoice
  static Future<Uint8List> generate(Invoice invoice, {BusinessInfo? businessInfo}) async {
    final pdf = pw.Document();
    final business = businessInfo ?? BusinessInfo.placeholder();
    
    // Load fonts
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontMedium = await PdfGoogleFonts.interMedium();
    final fontSemiBold = await PdfGoogleFonts.interSemiBold();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(invoice, business, fontBold, fontSemiBold, fontMedium, fontRegular),
            pw.SizedBox(height: 40),
            _buildBillingSection(invoice, business, fontBold, fontSemiBold, fontMedium, fontRegular),
            pw.SizedBox(height: 30),
            _buildLineItemsTable(invoice, fontSemiBold, fontMedium, fontRegular),
            pw.SizedBox(height: 20),
            _buildTotalsSection(invoice, fontBold, fontSemiBold, fontMedium, fontRegular),
            pw.Spacer(),
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildNotesSection(invoice, fontMedium, fontRegular),
            _buildFooter(business, fontRegular),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Preview invoice in system print dialog
  static Future<void> preview(Invoice invoice, {BusinessInfo? businessInfo}) async {
    final pdfBytes = await generate(invoice, businessInfo: businessInfo);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}',
    );
  }

  /// Share invoice via system share sheet
  static Future<void> share(Invoice invoice, {BusinessInfo? businessInfo}) async {
    final pdfBytes = await generate(invoice, businessInfo: businessInfo);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  // === HEADER ===
  static pw.Widget _buildHeader(
    Invoice invoice,
    BusinessInfo business,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Info (Left)
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                business.name,
                style: pw.TextStyle(font: fontBold, fontSize: 24, color: _dark),
              ),
              pw.SizedBox(height: 4),
              if (business.tagline != null)
                pw.Text(
                  business.tagline!,
                  style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _gray),
                ),
              pw.SizedBox(height: 12),
              _buildInfoLine(business.address, fontRegular),
              _buildInfoLine('${business.city}, ${business.state} ${business.zip}', fontRegular),
              _buildInfoLine(business.phone, fontRegular),
              _buildInfoLine(business.email, fontRegular),
              if (business.license != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Text(
                    'License: ${business.license}',
                    style: pw.TextStyle(font: fontMedium, fontSize: 9, color: _gray),
                  ),
                ),
            ],
          ),
        ),
        
        // Invoice Badge (Right)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: pw.BoxDecoration(
                color: _primary,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(font: fontBold, fontSize: 14, color: _white, letterSpacing: 1),
              ),
            ),
            pw.SizedBox(height: 16),
            _buildInvoiceDetail('Invoice #', invoice.invoiceNumber, fontMedium, fontBold),
            pw.SizedBox(height: 6),
            _buildInvoiceDetail('Date', _formatDate(invoice.createdAt), fontMedium, fontRegular),
            pw.SizedBox(height: 6),
            if (invoice.dueDate != null)
              _buildInvoiceDetail('Due Date', _formatDate(invoice.dueDate!), fontMedium, fontRegular,
                highlight: invoice.isOverdue),
            if (invoice.isPaid && invoice.paidAt != null) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF34C759),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'PAID ${_formatDate(invoice.paidAt!)}',
                  style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _white),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoLine(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10, color: _dark)),
    );
  }

  static pw.Widget _buildInvoiceDetail(String label, String value, pw.Font labelFont, pw.Font valueFont, {bool highlight = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(font: labelFont, fontSize: 10, color: _gray)),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: valueFont,
            fontSize: 10,
            color: highlight ? const PdfColor.fromInt(0xFFFF3B30) : _dark,
          ),
        ),
      ],
    );
  }

  // === BILLING SECTION ===
  static pw.Widget _buildBillingSection(
    Invoice invoice,
    BusinessInfo business,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bill To
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
                ),
                child: pw.Text(
                  'BILL TO',
                  style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _gray, letterSpacing: 0.5),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                invoice.customerName ?? 'Customer',
                style: pw.TextStyle(font: fontSemiBold, fontSize: 12, color: _dark),
              ),
              if (invoice.customerEmail != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.customerEmail!,
                  style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _dark),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        // Amount Due Summary
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Amount Due',
                style: pw.TextStyle(font: fontMedium, fontSize: 10, color: _gray),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '\$${invoice.total.toStringAsFixed(2)}',
                style: pw.TextStyle(font: fontBold, fontSize: 28, color: _dark),
              ),
              if (invoice.isPaid)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    'PAID IN FULL',
                    style: pw.TextStyle(
                      font: fontSemiBold,
                      fontSize: 9,
                      color: const PdfColor.fromInt(0xFF34C759),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // === LINE ITEMS TABLE ===
  static pw.Widget _buildLineItemsTable(
    Invoice invoice,
    pw.Font fontSemiBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Column(
      children: [
        // Header Row
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _dark,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text('Description', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _white)),
              ),
              pw.SizedBox(
                width: 60,
                child: pw.Text('Qty', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _white), textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(
                width: 80,
                child: pw.Text('Rate', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _white), textAlign: pw.TextAlign.right),
              ),
              pw.SizedBox(
                width: 80,
                child: pw.Text('Amount', style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _white), textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        ),
        // Data Rows
        ...invoice.lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 0;
          
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: isEven ? _white : _lightGray,
              border: pw.Border(
                left: const pw.BorderSide(color: _lightGray, width: 1),
                right: const pw.BorderSide(color: _lightGray, width: 1),
                bottom: const pw.BorderSide(color: _lightGray, width: 1),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    item.description,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _dark),
                  ),
                ),
                pw.SizedBox(
                  width: 60,
                  child: pw.Text(
                    _formatQuantity(item.quantity),
                    style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _dark),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    '\$${item.unitPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _dark),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: fontMedium, fontSize: 10, color: _dark),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // === TOTALS SECTION ===
  static pw.Widget _buildTotalsSection(
    Invoice invoice,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', '\$${invoice.subtotal.toStringAsFixed(2)}', fontRegular, fontMedium),
              if (invoice.taxRate > 0) ...[
                pw.SizedBox(height: 6),
                _buildTotalRow('Tax (${invoice.taxRate.toStringAsFixed(1)}%)', '\$${invoice.taxAmount.toStringAsFixed(2)}', fontRegular, fontMedium),
              ],
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: _dark,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(font: fontSemiBold, fontSize: 11, color: _white)),
                    pw.Text('\$${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 14, color: _primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, pw.Font labelFont, pw.Font valueFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: labelFont, fontSize: 10, color: _gray)),
          pw.Text(value, style: pw.TextStyle(font: valueFont, fontSize: 10, color: _dark)),
        ],
      ),
    );
  }

  // === NOTES SECTION ===
  static pw.Widget _buildNotesSection(Invoice invoice, pw.Font fontMedium, pw.Font fontRegular) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes', style: pw.TextStyle(font: fontMedium, fontSize: 9, color: _gray)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.notes!, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _dark)),
        ],
      ),
    );
  }

  // === FOOTER ===
  static pw.Widget _buildFooter(BusinessInfo business, pw.Font fontRegular) {
    return pw.Column(
      children: [
        pw.Divider(color: _lightGray, thickness: 1),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payment Terms',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: _gray),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Payment due within 30 days of invoice date.',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: _dark),
                ),
              ],
            ),
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _primary),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated with ZAFTO Electrical',
          style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _gray),
        ),
      ],
    );
  }

  // === HELPERS ===
  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatQuantity(double qty) {
    return qty == qty.toInt() ? qty.toInt().toString() : qty.toStringAsFixed(2);
  }
}

/// Business information for invoice header
class BusinessInfo {
  final String name;
  final String? tagline;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String phone;
  final String email;
  final String? website;
  final String? license;

  const BusinessInfo({
    required this.name,
    this.tagline,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.phone,
    required this.email,
    this.website,
    this.license,
  });

  /// Placeholder business info for testing
  factory BusinessInfo.placeholder() {
    return const BusinessInfo(
      name: 'Your Company Name',
      tagline: 'Professional Electrical Services',
      address: '123 Main Street',
      city: 'Anytown',
      state: 'CT',
      zip: '06001',
      phone: '(555) 123-4567',
      email: 'info@yourcompany.com',
      license: 'E1-123456',
    );
  }
}
