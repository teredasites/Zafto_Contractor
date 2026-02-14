import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/floor_plan_elements.dart';

import '../models/trade_layer.dart';
import 'dxf_writer.dart';
import 'fml_writer.dart';

enum ExportFormat { pdf, png, dxf, fml, svg }

/// Orchestrates all floor plan export formats.
class SketchExportService {
  // --- PDF Export ---

  static Future<Uint8List> generatePdf({
    required FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    String? companyName,
    String? projectAddress,
    int floorNumber = 1,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMedium = await PdfGoogleFonts.interMedium();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          final pdfFontBold = PdfFont.helveticaBold(context.document);
          final pdfFontRegular = PdfFont.helvetica(context.document);
          return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTitleBlock(
              companyName: companyName,
              projectAddress: projectAddress,
              floorNumber: floorNumber,
              scale: plan.scale,
              fontBold: fontBold,
              fontRegular: fontRegular,
            ),
            pw.SizedBox(height: 12),
            pw.Expanded(
              child: _buildFloorPlanDrawing(plan, tradeLayers, pdfFontBold, pdfFontRegular),
            ),
            pw.SizedBox(height: 12),
            _buildRoomSchedule(plan, fontBold, fontMedium, fontRegular),
            if (tradeLayers != null && tradeLayers.isNotEmpty)
              pw.SizedBox(height: 8),
            if (tradeLayers != null && tradeLayers.isNotEmpty)
              _buildTradeLegend(tradeLayers, fontMedium, fontRegular),
          ],
        );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTitleBlock({
    String? companyName,
    String? projectAddress,
    int floorNumber = 1,
    double scale = 4.0,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (companyName != null)
                pw.Text(companyName,
                    style: pw.TextStyle(font: fontBold, fontSize: 14)),
              if (projectAddress != null)
                pw.Text(projectAddress,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Floor $floorNumber',
                  style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text(
                  'Scale: 1" = ${(1 / scale * 12).toStringAsFixed(0)}\'',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              pw.Text(
                  'Date: ${DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFloorPlanDrawing(
    FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    PdfFont pdfFontBold,
    PdfFont pdfFontRegular,
  ) {
    // Calculate bounds
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final wall in plan.walls) {
      for (final pt in [wall.start, wall.end]) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }
    if (minX == double.infinity) {
      return pw.Center(child: pw.Text('No floor plan data'));
    }

    final padding = 24.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;
    final planW = maxX - minX;
    final planH = maxY - minY;

    return pw.CustomPaint(
      painter: (canvas, size) {
        final scaleX = size.x / planW;
        final scaleY = size.y / planH;
        final s = scaleX < scaleY ? scaleX : scaleY;

        PdfPoint transform(double x, double y) =>
            PdfPoint((x - minX) * s, size.y - (y - minY) * s);

        // Room fills — build polygon from wall endpoints
        for (final room in plan.rooms) {
          final wallPts = <PdfPoint>[];
          for (final wid in room.wallIds) {
            final wall = plan.wallById(wid);
            if (wall != null) {
              wallPts.add(transform(wall.start.dx, wall.start.dy));
              wallPts.add(transform(wall.end.dx, wall.end.dy));
            }
          }
          if (wallPts.length >= 3) {
            canvas
              ..setFillColor(PdfColor(0.85, 0.93, 1.0))
              ..moveTo(wallPts.first.x, wallPts.first.y);
            for (var i = 1; i < wallPts.length; i++) {
              canvas.lineTo(wallPts[i].x, wallPts[i].y);
            }
            canvas
              ..closePath()
              ..fillPath();
          }
        }

        // Walls
        canvas
          ..setStrokeColor(PdfColors.grey800)
          ..setLineWidth(2.0 * s);
        for (final wall in plan.walls) {
          final p1 = transform(wall.start.dx, wall.start.dy);
          final p2 = transform(wall.end.dx, wall.end.dy);
          canvas
            ..drawLine(p1.x, p1.y, p2.x, p2.y)
            ..strokePath();
        }

        // Doors — small arc
        canvas
          ..setStrokeColor(const PdfColor(0.6, 0.3, 0.8))
          ..setLineWidth(1.0 * s);
        for (final door in plan.doors) {
          final wall = plan.wallById(door.wallId);
          if (wall == null) continue;
          final pos = wall.pointAt(door.position);
          final tp = transform(pos.dx, pos.dy);
          canvas
            ..drawEllipse(tp.x, tp.y, door.width * s * 0.3,
                door.width * s * 0.3)
            ..strokePath();
        }

        // Windows — cyan line
        canvas
          ..setStrokeColor(const PdfColor(0.0, 0.8, 0.8))
          ..setLineWidth(1.5 * s);
        for (final win in plan.windows) {
          final wall = plan.wallById(win.wallId);
          if (wall == null) continue;
          final pos = wall.pointAt(win.position);
          final along = wall.direction;
          final halfW = win.width / 2;
          final p1 = transform(
              pos.dx - along.dx * halfW, pos.dy - along.dy * halfW);
          final p2 = transform(
              pos.dx + along.dx * halfW, pos.dy + along.dy * halfW);
          canvas
            ..drawLine(p1.x, p1.y, p2.x, p2.y)
            ..strokePath();
        }

        // Room labels — use DetectedRoom.center
        canvas.setFillColor(PdfColors.grey800);
        for (final room in plan.rooms) {
          final tp = transform(room.center.dx, room.center.dy);
          canvas.drawString(
            pdfFontBold,
            8 * s,
            room.name,
            tp.x,
            tp.y,
          );
        }

        // Dimensions
        canvas
          ..setStrokeColor(PdfColors.red)
          ..setLineWidth(0.5 * s);
        for (final dim in plan.dimensions) {
          final p1 = transform(dim.start.dx, dim.start.dy);
          final p2 = transform(dim.end.dx, dim.end.dy);
          canvas
            ..drawLine(p1.x, p1.y, p2.x, p2.y)
            ..strokePath();
          final mx = (p1.x + p2.x) / 2;
          final my = (p1.y + p2.y) / 2;
          canvas
            ..setFillColor(PdfColors.red)
            ..drawString(
              pdfFontRegular,
              6 * s,
              dim.label.isNotEmpty ? dim.label : dim.formattedDistance,
              mx,
              my + 4 * s,
            );
        }
      },
    );
  }

  static pw.Widget _buildRoomSchedule(
    FloorPlanData plan,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    if (plan.rooms.isEmpty) return pw.SizedBox.shrink();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor(0.93, 0.93, 0.93)),
          children: [
            _cell('Room', fontBold, bold: true),
            _cell('Area (SF)', fontBold, bold: true),
            _cell('Walls', fontBold, bold: true),
          ],
        ),
        ...plan.rooms.map((room) => pw.TableRow(
              children: [
                _cell(room.name, fontRegular),
                _cell(room.area.toStringAsFixed(1), fontRegular),
                _cell('${room.wallIds.length} walls', fontRegular),
              ],
            )),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 8)),
    );
  }

  static pw.Widget _buildTradeLegend(
    List<TradeLayer> tradeLayers,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      children: [
        pw.Text('Trade Layers: ',
            style: pw.TextStyle(font: fontMedium, fontSize: 8)),
        ...tradeLayers.where((tl) => tl.visible).map((tl) => pw.Container(
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.Row(children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  color: _tradePdfColor(tl.type),
                ),
                pw.SizedBox(width: 3),
                pw.Text(tl.name,
                    style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            )),
      ],
    );
  }

  static PdfColor _tradePdfColor(TradeLayerType type) {
    switch (type) {
      case TradeLayerType.electrical:
        return const PdfColor(0.0, 0.0, 1.0);
      case TradeLayerType.plumbing:
        return const PdfColor(1.0, 0.0, 0.0);
      case TradeLayerType.hvac:
        return const PdfColor(0.0, 0.7, 0.0);
      case TradeLayerType.damage:
        return const PdfColor(1.0, 0.5, 0.0);
    }
  }

  // --- PNG Export ---

  static Future<Uint8List?> generatePng({
    required GlobalKey repaintBoundaryKey,
    double pixelRatio = 2.0,
  }) async {
    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // --- SVG Export ---

  static String generateSvg({
    required FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    double width = 1200,
  }) {
    // Calculate bounds
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final wall in plan.walls) {
      for (final pt in [wall.start, wall.end]) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }
    if (minX == double.infinity) return '<svg></svg>';

    final pad = 24.0;
    minX -= pad;
    minY -= pad;
    maxX += pad;
    maxY += pad;
    final planW = maxX - minX;
    final planH = maxY - minY;
    final height = width * planH / planW;

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'width="$width" height="${height.toStringAsFixed(0)}" '
        'viewBox="${minX.toStringAsFixed(2)} ${minY.toStringAsFixed(2)} '
        '${planW.toStringAsFixed(2)} ${planH.toStringAsFixed(2)}">');

    // Room fills — build polygon from wall endpoints
    buf.writeln('  <g id="rooms" opacity="0.3">');
    for (final room in plan.rooms) {
      final wallPts = <String>[];
      for (final wid in room.wallIds) {
        final wall = plan.wallById(wid);
        if (wall != null) {
          wallPts.add('${wall.start.dx.toStringAsFixed(2)},'
              '${wall.start.dy.toStringAsFixed(2)}');
          wallPts.add('${wall.end.dx.toStringAsFixed(2)},'
              '${wall.end.dy.toStringAsFixed(2)}');
        }
      }
      if (wallPts.length >= 3) {
        buf.writeln('    <polygon points="${wallPts.join(' ')}" fill="#D9E8FF" '
            'stroke="none" />');
      }
    }
    buf.writeln('  </g>');

    // Walls
    buf.writeln('  <g id="walls" stroke="#333" stroke-width="6" '
        'stroke-linecap="round">');
    for (final wall in plan.walls) {
      buf.writeln('    <line '
          'x1="${wall.start.dx.toStringAsFixed(2)}" '
          'y1="${wall.start.dy.toStringAsFixed(2)}" '
          'x2="${wall.end.dx.toStringAsFixed(2)}" '
          'y2="${wall.end.dy.toStringAsFixed(2)}" />');
    }
    buf.writeln('  </g>');

    // Doors
    buf.writeln('  <g id="doors" stroke="#9933CC" stroke-width="2" '
        'fill="none">');
    for (final door in plan.doors) {
      final wall = plan.wallById(door.wallId);
      if (wall == null) continue;
      final pos = wall.pointAt(door.position);
      final along = wall.direction;
      final halfW = door.width / 2;
      buf.writeln('    <line '
          'x1="${(pos.dx - along.dx * halfW).toStringAsFixed(2)}" '
          'y1="${(pos.dy - along.dy * halfW).toStringAsFixed(2)}" '
          'x2="${(pos.dx + along.dx * halfW).toStringAsFixed(2)}" '
          'y2="${(pos.dy + along.dy * halfW).toStringAsFixed(2)}" />');
    }
    buf.writeln('  </g>');

    // Windows
    buf.writeln('  <g id="windows" stroke="#00CCCC" stroke-width="3">');
    for (final win in plan.windows) {
      final wall = plan.wallById(win.wallId);
      if (wall == null) continue;
      final pos = wall.pointAt(win.position);
      final along = wall.direction;
      final halfW = win.width / 2;
      buf.writeln('    <line '
          'x1="${(pos.dx - along.dx * halfW).toStringAsFixed(2)}" '
          'y1="${(pos.dy - along.dy * halfW).toStringAsFixed(2)}" '
          'x2="${(pos.dx + along.dx * halfW).toStringAsFixed(2)}" '
          'y2="${(pos.dy + along.dy * halfW).toStringAsFixed(2)}" />');
    }
    buf.writeln('  </g>');

    // Fixtures
    buf.writeln('  <g id="fixtures" fill="#4CAF50">');
    for (final fix in plan.fixtures) {
      buf.writeln('    <circle cx="${fix.position.dx.toStringAsFixed(2)}" '
          'cy="${fix.position.dy.toStringAsFixed(2)}" r="4" />');
      buf.writeln('    <text x="${(fix.position.dx + 6).toStringAsFixed(2)}" '
          'y="${(fix.position.dy + 3).toStringAsFixed(2)}" '
          'font-size="5" fill="#333">'
          '${_escSvg(fix.label ?? fix.type.name)}</text>');
    }
    buf.writeln('  </g>');

    // Dimensions
    buf.writeln('  <g id="dimensions" stroke="#FF0000" stroke-width="0.5">');
    for (final dim in plan.dimensions) {
      buf.writeln('    <line '
          'x1="${dim.start.dx.toStringAsFixed(2)}" '
          'y1="${dim.start.dy.toStringAsFixed(2)}" '
          'x2="${dim.end.dx.toStringAsFixed(2)}" '
          'y2="${dim.end.dy.toStringAsFixed(2)}" />');
      final mx = (dim.start.dx + dim.end.dx) / 2;
      final my = (dim.start.dy + dim.end.dy) / 2;
      buf.writeln('    <text x="${mx.toStringAsFixed(2)}" '
          'y="${(my - 3).toStringAsFixed(2)}" '
          'font-size="4" fill="#FF0000" text-anchor="middle">'
          '${_escSvg(dim.label.isNotEmpty ? dim.label : dim.formattedDistance)}</text>');
    }
    buf.writeln('  </g>');

    // Room labels — use DetectedRoom.center
    buf.writeln('  <g id="room-labels">');
    for (final room in plan.rooms) {
      final cx = room.center.dx;
      final cy = room.center.dy;
      buf.writeln('    <text x="${cx.toStringAsFixed(2)}" '
          'y="${cy.toStringAsFixed(2)}" '
          'font-size="8" font-weight="bold" fill="#333" '
          'text-anchor="middle" dominant-baseline="middle">'
          '${_escSvg(room.name)}</text>');
      buf.writeln('    <text x="${cx.toStringAsFixed(2)}" '
          'y="${(cy + 10).toStringAsFixed(2)}" '
          'font-size="5" fill="#666" text-anchor="middle">'
          '${room.area.toStringAsFixed(0)} SF</text>');
    }
    buf.writeln('  </g>');

    // Labels
    if (plan.labels.isNotEmpty) {
      buf.writeln('  <g id="labels">');
      for (final lbl in plan.labels) {
        buf.writeln('    <text x="${lbl.position.dx.toStringAsFixed(2)}" '
            'y="${lbl.position.dy.toStringAsFixed(2)}" '
            'font-size="${(lbl.fontSize / plan.scale).toStringAsFixed(1)}" '
            'fill="#${(lbl.colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}">'
            '${_escSvg(lbl.text)}</text>');
      }
      buf.writeln('  </g>');
    }

    // Trade layers
    if (tradeLayers != null) {
      for (final tl in tradeLayers) {
        if (!tl.visible) continue;
        final color = _tradeColorHex(tl.type);
        buf.writeln('  <g id="${tl.type.name}" opacity="${tl.opacity}">');
        for (final elem in tl.tradeData.elements) {
          buf.writeln('    <circle '
              'cx="${elem.position.dx.toStringAsFixed(2)}" '
              'cy="${elem.position.dy.toStringAsFixed(2)}" '
              'r="3" fill="$color" />');
          buf.writeln('    <text '
              'x="${(elem.position.dx + 5).toStringAsFixed(2)}" '
              'y="${(elem.position.dy + 2).toStringAsFixed(2)}" '
              'font-size="4" fill="$color">'
              '${_escSvg(elem.label ?? elem.symbolType.name)}</text>');
        }
        for (final path in tl.tradeData.paths) {
          if (path.points.length >= 2) {
            final pts = path.points
                .map((p) =>
                    '${p.dx.toStringAsFixed(2)},${p.dy.toStringAsFixed(2)}')
                .join(' ');
            buf.writeln('    <polyline points="$pts" fill="none" '
                'stroke="$color" stroke-width="1.5"'
                '${path.isDashed ? ' stroke-dasharray="4 2"' : ''} />');
          }
        }
        if (tl.damageData.zones.isNotEmpty) {
          for (final zone in tl.damageData.zones) {
            if (zone.boundary.length >= 3) {
              final pts = zone.boundary
                  .map((p) =>
                      '${p.dx.toStringAsFixed(2)},${p.dy.toStringAsFixed(2)}')
                  .join(' ');
              buf.writeln('    <polygon points="$pts" '
                  'fill="$color" fill-opacity="0.2" '
                  'stroke="$color" stroke-width="1" />');
            }
          }
        }
        buf.writeln('  </g>');
      }
    }

    buf.writeln('</svg>');
    return buf.toString();
  }

  static String _tradeColorHex(TradeLayerType type) {
    switch (type) {
      case TradeLayerType.electrical:
        return '#0000FF';
      case TradeLayerType.plumbing:
        return '#FF0000';
      case TradeLayerType.hvac:
        return '#00AA00';
      case TradeLayerType.damage:
        return '#FF8800';
    }
  }

  static String _escSvg(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // --- DXF/FML delegates ---

  static String generateDxf({
    required FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    String? projectTitle,
    String? companyName,
  }) =>
      DxfWriter.generate(
        plan: plan,
        tradeLayers: tradeLayers,
        projectTitle: projectTitle,
        companyName: companyName,
      );

  static String generateFml({
    required FloorPlanData plan,
    String? projectTitle,
    String? companyName,
    String? address,
    int floorNumber = 1,
  }) =>
      FmlWriter.generate(
        plan: plan,
        projectTitle: projectTitle,
        companyName: companyName,
        address: address,
        floorNumber: floorNumber,
      );

  // --- Share/Save ---

  static Future<void> shareFile({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: filename,
    );
  }

  static Future<void> shareText({
    required String content,
    required String filename,
    String? mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: filename,
    );
  }

  // --- Export Orchestrator ---

  static Future<void> export({
    required ExportFormat format,
    required FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    GlobalKey? repaintBoundaryKey,
    String? companyName,
    String? projectAddress,
    String? projectTitle,
    int floorNumber = 1,
    double pngPixelRatio = 2.0,
  }) async {
    switch (format) {
      case ExportFormat.pdf:
        final bytes = await generatePdf(
          plan: plan,
          tradeLayers: tradeLayers,
          companyName: companyName,
          projectAddress: projectAddress,
          floorNumber: floorNumber,
        );
        await Printing.layoutPdf(onLayout: (_) async => bytes);
        break;

      case ExportFormat.png:
        if (repaintBoundaryKey == null) return;
        final bytes = await generatePng(
          repaintBoundaryKey: repaintBoundaryKey,
          pixelRatio: pngPixelRatio,
        );
        if (bytes == null) return;
        await shareFile(
          bytes: bytes,
          filename: 'floor_plan_f${floorNumber}.png',
          mimeType: 'image/png',
        );
        break;

      case ExportFormat.dxf:
        final content = generateDxf(
          plan: plan,
          tradeLayers: tradeLayers,
          projectTitle: projectTitle,
          companyName: companyName,
        );
        await shareText(
          content: content,
          filename: 'floor_plan_f${floorNumber}.dxf',
          mimeType: 'application/dxf',
        );
        break;

      case ExportFormat.fml:
        final content = generateFml(
          plan: plan,
          projectTitle: projectTitle,
          companyName: companyName,
          address: projectAddress,
          floorNumber: floorNumber,
        );
        await shareText(
          content: content,
          filename: 'floor_plan_f${floorNumber}.fml',
          mimeType: 'application/xml',
        );
        break;

      case ExportFormat.svg:
        final content = generateSvg(
          plan: plan,
          tradeLayers: tradeLayers,
        );
        await shareText(
          content: content,
          filename: 'floor_plan_f${floorNumber}.svg',
          mimeType: 'image/svg+xml',
        );
        break;
    }
  }

  // --- Bottom Sheet UI ---

  static void showExportSheet({
    required BuildContext context,
    required FloorPlanData plan,
    List<TradeLayer>? tradeLayers,
    GlobalKey? repaintBoundaryKey,
    String? companyName,
    String? projectAddress,
    String? projectTitle,
    int floorNumber = 1,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Export Floor Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _ExportOption(
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              description: 'Print-ready with title block & room schedule',
              onTap: () {
                Navigator.pop(ctx);
                export(
                  format: ExportFormat.pdf,
                  plan: plan,
                  tradeLayers: tradeLayers,
                  companyName: companyName,
                  projectAddress: projectAddress,
                  projectTitle: projectTitle,
                  floorNumber: floorNumber,
                );
              },
            ),
            _ExportOption(
              icon: Icons.image,
              label: 'PNG Image',
              description: 'High-resolution raster image',
              onTap: () {
                Navigator.pop(ctx);
                _showPngScaleSheet(
                  context,
                  plan: plan,
                  repaintBoundaryKey: repaintBoundaryKey,
                  floorNumber: floorNumber,
                );
              },
            ),
            _ExportOption(
              icon: Icons.architecture,
              label: 'DXF (AutoCAD)',
              description: 'Opens in AutoCAD, LibreCAD, DraftSight',
              onTap: () {
                Navigator.pop(ctx);
                export(
                  format: ExportFormat.dxf,
                  plan: plan,
                  tradeLayers: tradeLayers,
                  companyName: companyName,
                  projectTitle: projectTitle,
                  floorNumber: floorNumber,
                );
              },
            ),
            _ExportOption(
              icon: Icons.code,
              label: 'FML (Open Format)',
              description: 'Symbility/Cotality compatible XML',
              onTap: () {
                Navigator.pop(ctx);
                export(
                  format: ExportFormat.fml,
                  plan: plan,
                  companyName: companyName,
                  projectAddress: projectAddress,
                  projectTitle: projectTitle,
                  floorNumber: floorNumber,
                );
              },
            ),
            _ExportOption(
              icon: Icons.draw,
              label: 'SVG',
              description: 'Scalable vector — Inkscape, browsers',
              onTap: () {
                Navigator.pop(ctx);
                export(
                  format: ExportFormat.svg,
                  plan: plan,
                  tradeLayers: tradeLayers,
                  floorNumber: floorNumber,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void _showPngScaleSheet(
    BuildContext context, {
    required FloorPlanData plan,
    GlobalKey? repaintBoundaryKey,
    int floorNumber = 1,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'PNG Resolution',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final scale in [1.0, 2.0, 4.0])
              _ExportOption(
                icon: Icons.photo_size_select_large,
                label: '${scale.toInt()}x',
                description: scale == 1.0
                    ? 'Standard'
                    : scale == 2.0
                        ? 'High resolution (recommended)'
                        : 'Ultra-high resolution',
                onTap: () {
                  Navigator.pop(ctx);
                  export(
                    format: ExportFormat.png,
                    plan: plan,
                    repaintBoundaryKey: repaintBoundaryKey,
                    floorNumber: floorNumber,
                    pngPixelRatio: scale,
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF9500), size: 24),
      title: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(description,
          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      trailing:
          Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
      onTap: onTap,
    );
  }
}
