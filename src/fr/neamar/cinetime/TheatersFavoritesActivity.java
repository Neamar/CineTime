package fr.neamar.cinetime;

import java.util.ArrayList;

import android.content.Intent;
import android.os.Bundle;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersFavoritesActivity extends TheatersActivity {
	public ArrayList<Theater> favorites;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		
		setTitle(R.string.app_name);

		favorites = DBHelper.getFavorites(this);

		if (favorites.size() > 0) {
			setTheaters(favorites);
		} else {
			// No favorites yet. Display theaters around
			Intent intent = new Intent(this, TheatersSearchGeoActivity.class);
			startActivity(intent);
			finish();
		}
	}

	@Override
	public void onResume() {
		favorites = DBHelper.getFavorites(this);
		setTheaters(favorites);

		super.onResume();
	}

	@Override
	protected ArrayList<Theater> retrieveResults(String... queries) {
		return null;
	}
}
