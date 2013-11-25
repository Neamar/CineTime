package fr.neamar.cinetime;

import android.app.Activity;
import android.content.Intent;
import android.content.Intent.ShortcutIconResource;
import android.os.Bundle;

public class ShortcutActivity extends Activity {
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		// The meat of our shortcut
		Intent shortcutIntent = new Intent(this, MoviesActivity.class);
		shortcutIntent.putExtra("code", "P0671");
		shortcutIntent.putExtra("theater", "UGC Cinécité Internationale");
		ShortcutIconResource iconResource = Intent.ShortcutIconResource.fromContext(this, R.drawable.ic_launcher);

		// The result we are passing back from this activity
		Intent intent = new Intent();
		intent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent);
		intent.putExtra(Intent.EXTRA_SHORTCUT_NAME, "UGC Cinécité Internationale");
		intent.putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, iconResource);
		setResult(RESULT_OK, intent);

		finish(); // Must call finish for result to be returned immediately
	}
}
