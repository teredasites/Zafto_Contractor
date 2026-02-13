// ZAFTO RoomPlan Service — SK5
// Native Swift wrapper for Apple RoomPlan LiDAR scanning.
// Communicates with Flutter via MethodChannel/EventChannel.
// Requires iOS 16+ with LiDAR hardware (iPhone 12 Pro+, iPad Pro 2020+).

import Flutter
import UIKit

#if canImport(RoomPlan)
import RoomPlan
#endif

class RoomPlanService: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    #if canImport(RoomPlan)
    @available(iOS 16.0, *)
    private var captureSession: RoomCaptureSession?

    @available(iOS 16.0, *)
    private var capturedRoom: CapturedRoom?
    #endif

    func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        methodChannel = FlutterMethodChannel(
            name: "com.zafto.roomplan",
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)

        eventChannel = FlutterEventChannel(
            name: "com.zafto.roomplan/progress",
            binaryMessenger: messenger
        )
        eventChannel?.setStreamHandler(self)
    }

    // Also support direct registration via FlutterBinaryMessenger
    func register(withMessenger messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.zafto.roomplan",
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)

        eventChannel = FlutterEventChannel(
            name: "com.zafto.roomplan/progress",
            binaryMessenger: messenger
        )
        eventChannel?.setStreamHandler(self)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAvailability":
            checkAvailability(result: result)
        case "startScan":
            startScan(result: result)
        case "stopScan":
            stopScan(result: result)
        case "getCapturedRoom":
            getCapturedRoom(result: result)
        case "cancelScan":
            cancelScan(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Availability Check

    private func checkAvailability(result: FlutterResult) {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *) {
            result(RoomCaptureSession.isSupported)
        } else {
            result(false)
        }
        #else
        result(false)
        #endif
    }

    // MARK: - Scan Lifecycle

    private func startScan(result: @escaping FlutterResult) {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *) {
            guard RoomCaptureSession.isSupported else {
                result(FlutterError(
                    code: "NOT_SUPPORTED",
                    message: "RoomPlan is not supported on this device",
                    details: nil
                ))
                return
            }

            let session = RoomCaptureSession()
            session.delegate = self
            captureSession = session

            let config = RoomCaptureSession.Configuration()
            session.run(configuration: config)

            result(nil)
        } else {
            result(FlutterError(
                code: "NOT_AVAILABLE",
                message: "Requires iOS 16.0 or later",
                details: nil
            ))
        }
        #else
        result(FlutterError(
            code: "NOT_AVAILABLE",
            message: "RoomPlan framework not available",
            details: nil
        ))
        #endif
    }

    private func stopScan(result: @escaping FlutterResult) {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *) {
            guard let session = captureSession else {
                result(nil)
                return
            }

            session.stop()

            // Wait for delegate callback to get final room,
            // then serialize and return
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else {
                    result(nil)
                    return
                }
                if let room = self.capturedRoom {
                    let data = self.serializeCapturedRoom(room)
                    result(data)
                } else {
                    result(nil)
                }
            }
        } else {
            result(nil)
        }
        #else
        result(nil)
        #endif
    }

    private func getCapturedRoom(result: FlutterResult) {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *) {
            if let room = capturedRoom {
                result(serializeCapturedRoom(room))
            } else {
                result(nil)
            }
        } else {
            result(nil)
        }
        #else
        result(nil)
        #endif
    }

    private func cancelScan(result: FlutterResult) {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *) {
            captureSession?.stop()
            captureSession = nil
            capturedRoom = nil
        }
        #endif
        result(nil)
    }

    // MARK: - Serialization

    #if canImport(RoomPlan)
    @available(iOS 16.0, *)
    private func serializeCapturedRoom(_ room: CapturedRoom) -> [String: Any] {
        var data: [String: Any] = [:]

        // Walls
        var walls: [[String: Any]] = []
        for wall in room.walls {
            walls.append(serializeSurface(wall))
        }
        data["walls"] = walls

        // Doors
        var doors: [[String: Any]] = []
        for door in room.doors {
            doors.append(serializeOpening(door, type: "door"))
        }
        data["doors"] = doors

        // Windows
        var windows: [[String: Any]] = []
        for window in room.windows {
            windows.append(serializeOpening(window, type: "window"))
        }
        data["windows"] = windows

        // Objects
        var objects: [[String: Any]] = []
        for object in room.objects {
            objects.append(serializeObject(object))
        }
        data["objects"] = objects

        return data
    }

    @available(iOS 16.0, *)
    private func serializeSurface(_ surface: CapturedRoom.Surface) -> [String: Any] {
        let transform = surface.transform
        return [
            "transform": transformToArray(transform),
            "dimensions": [
                "x": surface.dimensions.x,
                "y": surface.dimensions.y,
                "z": surface.dimensions.z,
            ],
            "category": surfaceCategoryString(surface.category),
        ]
    }

    @available(iOS 16.0, *)
    private func serializeOpening(_ opening: CapturedRoom.Opening, type: String) -> [String: Any] {
        let transform = opening.transform
        return [
            "transform": transformToArray(transform),
            "dimensions": [
                "x": opening.dimensions.x,
                "y": opening.dimensions.y,
                "z": opening.dimensions.z,
            ],
            "type": openingCategoryString(opening.category),
        ]
    }

    @available(iOS 16.0, *)
    private func serializeObject(_ object: CapturedRoom.Object) -> [String: Any] {
        let transform = object.transform
        return [
            "transform": transformToArray(transform),
            "dimensions": [
                "x": object.dimensions.x,
                "y": object.dimensions.y,
                "z": object.dimensions.z,
            ],
            "category": objectCategoryString(object.category),
        ]
    }
    #endif

    // Convert simd_float4x4 to flat [Float] array (column-major)
    private func transformToArray(_ t: simd_float4x4) -> [Float] {
        return [
            t.columns.0.x, t.columns.0.y, t.columns.0.z, t.columns.0.w,
            t.columns.1.x, t.columns.1.y, t.columns.1.z, t.columns.1.w,
            t.columns.2.x, t.columns.2.y, t.columns.2.z, t.columns.2.w,
            t.columns.3.x, t.columns.3.y, t.columns.3.z, t.columns.3.w,
        ]
    }

    #if canImport(RoomPlan)
    @available(iOS 16.0, *)
    private func surfaceCategoryString(_ category: CapturedRoom.Surface.Category) -> String {
        switch category {
        case .wall: return "wall"
        case .floor: return "floor"
        case .ceiling: return "ceiling"
        case .door: return "door"
        case .window: return "window"
        case .opening: return "opening"
        @unknown default: return "unknown"
        }
    }

    @available(iOS 16.0, *)
    private func openingCategoryString(_ category: CapturedRoom.Opening.Category) -> String {
        switch category {
        case .door: return "single"
        case .window: return "window"
        case .opening: return "opening"
        @unknown default: return "unknown"
        }
    }

    @available(iOS 16.0, *)
    private func objectCategoryString(_ category: CapturedRoom.Object.Category) -> String {
        switch category {
        case .storage: return "storage"
        case .refrigerator: return "refrigerator"
        case .stove: return "stove"
        case .bed: return "bed"
        case .sink: return "sink"
        case .washer: return "washer"
        case .dryer: return "dryer"
        case .toilet: return "toilet"
        case .bathtub: return "bathtub"
        case .oven: return "oven"
        case .dishwasher: return "dishwasher"
        case .table: return "table"
        case .sofa: return "sofa"
        case .chair: return "chair"
        case .fireplace: return "fireplace"
        case .television: return "television"
        case .stairs: return "stairs"
        @unknown default: return "unknown"
        }
    }
    #endif

    // MARK: - Progress Reporting

    private func sendProgress(walls: Int, doors: Int, windows: Int, objects: Int, status: String, message: String? = nil) {
        var data: [String: Any] = [
            "wall_count": walls,
            "door_count": doors,
            "window_count": windows,
            "object_count": objects,
            "status": status,
        ]
        if let msg = message {
            data["message"] = msg
        }
        eventSink?(data)
    }
}

