// ZAFTO Trade Toolbar — SK4
// Per-trade toolbars that swap based on active layer selection.
// Shows trade-specific tools (symbol placement, path drawing, etc.)
// and a symbol picker for the active trade.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/floor_plan_elements.dart';
import '../../models/trade_layer.dart';
import '../../theme/zafto_colors.dart';

// =============================================================================
// TRADE TOOLBAR — Left sidebar replacement when trade layer is active
// =============================================================================

class TradeToolbar extends StatelessWidget {
  final TradeLayerType layerType;
  final TradeTool activeTool;
  final ValueChanged<TradeTool> onToolChanged;
  final ZaftoColors colors;

  const TradeToolbar({
    super.key,
    required this.layerType,
    required this.activeTool,
    required this.onToolChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final tools = tradeToolsForLayer[layerType] ?? [];
    final layerColor = Color(tradeLayerColors[layerType] ?? 0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: layerColor.withValues(alpha: 0.4)),
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
          // Layer indicator
          _buildLayerIndicator(layerColor),
          _buildDivider(),
          // Tools
          ...tools.map((tool) => _buildToolButton(tool, layerColor)),
        ],
      ),
    );
  }

  Widget _buildLayerIndicator(Color layerColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Container(
        width: 42,
        height: 22,
        decoration: BoxDecoration(
          color: layerColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            _layerAbbrev(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: layerColor,
            ),
          ),
        ),
      ),
    );
  }

  String _layerAbbrev() {
    switch (layerType) {
      case TradeLayerType.electrical:
        return 'ELEC';
      case TradeLayerType.plumbing:
        return 'PLMB';
      case TradeLayerType.hvac:
        return 'HVAC';
      case TradeLayerType.damage:
        return 'DMG';
    }
  }

  Widget _buildToolButton(TradeTool tool, Color layerColor) {
    final isSelected = activeTool == tool;
    final icon = _iconForTool(tool);
    final tooltip = _tooltipForTool(tool);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onToolChanged(tool);
        },
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isSelected
                ? layerColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? layerColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      height: 1,
      color: colors.borderDefault,
    );
  }

  IconData _iconForTool(TradeTool tool) {
    switch (tool) {
      case TradeTool.select:
        return LucideIcons.mousePointer;
      case TradeTool.erase:
        return LucideIcons.eraser;
      case TradeTool.placeElecSymbol:
        return LucideIcons.zap;
      case TradeTool.drawWire:
        return LucideIcons.minus;
      case TradeTool.drawCircuit:
        return LucideIcons.gitBranch;
      case TradeTool.placePlumbSymbol:
        return LucideIcons.droplet;
      case TradeTool.drawPipeHot:
        return LucideIcons.thermometer;
      case TradeTool.drawPipeCold:
        return LucideIcons.snowflake;
      case TradeTool.drawPipeDrain:
        return LucideIcons.arrowDown;
      case TradeTool.drawPipeGas:
        return LucideIcons.flame;
      case TradeTool.placeHvacSymbol:
        return LucideIcons.wind;
      case TradeTool.drawDuctSupply:
        return LucideIcons.arrowUpRight;
      case TradeTool.drawDuctReturn:
        return LucideIcons.arrowDownLeft;
      case TradeTool.drawDamageZone:
        return LucideIcons.hexagon;
      case TradeTool.placeMoisture:
        return LucideIcons.droplets;
      case TradeTool.drawContainment:
        return LucideIcons.shield;
      case TradeTool.placeEquipment:
        return LucideIcons.box;
    }
  }

  String _tooltipForTool(TradeTool tool) {
    switch (tool) {
      case TradeTool.select:
        return 'Select';
      case TradeTool.erase:
        return 'Erase';
      case TradeTool.placeElecSymbol:
        return 'Place Symbol';
      case TradeTool.drawWire:
        return 'Draw Wire';
      case TradeTool.drawCircuit:
        return 'Draw Circuit';
      case TradeTool.placePlumbSymbol:
        return 'Place Symbol';
      case TradeTool.drawPipeHot:
        return 'Hot Pipe (Red)';
      case TradeTool.drawPipeCold:
        return 'Cold Pipe (Blue)';
      case TradeTool.drawPipeDrain:
        return 'Drain (Gray)';
      case TradeTool.drawPipeGas:
        return 'Gas (Yellow)';
      case TradeTool.placeHvacSymbol:
        return 'Place Equipment';
      case TradeTool.drawDuctSupply:
        return 'Supply Duct';
      case TradeTool.drawDuctReturn:
        return 'Return Duct';
      case TradeTool.drawDamageZone:
        return 'Damage Zone';
      case TradeTool.placeMoisture:
        return 'Moisture Reading';
      case TradeTool.drawContainment:
        return 'Containment';
      case TradeTool.placeEquipment:
        return 'Equipment';
    }
  }
}

