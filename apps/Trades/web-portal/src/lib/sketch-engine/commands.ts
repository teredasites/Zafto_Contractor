// ZAFTO Sketch Command System — SK6
// Port of UndoRedoManager + SketchCommand pattern from floor_plan_elements.dart
// Every canvas mutation goes through a command for undo/redo support.

import type {
  FloorPlanData,
  Wall,
  ArcWall,
  DoorPlacement,
  WindowPlacement,
  FixturePlacement,
  FloorLabel,
  DimensionLine,
  Point,
  TradeLayer,
  TradeElement,
  TradePath,
  DamageZone,
} from './types';

// =============================================================================
// COMMAND INTERFACE
// =============================================================================

export interface SketchCommand {
  execute(data: FloorPlanData): FloorPlanData;
  undo(data: FloorPlanData): FloorPlanData;
  description: string;
}

// =============================================================================
// UNDO/REDO MANAGER
// =============================================================================

export class UndoRedoManager {
  private undoStack: SketchCommand[] = [];
  private redoStack: SketchCommand[] = [];
  private maxHistory = 100;

  get canUndo(): boolean {
    return this.undoStack.length > 0;
  }

  get canRedo(): boolean {
    return this.redoStack.length > 0;
  }

  execute(command: SketchCommand, data: FloorPlanData): FloorPlanData {
    const result = command.execute(data);
    this.undoStack.push(command);
    this.redoStack = []; // Clear redo on new action
    if (this.undoStack.length > this.maxHistory) {
      this.undoStack.shift();
    }
    return result;
  }

  undo(data: FloorPlanData): FloorPlanData {
    const command = this.undoStack.pop();
    if (!command) return data;
    this.redoStack.push(command);
    return command.undo(data);
  }

  redo(data: FloorPlanData): FloorPlanData {
    const command = this.redoStack.pop();
    if (!command) return data;
    this.undoStack.push(command);
    return command.execute(data);
  }

  clear(): void {
    this.undoStack = [];
    this.redoStack = [];
  }
}

// =============================================================================
// WALL COMMANDS
// =============================================================================

export class AddWallCommand implements SketchCommand {
  description = 'Add wall';
  constructor(private wall: Wall) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, walls: [...data.walls, this.wall] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return { ...data, walls: data.walls.filter((w) => w.id !== this.wall.id) };
  }
}

export class RemoveWallCommand implements SketchCommand {
  description = 'Remove wall';
  private removedWall: Wall | null = null;
  constructor(private wallId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removedWall = data.walls.find((w) => w.id === this.wallId) ?? null;
    return { ...data, walls: data.walls.filter((w) => w.id !== this.wallId) };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removedWall) return data;
    return { ...data, walls: [...data.walls, this.removedWall] };
  }
}

export class MoveWallCommand implements SketchCommand {
  description = 'Move wall';
  constructor(
    private wallId: string,
    private oldStart: Point,
    private oldEnd: Point,
    private newStart: Point,
    private newEnd: Point,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      walls: data.walls.map((w) =>
        w.id === this.wallId
          ? { ...w, start: this.newStart, end: this.newEnd }
          : w,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      walls: data.walls.map((w) =>
        w.id === this.wallId
          ? { ...w, start: this.oldStart, end: this.oldEnd }
          : w,
      ),
    };
  }
}

// =============================================================================
// ARC WALL COMMANDS
// =============================================================================

export class AddArcWallCommand implements SketchCommand {
  description = 'Add arc wall';
  constructor(private arcWall: ArcWall) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, arcWalls: [...data.arcWalls, this.arcWall] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      arcWalls: data.arcWalls.filter((a) => a.id !== this.arcWall.id),
    };
  }
}

export class RemoveArcWallCommand implements SketchCommand {
  description = 'Remove arc wall';
  private removed: ArcWall | null = null;
  constructor(private arcId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removed = data.arcWalls.find((a) => a.id === this.arcId) ?? null;
    return {
      ...data,
      arcWalls: data.arcWalls.filter((a) => a.id !== this.arcId),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removed) return data;
    return { ...data, arcWalls: [...data.arcWalls, this.removed] };
  }
}

// =============================================================================
// DOOR COMMANDS
// =============================================================================

export class AddDoorCommand implements SketchCommand {
  description = 'Add door';
  constructor(private door: DoorPlacement) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, doors: [...data.doors, this.door] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return { ...data, doors: data.doors.filter((d) => d.id !== this.door.id) };
  }
}