// MARK: - FlutterStreamHandler

extension RoomPlanService: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - RoomCaptureSession Delegate

#if canImport(RoomPlan)
@available(iOS 16.0, *)
extension RoomPlanService: RoomCaptureSessionDelegate {
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        // Real-time progress updates
        sendProgress(
            walls: room.walls.count,
            doors: room.doors.count,
            windows: room.windows.count,
            objects: room.objects.count,
            status: "scanning"
        )
    }

    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        var message: String
        switch instruction {
        case .moveCloseToWall:
            message = "Move closer to the wall"
        case .moveAwayFromWall:
            message = "Move away from the wall"
        case .slowDown:
            message = "Slow down"
        case .turnOnLight:
            message = "Turn on more lights"
        case .normal:
            message = "Keep scanning"
        case .lowTexture:
            message = "Point at textured surfaces"
        @unknown default:
            message = "Keep scanning"
        }

        sendProgress(
            walls: 0, doors: 0, windows: 0, objects: 0,
            status: "instruction",
            message: message
        )
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?) {
        if let error = error {
            sendProgress(
                walls: 0, doors: 0, windows: 0, objects: 0,
                status: "error",
                message: error.localizedDescription
            )
            return
        }

        // Process the final room data
        let finalRoom = data.finalResults
        capturedRoom = finalRoom

        sendProgress(
            walls: finalRoom.walls.count,
            doors: finalRoom.doors.count,
            windows: finalRoom.windows.count,
            objects: finalRoom.objects.count,
            status: "complete"
        )
    }

    func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        sendProgress(
            walls: 0, doors: 0, windows: 0, objects: 0,
            status: "scanning",
            message: "Scan started"
        )
    }
}
#endif
