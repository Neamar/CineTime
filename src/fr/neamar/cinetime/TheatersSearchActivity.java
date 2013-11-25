package fr.neamar.cinetime;

import java.io.IOException;
import java.util.ArrayList;

import org.apache.http.client.ClientProtocolException;

import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Theater;
import android.app.SearchManager;
import android.os.Bundle;
import android.widget.TextView;

public class TheatersSearchActivity extends TheatersActivity {
	@Override
	public void onCreate(Bundle savedInstanceState) {	
		super.onCreate(savedInstanceState);
		((TextView) findViewById(android.R.id.empty)).setText("Aucun résultat pour cette recherche");
		
		String query = getIntent().getStringExtra(SearchManager.QUERY);
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
		
		return new ArrayList<Theater>();
	}
}
