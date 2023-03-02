package club.lemos.android.logic;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import club.lemos.flutter_vpn.StateListener;

public class VpnStateService extends Service {

    private static final String TAG = VpnStateService.class.getSimpleName();

    private final IBinder mBinder = new LocalBinder();

    private Bundle mProfileInfo;

    public StateListener stateListener;

    public void setStateListener(StateListener stateListener) {
        this.stateListener = stateListener;
    }

    public class LocalBinder extends Binder {
        // vpnStateServiceConnection.onServiceConnected, get current service
        public VpnStateService getService() {
            return VpnStateService.this;
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    public void connect(Bundle profileInfo, boolean fromScratch) {
        /* we assume we have the necessary permission */
        Context context = getApplicationContext();
        Intent intent = new Intent(context, CharonVpnService.class);
        if (profileInfo == null) {
            profileInfo = mProfileInfo;
        } else {
            mProfileInfo = profileInfo;
        }
        intent.putExtras(profileInfo);
        ContextCompat.startForegroundService(context, intent);
    }

    public void disconnect() {
        Context context = getApplicationContext();
        Intent intent = new Intent(context, CharonVpnService.class);
        intent.setAction(CharonVpnService.DISCONNECT_ACTION);
        context.startService(intent);
    }

}
