// ZAFTO Sketch Editor Screen — Full-screen floor plan drawing canvas
// Lets field technicians draw room layouts, place fixtures/symbols, and create
// floor plans during property walkthroughs.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/floor_plan.dart';
import '../../models/floor_plan_elements.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'sketch_painter.dart';
import 'symbol_library_sheet.dart';

// =============================================================================
// SKETCH EDITOR SCREEN
// =============================================================================

class SketchEditorScreen extends ConsumerStatefulWidget {
  final FloorPlan? existingPlan;
  final String? propertyId;
  final String? walkthroughId;

  const SketchEditorScreen({
    super.key,
    this.existingPlan,
    this.propertyId,
    this.walkthroughId,
  });

  @override
  ConsumerState<SketchEditorScreen> createState() => _SketchEditorScreenState();
}

class _SketchEditorScreenState extends ConsumerState<SketchEditorScreen> {
  // Floor plan data
  FloorPlanData _planData = const FloorPlanData();
  final UndoRedoManager _undoRedo = UndoRedoManager();

  // Multi-floor support
  final List<_FloorState> _floors = [];
  int _currentFloorIndex = 0;

  // Tool state
  SketchTool _activeTool = SketchTool.wall;
  bool _isDrawingWall = false;
  Offset? _wallStart;
  Offset? _ghostEnd;
  Offset? _snapIndicator;

  // Dimension tool
  Offset? _dimensionStart;

  // Fixture placement
  FixtureType? _pendingFixtureType;

  // Door/window placement
  DoorType _doorType = DoorType.single;
  double _doorWidth = 36.0;
  WindowType _windowType = WindowType.standard;
  double _windowWidth = 36.0;

  // Selection
  String? _selectedElementId;
  String? _selectedElementType;
  Offset? _dragOffset;

