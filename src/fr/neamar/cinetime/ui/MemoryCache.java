package fr.neamar.cinetime.ui;

import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;

import android.util.Log;

public class MemoryCache {

	private static final String TAG = "MemoryCache";
	private Map<String, Poster> cache = Collections
			.synchronizedMap(new LinkedHashMap<String, Poster>(10, 1.5f, true));
	// Last
	// argument
	// true
	// for
	// LRU
	// ordering
	private long size = 0;// current allocated size
	private long limit = 1000000;// max memory in bytes

	public MemoryCache() {
		// use 25% of available heap size
		setLimit(Runtime.getRuntime().maxMemory() / 4);
	}

	public void setLimit(long new_limit) {
		limit = new_limit;
		Log.i(TAG, "MemoryCache will use up to " + limit / 1024. / 1024. + "MB");
	}

	public Poster get(String id) {
		try {
			if (!cache.containsKey(id))
				return null;
			// NullPointerException sometimes happen here
			// http://code.google.com/p/osmdroid/issues/detail?id=78
			return cache.get(id);
		} catch (NullPointerException ex) {
			ex.printStackTrace();
			return null;
		}
	}

	public void put(String id, Poster bitmap) {
		try {
			if (cache.containsKey(id))
				size -= getSizeInBytes(cache.get(id));
			cache.put(id, bitmap);
			size += getSizeInBytes(bitmap);
			checkSize();
		} catch (Throwable th) {
			th.printStackTrace();
		}
	}

	private void checkSize() {
		if (size > limit) {
			Iterator<Entry<String, Poster>> iter = cache.entrySet().iterator();// least
																				// recently
																				// accessed
																				// item
																				// will
																				// be
																				// the
																				// first
																				// one
																				// iterated
			while (iter.hasNext()) {
				Entry<String, Poster> entry = iter.next();
				size -= getSizeInBytes(entry.getValue());
				iter.remove();
				if (size <= limit)
					break;
			}
			Log.i(TAG, "Clean cache. New size " + cache.size());
		}
	}

	public void clear() {
		try {
			// NullPointerException sometimes happen here
			// http://code.google.com/p/osmdroid/issues/detail?id=78
			cache.clear();
			size = 0;
		} catch (NullPointerException ex) {
			ex.printStackTrace();
		}
	}

	long getSizeInBytes(Poster bitmap) {
		if (bitmap == null)
			return 0;
		return bitmap.bmp.getRowBytes() * bitmap.bmp.getHeight();
	}
}