package fr.neamar.cinetime;

import java.io.IOException;
import java.util.ArrayList;

import org.apache.http.client.ClientProtocolException;

import android.annotation.TargetApi;
import android.app.SearchManager;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NavUtils;
import android.view.MenuItem;
import android.widget.TextView;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersSearchActivity extends TheatersActivity {
	@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		((TextView) findViewById(android.R.id.empty)).setText("Aucun résultat pour cette recherche.");

		if (hasRestoredFromNonConfigurationInstance) {
			return;
		}

		handleIntent(getIntent());

		// Title in action bar brings back one level
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
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

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		if (item.getItemId() == android.R.id.home) {
			NavUtils.navigateUpFromSameTask(this);
			return true;
		}
		return super.onOptionsItemSelected(item);
	}

	@Override
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
