package fr.neamar.cinetime;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.text.Html;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.ui.ImageLoader;

public class DetailsActivity extends Activity {
	protected Movie displayedMovie = new Movie();
	protected String theater = "";
	public ImageLoader imageLoader;

	@TargetApi(14)
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_details);

		imageLoader = new ImageLoader(getApplicationContext());

		// Build movie using current informations
		theater = getIntent().getStringExtra("theater");

		displayedMovie.code = getIntent().getStringExtra("code");
		displayedMovie.title = getIntent().getStringExtra("title");
		displayedMovie.directors = getIntent().getStringExtra("directors");
		displayedMovie.actors = getIntent().getStringExtra("actors");
		displayedMovie.genres = getIntent().getStringExtra("genres");
		displayedMovie.poster = getIntent().getStringExtra("poster");
		displayedMovie.duration = getIntent().getIntExtra("duration", 0);
		displayedMovie.pressRating = getIntent().getStringExtra("pressRating");
		displayedMovie.userRating = getIntent().getStringExtra("userRating");
		displayedMovie.display = getIntent().getStringExtra("display");
		displayedMovie.is3D = getIntent().getBooleanExtra("is3D", false);
		displayedMovie.isOriginalLanguage = getIntent()
				.getBooleanExtra("isOriginalLanguage", false);

		updateUI();

		(new LoadMovieTask()).execute(displayedMovie.code);

		// Title in action bar brings back one level
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.activity_details, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Click on title in actionbar
		switch (item.getItemId()) {
		case android.R.id.home:
			finish();
			return true;
		case R.id.menu_share:
			shareMovie();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}
	
	protected void shareMovie()
	{
		Intent sharingIntent = new Intent(android.content.Intent.ACTION_SEND);
		sharingIntent.setType("text/plain");
		sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT, displayedMovie.getSharingText(theater));
		
		startActivity(Intent.createChooser(sharingIntent, "Partager le film..."));
	}

	protected void updateUI() {
		setTitle(displayedMovie.title);

		TextView title = (TextView) findViewById(R.id.details_title);
		title.setText(displayedMovie.title);

		String extraString = "";
		extraString += "<strong>Durée</strong> : " + displayedMovie.getDuration() + "<br />";

		if (!displayedMovie.directors.equals(""))
			extraString += "<strong>Directeur</strong> : " + displayedMovie.directors + "<br />";
		if (!displayedMovie.actors.equals(""))
			extraString += "<strong>Acteurs</strong> : " + displayedMovie.actors + "<br />";
		extraString += "<strong>Genre</strong> : " + displayedMovie.genres;

		TextView extra = (TextView) findViewById(R.id.details_extra);
		extra.setText(Html.fromHtml(extraString));

		TextView display = (TextView) findViewById(R.id.details_display);
		display.setText(Html.fromHtml("<strong>" + theater + "</strong>"
				+ displayedMovie.getDisplayDetails() + "<br>" + displayedMovie.getDisplay()));

		TextView synopsis = (TextView) findViewById(R.id.details_synopsis);
		synopsis.setText(displayedMovie.synopsis.equals("") ? "Chargement du synopsis..." : Html
				.fromHtml(displayedMovie.synopsis));

		if (displayedMovie.poster != null) {
			ImageView poster = (ImageView) findViewById(R.id.details_poster);
			imageLoader.DisplayImage(displayedMovie.poster, poster);
		}

		ProgressBar pressRating = (ProgressBar) findViewById(R.id.details_pressrating);
		pressRating.setProgress(displayedMovie.getPressRating());

		ProgressBar userRating = (ProgressBar) findViewById(R.id.details_userrating);
		userRating.setProgress(displayedMovie.getUserRating());
	}

	private class LoadMovieTask extends AsyncTask<String, Void, Movie> {
		@Override
		protected Movie doInBackground(String... queries) {
			return (new APIHelper(DetailsActivity.this)).findMovie(displayedMovie);
		}

		@Override
		protected void onPostExecute(Movie resultsList) {
			displayedMovie = resultsList;
			updateUI();
		}
	}
}
