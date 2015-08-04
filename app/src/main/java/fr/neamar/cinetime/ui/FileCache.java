package fr.neamar.cinetime.ui;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;

import java.io.File;

public class FileCache {

    private File cacheDir;

    @TargetApi(8)
    public FileCache(Context context) {
        // Find the dir to save cached images
        if (android.os.Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
                cacheDir = new File(context.getExternalFilesDir(null), "poster");
            } else {
                cacheDir = new File(android.os.Environment.getExternalStorageDirectory(), "fr.neamar.cinetime");
            }
        else
            cacheDir = context.getCacheDir();
        if (!cacheDir.exists())
            cacheDir.mkdirs();
    }

    public File getFile(String url) {
        // I identify images by hashcode. Not a perfect solution, good for the
        // demo.
        String filename = String.valueOf(url.hashCode());
        // Another possible solution (thanks to grantland)
        // String filename = URLEncoder.encode(url);
        File f = new File(cacheDir, filename);
        return f;

    }

    public void clear() {
        File[] files = cacheDir.listFiles();
        if (files == null)
            return;
        for (File f : files)
            f.delete();
    }

}