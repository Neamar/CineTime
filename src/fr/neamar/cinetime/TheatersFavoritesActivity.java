package fr.neamar.cinetime;

import java.util.ArrayList;

import android.content.Intent;
import android.os.Bundle;
import android.widget.ListAdapter;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersFavoritesActivity extends TheatersActivity {
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		setTitle(R.string.app_name);

		new LoadTheatersTask().execute();
	}

	protected ArrayList<Theater> retrieveResults(String... queries) {
		return DBHelper.getFavorites(this);
	}

	@Override
	public void setListAdapter(ListAdapter adapter) {
		if (((TheaterAdapter) adapter).theaters.size() == 0) {
			// No favorites yet. Display theaters around
			Intent intent = new Intent(this, TheatersSearchGeoActivity.class);
			startActivity(intent);
			finish();
		}

		super.setListAdapter(adapter);
	}
}
