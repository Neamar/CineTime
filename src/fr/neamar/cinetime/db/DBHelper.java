package fr.neamar.cinetime.db;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Theater;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

public class DBHelper {

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
	public static void insertFavorite(Context context, String code, String title, String location) {
		SQLiteDatabase db = getDatabase(context);

		ContentValues values = new ContentValues();
		values.put("code", code);
		values.put("title", title);
		values.put("location", location);
		db.insert("favorites", null, values);
		db.close();
	}

	/**
	 * Retrieve favorites
	 * 
	 * @param context
	 * @param limit
	 * @return
	 */
	public static ArrayList<Theater> getFavorites(Context context) {
		SQLiteDatabase db = getDatabase(context);

		// Cursor query (boolean distinct, String table, String[] columns,
		// String selection, String[] selectionArgs, String groupBy, String
		// having, String orderBy, String limit)
		Cursor cursor = db.query(true, "favorites",
				new String[] { "code", "title", "location" }, null, null, null, null,
				"_id DESC", "20");

		ArrayList<Theater> favorites = new ArrayList<Theater>();

		cursor.moveToFirst();
		while (!cursor.isAfterLast()) {
			Theater entry = new Theater();

			entry.code = cursor.getString(0);
			entry.title = cursor.getString(1);
			entry.location = cursor.getString(2);

			favorites.add(entry);
			cursor.moveToNext();
		}
		cursor.close();
		db.close();

		return favorites;
	}
}
