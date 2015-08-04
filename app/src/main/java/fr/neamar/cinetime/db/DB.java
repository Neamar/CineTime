package fr.neamar.cinetime.db;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

public class DB extends SQLiteOpenHelper {

    final static int DB_VERSION = 1;
    final static String DB_NAME = "cintetime.s3db";
    Context context;

    public DB(Context context) {
        super(context, DB_NAME, null, DB_VERSION);
        this.context = context;
    }

    @Override
    public void onCreate(SQLiteDatabase database) {
        database.execSQL("CREATE TABLE favorites ( _id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, title TEXT NOT NULL, location TEXT NOT NULL)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase arg0, int arg1, int arg2) {
        // See
        // http://www.drdobbs.com/database/using-sqlite-on-android/232900584?pgno=2
    }
}