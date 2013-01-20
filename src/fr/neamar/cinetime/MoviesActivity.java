package fr.neamar.cinetime;

import java.util.ArrayList;

import android.annotation.TargetApi;
import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Movie;

public class MoviesActivity extends ListActivity {
	public ArrayList<Movie> movies = new ArrayList<Movie>();

	@TargetApi(14)
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_movies);

		new LoadMoviesTask().execute(getIntent().getStringExtra("code"));

		setTitle("Séances " + getIntent().getStringExtra("title"));

		getListView().setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
				Movie selection = movies.get(position);

				Intent details = new Intent(view.getContext(), DetailsActivity.class);
				details.putExtra("theater", getIntent().getStringExtra("title"));

				details.putExtra("code", selection.code);
				details.putExtra("title", selection.title);
				details.putExtra("directors", selection.directors);
				details.putExtra("actors", selection.actors);
				details.putExtra("genres", selection.genres);
				details.putExtra("poster", selection.poster);
				details.putExtra("duration", selection.duration);
				details.putExtra("pressRating", selection.pressRating);
				details.putExtra("userRating", selection.userRating);
				details.putExtra("display", selection.display);
				details.putExtra("is3D", selection.is3D);
				details.putExtra("isOriginalLanguage", selection.isOriginalLanguage);

				startActivity(details);
			}
		});

		// Title in action bar brings back one level
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Click on title in actionbar
		if (item.getItemId() == android.R.id.home) {
			finish();
			return true;
		}

		return super.onOptionsItemSelected(item);
	}

	private class LoadMoviesTask extends AsyncTask<String, Void, ArrayList<Movie>> {
		private final ProgressDialog dialog = new ProgressDialog(MoviesActivity.this);

		@Override
		protected void onPreExecute() {
			this.dialog.setMessage("Chargement des séances en cours...");
			this.dialog.show();

		}

		@Override
		protected ArrayList<Movie> doInBackground(String... queries) {
			return (new APIHelper(MoviesActivity.this)).findMoviesFromTheater(queries[0]);
		}

		@Override
		protected void onPostExecute(ArrayList<Movie> resultsList) {
			if (this.dialog.isShowing())
				this.dialog.dismiss();
			movies = resultsList;
			setListAdapter(new MovieAdapter(MoviesActivity.this, R.layout.listitem_theater,
					resultsList));
		}
	}
}