export class RemoveDoorCommand implements SketchCommand {
  description = 'Remove door';
  private removed: DoorPlacement | null = null;
  constructor(private doorId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removed = data.doors.find((d) => d.id === this.doorId) ?? null;
    return { ...data, doors: data.doors.filter((d) => d.id !== this.doorId) };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removed) return data;
    return { ...data, doors: [...data.doors, this.removed] };
  }
}

// =============================================================================
// WINDOW COMMANDS
// =============================================================================

export class AddWindowCommand implements SketchCommand {
  description = 'Add window';
  constructor(private window: WindowPlacement) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, windows: [...data.windows, this.window] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      windows: data.windows.filter((w) => w.id !== this.window.id),
    };
  }
}

export class RemoveWindowCommand implements SketchCommand {
  description = 'Remove window';
  private removed: WindowPlacement | null = null;
  constructor(private windowId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removed = data.windows.find((w) => w.id === this.windowId) ?? null;
    return {
      ...data,
      windows: data.windows.filter((w) => w.id !== this.windowId),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removed) return data;
    return { ...data, windows: [...data.windows, this.removed] };
  }
}

// =============================================================================
// FIXTURE COMMANDS
// =============================================================================

export class AddFixtureCommand implements SketchCommand {
  description = 'Add fixture';
  constructor(private fixture: FixturePlacement) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, fixtures: [...data.fixtures, this.fixture] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      fixtures: data.fixtures.filter((f) => f.id !== this.fixture.id),
    };
  }
}

export class MoveFixtureCommand implements SketchCommand {
  description = 'Move fixture';
  constructor(
    private fixtureId: string,
    private oldPos: Point,
    private newPos: Point,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      fixtures: data.fixtures.map((f) =>
        f.id === this.fixtureId ? { ...f, position: this.newPos } : f,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      fixtures: data.fixtures.map((f) =>
        f.id === this.fixtureId ? { ...f, position: this.oldPos } : f,
      ),
    };
  }
}

export class RemoveFixtureCommand implements SketchCommand {
  description = 'Remove fixture';
  private removed: FixturePlacement | null = null;
  constructor(private fixtureId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removed = data.fixtures.find((f) => f.id === this.fixtureId) ?? null;
    return {
      ...data,
      fixtures: data.fixtures.filter((f) => f.id !== this.fixtureId),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removed) return data;
    return { ...data, fixtures: [...data.fixtures, this.removed] };
  }
}

// =============================================================================
// LABEL COMMANDS
// =============================================================================

export class AddLabelCommand implements SketchCommand {
  description = 'Add label';
  constructor(private label: FloorLabel) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, labels: [...data.labels, this.label] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      labels: data.labels.filter((l) => l.id !== this.label.id),
    };
  }
}

export class RemoveLabelCommand implements SketchCommand {
  description = 'Remove label';
  private removed: FloorLabel | null = null;
  constructor(private labelId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removed = data.labels.find((l) => l.id === this.labelId) ?? null;
    return {
      ...data,
      labels: data.labels.filter((l) => l.id !== this.labelId),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removed) return data;
    return { ...data, labels: [...data.labels, this.removed] };
  }
}

// =============================================================================
// DIMENSION COMMANDS
// =============================================================================

export class AddDimensionCommand implements SketchCommand {
  description = 'Add dimension';
  constructor(private dimension: DimensionLine) {}

  execute(data: FloorPlanData): FloorPlanData {
    return { ...data, dimensions: [...data.dimensions, this.dimension] };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      dimensions: data.dimensions.filter((d) => d.id !== this.dimension.id),
    };
  }
}

export class RemoveDimensionCommand implements SketchCommand {
  description = 'Remove dimension';
  private removed: DimensionLine | null = null;
  constructor(private dimId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removed =
      data.dimensions.find((d) => d.id === this.dimId) ?? null;
    return {
      ...data,
      dimensions: data.dimensions.filter((d) => d.id !== this.dimId),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.removed) return data;
    return { ...data, dimensions: [...data.dimensions, this.removed] };
  }
}

// =============================================================================
// TRADE LAYER COMMANDS
// =============================================================================

export class AddTradeLayerCommand implements SketchCommand {
  description = 'Add trade layer';
  constructor(private layer: TradeLayer) {}

  execute(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: [...data.tradeLayers, this.layer],
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.filter((l) => l.id !== this.layer.id),
    };
  }
}

