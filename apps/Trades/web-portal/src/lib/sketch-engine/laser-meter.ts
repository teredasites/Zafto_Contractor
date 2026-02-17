// ZAFTO — Web Bluetooth Laser Meter Integration
// Created: Sprint FIELD4 (Session 131)
//
// Web Bluetooth API integration for connecting laser meters from the
// browser-based Konva.js sketch editor. Mirrors the Flutter adapter pattern.
//
// Web Bluetooth requirements:
// - Chrome 79+ or Edge 79+ (no Firefox, no Safari)
// - HTTPS only (no HTTP, no localhost without flag)
// - User gesture required to trigger bluetooth.requestDevice()
//
// Usage:
//   const meter = new WebLaserMeter();
//   const supported = meter.isSupported;
//   if (supported) {
//     await meter.requestDevice();
//     meter.onMeasurement((m) => console.log(m.distanceInches));
//   }

// =============================================================================
// TYPES
// =============================================================================

export interface LaserMeasurementWeb {
  /** Distance in inches (internal standard unit). */
  distanceInches: number;
  /** Original value from device. */
  originalValue: number;
  /** Original unit from device. */
  originalUnit: 'meters' | 'feet' | 'inches';
  /** When measurement was captured. */
  timestamp: Date;
  /** Confidence level 0–1. */
  confidence: number;
  /** Device name. */
  deviceName: string;
  /** Raw bytes from BLE characteristic. */
  rawBytes?: Uint8Array;
}

export type LaserConnectionStateWeb =
  | 'idle'
  | 'requesting'
  | 'connecting'
  | 'discovering'
  | 'ready'
  | 'disconnected'
  | 'error'
  | 'unsupported';

export interface LaserDeviceInfoWeb {
  name: string;
  brand: string;
  isBeta: boolean;
  batteryLevel?: number;
}

type MeasurementCallback = (measurement: LaserMeasurementWeb) => void;
type ConnectionCallback = (state: LaserConnectionStateWeb) => void;

// =============================================================================
// KNOWN SERVICE UUIDS
// =============================================================================

const BOSCH_MEASUREMENT_SERVICE = '00005301-0000-0041-4c50-574953450000';
const LEICA_MEASUREMENT_SERVICE = '3ab10100-f831-4395-b29d-570977d5bf94';
const DEWALT_MEASUREMENT_SERVICE = '6e40fff0-b5a3-f393-e0a9-e50e24dcca9e';

const BATTERY_SERVICE = 0x180f;
const BATTERY_LEVEL_CHAR = 0x2a19;

const ALL_KNOWN_SERVICES = [
  BOSCH_MEASUREMENT_SERVICE,
  LEICA_MEASUREMENT_SERVICE,
  DEWALT_MEASUREMENT_SERVICE,
];

// =============================================================================
// WEB LASER METER
// =============================================================================

export class WebLaserMeter {
  private device: BluetoothDevice | null = null;
  private server: BluetoothRemoteGATTServer | null = null;
  private measurementCallbacks: MeasurementCallback[] = [];
  private connectionCallbacks: ConnectionCallback[] = [];
  private state: LaserConnectionStateWeb = 'idle';

  /**
   * Whether Web Bluetooth is supported in this browser.
   * Returns false for Firefox, Safari, and non-HTTPS contexts.
   */
  get isSupported(): boolean {
    return typeof navigator !== 'undefined' && 'bluetooth' in navigator;
  }

  /** Current connection state. */
  get connectionState(): LaserConnectionStateWeb {
    return this.state;
  }

  /** Whether a device is connected and ready. */
  get isReady(): boolean {
    return this.state === 'ready';
  }

