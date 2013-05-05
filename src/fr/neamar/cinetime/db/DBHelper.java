package fr.neamar.cinetime.db;

import java.util.ArrayList;

import android.annotation.SuppressLint;
import android.app.backup.BackupManager;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Build;
import fr.neamar.cinetime.objects.Theater;

public class DBHelper {
	protected static ArrayList<String> favCodes = new ArrayList<String>();

	public static final Object sDataLock = new Object();

	private static SQLiteDatabase getDatabase(Context context) {
		DB db = new DB(context);
		return db.getReadableDatabase();
	}

	/**
	 * Insert new item into favorites
	 * 
	 * @param context
	 * @param query
	 * @param record
	 */
	@SuppressLint("NewApi")
	public static void insertFavorite(Context context, String code, String title, String location) {
		synchronized (DBHelper.sDataLock) {
			SQLiteDatabase db = getDatabase(context);

			ContentValues values = new ContentValues();
			values.put("code", code);
			values.put("title", title);
			values.put("location", location);
			db.insert("favorites", null, values);
			db.close();
		}
		favCodes.add(code);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
			new BackupManager(context).dataChanged();
		}
	}

	/**
	 * Retrieve favorites
	 * 
	 * @param context
	 * @param limit
	 * @return
	 */
	public static ArrayList<Theater> getFavorites(Context context) {

		ArrayList<Theater> favorites = new ArrayList<Theater>();
		synchronized (DBHelper.sDataLock) {
			SQLiteDatabase db = getDatabase(context);

			favCodes = new ArrayList<String>();

			// Cursor query (boolean distinct, String table, String[] columns,
			// String selection, String[] selectionArgs, String groupBy, String
			// having, String orderBy, String limit)
			Cursor cursor = db.query(true, "favorites",
					new String[] { "code", "title", "location" }, null, null, null, null,
					"_id DESC", "20");

			cursor.moveToFirst();
			while (!cursor.isAfterLast()) {
				Theater entry = new Theater();

				entry.code = cursor.getString(0);
				entry.title = cursor.getString(1);
				entry.location = cursor.getString(2);

				favorites.add(entry);
				favCodes.add(entry.code);
				cursor.moveToNext();
			}
			cursor.close();
			db.close();
		}
		return favorites;
	}

	@SuppressLint("NewApi")
	public static void removeFavorite(Context context, String code) {
		synchronized (DBHelper.sDataLock) {
			SQLiteDatabase db = getDatabase(context);

			db.delete("favorites", "code = ?", new String[] { code });
			db.close();
		}
		favCodes.remove(code);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
			new BackupManager(context).dataChanged();
		}
	}

    @SuppressLint("NewApi")
    public static void clearFavorite(Context context) {
        synchronized (DBHelper.sDataLock) {
            SQLiteDatabase db = getDatabase(context);

            db.delete("favorites", null, null);
            db.close();
        }
        favCodes.clear();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
            new BackupManager(context).dataChanged();
        }
    }


	public static boolean isFavorite(String code) {
		return favCodes.contains(code);
	}
}
