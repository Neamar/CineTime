package fr.neamar.cinetime;

import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.EditText;
import android.widget.ImageButton;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersActivity extends ListActivity {

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_theaters);

		// DBHelper.insertFavorite(this, "P0005", "UGC Astoria",
		// "31, cours Vitton");

		ArrayList<Theater> theaters = DBHelper.getFavorites(this);
		TheaterAdapter adapter = new TheaterAdapter(this,
				R.layout.listitem_theater, theaters);
		setListAdapter(adapter);

		final EditText search = (EditText) findViewById(R.id.theaters_search);
		ImageButton searchButton = (ImageButton) findViewById(R.id.theaters_search_button);
		searchButton.setOnClickListener(new View.OnClickListener() {

			@Override
			public void onClick(View v) {
				if (!search.getText().toString().equals(""))
					new LoadTheatersTask().execute(search.getText().toString());
			}
		});

		getListView().setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> parent, View view,
					int position, long id) {

				String code = ((TheaterAdapter) parent.getAdapter()).theaters
						.get(position).code;

				Intent intent = new Intent(view.getContext(), MoviesActivity.class);
				intent.putExtra("code", code);
				startActivity(intent);
			}
		});
		
		Intent intent = new Intent(this, MoviesActivity.class);
		intent.putExtra("code", "P0671");
		startActivity(intent);
	}

	private class LoadTheatersTask extends
			AsyncTask<String, Void, ArrayList<Theater>> {
		private final ProgressDialog dialog = new ProgressDialog(
				TheatersActivity.this);

		@Override
		protected void onPreExecute() {
			this.dialog.setMessage("Recherche en cours...");
			this.dialog.show();

		}

		@Override
		protected ArrayList<Theater> doInBackground(String... queries) {
			ArrayList<Theater> resultsList = new ArrayList<Theater>();

			JSONArray jsonResults = APIHelper.findTheater(queries[0]);

			for (int i = 0; i < jsonResults.length(); i++) {
				JSONObject jsonTheater;
				try {
					jsonTheater = jsonResults.getJSONObject(i);

					Theater theater = new Theater();
					theater.code = jsonTheater.getString("code");
					theater.title = jsonTheater.getString("name");
					theater.location = jsonTheater.getString("address");

					resultsList.add(theater);

				} catch (JSONException e) {
					e.printStackTrace();
				}
			}

			return resultsList;

		}

		@Override
		protected void onPostExecute(ArrayList<Theater> resultsList) {
			if (this.dialog.isShowing())
				this.dialog.dismiss();
			setListAdapter(new TheaterAdapter(TheatersActivity.this,
					R.layout.listitem_theater, resultsList));
		}
	}
}