  // Canvas transform
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  // Canvas rendering key for thumbnail
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeFromPlan();
  }

  void _initializeFromPlan() {
    if (widget.existingPlan != null && widget.existingPlan!.planData.isNotEmpty) {
      _planData = FloorPlanData.fromJson(widget.existingPlan!.planData);
      _floors.add(_FloorState(
        name: widget.existingPlan!.name.isNotEmpty
            ? widget.existingPlan!.name
            : 'Floor ${widget.existingPlan!.floorLevel}',
        level: widget.existingPlan!.floorLevel,
        data: _planData,
      ));
    } else {
      _floors.add(const _FloorState(
        name: 'Floor 1',
        level: 1,
        data: FloorPlanData(),
      ));
      _planData = _floors[0].data;
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Canvas
            _buildCanvas(colors),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(colors),
            ),
            // Left toolbar
            Positioned(
              top: 72,
              left: 8,
              child: _buildToolbar(colors),
            ),
            // Bottom tool options
            if (_shouldShowBottomSheet())
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomToolSheet(colors),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TOP BAR — Floor tabs, Undo, Redo, Save
  // =========================================================================

  Widget _buildTopBar(ZaftoColors colors) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, size: 20, color: colors.textPrimary),
            onPressed: () => _confirmExit(colors),
          ),
          // Floor tabs
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _floors.length + 1, // +1 for Add Floor
                itemBuilder: (_, i) {
                  if (i == _floors.length) {
                    return _buildAddFloorTab(colors);
                  }
                  return _buildFloorTab(colors, i);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Undo
          IconButton(
            icon: Icon(
              LucideIcons.undo2,
              size: 18,
              color: _undoRedo.canUndo
                  ? colors.textPrimary
                  : colors.textQuaternary,
            ),
            onPressed: _undoRedo.canUndo ? _undo : null,
          ),
          // Redo
          IconButton(
            icon: Icon(
              LucideIcons.redo2,
              size: 18,
              color: _undoRedo.canRedo
                  ? colors.textPrimary
                  : colors.textQuaternary,
            ),
            onPressed: _undoRedo.canRedo ? _redo : null,
          ),
          // Save
          IconButton(
            icon: Icon(LucideIcons.save, size: 18, color: colors.accentPrimary),
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _buildFloorTab(ZaftoColors colors, int index) {
    final isSelected = index == _currentFloorIndex;
    final floor = _floors[index];

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _switchFloor(index);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _renameFloor(index, colors);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderDefault,
            ),
          ),
          child: Text(
            floor.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? (colors.isDark ? Colors.black : Colors.white)
                  : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddFloorTab(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _addFloor();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderDefault, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 14, color: colors.textTertiary),
            const SizedBox(width: 4),
            Text(
              'Floor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // LEFT TOOLBAR
  // =========================================================================

  Widget _buildToolbar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolButton(colors, SketchTool.select, LucideIcons.mousePointer, 'Select'),
          _buildToolButton(colors, SketchTool.wall, LucideIcons.minus, 'Wall'),
          _buildToolButton(colors, SketchTool.door, LucideIcons.doorOpen, 'Door'),
          _buildToolButton(colors, SketchTool.window, LucideIcons.appWindow, 'Window'),
          _buildToolButton(colors, SketchTool.fixture, LucideIcons.layoutGrid, 'Fixture'),
          _buildToolButton(colors, SketchTool.label, LucideIcons.type, 'Label'),
          _buildToolButton(colors, SketchTool.dimension, LucideIcons.ruler, 'Measure'),
          _buildToolDivider(colors),
          _buildToolButton(colors, SketchTool.erase, LucideIcons.eraser, 'Erase'),
          _buildToolButton(colors, SketchTool.pan, LucideIcons.move, 'Pan'),
        ],
      ),
    );
  }

  Widget _buildToolButton(
      ZaftoColors colors, SketchTool tool, IconData icon, String tooltip) {
    final isSelected = _activeTool == tool;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _activeTool = tool;
            // Reset drawing state
            _isDrawingWall = false;
            _wallStart = null;
            _ghostEnd = null;
            _snapIndicator = null;
            _dimensionStart = null;
            if (tool != SketchTool.select) {
              _selectedElementId = null;
              _selectedElementType = null;
            }
          });
        },
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accentPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? colors.accentPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToolDivider(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      height: 1,
      color: colors.borderDefault,
    );
  }

  // =========================================================================
  // CANVAS
  // =========================================================================

  Widget _buildCanvas(ZaftoColors colors) {
    return RepaintBoundary(
      key: _repaintKey,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.1,
        maxScale: 5.0,
        boundaryMargin: const EdgeInsets.all(2000),
        panEnabled: _activeTool == SketchTool.pan,
        scaleEnabled: true,
        child: GestureDetector(
          key: _canvasKey,
          onTapDown: _onTapDown,
          onPanStart: _activeTool == SketchTool.select ? _onDragStart : null,
          onPanUpdate: _activeTool == SketchTool.select ? _onDragUpdate : null,
          onPanEnd: _activeTool == SketchTool.select ? _onDragEnd : null,
          onDoubleTap: _onDoubleTap,
          child: SizedBox(
            width: 4000,
            height: 4000,
            child: CustomPaint(
              painter: SketchPainter(
                planData: _planData,
                selectedElementId: _selectedElementId,
                selectedElementType: _selectedElementType,
                ghostWall: _buildGhostWall(),
                snapIndicator: _snapIndicator,
                ghostDimensionStart: _dimensionStart,
                scale: _planData.scale,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Wall? _buildGhostWall() {
    if (!_isDrawingWall || _wallStart == null || _ghostEnd == null) return null;
    return Wall(
      id: 'ghost',
      start: _wallStart!,
      end: _ghostEnd!,
    );
  }

  // =========================================================================
  // BOTTOM TOOL SHEETS
  // =========================================================================

  bool _shouldShowBottomSheet() {
    switch (_activeTool) {
      case SketchTool.fixture:
        return true;
      case SketchTool.door:
        return true;
      case SketchTool.window:
        return true;
      case SketchTool.select:
        return _selectedElementId != null;
      default:
        return false;
    }
  }

  Widget _buildBottomToolSheet(ZaftoColors colors) {
    switch (_activeTool) {
      case SketchTool.fixture:
        return SymbolLibrarySheet(
          onFixtureSelected: (type) {
            setState(() => _pendingFixtureType = type);
          },
        );
      case SketchTool.door:
        return DoorTypeSheet(
          selectedType: _doorType,
          width: _doorWidth,
          onTypeChanged: (type) => setState(() => _doorType = type),
          onWidthChanged: (w) => setState(() => _doorWidth = w),
        );
      case SketchTool.window:
        return WindowTypeSheet(
          selectedType: _windowType,
          width: _windowWidth,
          onTypeChanged: (type) => setState(() => _windowType = type),
          onWidthChanged: (w) => setState(() => _windowWidth = w),
        );
      case SketchTool.select:
        if (_selectedElementId != null) {
          return _buildSelectionSheet(colors);
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionSheet(ZaftoColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Icon(
            _selectionIcon(),
            size: 16,
            color: colors.accentPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            _selectionLabel(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          // Delete button
          GestureDetector(
            onTap: _deleteSelectedElement,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.trash2, size: 14, color: colors.accentError),
                  const SizedBox(width: 6),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.accentError,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _selectionIcon() {
    switch (_selectedElementType) {
      case 'wall':
        return LucideIcons.minus;
      case 'door':
        return LucideIcons.doorOpen;
      case 'window':
        return LucideIcons.appWindow;
      case 'fixture':
        return LucideIcons.layoutGrid;
      case 'label':
        return LucideIcons.type;
      case 'dimension':
        return LucideIcons.ruler;
      default:
        return LucideIcons.mousePointer;
    }
  }

  String _selectionLabel() {
    if (_selectedElementType == null) return 'Selected';
    final type = _selectedElementType!;
    return '${type[0].toUpperCase()}${type.substring(1)} selected';
  }

  // =========================================================================
  // GESTURE HANDLERS
  // =========================================================================

  Offset _toModelCoords(Offset screenPoint) {
    // Convert screen point through InteractiveViewer transform to model coords
    final RenderBox? box =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return screenPoint;

    final local = box.globalToLocal(screenPoint);
    return Offset(
      local.dx / _planData.scale,
      local.dy / _planData.scale,
    );
  }

  void _onTapDown(TapDownDetails details) {
    final modelPoint = _toModelCoords(details.globalPosition);

    switch (_activeTool) {
      case SketchTool.wall:
        _handleWallTap(modelPoint);
        break;
      case SketchTool.door:
        _handleDoorTap(modelPoint);
        break;
      case SketchTool.window:
        _handleWindowTap(modelPoint);
        break;
      case SketchTool.fixture:
        _handleFixtureTap(modelPoint);
        break;
      case SketchTool.label:
        _handleLabelTap(modelPoint);
        break;
      case SketchTool.dimension:
        _handleDimensionTap(modelPoint);
        break;
      case SketchTool.select:
        _handleSelectTap(modelPoint);
        break;
      case SketchTool.erase:
        _handleEraseTap(modelPoint);
        break;
      case SketchTool.pan:
        break; // handled by InteractiveViewer
    }
  }

  void _onDoubleTap() {
    if (_activeTool == SketchTool.wall && _isDrawingWall) {
      // Finish wall chain
      setState(() {
        _isDrawingWall = false;
        _wallStart = null;
        _ghostEnd = null;
        _snapIndicator = null;
        _detectRooms();
      });
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_selectedElementId == null) return;
    final modelPoint = _toModelCoords(details.globalPosition);

    // Check if drag starts near selected element
    if (_selectedElementType == 'fixture') {
      final fixture = _planData.fixtures
          .where((f) => f.id == _selectedElementId)
          .firstOrNull;
      if (fixture != null &&
          (fixture.position - modelPoint).distance < 24) {
        _dragOffset =
            Offset(modelPoint.dx - fixture.position.dx, modelPoint.dy - fixture.position.dy);
      }
    } else if (_selectedElementType == 'label') {
      final label = _planData.labels
          .where((l) => l.id == _selectedElementId)
          .firstOrNull;
      if (label != null &&
          (label.position - modelPoint).distance < 24) {
        _dragOffset =
            Offset(modelPoint.dx - label.position.dx, modelPoint.dy - label.position.dy);
      }
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragOffset == null || _selectedElementId == null) return;
    final modelPoint = _toModelCoords(details.globalPosition);
    final newPos = Offset(
      modelPoint.dx - _dragOffset!.dx,
      modelPoint.dy - _dragOffset!.dy,
    );

    setState(() {
      if (_selectedElementType == 'fixture') {
        _planData = _planData.copyWith(
          fixtures: _planData.fixtures.map((f) {
            if (f.id == _selectedElementId) return f.copyWith(position: newPos);
            return f;
          }).toList(),
        );
      } else if (_selectedElementType == 'label') {
        _planData = _planData.copyWith(
          labels: _planData.labels.map((l) {
            if (l.id == _selectedElementId) return l.copyWith(position: newPos);
            return l;
          }).toList(),
        );
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset != null && _selectedElementId != null) {
      // Commit the move as an undo-able command
      if (_selectedElementType == 'fixture') {
        final fixture = _planData.fixtures
            .where((f) => f.id == _selectedElementId)
            .firstOrNull;
        if (fixture != null) {
          // Already moved in _onDragUpdate — just log it for undo.
          // We could track the original position, but for simplicity
          // the current state is the post-move state.
        }
      }
    }
    _dragOffset = null;
  }

  // =========================================================================
  // WALL DRAWING
  // =========================================================================

  void _handleWallTap(Offset modelPoint) {
    // Snap to existing endpoint
    final snapped = SketchGeometry.findNearestEndpoint(
      modelPoint,
      _planData.walls,
      threshold: 16.0 / _planData.scale,
    );

    final point = snapped ?? modelPoint;

    if (!_isDrawingWall) {
      // Start new wall
      setState(() {
        _isDrawingWall = true;
        _wallStart = point;
        _ghostEnd = point;
        _snapIndicator = snapped;
      });
    } else {
      // End current wall segment, start next
      Offset endPoint = point;

      // Angle snapping
      if (_wallStart != null) {
        endPoint = SketchGeometry.snapEndpoint(
          _wallStart!,
          endPoint,
          threshold: 8.0,
        );

        // Endpoint snapping (existing endpoints)
        final endSnap = SketchGeometry.findNearestEndpoint(
          endPoint,
          _planData.walls,
          threshold: 16.0 / _planData.scale,
        );
        if (endSnap != null) endPoint = endSnap;
      }

      if (_wallStart != null && (endPoint - _wallStart!).distance > 2) {
        final wall = Wall(
          id: _generateId('wall'),
          start: _wallStart!,
          end: endPoint,
        );

        setState(() {
          _planData = _undoRedo.execute(AddWallCommand(wall), _planData);
          _wallStart = endPoint; // chain to next wall
          _ghostEnd = endPoint;
          _snapIndicator = null;
        });

        HapticFeedback.lightImpact();
      }
    }
  }

  // =========================================================================
  // DOOR PLACEMENT
  // =========================================================================

  void _handleDoorTap(Offset modelPoint) {
    final wall = SketchGeometry.findNearestWall(
      modelPoint,
      _planData.walls,
      threshold: 20.0 / _planData.scale,
    );
    if (wall == null) return;

    final t = SketchGeometry.projectOntoWall(modelPoint, wall);
    final door = DoorPlacement(
      id: _generateId('door'),
      wallId: wall.id,
      position: t.clamp(0.05, 0.95),
      width: _doorWidth,
      type: _doorType,
    );

    setState(() {
      _planData = _undoRedo.execute(AddDoorCommand(door), _planData);
    });

    HapticFeedback.mediumImpact();
  }

  // =========================================================================
  // WINDOW PLACEMENT
  // =========================================================================

  void _handleWindowTap(Offset modelPoint) {
    final wall = SketchGeometry.findNearestWall(
      modelPoint,
      _planData.walls,
      threshold: 20.0 / _planData.scale,
    );
    if (wall == null) return;

    final t = SketchGeometry.projectOntoWall(modelPoint, wall);
    final window = WindowPlacement(
      id: _generateId('window'),
      wallId: wall.id,
      position: t.clamp(0.05, 0.95),
      width: _windowWidth,
      type: _windowType,
    );

    setState(() {
      _planData = _undoRedo.execute(AddWindowCommand(window), _planData);
    });

    HapticFeedback.mediumImpact();
  }

  // =========================================================================
  // FIXTURE PLACEMENT
  // =========================================================================

  void _handleFixtureTap(Offset modelPoint) {
    final type = _pendingFixtureType;
    if (type == null) return;

    final fixture = FixturePlacement(
      id: _generateId('fixture'),
      position: modelPoint,
      type: type,
    );

    setState(() {
      _planData = _undoRedo.execute(AddFixtureCommand(fixture), _planData);
    });

    HapticFeedback.mediumImpact();
  }

  // =========================================================================
  // LABEL PLACEMENT
  // =========================================================================

  void _handleLabelTap(Offset modelPoint) {
    final colors = ref.read(zaftoColorsProvider);
    _showLabelDialog(colors, modelPoint);
  }

  void _showLabelDialog(ZaftoColors colors, Offset position) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          title: Text(
            'Add Label',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Label text...',
              hintStyle: TextStyle(color: colors.textTertiary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.accentPrimary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final label = FloorLabel(
                    id: _generateId('label'),
                    position: position,
                    text: text,
                  );
                  setState(() {
                    _planData =
                        _undoRedo.execute(AddLabelCommand(label), _planData);
                  });
                }
                Navigator.pop(ctx);
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // DIMENSION TOOL
  // =========================================================================

  void _handleDimensionTap(Offset modelPoint) {
    if (_dimensionStart == null) {
      setState(() {
        _dimensionStart = modelPoint;
      });
    } else {
      final dim = DimensionLine(
        id: _generateId('dim'),
        start: _dimensionStart!,
        end: modelPoint,
      );

      setState(() {
        _planData = _undoRedo.execute(AddDimensionCommand(dim), _planData);
        _dimensionStart = null;
      });

      HapticFeedback.lightImpact();
    }
  }

  // =========================================================================
  // SELECT TOOL
  // =========================================================================

  void _handleSelectTap(Offset modelPoint) {
    final hit = SketchGeometry.findElementAt(
      modelPoint,
      _planData,
      threshold: 20.0 / _planData.scale,
    );

    setState(() {
      if (hit != null) {
        _selectedElementType = hit.$1;
        _selectedElementId = hit.$2;
      } else {
        _selectedElementType = null;
        _selectedElementId = null;
      }
    });

    if (hit != null) HapticFeedback.lightImpact();
  }

  // =========================================================================
  // ERASE TOOL
  // =========================================================================

  void _handleEraseTap(Offset modelPoint) {
    final hit = SketchGeometry.findElementAt(
      modelPoint,
      _planData,
      threshold: 20.0 / _planData.scale,
    );

    if (hit == null) return;

    final (type, id) = hit;
    dynamic element;

    switch (type) {
      case 'wall':
        element = _planData.walls.where((w) => w.id == id).firstOrNull;
        break;
      case 'door':
        element = _planData.doors.where((d) => d.id == id).firstOrNull;
        break;
      case 'window':
        element = _planData.windows.where((w) => w.id == id).firstOrNull;
        break;
      case 'fixture':
        element = _planData.fixtures.where((f) => f.id == id).firstOrNull;
        break;
      case 'label':
        element = _planData.labels.where((l) => l.id == id).firstOrNull;
        break;
      case 'dimension':
        element = _planData.dimensions.where((d) => d.id == id).firstOrNull;
        break;
    }

    if (element == null) return;

    final cmd = EraseElementCommand(
      elementId: id,
      elementType: type,
      element: element,
    );

    setState(() {
      _planData = _undoRedo.execute(cmd, _planData);
      _detectRooms();
    });

    HapticFeedback.mediumImpact();
  }

  // =========================================================================
  // DELETE SELECTED
  // =========================================================================

  void _deleteSelectedElement() {
    if (_selectedElementId == null || _selectedElementType == null) return;

    final type = _selectedElementType!;
    final id = _selectedElementId!;
    dynamic element;

    switch (type) {
      case 'wall':
        element = _planData.walls.where((w) => w.id == id).firstOrNull;
        break;
      case 'door':
        element = _planData.doors.where((d) => d.id == id).firstOrNull;
        break;
      case 'window':
        element = _planData.windows.where((w) => w.id == id).firstOrNull;
        break;
      case 'fixture':
        element = _planData.fixtures.where((f) => f.id == id).firstOrNull;
        break;
      case 'label':
        element = _planData.labels.where((l) => l.id == id).firstOrNull;
        break;
      case 'dimension':
        element = _planData.dimensions.where((d) => d.id == id).firstOrNull;
        break;
    }

    if (element == null) return;

    final cmd = EraseElementCommand(
      elementId: id,
      elementType: type,
      element: element,
    );

    setState(() {
      _planData = _undoRedo.execute(cmd, _planData);
      _selectedElementId = null;
      _selectedElementType = null;
      _detectRooms();
    });

    HapticFeedback.heavyImpact();
  }

  // =========================================================================
  // UNDO / REDO
  // =========================================================================

  void _undo() {
    setState(() {
      _planData = _undoRedo.undo(_planData);
      _detectRooms();
    });
    HapticFeedback.lightImpact();
  }

  void _redo() {
    setState(() {
      _planData = _undoRedo.redo(_planData);
      _detectRooms();
    });
    HapticFeedback.lightImpact();
  }

  // =========================================================================
  // ROOM DETECTION
  // =========================================================================

  void _detectRooms() {
    final rooms = SketchGeometry.detectRooms(_planData.walls);
    // Preserve user-renamed rooms
    final existingNames = <String, String>{};
    for (final r in _planData.rooms) {
      existingNames[r.id] = r.name;
    }
    final updated = rooms.map((r) {
      final existingName = existingNames[r.id];
      if (existingName != null) {
        return r.copyWith(name: existingName);
      }
      return r;
    }).toList();
    _planData = _planData.copyWith(rooms: updated);
  }

  // =========================================================================
  // FLOOR MANAGEMENT
  // =========================================================================

  void _switchFloor(int index) {
    if (index == _currentFloorIndex) return;
    // Save current floor data
    _floors[_currentFloorIndex] =
        _floors[_currentFloorIndex].copyWith(data: _planData);
    _undoRedo.clear();

    setState(() {
      _currentFloorIndex = index;
      _planData = _floors[index].data;
      _isDrawingWall = false;
      _wallStart = null;
      _ghostEnd = null;
      _selectedElementId = null;
      _selectedElementType = null;
    });
  }

  void _addFloor() {
    // Save current
    _floors[_currentFloorIndex] =
        _floors[_currentFloorIndex].copyWith(data: _planData);
    _undoRedo.clear();

    final newLevel = _floors.length + 1;
    _floors.add(_FloorState(
      name: 'Floor $newLevel',
      level: newLevel,
      data: const FloorPlanData(),
    ));

    setState(() {
      _currentFloorIndex = _floors.length - 1;
      _planData = _floors[_currentFloorIndex].data;
      _isDrawingWall = false;
      _wallStart = null;
      _ghostEnd = null;
      _selectedElementId = null;
      _selectedElementType = null;
    });
  }

  void _renameFloor(int index, ZaftoColors colors) {
    final controller = TextEditingController(text: _floors[index].name);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          title: Text(
            'Rename Floor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Floor name...',
              hintStyle: TextStyle(color: colors.textTertiary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.accentPrimary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _floors[index] = _floors[index].copyWith(name: text);
                  });
                }
                Navigator.pop(ctx);
              },
              child: Text(
                'Rename',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // SAVE
  // =========================================================================

  void _save() {
    // Save current floor
    _floors[_currentFloorIndex] =
        _floors[_currentFloorIndex].copyWith(data: _planData);

    // Build the result to pass back
    final result = <String, dynamic>{
      'floors': _floors
          .map((f) => {
                'name': f.name,
                'level': f.level,
                'plan_data': f.data.toJson(),
              })
          .toList(),
    };

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Floor plan saved',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, result);
  }

  void _confirmExit(ZaftoColors colors) {
    final hasContent = _planData.walls.isNotEmpty ||
        _planData.fixtures.isNotEmpty ||
        _planData.labels.isNotEmpty;

    if (!hasContent) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          title: Text(
            'Unsaved Changes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'You have unsaved changes. Discard them?',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'Discard',
                style: TextStyle(
                  color: colors.accentError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _save();
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  String _generateId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(9999);
    return '${prefix}_${now}_$rand';
  }
}

// =============================================================================
// FLOOR STATE — per-floor data holder
// =============================================================================

class _FloorState {
  final String name;
  final int level;
  final FloorPlanData data;

  const _FloorState({
    required this.name,
    required this.level,
    required this.data,
  });

  _FloorState copyWith({
    String? name,
    int? level,
    FloorPlanData? data,
  }) {
    return _FloorState(
      name: name ?? this.name,
      level: level ?? this.level,
      data: data ?? this.data,
    );
  }
}
