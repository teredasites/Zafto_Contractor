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
import '../../models/trade_layer.dart';
import '../../painters/trade_layer_painter.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/sketch/layer_panel.dart';
import '../../widgets/sketch/lidar_scan_screen.dart';
import '../../widgets/sketch/manual_room_entry.dart';
import '../../widgets/sketch/trade_toolbar.dart';
import '../../services/sketch_export_service.dart';
import '../../widgets/laser_meter_sheet.dart';
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

  // SK2: Wall thickness for new walls
  double _newWallThickness = 6.0;

  // SK2: Measurement units
  MeasurementUnit _currentUnits = MeasurementUnit.imperial;

  // Selection
  String? _selectedElementId;
  String? _selectedElementType;
  Offset? _dragOffset;

  // SK2: Wall endpoint dragging
  String? _draggingWallEndpointType; // 'start' or 'end'

  // SK2: Fixture rotation dragging
  bool _isRotatingFixture = false;
  double _rotationStartAngle = 0.0;
  double _rotationBaseAngle = 0.0;

  // SK3: Arc wall drawing state
  Offset? _arcWallStart;
  Offset? _arcWallEnd;
  bool _isArcWallAdjusting = false; // true = dragging control point

  // SK3: Multi-select
  Set<String> _multiSelectedIds = {};
  Map<String, String> _multiSelectedTypes = {}; // id -> type

  // SK3: Lasso
  List<Offset> _lassoPoints = [];

  // SK3: Copy/paste clipboard
  List<Wall> _clipboardWalls = [];
  List<ArcWall> _clipboardArcWalls = [];
  List<FixturePlacement> _clipboardFixtures = [];
  List<FloorLabel> _clipboardLabels = [];
  List<DimensionLine> _clipboardDimensions = [];

  // SK3: Auto-dimensions toggle
  final bool _autoDimensions = true;

  // SK4: Trade layer state
  String? _activeLayerId; // null = base layer
  bool _isLayerPanelOpen = false;
  TradeTool _activeTradeTool = TradeTool.select;
  TradeSymbolType? _pendingTradeSymbol;
  List<Offset> _tradePathPoints = []; // points for wire/pipe/duct drawing
  List<Offset> _damageZonePoints = []; // polygon points for damage zone
  String _selectedDamageClass = '1';
  String _selectedIicrcCategory = '1';
  BarrierType _selectedEquipment = BarrierType.dehumidifier;
  Offset? _containmentStart;
  String? _selectedTradeElementId;

  // SK4: Convenience getters
  bool get _isTradeLayerActive => _activeLayerId != null;
  TradeLayer? get _activeTradeLayer =>
      _activeLayerId != null ? _planData.tradeLayerById(_activeLayerId!) : null;

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
      _currentUnits = _planData.units; // Restore saved unit preference
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
            // Left toolbar — swap between base and trade tools
            Positioned(
              top: 72,
              left: 8,
              child: _isTradeLayerActive && _activeTradeLayer != null
                  ? TradeToolbar(
                      layerType: _activeTradeLayer!.type,
                      activeTool: _activeTradeTool,
                      onToolChanged: (tool) {
                        setState(() {
                          _activeTradeTool = tool;
                          _resetTradeDrawingState();
                        });
                      },
                      colors: colors,
                    )
                  : _buildToolbar(colors),
            ),
            // SK4: Layer panel (right side, collapsible)
            if (_isLayerPanelOpen)
              Positioned(
                top: 72,
                right: 8,
                child: LayerPanel(
                  layers: _planData.tradeLayers,
                  activeLayerId: _activeLayerId,
                  isBaseLayerActive: !_isTradeLayerActive,
                  onActiveLayerChanged: _setActiveLayer,
                  onToggleVisibility: _toggleLayerVisibility,
                  onToggleLock: _toggleLayerLock,
                  onOpacityChanged: _setLayerOpacity,
                  onAddLayer: () => _showAddLayerDialog(colors),
                  onRemoveLayer: _removeLayer,
                  colors: colors,
                ),
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
          // SK2: Unit toggle (Imperial ↔ Metric) — persisted to plan data
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _currentUnits = _currentUnits == MeasurementUnit.imperial
                    ? MeasurementUnit.metric
                    : MeasurementUnit.imperial;
                _planData = _planData.copyWith(units: _currentUnits);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _currentUnits == MeasurementUnit.imperial ? 'ft/in' : 'm/cm',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.accentPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // SK4: Layer panel toggle
          IconButton(
            icon: Icon(
              LucideIcons.layers,
              size: 18,
              color: _isLayerPanelOpen
                  ? colors.accentPrimary
                  : colors.textSecondary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isLayerPanelOpen = !_isLayerPanelOpen);
            },
          ),
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
          // SK9: Export
          IconButton(
            icon: Icon(LucideIcons.download, size: 18, color: colors.textSecondary),
            onPressed: _planData.walls.isEmpty
                ? null
                : () => SketchExportService.showExportSheet(
                      context: context,
                      plan: _planData,
                      tradeLayers: _planData.tradeLayers,
                      floorNumber: _currentFloorIndex + 1,
                    ),
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
          _buildToolButton(colors, SketchTool.arcWall, LucideIcons.spline, 'Arc'),
          _buildToolButton(colors, SketchTool.door, LucideIcons.doorOpen, 'Door'),
          _buildToolButton(colors, SketchTool.window, LucideIcons.appWindow, 'Window'),
          _buildToolButton(colors, SketchTool.fixture, LucideIcons.layoutGrid, 'Fixture'),
          _buildToolButton(colors, SketchTool.label, LucideIcons.type, 'Label'),
          _buildToolButton(colors, SketchTool.dimension, LucideIcons.ruler, 'Measure'),
          _buildToolDivider(colors),
          _buildToolButton(colors, SketchTool.lasso, LucideIcons.lasso, 'Lasso'),
          _buildToolButton(colors, SketchTool.erase, LucideIcons.eraser, 'Erase'),
          _buildToolButton(colors, SketchTool.pan, LucideIcons.move, 'Pan'),
          _buildToolDivider(colors),
          // SK5: Import tools
          _buildActionButton(
            colors,
            LucideIcons.scan,
            'LiDAR',
            () => _launchLidarScan(colors),
          ),
          _buildActionButton(
            colors,
            LucideIcons.ruler,
            'Laser',
            () => _launchLaserMeter(),
          ),
          _buildActionButton(
            colors,
            LucideIcons.layoutGrid,
            'Rooms',
            () => _launchManualEntry(),
          ),
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

  /// Action button (non-toggle) for toolbar — LiDAR, Manual Entry, etc.
  Widget _buildActionButton(
    ZaftoColors colors,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colors.textSecondary),
        ),
      ),
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
          onPanStart: _canHandlePan() ? _onDragStart : null,
          onPanUpdate: _canHandlePan() ? _onDragUpdate : null,
          onPanEnd: _canHandlePan() ? _onDragEnd : null,
          onDoubleTapDown: _onDoubleTapDown,
          onLongPressStart: _onLongPressStart,
          child: SizedBox(
            width: 4000,
            height: 4000,
            child: Stack(
              children: [
                // Base floor plan layer
                CustomPaint(
                  size: const Size(4000, 4000),
                  painter: SketchPainter(
                    planData: _planData,
                    selectedElementId: _selectedElementId,
                    selectedElementType: _selectedElementType,
                    ghostWall: _buildGhostWall(),
                    snapIndicator: _snapIndicator,
                    ghostDimensionStart: _dimensionStart,
                    scale: _planData.scale,
                    units: _currentUnits,
                    multiSelectedIds: _multiSelectedIds,
                    lassoPoints:
                        _lassoPoints.length >= 2 ? _lassoPoints : null,
                  ),
                ),
                // SK4: Trade layer overlay
                if (_planData.tradeLayers.isNotEmpty)
                  CustomPaint(
                    size: const Size(4000, 4000),
                    painter: TradeLayerPainter(
                      layers: _planData.tradeLayers,
                      activeLayerId: _activeLayerId,
                      selectedElementId: _selectedTradeElementId,
                      units: _currentUnits,
                      scale: _planData.scale,
                    ),
                  ),
              ],
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
    if (_multiSelectedIds.isNotEmpty) return true; // SK3: multi-select actions

    // SK4: Trade layer bottom sheets
    if (_isTradeLayerActive) {
      final layer = _activeTradeLayer;
      if (layer == null) return false;
      if (layer.type == TradeLayerType.damage) {
        return _activeTradeTool == TradeTool.drawDamageZone ||
            _activeTradeTool == TradeTool.placeEquipment ||
            _activeTradeTool == TradeTool.placeMoisture;
      }
      // Symbol pickers for electrical/plumbing/HVAC
      return _activeTradeTool == TradeTool.placeElecSymbol ||
          _activeTradeTool == TradeTool.placePlumbSymbol ||
          _activeTradeTool == TradeTool.placeHvacSymbol;
    }

    switch (_activeTool) {
      case SketchTool.fixture:
        return true;
      case SketchTool.door:
        return true;
      case SketchTool.window:
        return true;
      case SketchTool.wall:
        return true; // SK2: thickness picker
      case SketchTool.select:
        return _selectedElementId != null;
      default:
        return false;
    }
  }

  Widget _buildBottomToolSheet(ZaftoColors colors) {
    // SK3: Multi-select action bar
    if (_multiSelectedIds.isNotEmpty) {
      return _buildMultiSelectActionBar(colors);
    }

    // SK4: Trade layer bottom sheets
    if (_isTradeLayerActive && _activeTradeLayer != null) {
      return _buildTradeBottomSheet(colors);
    }

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
      case SketchTool.wall:
        return _buildThicknessPickerSheet(colors);
      case SketchTool.select:
        if (_selectedElementId != null) {
          return _buildSelectionSheet(colors);
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  // SK2: Thickness picker for wall drawing mode
  Widget _buildThicknessPickerSheet(ZaftoColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.ruler, size: 14, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Thickness',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          ...[4.0, 6.0, 8.0, 12.0].map((t) {
            final isActive = _newWallThickness == t;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _newWallThickness = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.accentPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? colors.accentPrimary
                          : colors.borderDefault,
                    ),
                  ),
                  child: Text(
                    '${t.round()}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom thickness input
          _buildCustomThicknessChip(colors),
        ],
      ),
    );
  }

  // SK3: Multi-select action bar with copy, paste, delete, deselect
  Widget _buildMultiSelectActionBar(ZaftoColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Text(
            '${_multiSelectedIds.length} selected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          _buildActionChip(colors, LucideIcons.copy, 'Copy', _copySelectedElements),
          const SizedBox(width: 8),
          if (_hasClipboard)
            _buildActionChip(colors, LucideIcons.clipboardPaste, 'Paste', _pasteElements),
          if (_hasClipboard) const SizedBox(width: 8),
          _buildActionChip(colors, LucideIcons.trash2, 'Delete', _deleteSelectedGroup,
              isDestructive: true),
          const SizedBox(width: 8),
          _buildActionChip(colors, LucideIcons.x, 'Clear', () {
            setState(() {
              _multiSelectedIds = {};
              _multiSelectedTypes = {};
            });
          }),
        ],
      ),
    );
  }

  Widget _buildActionChip(
      ZaftoColors colors, IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive
                ? colors.accentError.withValues(alpha: 0.5)
                : colors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isDestructive ? colors.accentError : colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDestructive ? colors.accentError : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomThicknessChip(ZaftoColors colors) {
    final isCustom = ![4.0, 6.0, 8.0, 12.0].contains(_newWallThickness);
    return GestureDetector(
      onTap: () {
        final controller = TextEditingController(
          text: isCustom ? _newWallThickness.toStringAsFixed(0) : '',
        );
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.bgElevated,
            title: Text(
              'Custom Thickness',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            content: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Inches',
                suffixText: '"',
                hintStyle: TextStyle(color: colors.textQuaternary),
              ),
              style: TextStyle(color: colors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text('Cancel', style: TextStyle(color: colors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value != null && value >= 1 && value <= 24) {
                    setState(() => _newWallThickness = value);
                  }
                  Navigator.pop(ctx);
                },
                child: Text('Apply',
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCustom ? colors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCustom ? colors.accentPrimary : colors.borderDefault,
          ),
        ),
        child: Text(
          isCustom ? '${_newWallThickness.toStringAsFixed(0)}"' : 'Custom',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isCustom
                ? (colors.isDark ? Colors.black : Colors.white)
                : colors.textPrimary,
          ),
        ),
      ),
    );
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

    // SK4: Route to trade layer handlers when active
    if (_isTradeLayerActive) {
      _handleTradeToolTap(modelPoint);
      return;
    }

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
      case SketchTool.arcWall:
        _handleArcWallTap(modelPoint);
        break;
      case SketchTool.lasso:
        break; // lasso is handled by pan gestures, not tap
      case SketchTool.pan:
        break; // handled by InteractiveViewer
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_activeTool == SketchTool.wall && _isDrawingWall) {
      // Finish wall chain
      setState(() {
        _isDrawingWall = false;
        _wallStart = null;
        _ghostEnd = null;
        _snapIndicator = null;
        _detectRooms();
      });
      return;
    }

    // SK2: Double-tap on wall → show wall properties sheet
    if (_activeTool == SketchTool.select) {
      final modelPoint = _toModelCoords(details.globalPosition);
      final wall = SketchGeometry.findNearestWall(
        modelPoint,
        _planData.walls,
        threshold: 20.0 / _planData.scale,
      );
      if (wall != null) {
        _showWallPropertiesSheet(wall);
      }
    }
  }

  // SK2: Long press → split wall at tap point
  void _onLongPressStart(LongPressStartDetails details) {
    if (_activeTool != SketchTool.select && _activeTool != SketchTool.wall) {
      return;
    }

    final modelPoint = _toModelCoords(details.globalPosition);
    final wall = SketchGeometry.findNearestWall(
      modelPoint,
      _planData.walls,
      threshold: 20.0 / _planData.scale,
    );
    if (wall == null) return;

    // Project tap onto wall to find split point
    final t = SketchGeometry.projectOntoWall(modelPoint, wall);
    if (t < 0.1 || t > 0.9) return; // Too close to endpoints

    final splitPoint = Offset(
      wall.start.dx + (wall.end.dx - wall.start.dx) * t,
      wall.start.dy + (wall.end.dy - wall.start.dy) * t,
    );

    // Create two new walls from the split
    final wall1 = Wall(
      id: _generateId('wall'),
      start: wall.start,
      end: splitPoint,
      thickness: wall.thickness,
      height: wall.height,
      material: wall.material,
    );
    final wall2 = Wall(
      id: _generateId('wall'),
      start: splitPoint,
      end: wall.end,
      thickness: wall.thickness,
      height: wall.height,
      material: wall.material,
    );

    // Re-parent doors/windows — strict < to avoid edge case at split point
    final updatedDoors = _planData.doors.map((d) {
      if (d.wallId == wall.id) {
        if (d.position < t) {
          return d.copyWith(wallId: wall1.id, position: d.position / t);
        } else {
          return d.copyWith(
              wallId: wall2.id, position: (d.position - t) / (1 - t));
        }
      }
      return d;
    }).toList();

    final updatedWindows = _planData.windows.map((w) {
      if (w.wallId == wall.id) {
        if (w.position < t) {
          return w.copyWith(wallId: wall1.id, position: w.position / t);
        } else {
          return w.copyWith(
              wallId: wall2.id, position: (w.position - t) / (1 - t));
        }
      }
      return w;
    }).toList();

    setState(() {
      _planData = _undoRedo.execute(
        SplitWallCommand(
          originalWall: wall,
          wall1: wall1,
          wall2: wall2,
          originalDoors: _planData.doors,
          updatedDoors: updatedDoors,
          originalWindows: _planData.windows,
          updatedWindows: updatedWindows,
        ),
        _planData,
      );
      _detectRooms();
    });

    HapticFeedback.mediumImpact();
  }

  void _onDragStart(DragStartDetails details) {
    final modelPoint = _toModelCoords(details.globalPosition);

    // SK4: Trade path/zone drawing
    if (_isTradeLayerActive && _isTradePathTool(_activeTradeTool)) {
      _handleTradePathDragStart(modelPoint);
      return;
    }

    // SK3: Lasso tool starts drawing
    if (_activeTool == SketchTool.lasso) {
      _handleLassoDragStart(modelPoint);
      return;
    }

    if (_selectedElementId == null) return;
    final threshold = 24.0 / _planData.scale;

    // SK2: Check wall endpoint handles first
    if (_selectedElementType == 'wall') {
      final wall = _planData.walls
          .where((w) => w.id == _selectedElementId)
          .firstOrNull;
      if (wall != null) {
        if ((wall.start - modelPoint).distance < threshold) {
          _draggingWallEndpointType = 'start';
          _dragOffset = Offset.zero;
          return;
        }
        if ((wall.end - modelPoint).distance < threshold) {
          _draggingWallEndpointType = 'end';
          _dragOffset = Offset.zero;
          return;
        }
      }
    }

    // SK2: Check fixture rotation handle
    if (_selectedElementType == 'fixture') {
      final fixture = _planData.fixtures
          .where((f) => f.id == _selectedElementId)
          .firstOrNull;
      if (fixture != null) {
        // Rotation handle is 22*scale model units above fixture
        final handlePos = Offset(fixture.position.dx, fixture.position.dy - 22);
        if ((handlePos - modelPoint).distance < threshold) {
          _isRotatingFixture = true;
          _rotationBaseAngle = fixture.rotation;
          _rotationStartAngle = atan2(
            modelPoint.dy - fixture.position.dy,
            modelPoint.dx - fixture.position.dx,
          );
          _dragOffset = Offset.zero;
          return;
        }

        // Normal fixture drag (position move)
        if ((fixture.position - modelPoint).distance < threshold) {
          _dragOffset = Offset(
            modelPoint.dx - fixture.position.dx,
            modelPoint.dy - fixture.position.dy,
          );
          return;
        }
      }
    }

    // Label drag
    if (_selectedElementType == 'label') {
      final label = _planData.labels
          .where((l) => l.id == _selectedElementId)
          .firstOrNull;
      if (label != null && (label.position - modelPoint).distance < threshold) {
        _dragOffset = Offset(
          modelPoint.dx - label.position.dx,
          modelPoint.dy - label.position.dy,
        );
      }
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final modelPoint = _toModelCoords(details.globalPosition);

    // SK4: Trade path/zone drawing continuation
    if (_isTradeLayerActive && _tradePathPoints.isNotEmpty) {
      _handleTradePathDragUpdate(modelPoint);
      return;
    }
    if (_isTradeLayerActive && _damageZonePoints.isNotEmpty) {
      _handleDamageZoneDragUpdate(modelPoint);
      return;
    }

    // SK3: Lasso drawing
    if (_activeTool == SketchTool.lasso && _lassoPoints.isNotEmpty) {
      _handleLassoDragUpdate(modelPoint);
      return;
    }

    if (_dragOffset == null || _selectedElementId == null) return;

    setState(() {
      // SK2: Wall endpoint dragging with chain constraint
      if (_draggingWallEndpointType != null &&
          _selectedElementType == 'wall') {
        final wallId = _selectedElementId!;
        final isStart = _draggingWallEndpointType == 'start';

        // Snap to nearby endpoints
        final snapped = SketchGeometry.findNearestEndpoint(
          modelPoint,
          _planData.walls.where((w) => w.id != wallId).toList(),
          threshold: 16.0 / _planData.scale,
        );
        final newPoint = snapped ?? modelPoint;

        // Move the dragged endpoint
        final walls = _planData.walls.map((w) {
          if (w.id == wallId) {
            return isStart
                ? w.copyWith(start: newPoint)
                : w.copyWith(end: newPoint);
          }
          // Chain constraint: move connected wall endpoints
          final draggedWall =
              _planData.walls.where((ww) => ww.id == wallId).first;
          final oldPoint =
              isStart ? draggedWall.start : draggedWall.end;
          final snapDist = 2.0 / _planData.scale;

          if ((w.start - oldPoint).distance < snapDist) {
            return w.copyWith(start: newPoint);
          }
          if ((w.end - oldPoint).distance < snapDist) {
            return w.copyWith(end: newPoint);
          }
          return w;
        }).toList();

        _planData = _planData.copyWith(walls: walls);
        _snapIndicator = snapped;
        return;
      }

      // SK2: Fixture rotation
      if (_isRotatingFixture && _selectedElementType == 'fixture') {
        final fixture = _planData.fixtures
            .where((f) => f.id == _selectedElementId)
            .firstOrNull;
        if (fixture != null) {
          final currentAngle = atan2(
            modelPoint.dy - fixture.position.dy,
            modelPoint.dx - fixture.position.dx,
          );
          final deltaAngle =
              (currentAngle - _rotationStartAngle) * 180 / pi;
          var newRotation = _rotationBaseAngle + deltaAngle;

          // Snap to 45-degree increments
          const snapDegrees = 45.0;
          const snapThreshold = 8.0;
          final nearest =
              (newRotation / snapDegrees).round() * snapDegrees;
          if ((newRotation - nearest).abs() < snapThreshold) {
            newRotation = nearest;
          }

          // Normalize to 0-360
          newRotation = newRotation % 360;
          if (newRotation < 0) newRotation += 360;

          _planData = _planData.copyWith(
            fixtures: _planData.fixtures.map((f) {
              if (f.id == _selectedElementId) {
                return f.copyWith(rotation: newRotation);
              }
              return f;
            }).toList(),
          );
        }
        return;
      }

      // Fixture position drag
      if (_selectedElementType == 'fixture' && !_isRotatingFixture) {
        final newPos = Offset(
          modelPoint.dx - _dragOffset!.dx,
          modelPoint.dy - _dragOffset!.dy,
        );
        _planData = _planData.copyWith(
          fixtures: _planData.fixtures.map((f) {
            if (f.id == _selectedElementId) return f.copyWith(position: newPos);
            return f;
          }).toList(),
        );
        return;
      }

      // Label drag
      if (_selectedElementType == 'label') {
        final newPos = Offset(
          modelPoint.dx - _dragOffset!.dx,
          modelPoint.dy - _dragOffset!.dy,
        );
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
    // SK4: Finish trade path/zone drawing
    if (_isTradeLayerActive && _tradePathPoints.isNotEmpty) {
      _handleTradePathDragEnd();
      return;
    }
    if (_isTradeLayerActive && _damageZonePoints.isNotEmpty) {
      _handleDamageZoneDragEnd();
      return;
    }

    // SK3: Finish lasso
    if (_activeTool == SketchTool.lasso && _lassoPoints.isNotEmpty) {
      _handleLassoDragEnd();
      return;
    }

    if (_draggingWallEndpointType != null) {
      _detectRooms();
    }
    // Record rotation as undoable command
    if (_isRotatingFixture && _selectedElementId != null) {
      final fixture = _planData.fixtures
          .where((f) => f.id == _selectedElementId)
          .firstOrNull;
      if (fixture != null && fixture.rotation != _rotationBaseAngle) {
        // Push to undo stack (rotation already applied in _onDragUpdate)
        _undoRedo.pushExternal(RotateFixtureCommand(
          fixtureId: fixture.id,
          oldRotation: _rotationBaseAngle,
          newRotation: fixture.rotation,
        ));
      }
    }
    _dragOffset = null;
    _draggingWallEndpointType = null;
    _isRotatingFixture = false;
    _snapIndicator = null;
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
          thickness: _newWallThickness,
        );

        setState(() {
          _planData = _undoRedo.execute(AddWallCommand(wall), _planData);
          _addAutoDimension(wall);
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
  // SK2: WALL PROPERTIES SHEET (double-tap)
  // =========================================================================

  void _showWallPropertiesSheet(Wall wall) {
    final colors = ref.read(zaftoColorsProvider);
    double thickness = wall.thickness;
    double height = wall.height.clamp(48.0, 240.0);
    String? material = wall.material;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(LucideIcons.minus, size: 18, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Wall Properties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Length readout
                      Text(
                        _formatDimension(wall.length, _currentUnits),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Thickness presets
                  Text(
                    'Thickness',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...[4.0, 6.0, 8.0, 12.0].map((t) {
                        final isActive = thickness == t;
                        return GestureDetector(
                          onTap: () => setSheetState(() => thickness = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors.accentPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive
                                    ? colors.accentPrimary
                                    : colors.borderDefault,
                              ),
                            ),
                            child: Text(
                              '${t.round()}"',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? (colors.isDark
                                        ? Colors.black
                                        : Colors.white)
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Custom thickness input
                      GestureDetector(
                        onTap: () {
                          final ctrl = TextEditingController(
                            text: ![4.0, 6.0, 8.0, 12.0].contains(thickness)
                                ? thickness.toStringAsFixed(0)
                                : '',
                          );
                          showDialog(
                            context: ctx,
                            builder: (dlg) => AlertDialog(
                              backgroundColor: colors.bgElevated,
                              title: Text('Custom Thickness',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  )),
                              content: TextField(
                                controller: ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Inches',
                                  suffixText: '"',
                                  hintStyle:
                                      TextStyle(color: colors.textQuaternary),
                                ),
                                style: TextStyle(color: colors.textPrimary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dlg),
                                  child: Text('Cancel',
                                      style: TextStyle(
                                          color: colors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final v = double.tryParse(ctrl.text);
                                    if (v != null && v >= 1 && v <= 24) {
                                      setSheetState(() => thickness = v);
                                    }
                                    Navigator.pop(dlg);
                                  },
                                  child: Text('Apply',
                                      style: TextStyle(
                                        color: colors.accentPrimary,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: ![4.0, 6.0, 8.0, 12.0].contains(thickness)
                                ? colors.accentPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  ![4.0, 6.0, 8.0, 12.0].contains(thickness)
                                      ? colors.accentPrimary
                                      : colors.borderDefault,
                            ),
                          ),
                          child: Text(
                            ![4.0, 6.0, 8.0, 12.0].contains(thickness)
                                ? '${thickness.toStringAsFixed(0)}"'
                                : 'Custom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  ![4.0, 6.0, 8.0, 12.0].contains(thickness)
                                      ? (colors.isDark
                                          ? Colors.black
                                          : Colors.white)
                                      : colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Height
                  Row(
                    children: [
                      Text(
                        'Height',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDimension(height, _currentUnits),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: colors.accentPrimary,
                      inactiveTrackColor: colors.borderDefault,
                      thumbColor: colors.accentPrimary,
                    ),
                    child: Slider(
                      value: height,
                      min: 48,
                      max: 240,
                      divisions: 32,
                      onChanged: (v) => setSheetState(() => height = v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Material dropdown
                  Text(
                    'Material',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [null, 'drywall', 'concrete', 'brick', 'wood', 'steel']
                        .map((m) {
                      final isActive = material == m;
                      final label = m ?? 'Default';
                      return GestureDetector(
                        onTap: () => setSheetState(() => material = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? colors.accentPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? colors.accentPrimary
                                  : colors.borderDefault,
                            ),
                          ),
                          child: Text(
                            label[0].toUpperCase() + label.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? (colors.isDark
                                      ? Colors.black
                                      : Colors.white)
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentPrimary,
                        foregroundColor:
                            colors.isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _planData = _undoRedo.execute(
                            UpdateWallPropertiesCommand(
                              wallId: wall.id,
                              oldThickness: wall.thickness,
                              newThickness: thickness,
                              oldHeight: wall.height,
                              newHeight: height,
                              oldMaterial: wall.material,
                              newMaterial: material,
                            ),
                            _planData,
                          );
                        });
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  // SK2: Format a dimension in inches to the current unit system
  String _formatDimension(double inches, MeasurementUnit units) {
    if (units == MeasurementUnit.metric) {
      final cm = inches * 2.54;
      if (cm >= 100) {
        final m = cm / 100;
        return '${m.toStringAsFixed(2)} m';
      }
      return '${cm.toStringAsFixed(1)} cm';
    }
    final feet = inches ~/ 12;
    final remainInches = (inches % 12).round();
    if (feet == 0) return '$remainInches"';
    if (remainInches == 0) return "$feet'";
    return "$feet' $remainInches\"";
  }

  // =========================================================================
  // SK3: PAN HANDLER ROUTING
  // =========================================================================

  bool _canHandlePan() {
    // SK4: Trade path/zone tools use pan for drawing
    if (_isTradeLayerActive) {
      return _isTradePathTool(_activeTradeTool) ||
          _activeTradeTool == TradeTool.drawDamageZone ||
          _activeTradeTool == TradeTool.select;
    }
    return _activeTool == SketchTool.select ||
        _activeTool == SketchTool.lasso;
  }

  // =========================================================================
  // SK3: ARC WALL DRAWING
  // =========================================================================

  void _handleArcWallTap(Offset modelPoint) {
    setState(() {
      if (_arcWallStart == null) {
        // First tap: set start point
        _arcWallStart = modelPoint;
        _arcWallEnd = null;
        _isArcWallAdjusting = false;
      } else if (_arcWallEnd == null) {
        // Second tap: set end point, create arc
        _arcWallEnd = modelPoint;
        // Create arc from start to end with default curvature
        final mid = Offset(
          (_arcWallStart!.dx + _arcWallEnd!.dx) / 2,
          (_arcWallStart!.dy + _arcWallEnd!.dy) / 2,
        );
        final dx = _arcWallEnd!.dx - _arcWallStart!.dx;
        final dy = _arcWallEnd!.dy - _arcWallStart!.dy;
        final chordLen = sqrt(dx * dx + dy * dy);
        if (chordLen < 6) {
          // Too short, cancel
          _arcWallStart = null;
          _arcWallEnd = null;
          return;
        }
        // Default: semicircle. Center = midpoint offset by half chord length.
        final radius = chordLen / 2;
        final startAngle = atan2(
          _arcWallStart!.dy - mid.dy,
          _arcWallStart!.dx - mid.dx,
        );

        final arcWall = ArcWall(
          id: _generateId('arc'),
          center: mid,
          radius: radius,
          startAngle: startAngle,
          sweepAngle: pi, // semicircle
          thickness: _newWallThickness,
        );

        _planData = _undoRedo.execute(AddArcWallCommand(arcWall), _planData);
        _arcWallStart = null;
        _arcWallEnd = null;
        _isArcWallAdjusting = false;
      }
    });
    HapticFeedback.lightImpact();
  }

  // =========================================================================
  // SK3: LASSO SELECTION
  // =========================================================================

  void _handleLassoDragStart(Offset modelPoint) {
    _lassoPoints = [modelPoint];
    _multiSelectedIds = {};
    _multiSelectedTypes = {};
  }

  void _handleLassoDragUpdate(Offset modelPoint) {
    setState(() {
      _lassoPoints.add(modelPoint);
    });
  }

  void _handleLassoDragEnd() {
    if (_lassoPoints.length >= 3) {
      final found = SketchGeometry.findElementsInLasso(_lassoPoints, _planData);
      setState(() {
        _multiSelectedIds = found.keys.toSet();
        _multiSelectedTypes = found;
        _lassoPoints = [];
        // Clear single selection when multi-selecting
        if (_multiSelectedIds.isNotEmpty) {
          _selectedElementId = null;
          _selectedElementType = null;
        }
      });
    } else {
      setState(() {
        _lassoPoints = [];
      });
    }
  }

  // =========================================================================
  // SK3: MULTI-SELECT (Toggle-tap mode)
  // =========================================================================

  void _toggleMultiSelect(String id, String type) {
    setState(() {
      if (_multiSelectedIds.contains(id)) {
        _multiSelectedIds.remove(id);
        _multiSelectedTypes.remove(id);
      } else {
        _multiSelectedIds.add(id);
        _multiSelectedTypes[id] = type;
      }
    });
  }

  // =========================================================================
  // SK3: COPY/PASTE
  // =========================================================================

  void _copySelectedElements() {
    _clipboardWalls = [];
    _clipboardArcWalls = [];
    _clipboardFixtures = [];
    _clipboardLabels = [];
    _clipboardDimensions = [];

    final ids = _multiSelectedIds.isNotEmpty
        ? _multiSelectedIds
        : (_selectedElementId != null ? {_selectedElementId!} : <String>{});

    for (final id in ids) {
      for (final w in _planData.walls) {
        if (w.id == id) _clipboardWalls.add(w);
      }
      for (final a in _planData.arcWalls) {
        if (a.id == id) _clipboardArcWalls.add(a);
      }
      for (final f in _planData.fixtures) {
        if (f.id == id) _clipboardFixtures.add(f);
      }
      for (final l in _planData.labels) {
        if (l.id == id) _clipboardLabels.add(l);
      }
      for (final d in _planData.dimensions) {
        if (d.id == id) _clipboardDimensions.add(d);
      }
    }
    HapticFeedback.lightImpact();
  }

  bool get _hasClipboard =>
      _clipboardWalls.isNotEmpty ||
      _clipboardArcWalls.isNotEmpty ||
      _clipboardFixtures.isNotEmpty ||
      _clipboardLabels.isNotEmpty ||
      _clipboardDimensions.isNotEmpty;

  void _pasteElements() {
    if (!_hasClipboard) return;

    const pasteOffset = Offset(48, 48); // 4 feet offset
    final commands = <SketchCommand>[];

    for (final w in _clipboardWalls) {
      final newWall = w.copyWith(
        id: _generateId('wall'),
        start: w.start + pasteOffset,
        end: w.end + pasteOffset,
      );
      commands.add(AddWallCommand(newWall));
    }
    for (final a in _clipboardArcWalls) {
      final newArc = a.copyWith(
        id: _generateId('arc'),
        center: a.center + pasteOffset,
      );
      commands.add(AddArcWallCommand(newArc));
    }
    for (final f in _clipboardFixtures) {
      final newFixture = f.copyWith(
        id: _generateId('fix'),
        position: f.position + pasteOffset,
      );
      commands.add(AddFixtureCommand(newFixture));
    }
    for (final l in _clipboardLabels) {
      final newLabel = l.copyWith(
        id: _generateId('lbl'),
        position: l.position + pasteOffset,
      );
      commands.add(AddLabelCommand(newLabel));
    }
    for (final d in _clipboardDimensions) {
      final newDim = d.copyWith(
        id: _generateId('dim'),
        start: d.start + pasteOffset,
        end: d.end + pasteOffset,
      );
      commands.add(AddDimensionCommand(newDim));
    }

    if (commands.isNotEmpty) {
      setState(() {
        _planData = _undoRedo.execute(BatchCommand(commands), _planData);
        _detectRooms();
      });
      HapticFeedback.mediumImpact();
    }
  }

  // =========================================================================
  // SK3: GROUP OPERATIONS
  // =========================================================================

  void _deleteSelectedGroup() {
    if (_multiSelectedIds.isEmpty) return;

    final commands = <SketchCommand>[];
    for (final id in _multiSelectedIds) {
      final type = _multiSelectedTypes[id];
      if (type == 'wall') {
        final w = _planData.walls.where((w) => w.id == id).firstOrNull;
        if (w != null) commands.add(RemoveWallCommand(w));
      } else if (type == 'arcWall') {
        final a = _planData.arcWalls.where((a) => a.id == id).firstOrNull;
        if (a != null) commands.add(RemoveArcWallCommand(a));
      } else if (type == 'fixture') {
        final f = _planData.fixtures.where((f) => f.id == id).firstOrNull;
        if (f != null) commands.add(RemoveFixtureCommand(f));
      } else if (type == 'label') {
        final l = _planData.labels.where((l) => l.id == id).firstOrNull;
        if (l != null) commands.add(RemoveLabelCommand(l));
      } else if (type == 'dimension') {
        final d = _planData.dimensions.where((d) => d.id == id).firstOrNull;
        if (d != null) commands.add(RemoveDimensionCommand(d));
      }
    }

    if (commands.isNotEmpty) {
      setState(() {
        _planData = _undoRedo.execute(BatchCommand(commands), _planData);
        _multiSelectedIds = {};
        _multiSelectedTypes = {};
        _detectRooms();
      });
      HapticFeedback.mediumImpact();
    }
  }

  // =========================================================================
  // SK3: AUTO-DIMENSIONS (wall lengths on draw)
  // =========================================================================

  void _addAutoDimension(Wall wall) {
    if (!_autoDimensions) return;
    if (wall.length < 12) return; // skip tiny walls (< 1 foot)

    final normal = wall.normal;
    const offset = 18.0; // dimension offset from wall in inches

    final dim = DimensionLine(
      id: _generateId('adim'),
      start: Offset(
        wall.start.dx + normal.dx * offset,
        wall.start.dy + normal.dy * offset,
      ),
      end: Offset(
        wall.end.dx + normal.dx * offset,
        wall.end.dy + normal.dy * offset,
      ),
    );

    _planData = _planData.copyWith(
      dimensions: [..._planData.dimensions, dim],
    );
  }

  String _generateId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(9999);
    return '${prefix}_${now}_$rand';
  }

  // =========================================================================
  // SK4: TRADE LAYER MANAGEMENT
  // =========================================================================

  void _setActiveLayer(String? layerId) {
    setState(() {
      _activeLayerId = layerId;
      _activeTradeTool = TradeTool.select;
      _resetTradeDrawingState();
      // When switching to base layer, clear trade selection
      if (layerId == null) {
        _selectedTradeElementId = null;
      }
    });
  }

  void _toggleLayerVisibility(String layerId) {
    setState(() {
      _planData = _planData.copyWith(
        tradeLayers: _planData.tradeLayers.map((l) {
          if (l.id == layerId) return l.copyWith(visible: !l.visible);
          return l;
        }).toList(),
      );
    });
  }

  void _toggleLayerLock(String layerId) {
    setState(() {
      _planData = _planData.copyWith(
        tradeLayers: _planData.tradeLayers.map((l) {
          if (l.id == layerId) return l.copyWith(locked: !l.locked);
          return l;
        }).toList(),
      );
    });
  }

  void _setLayerOpacity(String layerId, double opacity) {
    setState(() {
      _planData = _planData.copyWith(
        tradeLayers: _planData.tradeLayers.map((l) {
          if (l.id == layerId) return l.copyWith(opacity: opacity);
          return l;
        }).toList(),
      );
    });
  }

  void _removeLayer(String layerId) {
    setState(() {
      if (_activeLayerId == layerId) {
        _activeLayerId = null;
        _activeTradeTool = TradeTool.select;
      }
      _planData = _planData.copyWith(
        tradeLayers: _planData.tradeLayers
            .where((l) => l.id != layerId)
            .toList(),
      );
    });
  }

  void _showAddLayerDialog(ZaftoColors colors) {
    // Check which layer types are already in use
    final existing =
        _planData.tradeLayers.map((l) => l.type).toSet();
    final available = TradeLayerType.values
        .where((t) => !existing.contains(t))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All trade layers already added'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF6B7280),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Trade Layer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...available.map((type) {
                final layerColor =
                    Color(tradeLayerColors[type] ?? 0xFF6B7280);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: layerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForLayerType(type),
                      size: 16,
                      color: layerColor,
                    ),
                  ),
                  title: Text(
                    tradeLayerLabels[type] ?? type.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _layerDescription(type),
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textTertiary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addTradeLayer(type);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _addTradeLayer(TradeLayerType type) {
    final layer = TradeLayer(
      id: _generateId('layer'),
      type: type,
    );
    setState(() {
      _planData = _planData.copyWith(
        tradeLayers: [..._planData.tradeLayers, layer],
      );
      _activeLayerId = layer.id;
      _activeTradeTool = TradeTool.select;
    });
    HapticFeedback.mediumImpact();
  }

  IconData _iconForLayerType(TradeLayerType type) {
    switch (type) {
      case TradeLayerType.electrical:
        return LucideIcons.zap;
      case TradeLayerType.plumbing:
        return LucideIcons.droplet;
      case TradeLayerType.hvac:
        return LucideIcons.wind;
      case TradeLayerType.damage:
        return LucideIcons.alertTriangle;
    }
  }

  String _layerDescription(TradeLayerType type) {
    switch (type) {
      case TradeLayerType.electrical:
        return 'Outlets, switches, lights, panels, wire runs';
      case TradeLayerType.plumbing:
        return 'Fixtures, valves, pipe runs (hot/cold/drain/gas)';
      case TradeLayerType.hvac:
        return 'Equipment, ducts, registers, dampers';
      case TradeLayerType.damage:
        return 'Damage zones, moisture readings, containment, equipment';
    }
  }

  // =========================================================================
  // SK5: LiDAR SCAN & MANUAL ENTRY
  // =========================================================================

  Future<void> _launchLidarScan(ZaftoColors colors) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => const LidarScanScreen()),
    );

    if (!mounted || result == null) return;

    if (result == 'manual') {
      // User chose manual entry from unavailable screen
      _launchManualEntry();
      return;
    }

    if (result is FloorPlanData) {
      _importScannedPlan(result);
    }
  }

  // FIELD4: Launch laser meter bottom sheet
  void _launchLaserMeter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (_) => const LaserMeterSheet(),
    );
  }

  Future<void> _launchManualEntry() async {
    final result = await Navigator.push<FloorPlanData>(
      context,
      MaterialPageRoute(builder: (_) => const ManualRoomEntryScreen()),
    );

    if (!mounted || result == null) return;
    _importScannedPlan(result);
  }

  /// Merge imported plan data into current plan (scanned or manual).
  /// Scanned data is fully editable after import.
  void _importScannedPlan(FloorPlanData imported) {
    // Merge walls, doors, windows, fixtures, rooms into current plan
    final merged = _planData.copyWith(
      walls: [..._planData.walls, ...imported.walls],
      doors: [..._planData.doors, ...imported.doors],
      windows: [..._planData.windows, ...imported.windows],
      fixtures: [..._planData.fixtures, ...imported.fixtures],
      rooms: [..._planData.rooms, ...imported.rooms],
    );

    setState(() {
      _planData = merged;
      // Update current floor data
      if (_floors.isNotEmpty) {
        _floors[_currentFloorIndex] = _floors[_currentFloorIndex].copyWith(
          data: merged,
        );
      }
    });

    // Show success feedback
    HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${imported.walls.length} walls, '
            '${imported.doors.length} doors, '
            '${imported.windows.length} windows, '
            '${imported.rooms.length} rooms',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetTradeDrawingState() {
    _tradePathPoints = [];
    _damageZonePoints = [];
    _containmentStart = null;
    _selectedTradeElementId = null;
  }

  // =========================================================================
  // SK4: TRADE TOOL HANDLERS
  // =========================================================================

  void _handleTradeToolTap(Offset modelPoint) {
    final layer = _activeTradeLayer;
    if (layer == null || layer.locked) return;

    switch (_activeTradeTool) {
      case TradeTool.select:
        _handleTradeSelectTap(modelPoint, layer);
        break;
      case TradeTool.erase:
        _handleTradeEraseTap(modelPoint, layer);
        break;
      case TradeTool.placeElecSymbol:
      case TradeTool.placePlumbSymbol:
      case TradeTool.placeHvacSymbol:
        _handleTradeSymbolPlacement(modelPoint, layer);
        break;
      case TradeTool.drawWire:
      case TradeTool.drawCircuit:
      case TradeTool.drawPipeHot:
      case TradeTool.drawPipeCold:
      case TradeTool.drawPipeDrain:
      case TradeTool.drawPipeGas:
      case TradeTool.drawDuctSupply:
      case TradeTool.drawDuctReturn:
        _handleTradePathTap(modelPoint, layer);
        break;
      case TradeTool.drawDamageZone:
        _handleDamageZoneTap(modelPoint, layer);
        break;
      case TradeTool.placeMoisture:
        _handleMoistureReadingTap(modelPoint, layer);
        break;
      case TradeTool.drawContainment:
        _handleContainmentTap(modelPoint, layer);
        break;
      case TradeTool.placeEquipment:
        _handleEquipmentPlacementTap(modelPoint, layer);
        break;
    }
  }

  void _handleTradeSelectTap(Offset modelPoint, TradeLayer layer) {
    final threshold = 20.0 / _planData.scale;
    String? foundId;

    // Check trade elements
    for (final el in layer.tradeData.elements) {
      if ((el.position - modelPoint).distance < threshold) {
        foundId = el.id;
        break;
      }
    }

    // Check moisture readings (damage layer)
    if (foundId == null && layer.type == TradeLayerType.damage) {
      for (final r in layer.moistureReadings) {
        if ((r.position - modelPoint).distance < threshold) {
          foundId = r.id;
          break;
        }
      }
    }

    // Check equipment (damage layer)
    if (foundId == null && layer.type == TradeLayerType.damage) {
      for (final b in layer.damageData.barriers) {
        if ((b.position - modelPoint).distance < threshold) {
          foundId = b.id;
          break;
        }
      }
    }

    setState(() {
      _selectedTradeElementId = foundId;
    });
  }

  void _handleTradeEraseTap(Offset modelPoint, TradeLayer layer) {
    final threshold = 20.0 / _planData.scale;

    // Try to erase trade elements
    for (final el in layer.tradeData.elements) {
      if ((el.position - modelPoint).distance < threshold) {
        setState(() {
          _planData = _undoRedo.execute(
            RemoveTradeElementCommand(
                layerId: layer.id, element: el),
            _planData,
          );
        });
        HapticFeedback.lightImpact();
        return;
      }
    }

    // Try to erase trade paths (check each segment)
    for (final path in layer.tradeData.paths) {
      for (int i = 0; i < path.points.length - 1; i++) {
        final dist = SketchGeometry.pointToSegmentDistance(
            modelPoint, path.points[i], path.points[i + 1]);
        if (dist < threshold) {
          setState(() {
            _planData = _undoRedo.execute(
              RemoveTradePathCommand(
                  layerId: layer.id, path: path),
              _planData,
            );
          });
          HapticFeedback.lightImpact();
          return;
        }
      }
    }

    // Try to erase damage zones
    if (layer.type == TradeLayerType.damage) {
      for (final zone in layer.damageData.zones) {
        if (SketchGeometry.pointInPolygon(modelPoint, zone.boundary)) {
          setState(() {
            _planData = _undoRedo.execute(
              RemoveDamageZoneCommand(
                  layerId: layer.id, zone: zone),
              _planData,
            );
          });
          HapticFeedback.lightImpact();
          return;
        }
      }
    }
  }

  void _handleTradeSymbolPlacement(Offset modelPoint, TradeLayer layer) {
    if (_pendingTradeSymbol == null) return;

    final element = TradeElement(
      id: _generateId('te'),
      position: modelPoint,
      symbolType: _pendingTradeSymbol!,
    );

    setState(() {
      _planData = _undoRedo.execute(
        AddTradeElementCommand(layerId: layer.id, element: element),
        _planData,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _handleTradePathTap(Offset modelPoint, TradeLayer layer) {
    // Tap adds a point to the active path. Double-tap finishes.
    setState(() {
      _tradePathPoints.add(modelPoint);
    });
  }

  bool _isTradePathTool(TradeTool tool) {
    return tool == TradeTool.drawWire ||
        tool == TradeTool.drawCircuit ||
        tool == TradeTool.drawPipeHot ||
        tool == TradeTool.drawPipeCold ||
        tool == TradeTool.drawPipeDrain ||
        tool == TradeTool.drawPipeGas ||
        tool == TradeTool.drawDuctSupply ||
        tool == TradeTool.drawDuctReturn;
  }

  String _pathTypeForTool(TradeTool tool) {
    switch (tool) {
      case TradeTool.drawWire:
        return 'wire';
      case TradeTool.drawCircuit:
        return 'circuit';
      case TradeTool.drawPipeHot:
        return 'pipe_hot';
      case TradeTool.drawPipeCold:
        return 'pipe_cold';
      case TradeTool.drawPipeDrain:
        return 'pipe_drain';
      case TradeTool.drawPipeGas:
        return 'pipe_gas';
      case TradeTool.drawDuctSupply:
        return 'duct_supply';
      case TradeTool.drawDuctReturn:
        return 'duct_return';
      default:
        return 'wire';
    }
  }

  void _handleTradePathDragStart(Offset modelPoint) {
    setState(() {
      _tradePathPoints = [modelPoint];
    });
  }

  void _handleTradePathDragUpdate(Offset modelPoint) {
    setState(() {
      // Add points with minimum distance to avoid noise
      if (_tradePathPoints.isEmpty ||
          (modelPoint - _tradePathPoints.last).distance > 6.0) {
        _tradePathPoints.add(modelPoint);
      }
    });
  }

  void _handleTradePathDragEnd() {
    if (_tradePathPoints.length < 2) {
      setState(() => _tradePathPoints = []);
      return;
    }

    final layer = _activeTradeLayer;
    if (layer == null) return;

    final pathType = _pathTypeForTool(_activeTradeTool);
    final colorValue = pipePathColors[pathType] ?? 0xFF000000;
    final isDashed = _activeTradeTool == TradeTool.drawCircuit;

    // Simplify polyline to reduce points (Douglas-Peucker style)
    final simplified = _simplifyPath(_tradePathPoints, 4.0);

    final path = TradePath(
      id: _generateId('tp'),
      points: simplified,
      pathType: pathType,
      strokeWidth: pathType.startsWith('duct') ? 4.0 : 2.0,
      colorValue: colorValue,
      isDashed: isDashed,
    );

    setState(() {
      _planData = _undoRedo.execute(
        AddTradePathCommand(layerId: layer.id, path: path),
        _planData,
      );
      _tradePathPoints = [];
    });
    HapticFeedback.lightImpact();
  }

  // Simplified Douglas-Peucker path simplification
  List<Offset> _simplifyPath(List<Offset> points, double epsilon) {
    if (points.length <= 2) return List.from(points);

    // Find the point with the maximum distance from the line start→end
    double maxDist = 0;
    int maxIndex = 0;
    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = SketchGeometry.pointToSegmentDistance(
          points[i], start, end);
      if (dist > maxDist) {
        maxDist = dist;
        maxIndex = i;
      }
    }

    if (maxDist > epsilon) {
      final left = _simplifyPath(points.sublist(0, maxIndex + 1), epsilon);
      final right = _simplifyPath(points.sublist(maxIndex), epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  // =========================================================================
  // SK4: DAMAGE LAYER HANDLERS
  // =========================================================================

  void _handleDamageZoneTap(Offset modelPoint, TradeLayer layer) {
    // Tap adds a point to the zone polygon
    setState(() {
      _damageZonePoints.add(modelPoint);
    });
  }

  void _handleDamageZoneDragUpdate(Offset modelPoint) {
    setState(() {
      if (_damageZonePoints.isEmpty ||
          (modelPoint - _damageZonePoints.last).distance > 6.0) {
        _damageZonePoints.add(modelPoint);
      }
    });
  }

  void _handleDamageZoneDragEnd() {
    if (_damageZonePoints.length < 3) {
      setState(() => _damageZonePoints = []);
      return;
    }

    final layer = _activeTradeLayer;
    if (layer == null || layer.type != TradeLayerType.damage) return;

    final zone = DamageZone(
      id: _generateId('dz'),
      boundary: List.from(_damageZonePoints),
      damageType: 'water',
      damageClass: _selectedDamageClass,
      iicrcCategory: _selectedIicrcCategory,
      colorValue:
          IicrcClassification.colorForCategory(_selectedIicrcCategory),
    );

    setState(() {
      _planData = _undoRedo.execute(
        AddDamageZoneCommand(layerId: layer.id, zone: zone),
        _planData,
      );
      _damageZonePoints = [];
    });
    HapticFeedback.lightImpact();
  }

  void _handleMoistureReadingTap(Offset modelPoint, TradeLayer layer) {
    // Show a dialog to enter moisture reading value
    _showMoistureReadingDialog(modelPoint, layer);
  }

  void _showMoistureReadingDialog(Offset position, TradeLayer layer) {
    final controller = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ref.watch(zaftoColorsProvider);
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          title: Text(
            'Moisture Reading',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Moisture % (0-100)',
                  labelStyle: TextStyle(
                      fontSize: 12, color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final value =
                    double.tryParse(controller.text)?.clamp(0, 100) ??
                        0.0;
                Navigator.pop(ctx);
                _addMoistureReading(position, value.toDouble(), layer);
              },
              child: Text('Add',
                  style: TextStyle(color: colors.accentPrimary)),
            ),
          ],
        );
      },
    );
  }

  void _addMoistureReading(
      Offset position, double value, TradeLayer layer) {
    final severity = MoistureReading.severityFromValue(value);
    final reading = MoistureReading(
      id: _generateId('mr'),
      position: position,
      value: value,
      severity: severity,
      timestamp: DateTime.now(),
    );

    setState(() {
      _planData = _undoRedo.execute(
        AddMoistureReadingCommand(
            layerId: layer.id, reading: reading),
        _planData,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _handleContainmentTap(Offset modelPoint, TradeLayer layer) {
    if (_containmentStart == null) {
      // First tap: set start point
      setState(() => _containmentStart = modelPoint);
    } else {
      // Second tap: complete containment line
      final line = ContainmentLine(
        id: _generateId('cl'),
        start: _containmentStart!,
        end: modelPoint,
      );

      setState(() {
        _planData = _undoRedo.execute(
          AddContainmentLineCommand(layerId: layer.id, line: line),
          _planData,
        );
        _containmentStart = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _handleEquipmentPlacementTap(
      Offset modelPoint, TradeLayer layer) {
    final barrier = DamageBarrier(
      id: _generateId('db'),
      position: modelPoint,
      barrierType: _selectedEquipment,
    );

    setState(() {
      _planData = _undoRedo.execute(
        AddDamageBarrierCommand(layerId: layer.id, barrier: barrier),
        _planData,
      );
    });
    HapticFeedback.lightImpact();
  }

  // =========================================================================
  // SK4: TRADE BOTTOM SHEET BUILDER
  // =========================================================================

  Widget _buildTradeBottomSheet(ZaftoColors colors) {
    final layer = _activeTradeLayer!;

    // Damage layer: show damage class/category/equipment pickers
    if (layer.type == TradeLayerType.damage) {
      return DamageToolsSheet(
        activeTool: _activeTradeTool,
        selectedDamageClass: _selectedDamageClass,
        selectedIicrcCategory: _selectedIicrcCategory,
        selectedEquipment: _selectedEquipment,
        onDamageClassChanged: (cls) {
          setState(() => _selectedDamageClass = cls);
        },
        onIicrcCategoryChanged: (cat) {
          setState(() => _selectedIicrcCategory = cat);
        },
        onEquipmentSelected: (eq) {
          setState(() => _selectedEquipment = eq);
        },
        colors: colors,
      );
    }

    // Trade symbol picker for electrical/plumbing/HVAC
    return TradeSymbolPickerSheet(
      layerType: layer.type,
      selectedSymbol: _pendingTradeSymbol,
      onSymbolSelected: (symbol) {
        setState(() => _pendingTradeSymbol = symbol);
      },
      colors: colors,
    );
  }
}

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