// =============================================================================
// TRADE SYMBOL PICKER — Bottom sheet for picking symbols within a trade
// =============================================================================

class TradeSymbolPickerSheet extends StatelessWidget {
  final TradeLayerType layerType;
  final TradeSymbolType? selectedSymbol;
  final ValueChanged<TradeSymbolType> onSymbolSelected;
  final ZaftoColors colors;

  const TradeSymbolPickerSheet({
    super.key,
    required this.layerType,
    this.selectedSymbol,
    required this.onSymbolSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final groups = tradeSymbolGroups[layerType] ?? {};
    final layerColor = Color(tradeLayerColors[layerType] ?? 0xFF6B7280);

    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: layerColor.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: layerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${tradeLayerLabels[layerType]} Symbols',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Symbol groups
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: groups.entries.expand((group) {
                return [
                  // Group label
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.key,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: group.value.map((symbol) {
                            final isActive = selectedSymbol == symbol;
                            final label =
                                tradeSymbolLabels[symbol] ?? symbol.name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onSymbolSelected(symbol);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? layerColor.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isActive
                                          ? layerColor
                                          : colors.borderDefault,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _iconForSymbol(symbol),
                                        size: 16,
                                        color: isActive
                                            ? layerColor
                                            : colors.textSecondary,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w500,
                                          color: isActive
                                              ? layerColor
                                              : colors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Group separator
                  const SizedBox(width: 6),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSymbol(TradeSymbolType symbol) {
    switch (symbol) {
      // Electrical
      case TradeSymbolType.outlet120v:
      case TradeSymbolType.outlet240v:
        return LucideIcons.plug;
      case TradeSymbolType.gfciOutlet:
        return LucideIcons.shieldCheck;
      case TradeSymbolType.switchSingle:
      case TradeSymbolType.switchThreeWay:
      case TradeSymbolType.switchDimmer:
      case TradeSymbolType.lightSwitch:
        return LucideIcons.toggleLeft;
      case TradeSymbolType.junctionBox:
        return LucideIcons.box;
      case TradeSymbolType.panelMain:
      case TradeSymbolType.panelSub:
        return LucideIcons.server;
      case TradeSymbolType.lightFixture:
      case TradeSymbolType.lightRecessed:
        return LucideIcons.lightbulb;
      case TradeSymbolType.smokeDetector:
        return LucideIcons.bell;
      case TradeSymbolType.thermostat:
        return LucideIcons.thermometer;
      case TradeSymbolType.ceilingFan:
        return LucideIcons.fan;
      // Plumbing
      case TradeSymbolType.pipeHot:
        return LucideIcons.thermometer;
      case TradeSymbolType.pipeCold:
        return LucideIcons.snowflake;
      case TradeSymbolType.pipeDrain:
        return LucideIcons.arrowDown;
      case TradeSymbolType.pipeVent:
        return LucideIcons.arrowUp;
      case TradeSymbolType.cleanout:
        return LucideIcons.circle;
      case TradeSymbolType.shutoffValve:
      case TradeSymbolType.prv:
        return LucideIcons.disc;
      case TradeSymbolType.waterMeter:
        return LucideIcons.gauge;
      case TradeSymbolType.seweLine:
        return LucideIcons.minus;
      case TradeSymbolType.hosebibb:
        return LucideIcons.droplet;
      case TradeSymbolType.floorDrain:
        return LucideIcons.circleDot;
      case TradeSymbolType.sumpPump:
        return LucideIcons.arrowUpCircle;
      // HVAC
      case TradeSymbolType.supplyDuct:
        return LucideIcons.arrowUpRight;
      case TradeSymbolType.returnDuct:
        return LucideIcons.arrowDownLeft;
      case TradeSymbolType.flexDuct:
        return LucideIcons.spline;
      case TradeSymbolType.register:
        return LucideIcons.grid;
      case TradeSymbolType.returnGrille:
        return LucideIcons.layoutGrid;
      case TradeSymbolType.damper:
        return LucideIcons.slidersHorizontal;
      case TradeSymbolType.airHandler:
        return LucideIcons.wind;
      case TradeSymbolType.condenser:
        return LucideIcons.snowflake;
      case TradeSymbolType.miniSplit:
        return LucideIcons.thermometerSnowflake;
      case TradeSymbolType.exhaustFan:
        return LucideIcons.fan;
      // Damage
      case TradeSymbolType.waterDamage:
        return LucideIcons.droplets;
      case TradeSymbolType.fireDamage:
        return LucideIcons.flame;
      case TradeSymbolType.moldPresent:
        return LucideIcons.bug;
      case TradeSymbolType.asbestosWarning:
        return LucideIcons.alertTriangle;
    }
  }
}

// =============================================================================
// DAMAGE TOOLS SHEET — Bottom sheet for damage-specific tools
// =============================================================================

class DamageToolsSheet extends StatelessWidget {
  final TradeTool activeTool;
  final String? selectedDamageClass; // '1'-'4'
  final String? selectedIicrcCategory; // '1'-'3'
  final BarrierType? selectedEquipment;
  final ValueChanged<String> onDamageClassChanged;
  final ValueChanged<String> onIicrcCategoryChanged;
  final ValueChanged<BarrierType> onEquipmentSelected;
  final ZaftoColors colors;

  const DamageToolsSheet({
    super.key,
    required this.activeTool,
    this.selectedDamageClass,
    this.selectedIicrcCategory,
    this.selectedEquipment,
    required this.onDamageClassChanged,
    required this.onIicrcCategoryChanged,
    required this.onEquipmentSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
            top: BorderSide(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeTool == TradeTool.drawDamageZone) ...[
            _buildSectionLabel('Damage Class'),
            _buildClassPicker(),
            const SizedBox(height: 6),
            _buildSectionLabel('IICRC Water Category'),
            _buildCategoryPicker(),
          ],
          if (activeTool == TradeTool.placeEquipment) ...[
            _buildSectionLabel('Equipment Type'),
            _buildEquipmentPicker(),
          ],
          if (activeTool == TradeTool.placeMoisture)
            _buildSectionLabel('Tap to place moisture reading point'),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildClassPicker() {
    return Row(
      children: ['1', '2', '3', '4'].map((cls) {
        final isActive = selectedDamageClass == cls;
        final color = Color(IicrcClassification.colorForClass(cls));
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDamageClassChanged(cls);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? color : colors.borderDefault,
                ),
              ),
              child: Text(
                'Class $cls',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : colors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryPicker() {
    return Row(
      children: ['1', '2', '3'].map((cat) {
        final isActive = selectedIicrcCategory == cat;
        final color = Color(IicrcClassification.colorForCategory(cat));
        final labels = {'1': 'Cat 1 (Clean)', '2': 'Cat 2 (Gray)', '3': 'Cat 3 (Black)'};
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onIicrcCategoryChanged(cat);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? color : colors.borderDefault,
                ),
              ),
              child: Text(
                labels[cat] ?? 'Cat $cat',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentPicker() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: BarrierType.values.map((type) {
        final isActive = selectedEquipment == type;
        final label = _equipmentLabel(type);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onEquipmentSelected(type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFF97316).withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFF97316)
                    : colors.borderDefault,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFFF97316)
                    : colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _equipmentLabel(BarrierType type) {
    switch (type) {
      case BarrierType.dehumidifier:
        return 'Dehumidifier';
      case BarrierType.airMover:
        return 'Air Mover';
      case BarrierType.airScrubber:
        return 'Air Scrubber';
      case BarrierType.containmentBarrier:
        return 'Containment';
      case BarrierType.negativePressure:
        return 'Neg. Pressure';
      case BarrierType.moistureMeter:
        return 'Moisture Meter';
      case BarrierType.thermalCamera:
        return 'Thermal Cam';
      case BarrierType.dryingMat:
        return 'Drying Mat';
    }
  }
}
