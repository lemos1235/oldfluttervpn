package club.lemos.android.logic;

import android.app.Service;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.Bundle;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.util.Log;


import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.UUID;

import club.lemos.android.data.VpnProfile;
import club.lemos.flutter_vpn.VpnState;

public class CharonVpnService extends VpnService {

    private static final String TAG = CharonVpnService.class.getSimpleName();

    public static final String DISCONNECT_ACTION = "club.lemos.android.logic.CharonVpnService.DISCONNECT";

    private static final String ADDRESS = "10.0.0.2";

    private static final String ROUTE = "0.0.0.0";
    private static final String DNS = "1.1.1.1";

    private ParcelFileDescriptor tun;

    private VpnProfile mProfile;

    private Thread mConnectionHandler;

    private VpnStateService mService;

    private final ServiceConnection mServiceConnection = new ServiceConnection() {

        @Override
        public void onServiceDisconnected(ComponentName name) {    /* since the service is local this is theoretically only called when the process is terminated */
            Log.i(TAG, "onServiceDisconnected");
            mService = null;
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            Log.i(TAG, "onServiceConnected");
            mService = ((VpnStateService.LocalBinder) service).getService();
        }
    };

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "onStartCommand");
        if (intent != null) {
            if (DISCONNECT_ACTION.equals(intent.getAction())) {
                mProfile = null;
                stopVpn();
            } else {
                Bundle bundle = intent.getExtras();
                VpnProfile profile = new VpnProfile();
                profile.setUUID(UUID.randomUUID());
                profile.setProxy(bundle.getString("PROXY"));
                profile.setMTU(bundle.getInt("MTU", 0));
                profile.setMark(bundle.getInt("MARK", 0));
                mProfile = profile;
                startVpn();
            }
        }
        return START_NOT_STICKY;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "onCreate");
        bindService(new Intent(this, VpnStateService.class),
                mServiceConnection, Service.BIND_AUTO_CREATE);
    }

    @Override
    public void onRevoke() {
        stopVpn();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        unbindService(mServiceConnection);
    }

    public void startVpn() {
        Log.i(TAG, "startVpn");
        mConnectionHandler = new Thread(this::setupVpn);
        mConnectionHandler.start();
    }

    private void setupVpn() {
        setState(VpnState.CONNECTING);
        if (tun == null) {
            try {
                Builder builder = new Builder()
                        .addAddress(ADDRESS, 24)
//                        .addRoute(ROUTE, 0)
                        .addDnsServer(DNS)
                        .addDisallowedApplication(this.getApplication().getPackageName());

                // let DNS queries bypass VPN if SOCKS server does not support UDP bind
                addRoutesExcept(builder, DNS, 32);
                tun = builder.establish();
            } catch (PackageManager.NameNotFoundException e) {
                throw new RuntimeException(e);
            }
        }

        if (mProfile != null) {
            engine.Key key = new engine.Key();
            key.setMark(mProfile.getMark());
            key.setMTU(mProfile.getMTU());
            key.setDevice("fd://" + tun.getFd());
            key.setInterface("");
            key.setLogLevel("debug");
            key.setProxy(mProfile.getProxy());
            key.setRestAPI("");
            key.setTCPSendBufferSize("");
            key.setTCPReceiveBufferSize("");
            key.setTCPModerateReceiveBuffer(false);
            engine.Engine.insert(key);
            engine.Engine.start();
            Log.i(TAG, "VPN is started");
            setState(VpnState.CONNECTED);
        }
    }

    public void stopVpn() {
        setState(VpnState.DISCONNECTING);
        try {
            if (tun != null) {
                tun.close();
                tun = null;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        try {
            mConnectionHandler.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        Log.i(TAG, "VPN is stopped");
    }

    public void setState(VpnState state) {
        if (mService != null) {
            mService.stateListener.stateChanged(state);
        }
    }

    /**
     * Computes the inverted subnet, routing all traffic except to the specified subnet. Use prefixLength
     * of 32 or 128 for a single address.
     *
     * @see <a href="https://stackoverflow.com/a/41289228"></a>
     */
    private void addRoutesExcept(Builder builder, String address, int prefixLength) {
        try {
            byte[] bytes = InetAddress.getByName(address).getAddress();
            for (int i = 0; i < prefixLength; i++) { // each entry
                byte[] res = new byte[bytes.length];
                for (int j = 0; j <= i; j++) { // each prefix bit
                    res[j / 8] = (byte) (res[j / 8] | (bytes[j / 8] & (1 << (7 - (j % 8)))));
                }
                res[i / 8] ^= (1 << (7 - (i % 8)));

                builder.addRoute(InetAddress.getByAddress(res), i + 1);
            }
        } catch (UnknownHostException e) {
            throw new RuntimeException(e);
        }
    }

}