export class AddTradeElementCommand implements SketchCommand {
  description = 'Add trade element';
  constructor(
    private layerId: string,
    private element: TradeElement,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.map((l) =>
        l.id === this.layerId && l.tradeData
          ? {
              ...l,
              tradeData: {
                ...l.tradeData,
                elements: [...l.tradeData.elements, this.element],
              },
            }
          : l,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.map((l) =>
        l.id === this.layerId && l.tradeData
          ? {
              ...l,
              tradeData: {
                ...l.tradeData,
                elements: l.tradeData.elements.filter(
                  (e) => e.id !== this.element.id,
                ),
              },
            }
          : l,
      ),
    };
  }
}

export class AddTradePathCommand implements SketchCommand {
  description = 'Add trade path';
  constructor(
    private layerId: string,
    private path: TradePath,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.map((l) =>
        l.id === this.layerId && l.tradeData
          ? {
              ...l,
              tradeData: {
                ...l.tradeData,
                paths: [...l.tradeData.paths, this.path],
              },
            }
          : l,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.map((l) =>
        l.id === this.layerId && l.tradeData
          ? {
              ...l,
              tradeData: {
                ...l.tradeData,
                paths: l.tradeData.paths.filter(
                  (p) => p.id !== this.path.id,
                ),
              },
            }
          : l,
      ),
    };
  }
}

export class AddDamageZoneCommand implements SketchCommand {
  description = 'Add damage zone';
  constructor(
    private layerId: string,
    private zone: DamageZone,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.map((l) =>
        l.id === this.layerId && l.damageData
          ? {
              ...l,
              damageData: {
                ...l.damageData,
                zones: [...l.damageData.zones, this.zone],
              },
            }
          : l,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      tradeLayers: data.tradeLayers.map((l) =>
        l.id === this.layerId && l.damageData
          ? {
              ...l,
              damageData: {
                ...l.damageData,
                zones: l.damageData.zones.filter(
                  (z) => z.id !== this.zone.id,
                ),
              },
            }
          : l,
      ),
    };
  }
}

// =============================================================================
// BULK COMMANDS
// =============================================================================

// =============================================================================
// UPDATE COMMANDS (for PropertyInspector — undoable property edits)
// =============================================================================

export class UpdateWallCommand implements SketchCommand {
  description = 'Update wall properties';
  private oldWall: Wall | null = null;
  constructor(
    private wallId: string,
    private updates: Partial<Wall>,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.oldWall = data.walls.find((w) => w.id === this.wallId) ?? null;
    return {
      ...data,
      walls: data.walls.map((w) =>
        w.id === this.wallId ? { ...w, ...this.updates } : w,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.oldWall) return data;
    return {
      ...data,
      walls: data.walls.map((w) =>
        w.id === this.wallId ? this.oldWall! : w,
      ),
    };
  }
}

export class UpdateDoorCommand implements SketchCommand {
  description = 'Update door properties';
  private oldDoor: DoorPlacement | null = null;
  constructor(
    private doorId: string,
    private updates: Partial<DoorPlacement>,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.oldDoor = data.doors.find((d) => d.id === this.doorId) ?? null;
    return {
      ...data,
      doors: data.doors.map((d) =>
        d.id === this.doorId ? { ...d, ...this.updates } : d,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.oldDoor) return data;
    return {
      ...data,
      doors: data.doors.map((d) =>
        d.id === this.doorId ? this.oldDoor! : d,
      ),
    };
  }
}

export class UpdateWindowCommand implements SketchCommand {
  description = 'Update window properties';
  private oldWindow: WindowPlacement | null = null;
  constructor(
    private windowId: string,
    private updates: Partial<WindowPlacement>,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.oldWindow = data.windows.find((w) => w.id === this.windowId) ?? null;
    return {
      ...data,
      windows: data.windows.map((w) =>
        w.id === this.windowId ? { ...w, ...this.updates } : w,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.oldWindow) return data;
    return {
      ...data,
      windows: data.windows.map((w) =>
        w.id === this.windowId ? this.oldWindow! : w,
      ),
    };
  }
}

export class UpdateFixtureCommand implements SketchCommand {
  description = 'Update fixture properties';
  private oldFixture: FixturePlacement | null = null;
  constructor(
    private fixtureId: string,
    private updates: Partial<FixturePlacement>,
  ) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.oldFixture = data.fixtures.find((f) => f.id === this.fixtureId) ?? null;
    return {
      ...data,
      fixtures: data.fixtures.map((f) =>
        f.id === this.fixtureId ? { ...f, ...this.updates } : f,
      ),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    if (!this.oldFixture) return data;
    return {
      ...data,
      fixtures: data.fixtures.map((f) =>
        f.id === this.fixtureId ? this.oldFixture! : f,
      ),
    };
  }
}

// =============================================================================
// SMART DELETE — finds element type by ID, removes from correct array
// =============================================================================

export class RemoveAnyElementCommand implements SketchCommand {
  description = 'Remove element';
  private removedWall: Wall | null = null;
  private removedArcWall: ArcWall | null = null;
  private removedDoor: DoorPlacement | null = null;
  private removedWindow: WindowPlacement | null = null;
  private removedFixture: FixturePlacement | null = null;
  private removedLabel: FloorLabel | null = null;
  private removedDimension: DimensionLine | null = null;

