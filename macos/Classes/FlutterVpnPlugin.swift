import Cocoa
import FlutterMacOS

let conf = """
[General]
loglevel = debug
dns-server = 223.5.5.5
tun = auto

[Proxy]
Direct = direct
SOCKS5 = SOCKS_PROXY
[Rule]
DOMAIN-KEYWORD, google, SOCKS5
FINAL, Direct
"""

let fileName = "config.conf"

public class FlutterVpnPlugin: NSObject, FlutterPlugin {
  
  var mConnectionHandler:  Thread?
  
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
      result(VPNStateHandler.vpnState.rawValue)
    case "prepare":
      result(true)
    case "connect":
      let args = call.arguments! as! [NSString: NSString]
      let proxy = args["proxy"]! as String
      let confContent = conf.replacingOccurrences(of: "SOCKS_PROXY", with: transformProxyUrl(proxy))
      
      //开始连接
      VPNStateHandler.updateState(VpnState.connecting)

      // Get the URL for the app's main bundle
      let bundleURL =  Bundle.main.bundleURL

      // Create a directory URL
      let directoryURL = bundleURL.appendingPathComponent("conf")

      // Create the directory
      if !FileManager.default.fileExists(atPath: directoryURL.path) {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Error creating directory: \(error.localizedDescription)")
        }
      } else {
          print("Directory already exists")
      }

      let fileURL = directoryURL.appendingPathComponent(fileName)
      // Write the data to the file
      do {
        try confContent.write(to: fileURL, atomically: false, encoding: .utf8)
      } catch {
          fatalError("Error writing data to file: \(error.localizedDescription)")
      }
      //创建线程
      mConnectionHandler = Thread(block: {
        let r = leaf_run(0, "\(fileURL.path)")
        print("\(r)")
      })
      mConnectionHandler?.start()
      //连接成功
      VPNStateHandler.updateState(VpnState.connected)

      result(true)
    case "disconnect":
      VPNStateHandler.updateState(VpnState.disconnecting)
      leaf_shutdown(0)
      mConnectionHandler?.cancel()
      //断开连接
      VPNStateHandler.updateState(VpnState.disconnected)
      result(true)
    case "switchProxy":
      let args = call.arguments! as! [NSString: NSString]
      let proxy = args["proxy"]! as String
      let confContent = conf.replacingOccurrences(of: "SOCKS_PROXY", with: transformProxyUrl(proxy))
      
      // 生成新的配置文件
      let bundleURL =  Bundle.main.bundleURL
      let directoryURL = bundleURL.appendingPathComponent("conf")
      let fileURL = directoryURL.appendingPathComponent(fileName)
      do {
        try confContent.write(to: fileURL, atomically: false, encoding: .utf8)
      } catch {
          fatalError("Error writing data to file: \(error.localizedDescription)")
      }
      //reload leaf
      leaf_reload(0)
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  func transformProxyUrl(_ proxyUrl: String) -> String {
    guard let url = URL(string: proxyUrl),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let scheme = components.scheme,
          let host = components.host,
          let port = components.port?.description
    else {
        fatalError("Invalid URL")
    }

    var output = "\(scheme),\(host),\(port)"
    if let user = components.user {
        output += ",username=\(user)"
    }
    if let password = components.password {
        output += ",password=\(password)"
    }
    return output
  }
}

