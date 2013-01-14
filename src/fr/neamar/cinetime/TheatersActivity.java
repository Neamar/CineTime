package fr.neamar.cinetime;

import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.TextView;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersActivity extends ListActivity {

	public EditText searchText;
	public ImageButton searchButton;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_theaters);
		setTitle(R.string.title_activity_theaters);

		searchText = (EditText) findViewById(R.id.theaters_search);
		searchButton = (ImageButton) findViewById(R.id.theaters_search_button);
		
		searchButton.setOnClickListener(new View.OnClickListener() {

			@Override
			public void onClick(View v) {
				searchForTheater(searchText.getText().toString().trim());
			}
		});

		// When searching from keyboard
		searchText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
			@Override
			public boolean onEditorAction(TextView v, int actionId,
					KeyEvent event) {
				InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
				imm.hideSoftInputFromWindow(searchText.getWindowToken(), 0);
				return searchButton.performClick();
			}

		});

		getListView().setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> parent, View view,
					int position, long id) {

				String code = ((TheaterAdapter) parent.getAdapter()).theaters
						.get(position).code;

				String title = ((TheaterAdapter) parent.getAdapter()).theaters
						.get(position).title;

				Intent intent = new Intent(view.getContext(),
						MoviesActivity.class);
				intent.putExtra("code", code);
				intent.putExtra("title", title);
				startActivity(intent);
			}
		});

		// Display favorites :
		searchButton.performClick();
	}

	@Override
	public void onBackPressed()
	{
		//When pressing back, if a query is entered redisplay favorites. 
		//Else perform default back action.
		if(searchText.getText().toString().equals(""))
		{
			super.onBackPressed();
		}
		else
		{
			searchText.setText("");
			searchButton.performClick();
		}
	}

	private void searchForTheater(String query) {
		new LoadTheatersTask().execute(query);
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
			if (queries[0].equals("")) {
				return DBHelper.getFavorites(TheatersActivity.this);
			}

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
