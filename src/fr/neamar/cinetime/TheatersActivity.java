package fr.neamar.cinetime;

import java.util.ArrayList;

import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView.OnItemLongClickListener;
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
			public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
				InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
				imm.hideSoftInputFromWindow(searchText.getWindowToken(), 0);
				return searchButton.performClick();
			}

		});

		getListView().setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position, long id) {

				String code = ((TheaterAdapter) parent.getAdapter()).theaters.get(position).code;

				String title = ((TheaterAdapter) parent.getAdapter()).theaters.get(position).title;

				Intent intent = new Intent(view.getContext(), MoviesActivity.class);
				intent.putExtra("code", code);
				intent.putExtra("title", title);
				startActivity(intent);
			}
		});

		getListView().setLongClickable(true);
		getListView().setOnItemLongClickListener(new OnItemLongClickListener() {

			public boolean onItemLongClick(AdapterView<?> parent, View view, int position, long id) {
				// TODO Auto-generated method stub

				String uri = "geo:0,0?q="
						+ ((TheaterAdapter) parent.getAdapter()).theaters.get(position).location;
				startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));

				return true;
			}
		});

		// Display favorites :
		searchButton.performClick();
	}

	@Override
	public void onBackPressed() {
		// When pressing back, if a query is entered redisplay favorites.
		// Else perform default back action.
		if (searchText.getText().toString().equals("")) {
			super.onBackPressed();
		} else {
			searchText.setText("");
			searchButton.performClick();
		}
	}

	private void searchForTheater(String query) {
		new LoadTheatersTask().execute(query);
	}

	private class LoadTheatersTask extends AsyncTask<String, Void, ArrayList<Theater>> {
		private final ProgressDialog dialog = new ProgressDialog(TheatersActivity.this);
		private Boolean isLoadingFavorites = false;
		
		@Override
		protected void onPreExecute() {
			this.dialog.setMessage("Recherche en cours...");
			this.dialog.show();
		}

		@Override
		protected ArrayList<Theater> doInBackground(String... queries) {
			if (queries[0].equals("")) {
				isLoadingFavorites = true;
				return DBHelper.getFavorites(TheatersActivity.this);
			}

			return (new APIHelper(TheatersActivity.this)).findTheaters(queries[0]);
		}

		@Override
		protected void onPostExecute(ArrayList<Theater> resultsList) {
			if (this.dialog.isShowing()) {
				try {
					this.dialog.dismiss();
				} catch (IllegalArgumentException e) {
				}
			}
			
			setListAdapter(new TheaterAdapter(TheatersActivity.this, R.layout.listitem_theater,
					resultsList));
			
			if(!isLoadingFavorites)
			{
				((TextView) getListView().getEmptyView())
				.setText("Aucun résultat pour cette recherche.");
			}
		}
	}
}
