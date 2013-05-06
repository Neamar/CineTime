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
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.preference.PreferenceManager;
import android.support.v4.util.LruCache;
import android.widget.ImageView;
import fr.neamar.cinetime.PosterViewerActivity;
import fr.neamar.cinetime.R;

public class ImageLoader {

	private static ImageLoader instance;

	LruCache<String, Poster> posterCache;
	final int stub_id = R.drawable.stub;
	Context ctx;
	FileCache fileCache;
	private Map<ImageView, String> imageViews = Collections
			.synchronizedMap(new WeakHashMap<ImageView, String>());
	ExecutorService executorService;
	Handler handler = new Handler();// handler to display images in UI thread

	private ImageLoader(Context context) {
		fileCache = new FileCache(context);
		ctx = context;
		executorService = Executors.newFixedThreadPool(5);
		int cacheSize = (int) (Runtime.getRuntime().maxMemory() / 4);
		posterCache = new LruCache<String, Poster>(cacheSize) {
			protected int sizeOf(String key, Poster value) {
				return value.getBytes();
			}
		};
		Poster.generateStub(context, stub_id);
	}

	public static ImageLoader getInstance(Context ctx) {
		if (instance == null) {
			instance = new ImageLoader(ctx);
		}
		return instance;
	}

	public void DisplayImage(String url, ImageView imageView, int levelRequested) {
		if (url == null) {
			url = "";
		}
		if (url != "") {
			imageViews.put(imageView, url);
			Poster poster = posterCache.get(url);
			if (poster != null) {
				imageView.setImageBitmap(poster.getBmp(levelRequested));
				if (poster.levelRequested < levelRequested) {
					poster.levelRequested = levelRequested;
				}
				if (poster.continueLoading()) {
					poster.level++;
					queuePhoto(poster, url, imageView, levelRequested);
				} else {
					Intent i = new Intent(PosterViewerActivity.POSTER_LOADED);
					ctx.sendBroadcast(i);
				}
			} else {
				Poster nPoster = new Poster(1, levelRequested);
				imageView.setImageBitmap(nPoster.getBmp(levelRequested));
				queuePhoto(nPoster, url, imageView, levelRequested);
			}
		} else {
			imageView.setImageBitmap(Poster.getStub(levelRequested));
			if (levelRequested == 3) {
				Intent i = new Intent(PosterViewerActivity.POSTER_LOADED);
				ctx.sendBroadcast(i);
			}
		}
	}

	private void queuePhoto(Poster poster, String url, ImageView imageView,
			int levelRequested) {
		PhotoToLoad p = new PhotoToLoad(poster, url, imageView, levelRequested);
		executorService.submit(new PhotosLoader(p));
	}

	private void queuePhoto(PhotoToLoad p) {
		executorService.submit(new PhotosLoader(p));
	}

	private Bitmap getBitmap(String url, Poster poster) {
		String fullUrl = makeUrl(url, poster.level);

		File f = fileCache.getFile(fullUrl);

		if (poster.level < 3) {
			// from SD cache
			Bitmap b = decodeFile(f);
			if (b != null)
				return b;
		}

		// from web
		try {
			Bitmap bitmap = null;
			URL imageUrl = new URL(fullUrl);
			HttpURLConnection conn = (HttpURLConnection) imageUrl
					.openConnection();
			conn.setConnectTimeout(30000);
			conn.setReadTimeout(30000);
			conn.setInstanceFollowRedirects(true);
			InputStream is = conn.getInputStream();
			OutputStream os = new FileOutputStream(f);
			Utils.CopyStream(is, os);
			os.close();
			bitmap = decodeFile(f);
			if (poster.level > 2) {
				f.delete();
			}
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
			FileInputStream stream2 = new FileInputStream(f);
			Bitmap bitmap = BitmapFactory.decodeStream(stream2);
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
		public int levelRequested;

		public PhotoToLoad(Poster p, String u, ImageView i, int l) {
			poster = p;
			url = u;
			imageView = i;
			levelRequested = l;
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
				photoToLoad.poster.setCurrentBmp(getBitmap(photoToLoad.url,
						photoToLoad.poster));
				posterCache.put(photoToLoad.url, photoToLoad.poster);
				if (photoToLoad.poster.continueLoading()) {
					photoToLoad.poster.level++;
					queuePhoto(photoToLoad);
				}
				if (imageViewReused(photoToLoad))
					return;
				BitmapDisplayer bd = new BitmapDisplayer(photoToLoad);
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
		PhotoToLoad photoToLoad;

		public BitmapDisplayer(PhotoToLoad p) {
			photoToLoad = p;
		}

		@Override
		public void run() {
			if (imageViewReused(photoToLoad))
				return;
			photoToLoad.imageView.setImageBitmap(photoToLoad.poster
					.getBmp(photoToLoad.levelRequested));
			if (photoToLoad.poster.level == photoToLoad.levelRequested) {
				Intent i = new Intent(PosterViewerActivity.POSTER_LOADED);
				ctx.sendBroadcast(i);
			}
		}
	}

	public void clearCache() {
		posterCache.evictAll();
		fileCache.clear();
	}

	private String getLocalisedUrl() {
		String country = PreferenceManager.getDefaultSharedPreferences(ctx)
				.getString("country", ctx.getString(R.string.default_country));
		String url;
		if (country.equalsIgnoreCase("uk")) {
			url = ctx.getResources().getString(R.string.images_url_uk);
		} else if (country.equalsIgnoreCase("fr")) {
			url = ctx.getResources().getString(R.string.images_url_fr);
		} else if (country.equalsIgnoreCase("de")) {
			url = ctx.getResources().getString(R.string.images_url_de);
		} else if (country.equalsIgnoreCase("es")) {
			url = ctx.getResources().getString(R.string.images_url_es);
		} else {
			throw new UnsupportedOperationException("Locale unkown " + country);
		}
		return "http://" + url;
	}

	private String makeUrl(String baseUrl, int level) {
		String url = null;
		switch (level) {
		case 1:
			url = getLocalisedUrl() + "/r_150_500" + baseUrl;
			break;
		case 2:
			url = getLocalisedUrl() + "/r_200_666" + baseUrl;
			break;
		case 3:
			url = getLocalisedUrl() + "/r_720_2400" + baseUrl;
			break;
		default:
			url = "";
			break;
		}
		return url;
	}

}