import Cocoa
import FlutterMacOS

public class FlutterVpnPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_vpn", binaryMessenger: registrar.messenger)
    let instance = FlutterVpnPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
      let stateChannel = FlutterEventChannel(name: "flutter_vpn_states", binaryMessenger: registrar.messenger)
    stateChannel.setStreamHandler((VPNStateHandler() as! FlutterStreamHandler & NSObjectProtocol))
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCurrentState":
        result(0)
    case "prepare":
        result(true)
    case "connect":
        let args = call.arguments! as! [NSString: NSString]
        let proxy = args["proxy"]! as String
      result(true)
    case "disconnect":
        result(true)
    case "switchProxy":
        result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