  /**
   * Get a user-friendly message for unsupported browsers.
   */
  get unsupportedMessage(): string {
    const ua = navigator.userAgent.toLowerCase();
    if (ua.includes('firefox')) {
      return 'Web Bluetooth is not supported in Firefox. Use Chrome or Edge, or connect via the Zafto mobile app.';
    }
    if (ua.includes('safari') && !ua.includes('chrome')) {
      return 'Web Bluetooth is not supported in Safari. Use Chrome or Edge, or connect via the Zafto mobile app.';
    }
    if (location.protocol !== 'https:') {
      return 'Web Bluetooth requires HTTPS. Please access this page via HTTPS.';
    }
    return 'Web Bluetooth is not supported in this browser. Use Chrome 79+ or Edge 79+, or connect via the Zafto mobile app.';
  }

  /**
   * Request a Bluetooth device from the user.
   * MUST be called from a user gesture (click/tap).
   */
  async requestDevice(): Promise<boolean> {
    if (!this.isSupported) {
      this.emitState('unsupported');
      return false;
    }

    try {
      this.emitState('requesting');

      // Request device with known laser meter service filters
      this.device = await navigator.bluetooth.requestDevice({
        filters: ALL_KNOWN_SERVICES.map((uuid) => ({
          services: [uuid],
        })),
        optionalServices: [BATTERY_SERVICE, 0x180a /* Device Info */],
      });

      if (!this.device) {
        this.emitState('idle');
        return false;
      }

      // Listen for disconnection
      this.device.addEventListener('gattserverdisconnected', () => {
        this.emitState('disconnected');
      });

      return await this.connect();
    } catch (e) {
      // User cancelled the device picker or error occurred
      if (e instanceof DOMException && e.name === 'NotFoundError') {
        // User cancelled — not an error
        this.emitState('idle');
      } else {
        this.emitState('error');
      }
      return false;
    }
  }

  /**
   * Connect to the selected device and subscribe to measurements.
   */
  private async connect(): Promise<boolean> {
    if (!this.device?.gatt) {
      this.emitState('error');
      return false;
    }

    try {
      this.emitState('connecting');
      this.server = await this.device.gatt.connect();

      this.emitState('discovering');

      // Try to find a measurement service
      let subscribed = false;

      for (const serviceUuid of ALL_KNOWN_SERVICES) {
        try {
          const service = await this.server.getPrimaryService(serviceUuid);
          const characteristics = await service.getCharacteristics();

          for (const char of characteristics) {
            if (
              char.properties.notify ||
              char.properties.indicate
            ) {
              await char.startNotifications();
              char.addEventListener(
                'characteristicvaluechanged',
                (event: Event) => {
                  const target = event.target as BluetoothRemoteGATTCharacteristic;
                  if (target.value) {
                    this.parseMeasurement(
                      new Uint8Array(target.value.buffer),
                      serviceUuid
                    );
                  }
                }
              );
              subscribed = true;
            }
          }

          if (subscribed) break;
        } catch {
          // Service not available on this device — try next
        }
      }

      if (!subscribed) {
        this.emitState('error');
        return false;
      }

      this.emitState('ready');
      return true;
    } catch {
      this.emitState('error');
      return false;
    }
  }

  /**
   * Disconnect from the device.
   */
  disconnect(): void {
    if (this.server?.connected) {
      this.server.disconnect();
    }
    this.device = null;
    this.server = null;
    this.emitState('disconnected');
  }

  /**
   * Get device info.
   */
  getDeviceInfo(): LaserDeviceInfoWeb | null {
    if (!this.device) return null;

    const name = this.device.name || 'Unknown Device';
    const nameLower = name.toLowerCase();

    let brand = 'Unknown';
    let isBeta = true;

    if (nameLower.includes('glm') || nameLower.includes('bosch')) {
      brand = 'Bosch';
      isBeta = false;
    } else if (nameLower.includes('disto') || nameLower.includes('leica')) {
      brand = 'Leica';
    } else if (nameLower.includes('dewalt') || nameLower.includes('dw0')) {
      brand = 'DeWalt';
    } else if (nameLower.includes('hilti')) {
      brand = 'Hilti';
    } else if (nameLower.includes('milwaukee')) {
      brand = 'Milwaukee';
    } else if (nameLower.includes('stabila')) {
      brand = 'Stabila';
    }

    return { name, brand, isBeta };
  }

