package fr.neamar.cinetime.ui;

//Credits goes to com.fedorvlasov.lazylist
// https://github.com/thest1/LazyList

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.support.v4.util.LruCache;
import android.util.Log;
import android.widget.ImageView;
import fr.neamar.cinetime.R;

public class ImageLoader {

	LruCache<String, Poster> posterCache;
	FileCache fileCache;
	private Map<ImageView, String> imageViews = Collections
			.synchronizedMap(new WeakHashMap<ImageView, String>());
	ExecutorService executorService;
	Handler handler = new Handler();// handler to display images in UI thread

	public ImageLoader(Context context) {
		fileCache = new FileCache(context);
		executorService = Executors.newFixedThreadPool(5);
		int cacheSize = (int) (Runtime.getRuntime().maxMemory()/4);
		posterCache = new LruCache<String, Poster>(cacheSize){
			protected int sizeOf(String key, Poster value) {
		           return value.bmp.getRowBytes() * value.bmp.getHeight();
			}
		};
	}

	final int stub_id = R.drawable.stub;

	public void DisplayImage(String url, ImageView imageView, int levelRequested) {
		imageViews.put(imageView, url);
		Log.d("Image", url);
		Poster poster = posterCache.get(url);
		if (poster != null){
			imageView.setImageBitmap(poster.bmp);
			if(poster.levelRequested < levelRequested){
				poster.levelRequested = levelRequested;
			}
			if(poster.level < levelRequested){
				poster.level++;
				queuePhoto(poster, url, imageView);
			}
		}
		else {
			queuePhoto(new Poster(1, levelRequested, null), url, imageView);
			imageView.setImageResource(stub_id);
		}
	}

	private void queuePhoto(Poster poster, String url, ImageView imageView) {
		PhotoToLoad p = new PhotoToLoad(poster, url, imageView);
		executorService.submit(new PhotosLoader(p));
	}

	private Bitmap getBitmap(String url) {
		File f = fileCache.getFile(url);

		// from SD cache
		Bitmap b = decodeFile(f);
		if (b != null)
			return b;

		// from web
		try {
			Bitmap bitmap = null;
			URL imageUrl = new URL(url);
			HttpURLConnection conn = (HttpURLConnection) imageUrl.openConnection();
			conn.setConnectTimeout(30000);
			conn.setReadTimeout(30000);
			conn.setInstanceFollowRedirects(true);
			InputStream is = conn.getInputStream();
			OutputStream os = new FileOutputStream(f);
			Utils.CopyStream(is, os);
			os.close();
			bitmap = decodeFile(f);
			return bitmap;
		} catch (Throwable ex) {
			ex.printStackTrace();
			if (ex instanceof OutOfMemoryError)
				posterCache.evictAll();
			return null;
		}
	}

	// decodes image and scales it to reduce memory consumption
	private Bitmap decodeFile(File f) {
		try {
			// decode image size
			BitmapFactory.Options o = new BitmapFactory.Options();
			o.inJustDecodeBounds = true;
			FileInputStream stream1 = new FileInputStream(f);
			BitmapFactory.decodeStream(stream1, null, o);
			stream1.close();
			
			// Find the correct scale value. It should be the power of 2.
			final int REQUIRED_SIZE = 968;
			int width_tmp = o.outWidth, height_tmp = o.outHeight;
			int scale = 1;
			while (true) {
				if (width_tmp / 2 < REQUIRED_SIZE || height_tmp / 2 < REQUIRED_SIZE)
					break;
				width_tmp /= 2;
				height_tmp /= 2;
				scale *= 2;
			}

			// decode with inSampleSize
			BitmapFactory.Options o2 = new BitmapFactory.Options();
			o2.inSampleSize = scale;
			FileInputStream stream2 = new FileInputStream(f);
			Bitmap bitmap = BitmapFactory.decodeStream(stream2, null, o2);
			stream2.close();
			return bitmap;
		} catch (FileNotFoundException e) {
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	// Task for the queue
	private class PhotoToLoad {
		public Poster poster;
		public String url;
		public ImageView imageView;

		public PhotoToLoad(Poster p, String u, ImageView i) {
			poster = p;
			url = u;
			imageView = i;
		}
	}

	class PhotosLoader implements Runnable {
		PhotoToLoad photoToLoad;

		PhotosLoader(PhotoToLoad photoToLoad) {
			this.photoToLoad = photoToLoad;
		}

		@Override
		public void run() {
			try {
				if (imageViewReused(photoToLoad))
					return;
				Bitmap oldBmp = photoToLoad.poster.bmp;
				photoToLoad.poster.bmp = getBitmap(makeUrl(photoToLoad.url, photoToLoad.poster.level));
				posterCache.put(photoToLoad.url, photoToLoad.poster);
				if(photoToLoad.poster.continueLoading()){
					photoToLoad.poster.level++;
					queuePhoto(photoToLoad.poster, photoToLoad.url, photoToLoad.imageView);
				}
				if (imageViewReused(photoToLoad))
					return;
				BitmapDisplayer bd = new BitmapDisplayer(photoToLoad, oldBmp);
				handler.post(bd);
			} catch (Throwable th) {
				th.printStackTrace();
			}
		}
	}

	boolean imageViewReused(PhotoToLoad photoToLoad) {
		String tag = imageViews.get(photoToLoad.imageView);
		if (tag == null || !tag.equals(photoToLoad.url))
			return true;
		return false;
	}

	// Used to display bitmap in the UI thread
	class BitmapDisplayer implements Runnable {
		Bitmap oldBmp;
		PhotoToLoad photoToLoad;

		public BitmapDisplayer(PhotoToLoad p, Bitmap o) {
			oldBmp = o;
			photoToLoad = p;
		}

		@Override
		public void run() {
			if (imageViewReused(photoToLoad))
				return;
			if (photoToLoad.poster.bmp != null){
				photoToLoad.imageView.setImageBitmap(photoToLoad.poster.bmp);
			}else if(oldBmp != null){
				photoToLoad.imageView.setImageBitmap(oldBmp);
			}else {
				photoToLoad.imageView.setImageResource(stub_id);
			}
		}
	}

	public void clearCache() {
		posterCache.evictAll();
		fileCache.clear();
	}
	
	private String makeUrl(String baseUrl, int level){
		String url = null;
		switch (level) {
		case 1:
			url = "http://images.allocine.fr/r_150_500" + baseUrl;
			break;
		case 2:
			url = "http://images.allocine.fr/r_200_666" + baseUrl;
			break;
		case 3:
			url = "http://images.allocine.fr/r_720_2400" + baseUrl;
			break;
		default:
			url = "";
			break;
		}
		return url;
	}

}