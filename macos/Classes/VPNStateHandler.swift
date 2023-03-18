//
//  VPNStateHandler.swift
//  flutter_vpn
//
//  Created by Alfred Jobs on 2023/3/17.
//

import FlutterMacOS

enum VpnState: Int {
    case disconnected = 0;
    case connecting = 1;
    case connected = 2;
    case disconnecting = 3;
    case error = 4;
}


class VPNStateHandler: FlutterStreamHandler {
  static var _sink: FlutterEventSink?
  
  static var vpnState: VpnState = VpnState.disconnected

  static func updateState(_ newState: VpnState, errorMessage: String? = nil) {
    guard let sink = _sink else {
      return
    }

    if let errorMsg = errorMessage {
      sink(FlutterError(code: "\(newState)",
                        message: errorMsg,
                        details: nil))
      return
    }
    vpnState = newState
    sink(newState.rawValue)
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    VPNStateHandler._sink = events
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    VPNStateHandler._sink = nil
    return nil
  }
}
