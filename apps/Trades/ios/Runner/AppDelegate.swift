import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let roomPlanService = RoomPlanService()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register RoomPlan platform channel (SK5)
    if let controller = window?.rootViewController as? FlutterViewController {
      roomPlanService.register(withMessenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
