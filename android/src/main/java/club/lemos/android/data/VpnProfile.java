package club.lemos.android.data;

import java.util.UUID;

public class VpnProfile {

    private UUID mUUID;
    private String proxy;

    private Integer mMTU, mMark;

    public void setUUID(UUID uuid) {
        this.mUUID = uuid;
    }

    public UUID getUUID() {
        return mUUID;
    }

    public String getProxy() {
        return proxy;
    }

    public void setProxy(String proxy) {
        this.proxy = proxy;
    }

    public Integer getMTU() {
        return mMTU;
    }

    public void setMTU(Integer mtu) {
        this.mMTU = mtu;
    }

    public Integer getMark() {
        return mMark;
    }

    public void setMark(Integer mMark) {
        this.mMark = mMark;
    }
}