  constructor(private elementId: string) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removedWall = data.walls.find((w) => w.id === this.elementId) ?? null;
    this.removedArcWall = data.arcWalls.find((a) => a.id === this.elementId) ?? null;
    this.removedDoor = data.doors.find((d) => d.id === this.elementId) ?? null;
    this.removedWindow = data.windows.find((w) => w.id === this.elementId) ?? null;
    this.removedFixture = data.fixtures.find((f) => f.id === this.elementId) ?? null;
    this.removedLabel = data.labels.find((l) => l.id === this.elementId) ?? null;
    this.removedDimension = data.dimensions.find((d) => d.id === this.elementId) ?? null;

    return {
      ...data,
      walls: data.walls.filter((w) => w.id !== this.elementId),
      arcWalls: data.arcWalls.filter((a) => a.id !== this.elementId),
      doors: data.doors.filter((d) => d.id !== this.elementId),
      windows: data.windows.filter((w) => w.id !== this.elementId),
      fixtures: data.fixtures.filter((f) => f.id !== this.elementId),
      labels: data.labels.filter((l) => l.id !== this.elementId),
      dimensions: data.dimensions.filter((d) => d.id !== this.elementId),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      walls: this.removedWall ? [...data.walls, this.removedWall] : data.walls,
      arcWalls: this.removedArcWall ? [...data.arcWalls, this.removedArcWall] : data.arcWalls,
      doors: this.removedDoor ? [...data.doors, this.removedDoor] : data.doors,
      windows: this.removedWindow ? [...data.windows, this.removedWindow] : data.windows,
      fixtures: this.removedFixture ? [...data.fixtures, this.removedFixture] : data.fixtures,
      labels: this.removedLabel ? [...data.labels, this.removedLabel] : data.labels,
      dimensions: this.removedDimension ? [...data.dimensions, this.removedDimension] : data.dimensions,
    };
  }
}

export class RemoveMultipleCommand implements SketchCommand {
  description = 'Remove multiple elements';
  private removedWalls: Wall[] = [];
  private removedArcWalls: ArcWall[] = [];
  private removedDoors: DoorPlacement[] = [];
  private removedWindows: WindowPlacement[] = [];
  private removedFixtures: FixturePlacement[] = [];
  private removedLabels: FloorLabel[] = [];
  private removedDimensions: DimensionLine[] = [];

  constructor(private ids: Set<string>) {}

  execute(data: FloorPlanData): FloorPlanData {
    this.removedWalls = data.walls.filter((w) => this.ids.has(w.id));
    this.removedArcWalls = data.arcWalls.filter((a) => this.ids.has(a.id));
    this.removedDoors = data.doors.filter((d) => this.ids.has(d.id));
    this.removedWindows = data.windows.filter((w) => this.ids.has(w.id));
    this.removedFixtures = data.fixtures.filter((f) => this.ids.has(f.id));
    this.removedLabels = data.labels.filter((l) => this.ids.has(l.id));
    this.removedDimensions = data.dimensions.filter((d) =>
      this.ids.has(d.id),
    );

    return {
      ...data,
      walls: data.walls.filter((w) => !this.ids.has(w.id)),
      arcWalls: data.arcWalls.filter((a) => !this.ids.has(a.id)),
      doors: data.doors.filter((d) => !this.ids.has(d.id)),
      windows: data.windows.filter((w) => !this.ids.has(w.id)),
      fixtures: data.fixtures.filter((f) => !this.ids.has(f.id)),
      labels: data.labels.filter((l) => !this.ids.has(l.id)),
      dimensions: data.dimensions.filter((d) => !this.ids.has(d.id)),
    };
  }

  undo(data: FloorPlanData): FloorPlanData {
    return {
      ...data,
      walls: [...data.walls, ...this.removedWalls],
      arcWalls: [...data.arcWalls, ...this.removedArcWalls],
      doors: [...data.doors, ...this.removedDoors],
      windows: [...data.windows, ...this.removedWindows],
      fixtures: [...data.fixtures, ...this.removedFixtures],
      labels: [...data.labels, ...this.removedLabels],
      dimensions: [...data.dimensions, ...this.removedDimensions],
    };
  }
}
