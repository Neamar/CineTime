package fr.neamar.cinetime;

import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.TargetApi;
import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
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
			public void onItemClick(AdapterView<?> parent, View view,
					int position, long id) {
				Uri uriUrl = Uri
						.parse("http://www.allocine.fr/film/fichefilm_gen_cfilm="
								+ movies.get(position).code + ".html");
				Intent launchBrowser = new Intent(Intent.ACTION_VIEW, uriUrl);
				startActivity(launchBrowser);
			}
		});
		
		if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH)
		{
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		if(item.getItemId() == android.R.id.home)
		{
			Intent i = new Intent(this, TheatersActivity.class);
			i.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
			startActivity(i);
			return true;
		}
		
		return super.onOptionsItemSelected(item);
	}

	private class LoadMoviesTask extends
			AsyncTask<String, Void, ArrayList<Movie>> {
		private final ProgressDialog dialog = new ProgressDialog(
				MoviesActivity.this);

		@Override
		protected void onPreExecute() {
			this.dialog.setMessage("Chargement des séances en cours...");
			this.dialog.show();

		}

		@Override
		protected ArrayList<Movie> doInBackground(String... queries) {
			ArrayList<Movie> resultsList = new ArrayList<Movie>();

			JSONArray jsonResults = APIHelper.findMovies(queries[0]);

			for (int i = 0; i < jsonResults.length(); i++) {
				JSONObject jsonMovie, jsonShow;

				try {
					jsonMovie = jsonResults.getJSONObject(i);
					jsonShow = jsonMovie.getJSONObject("onShow").getJSONObject(
							"movie");

					Movie movie = new Movie();
					movie.code = jsonShow.getString("code");
					movie.title = jsonShow.getString("title");
					movie.poster = "http://images.allocine.fr/r_120_500"
							+ jsonShow.getJSONObject("poster")
									.getString("path");
					movie.duration = jsonShow.getInt("runtime");
					movie.duration = jsonShow.getInt("runtime");
					if (jsonShow.has("statistics")) {
						if (jsonShow.getJSONObject("statistics").has(
								"pressRating"))
							movie.pressRating = jsonShow.getJSONObject(
									"statistics").getString("pressRating");
						if (jsonShow.getJSONObject("statistics").has(
								"userRating"))
							movie.userRating = jsonShow.getJSONObject(
									"statistics").getString("userRating");
					}
					movie.display = jsonMovie.getString("display");
					movie.isOriginalLanguage = jsonMovie
							.getJSONObject("version").getString("original")
							.equals("true");
					if (jsonMovie.has("screenFormat"))
						movie.is3D = jsonMovie.getJSONObject("screenFormat")
								.getString("$").equals("3D");

					resultsList.add(movie);

				} catch (JSONException e) {
					Log.e("wtf", e.getMessage());
					e.printStackTrace();
				}
			}

			return resultsList;
		}

		@Override
		protected void onPostExecute(ArrayList<Movie> resultsList) {
			if (this.dialog.isShowing())
				this.dialog.dismiss();
			movies = resultsList;
			setListAdapter(new MovieAdapter(MoviesActivity.this,
					R.layout.listitem_theater, resultsList));
		}
	}
}
