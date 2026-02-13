// ZAFTO Layer Panel — SK4
// Collapsible sidebar for managing trade overlay layers: visibility toggle,
// lock toggle, opacity slider, active layer selection, add/remove layers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/trade_layer.dart';
import '../../theme/zafto_colors.dart';

class LayerPanel extends StatelessWidget {
  final List<TradeLayer> layers;
  final String? activeLayerId; // null = base layer active
  final bool isBaseLayerActive;
  final ValueChanged<String?> onActiveLayerChanged;
  final ValueChanged<String> onToggleVisibility;
  final ValueChanged<String> onToggleLock;
  final void Function(String layerId, double opacity) onOpacityChanged;
  final VoidCallback onAddLayer;
  final ValueChanged<String> onRemoveLayer;
  final ZaftoColors colors;

  const LayerPanel({
    super.key,
    required this.layers,
    this.activeLayerId,
    this.isBaseLayerActive = true,
    required this.onActiveLayerChanged,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onOpacityChanged,
    required this.onAddLayer,
    required this.onRemoveLayer,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colors.bgElevated.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(-2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          const Divider(height: 1),

          // Base layer tile
          _buildBaseLayerTile(),

          // Trade layers
          ...layers.map(_buildLayerTile),

          // Add layer button
          _buildAddLayerButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.layers, size: 14, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Layers',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${layers.length + 1}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseLayerTile() {
    final isActive = isBaseLayerActive;
    return _LayerTile(
      name: 'Base (Floor Plan)',
      colorValue: 0xFF1F2937,
      isActive: isActive,
      visible: true,
      locked: false,
      onTap: () {
        HapticFeedback.lightImpact();
        onActiveLayerChanged(null);
      },
      colors: colors,
    );
  }

  Widget _buildLayerTile(TradeLayer layer) {
    final isActive = activeLayerId == layer.id;
    return _LayerTile(
      name: layer.name,
      colorValue: layer.colorValue,
      isActive: isActive,
      visible: layer.visible,
      locked: layer.locked,
      opacity: layer.opacity,
      onTap: () {
        HapticFeedback.lightImpact();
        onActiveLayerChanged(layer.id);
      },
      onToggleVisibility: () {
        HapticFeedback.lightImpact();
        onToggleVisibility(layer.id);
      },
      onToggleLock: () {
        HapticFeedback.lightImpact();
        onToggleLock(layer.id);
      },
      onOpacityChanged: (v) => onOpacityChanged(layer.id, v),
      onRemove: layer.isEmpty
          ? () {
              HapticFeedback.mediumImpact();
              onRemoveLayer(layer.id);
            }
          : null,
      colors: colors,
    );
  }

  Widget _buildAddLayerButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onAddLayer();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: 14, color: colors.accentPrimary),
            const SizedBox(width: 4),
            Text(
              'Add Layer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual layer tile
class _LayerTile extends StatefulWidget {
  final String name;
  final int colorValue;
  final bool isActive;
  final bool visible;
  final bool locked;
  final double opacity;
  final VoidCallback onTap;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onToggleLock;
  final ValueChanged<double>? onOpacityChanged;
  final VoidCallback? onRemove;
  final ZaftoColors colors;

  const _LayerTile({
    required this.name,
    required this.colorValue,
    required this.isActive,
    required this.visible,
    required this.locked,
    this.opacity = 1.0,
    required this.onTap,
    this.onToggleVisibility,
    this.onToggleLock,
    this.onOpacityChanged,
    this.onRemove,
    required this.colors,
  });

  @override
  State<_LayerTile> createState() => _LayerTileState();
}

class _LayerTileState extends State<_LayerTile> {
  bool _showOpacity = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.colorValue);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isActive
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: widget.isActive ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Color indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: widget.visible ? 1.0 : 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: widget.visible
                          ? widget.colors.textPrimary
                          : widget.colors.textQuaternary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Visibility toggle
                if (widget.onToggleVisibility != null)
                  _iconButton(
                    widget.visible ? LucideIcons.eye : LucideIcons.eyeOff,
                    widget.visible
                        ? widget.colors.textSecondary
                        : widget.colors.textQuaternary,
                    widget.onToggleVisibility!,
                  ),
                // Lock toggle
                if (widget.onToggleLock != null)
                  _iconButton(
                    widget.locked ? LucideIcons.lock : LucideIcons.unlock,
                    widget.locked
                        ? widget.colors.textSecondary
                        : widget.colors.textQuaternary,
                    widget.onToggleLock!,
                  ),
                // Opacity toggle
                if (widget.onOpacityChanged != null)
                  _iconButton(
                    LucideIcons.sliders,
                    _showOpacity
                        ? widget.colors.accentPrimary
                        : widget.colors.textQuaternary,
                    () => setState(() => _showOpacity = !_showOpacity),
                  ),
              ],
            ),
            // Opacity slider (expandable)
            if (_showOpacity && widget.onOpacityChanged != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 18),
                child: Row(
                  children: [
                    Text(
                      '${(widget.opacity * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: widget.colors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          activeTrackColor: color,
                          inactiveTrackColor: color.withValues(alpha: 0.2),
                          thumbColor: color,
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: widget.opacity,
                          min: 0.1,
                          max: 1.0,
                          onChanged: widget.onOpacityChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}