  /**
   * Get battery level (0–100 or undefined).
   */
  async getBatteryLevel(): Promise<number | undefined> {
    if (!this.server?.connected) return undefined;

    try {
      const service = await this.server.getPrimaryService(BATTERY_SERVICE);
      const char = await service.getCharacteristic(BATTERY_LEVEL_CHAR);
      const value = await char.readValue();
      return value.getUint8(0);
    } catch {
      return undefined;
    }
  }

  /**
   * Register a callback for measurement events.
   */
  onMeasurement(callback: MeasurementCallback): () => void {
    this.measurementCallbacks.push(callback);
    return () => {
      this.measurementCallbacks = this.measurementCallbacks.filter(
        (cb) => cb !== callback
      );
    };
  }

  /**
   * Register a callback for connection state changes.
   */
  onConnectionStateChange(callback: ConnectionCallback): () => void {
    this.connectionCallbacks.push(callback);
    return () => {
      this.connectionCallbacks = this.connectionCallbacks.filter(
        (cb) => cb !== callback
      );
    };
  }

  /**
   * Clean up resources.
   */
  dispose(): void {
    this.disconnect();
    this.measurementCallbacks = [];
    this.connectionCallbacks = [];
  }

  // ===========================================================================
  // PRIVATE
  // ===========================================================================

  private emitState(state: LaserConnectionStateWeb): void {
    this.state = state;
    for (const cb of this.connectionCallbacks) {
      try {
        cb(state);
      } catch {
        // Don't let callback errors break the flow
      }
    }
  }

  /**
   * Parse measurement from BLE characteristic value.
   * Tries IEEE 754 float (little-endian) in meters first.
   */
  private parseMeasurement(bytes: Uint8Array, serviceUuid: string): void {
    if (bytes.length < 4) return;

    const view = new DataView(bytes.buffer);
    let meters: number;

    try {
      meters = view.getFloat32(0, true); // little-endian
    } catch {
      return;
    }

    // Validate
    if (Number.isNaN(meters) || !Number.isFinite(meters) || meters < 0 || meters > 300) {
      // Try offset 1 (Leica sometimes has status byte prefix)
      if (bytes.length >= 5) {
        try {
          meters = view.getFloat32(1, true);
          if (Number.isNaN(meters) || !Number.isFinite(meters) || meters < 0 || meters > 300) {
            return;
          }
        } catch {
          return;
        }
      } else {
        return;
      }
    }

    const inches = meters * 39.3701;

    // Determine confidence based on service
    let confidence = 0.7;
    if (serviceUuid === BOSCH_MEASUREMENT_SERVICE) confidence = 1.0;
    else if (serviceUuid === LEICA_MEASUREMENT_SERVICE) confidence = 0.85;
    else if (serviceUuid === DEWALT_MEASUREMENT_SERVICE) confidence = 0.8;

    const measurement: LaserMeasurementWeb = {
      distanceInches: inches,
      originalValue: meters,
      originalUnit: 'meters',
      timestamp: new Date(),
      confidence,
      deviceName: this.device?.name || 'Unknown',
      rawBytes: bytes,
    };

    for (const cb of this.measurementCallbacks) {
      try {
        cb(measurement);
      } catch {
        // Don't let callback errors break the flow
      }
    }
  }
}

// =============================================================================
// HELPERS
// =============================================================================

/**
 * Format measurement in imperial (feet/inches).
 */
export function formatImperial(distanceInches: number): string {
  const feet = Math.floor(distanceInches / 12);
  const inches = distanceInches % 12;
  if (feet === 0) return `${inches.toFixed(1)}"`;
  return `${feet}' ${inches.toFixed(1)}"`;
}

/**
 * Format measurement in metric.
 */
export function formatMetric(distanceInches: number): string {
  const meters = distanceInches * 0.0254;
  return `${meters.toFixed(3)} m`;
}
