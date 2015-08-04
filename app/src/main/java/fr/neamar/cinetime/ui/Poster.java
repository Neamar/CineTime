package fr.neamar.cinetime.ui;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class Poster {
    static public Bitmap stub;
    public int level;
    public int levelRequested;
    public Bitmap bmpLow;
    public Bitmap bmpMed;
    public Bitmap bmpHigh;

    public Poster(int level, int levelRequested) {
        super();
        this.level = level;
        this.levelRequested = levelRequested;
    }

    public static Bitmap getStub(int level) {
        switch (level) {
            case 1:
                return Bitmap.createScaledBitmap(stub, 150, 200, false);
            case 2:
                return Bitmap.createScaledBitmap(stub, 200, 267, false);
            case 3:
                return stub;
            default:
                return null;
        }
    }

    static public void generateStub(Context ctx, int stub_id) {
        Bitmap bitmap = BitmapFactory.decodeResource(ctx.getResources(), stub_id);
        stub = bitmap;
    }

    public boolean continueLoading() {
        return (level < levelRequested);
    }

    public Bitmap getBmp(int level) {
        switch (level) {
            case 1:
                return Bitmap.createScaledBitmap(getBmpLow(), 150, 200, false);
            case 2:
                return Bitmap.createScaledBitmap(getBmpMed(), 200, 267, false);
            case 3:
                return getBmpHigh();
            default:
                return null;
        }
    }

    private Bitmap getBmpLow() {
        if (bmpLow != null)
            return bmpLow;
        return stub;
    }

    private Bitmap getBmpMed() {
        if (bmpMed != null)
            return bmpMed;
        return getBmpLow();
    }

    private Bitmap getBmpHigh() {
        if (bmpHigh != null)
            return bmpHigh;
        return getBmpMed();
    }

    public void setBmp(Bitmap bmp, int level) {
        switch (level) {
            case 1:
                this.bmpLow = bmp;
                break;
            case 2:
                this.bmpMed = bmp;
                break;
            case 3:
                this.bmpHigh = bmp;
                break;
            default:
                break;
        }
    }

    public void setCurrentBmp(Bitmap bmp) {
        switch (level) {
            case 1:
                this.bmpLow = bmp;
                break;
            case 2:
                this.bmpMed = bmp;
                break;
            case 3:
                this.bmpHigh = bmp;
                break;
            default:
                break;
        }
    }

    public int getBytes() {
        int size = 0;
        if (bmpLow != null) {
            size += bmpLow.getRowBytes() * bmpLow.getHeight();
        }
        if (bmpMed != null) {
            size += bmpMed.getRowBytes() * bmpMed.getHeight();
        }
        if (bmpHigh != null) {
            size += bmpHigh.getRowBytes() * bmpHigh.getHeight();
        }
        size += Integer.SIZE * 2;
        return size;
    }

}
