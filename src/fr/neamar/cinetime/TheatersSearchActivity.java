package fr.neamar.cinetime;

import java.io.IOException;
import java.util.ArrayList;

import org.apache.http.client.ClientProtocolException;

import android.app.SearchManager;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersSearchActivity extends TheatersActivity {
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		((TextView) findViewById(android.R.id.empty)).setText("Aucun résultat pour cette recherche.");

		if (hasRestoredFromNonConfigurationInstance) {
			return;
		}

		handleIntent(getIntent());
	}

	@Override
	protected void onNewIntent(Intent intent) {
		setIntent(intent);
		handleIntent(intent);
	}

	public void handleIntent(Intent intent) {
		String query = intent.getStringExtra(SearchManager.QUERY);
		setTitle("Recherche : " + query);

		new LoadTheatersTask().execute(query);
	}

	protected ArrayList<Theater> retrieveResults(String... queries) {
		try {
			return (new APIHelper().findTheaters(queries[0]));
		} catch (ClientProtocolException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return null;
	}
}
