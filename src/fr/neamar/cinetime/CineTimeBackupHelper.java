package fr.neamar.cinetime;

import android.annotation.TargetApi;
import android.app.backup.*;
import android.os.Build;
import android.os.ParcelFileDescriptor;

import java.io.IOException;

import fr.neamar.cinetime.db.DBHelper;

@TargetApi(Build.VERSION_CODES.FROYO)
public class CineTimeBackupHelper extends BackupAgentHelper {

	// The name of the SharedPreferences file
	static final String PREFS = "synopsis";
    static final String PREFS_COUNTRY = "fr.neamar.summon_preferences";

	// A key to uniquely identify the set of backup data
	static final String PREFS_BACKUP_KEY = "prefs";
    static final String PREFS_BACKUP_KEY_COUNTRY = "prefs_country";

	// The name of the SharedPreferences file
	static final String DB = "../databases/cintetime.s3db";

	// A key to uniquely identify the set of backup data
	static final String FILES_BACKUP_KEY = "files";

	// Allocate a helper and add it to the backup agent
	@Override
	public void onCreate() {
		SharedPreferencesBackupHelper helper = new SharedPreferencesBackupHelper(this, PREFS);
		addHelper(PREFS_BACKUP_KEY, helper);
        SharedPreferencesBackupHelper helperC = new SharedPreferencesBackupHelper(this, PREFS_COUNTRY);
        addHelper(PREFS_BACKUP_KEY_COUNTRY, helperC);
		FileBackupHelper helperF = new FileBackupHelper(this, DB);
		addHelper(FILES_BACKUP_KEY, helperF);
	}

	@Override
	public void onBackup(ParcelFileDescriptor oldState, BackupDataOutput data,
			ParcelFileDescriptor newState) throws IOException {
		// Hold the lock while the FileBackupHelper performs backup
		synchronized (DBHelper.sDataLock) {
			super.onBackup(oldState, data, newState);
		}
	}

	@Override
	public void onRestore(BackupDataInput data, int appVersionCode, ParcelFileDescriptor newState)
			throws IOException {
		// Hold the lock while the FileBackupHelper restores the file
		synchronized (DBHelper.sDataLock) {
			super.onRestore(data, appVersionCode, newState);
		}
	}
}
