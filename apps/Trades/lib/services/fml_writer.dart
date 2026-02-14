import '../models/floor_plan_elements.dart';

/// FML Writer — Floor Markup Language (XML-based open format).
/// Origin: Floorplanner open standard. NOT Verisk/Xactimate proprietary.
/// Safe for Symbility/Cotality integration. NOT accepted by Xactimate (ESX deferred).
class FmlWriter {
  /// Generate FML XML string from floor plan data.
  static String generate({
    required FloorPlanData plan,
    String? projectTitle,
    String? companyName,
    String? address,
    int floorNumber = 1,
  }) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<floorplan version="2.0" '
        'generator="Zafto" '
        'units="${plan.units == MeasurementUnit.metric ? 'metric' : 'imperial'}">');

    // Metadata
    buf.writeln('  <metadata>');
    if (projectTitle != null) {
      buf.writeln('    <title>${_escXml(projectTitle)}</title>');
    }
    if (companyName != null) {
      buf.writeln('    <company>${_escXml(companyName)}</company>');
    }
    if (address != null) {
      buf.writeln('    <address>${_escXml(address)}</address>');
    }
    buf.writeln('    <floor>$floorNumber</floor>');
    buf.writeln('    <scale>${plan.scale}</scale>');
    buf.writeln('  </metadata>');

    // Walls
    buf.writeln('  <walls>');
    for (final wall in plan.walls) {
      buf.writeln('    <wall id="${_escXml(wall.id)}" '
          'x1="${wall.start.dx.toStringAsFixed(2)}" '
          'y1="${wall.start.dy.toStringAsFixed(2)}" '
          'x2="${wall.end.dx.toStringAsFixed(2)}" '
          'y2="${wall.end.dy.toStringAsFixed(2)}" '
          'thickness="${wall.thickness.toStringAsFixed(1)}" '
          'height="${wall.height.toStringAsFixed(1)}"'
          '${wall.material != null ? ' material="${_escXml(wall.material!)}"' : ''}'
          ' />');
    }
    for (final arc in plan.arcWalls) {
      buf.writeln('    <arcwall id="${_escXml(arc.id)}" '
          'cx="${arc.center.dx.toStringAsFixed(2)}" '
          'cy="${arc.center.dy.toStringAsFixed(2)}" '
          'radius="${arc.radius.toStringAsFixed(2)}" '
          'start-angle="${arc.startAngle.toStringAsFixed(4)}" '
          'sweep-angle="${arc.sweepAngle.toStringAsFixed(4)}" '
          'thickness="${arc.thickness.toStringAsFixed(1)}"'
          ' />');
    }
    buf.writeln('  </walls>');

    // Rooms
    buf.writeln('  <rooms>');
    for (final room in plan.rooms) {
      buf.writeln('    <room id="${_escXml(room.id)}" '
          'name="${_escXml(room.name)}" '
          'area-sf="${room.area.toStringAsFixed(2)}" '
          'cx="${room.center.dx.toStringAsFixed(2)}" '
          'cy="${room.center.dy.toStringAsFixed(2)}">');
      if (room.wallIds.isNotEmpty) {
        buf.writeln('      <wall-refs>');
        for (final wid in room.wallIds) {
          buf.writeln('        <wall-ref id="${_escXml(wid)}" />');
        }
        buf.writeln('      </wall-refs>');
      }
      buf.writeln('    </room>');
    }
    buf.writeln('  </rooms>');

    // Openings (doors + windows)
    buf.writeln('  <openings>');
    for (final door in plan.doors) {
      buf.writeln('    <door id="${_escXml(door.id)}" '
          'wall-id="${_escXml(door.wallId)}" '
          'position="${door.position.toStringAsFixed(4)}" '
          'width="${door.width.toStringAsFixed(1)}" '
          'type="${door.type.name}" '
          'swing-angle="${door.swingAngle.toStringAsFixed(1)}" />');
    }
    for (final win in plan.windows) {
      buf.writeln('    <window id="${_escXml(win.id)}" '
          'wall-id="${_escXml(win.wallId)}" '
          'position="${win.position.toStringAsFixed(4)}" '
          'width="${win.width.toStringAsFixed(1)}" '
          'type="${win.type.name}" />');
    }
    buf.writeln('  </openings>');

    // Fixtures
    if (plan.fixtures.isNotEmpty) {
      buf.writeln('  <fixtures>');
      for (final fix in plan.fixtures) {
        buf.writeln('    <fixture id="${_escXml(fix.id)}" '
            'type="${fix.type.name}" '
            'x="${fix.position.dx.toStringAsFixed(2)}" '
            'y="${fix.position.dy.toStringAsFixed(2)}" '
            'rotation="${fix.rotation.toStringAsFixed(1)}"'
            '${fix.label != null ? ' label="${_escXml(fix.label!)}"' : ''}'
            ' />');
      }
      buf.writeln('  </fixtures>');
    }

    // Dimensions
    if (plan.dimensions.isNotEmpty) {
      buf.writeln('  <dimensions>');
      for (final dim in plan.dimensions) {
        buf.writeln('    <dimension id="${_escXml(dim.id)}" '
            'x1="${dim.start.dx.toStringAsFixed(2)}" '
            'y1="${dim.start.dy.toStringAsFixed(2)}" '
            'x2="${dim.end.dx.toStringAsFixed(2)}" '
            'y2="${dim.end.dy.toStringAsFixed(2)}" '
            'label="${_escXml(dim.label.isNotEmpty ? dim.label : dim.formattedDistance)}" '
            'manual="${dim.isManual}" />');
      }
      buf.writeln('  </dimensions>');
    }

    // Labels
    if (plan.labels.isNotEmpty) {
      buf.writeln('  <labels>');
      for (final lbl in plan.labels) {
        buf.writeln('    <label id="${_escXml(lbl.id)}" '
            'x="${lbl.position.dx.toStringAsFixed(2)}" '
            'y="${lbl.position.dy.toStringAsFixed(2)}" '
            'font-size="${lbl.fontSize.toStringAsFixed(1)}" '
            'color="${lbl.colorValue.toRadixString(16).padLeft(8, '0')}">'
            '${_escXml(lbl.text)}</label>');
      }
      buf.writeln('  </labels>');
    }

    buf.writeln('</floorplan>');
    return buf.toString();
  }

  static String _escXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
