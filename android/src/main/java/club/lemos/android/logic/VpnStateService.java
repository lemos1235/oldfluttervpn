package club.lemos.android.logic;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

public class VpnStateService extends Service {

    private final IBinder mBinder = new LocalBinder();

    private Bundle mProfileInfo;

    public class LocalBinder extends Binder {
        public VpnStateService getService() {
            return VpnStateService.this;
        }
    }

    @Override
    public void onCreate() {
        System.out.println("onCreate");
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    @Override
    public void onDestroy() {
        System.out.println("onDestroy");
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
