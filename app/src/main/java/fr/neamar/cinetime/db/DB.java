package fr.neamar.cinetime.db;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

public class DB extends SQLiteOpenHelper {

    private final static int DB_VERSION = 2;
    private final static String DB_NAME = "cintetime.s3db";

    DB(Context context) {
        super(context, DB_NAME, null, DB_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase database) {
        database.execSQL("CREATE TABLE favorites ( _id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, title TEXT NOT NULL, location TEXT NOT NULL, city TEXT NOT NULL DEFAULT '')");
    }

    @Override
    public void onUpgrade(SQLiteDatabase database, int oldV, int newV) {
        // See
        // http://www.drdobbs.com/database/using-sqlite-on-android/232900584?pgno=2
        if (oldV < 2 && newV >= 2) {
            upgradeV2(database);
        }
    }

    private void upgradeV2(SQLiteDatabase database) {
        Log.i("DB", "Upgrading database");
        database.execSQL("ALTER TABLE favorites ADD COLUMN city TEXT NOT NULL DEFAULT ''");
    }
}