package club.lemos.flutter_vpn

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

enum class VpnState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR,
}

interface StateListener {

    fun stateChanged(state: VpnState)
}

object VpnStateHandler : EventChannel.StreamHandler, StateListener {

    private var eventSink: EventChannel.EventSink? = null

    var vpnState: VpnState? = null

    override fun stateChanged(state: VpnState) {
        vpnState = state
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(state.ordinal)
        }
    }

    override fun onListen(p0: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}