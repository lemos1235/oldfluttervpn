import Cocoa
import FlutterMacOS

let conf = """
[General]
loglevel = debug
dns-server = 223.5.5.5
tun = auto

[Proxy]
Direct = direct
SOCKS5 = socks,192.168.1.5,7890
[Rule]
DOMAIN-KEYWORD, google, SOCKS5
FINAL, Direct
"""

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
      let confContent = conf.replacingOccurrences(of: "SOCKS_PROXY", with: proxy)
      let fileName = "config.conf"
      if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = dir.appendingPathComponent(fileName)
        do {
          try confContent.write(to: fileURL, atomically: false, encoding: .utf8)
          print("写入成功")
          let r = leaf_run(0, "\(fileURL.path)")
          print("\(r)")
        }
        catch let error{
          print(error)
          print("写入失败")
        }
      }
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

