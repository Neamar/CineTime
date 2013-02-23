package fr.neamar.cinetime.fragments;

import java.util.ArrayList;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.Html;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import fr.neamar.cinetime.R;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.callbacks.TaskMoviesCallbacks;
import fr.neamar.cinetime.fragments.MoviesFragment.Callbacks;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.ui.ImageLoader;

public class DetailsFragment extends Fragment implements TaskMoviesCallbacks {

	public static final String ARG_ITEM_ID = "item_id";
	public static final String ARG_THEATER_NAME = "theater_name";
	protected Movie displayedMovie;

	private Callbacks mCallbacks = sDummyCallbacks;

	private int idItem;
	private TextView title;
	private TextView extra;
	private TextView display;
	private ImageView poster;
	private TextView certificate;
	private TextView synopsis;
	private ProgressBar pressRating;
	private ProgressBar userRating;
	public ImageLoader imageLoader;
	protected String theater = "";
	private LoadMovieTask mTask;
	private boolean titleToSet = false;
	private boolean toFinish = false;

	public DetailsFragment() {
	}

	private static Callbacks sDummyCallbacks = new Callbacks() {
		@Override
		public void onItemSelected(int position) {
		}

		@Override
		public void setFragment(Fragment fragment) {
		}
	};

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		this.setRetainInstance(true);
	}

	@Override
	public void onResume() {
		super.onResume();
		if (displayedMovie.synopsis.equalsIgnoreCase("") && mTask == null) {
			mTask = new LoadMovieTask();
			mTask.execute(displayedMovie.code);
		}
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.fragment_details, container, false);
		title = (TextView) view.findViewById(R.id.details_title);
		extra = (TextView) view.findViewById(R.id.details_extra);
		display = (TextView) view.findViewById(R.id.details_display);
		poster = (ImageView) view.findViewById(R.id.details_poster);
		pressRating = (ProgressBar) view.findViewById(R.id.details_pressrating);
		userRating = (ProgressBar) view.findViewById(R.id.details_userrating);
		synopsis = (TextView) view.findViewById(R.id.details_synopsis);
		certificate = (TextView) view.findViewById(R.id.details_certificate);
		imageLoader = new ImageLoader(getActivity().getApplicationContext());
		if(displayedMovie != null){
			updateUI();
		}
		return view;
	}

	@Override
	public void onDetach() {
		super.onDetach();
		mCallbacks = sDummyCallbacks;
	}

	@Override
	public void onAttach(Activity activity) {
		super.onAttach(activity);
		if (!(activity instanceof Callbacks)) {
			throw new IllegalStateException("Activity must implement fragment's callbacks.");
		}
		mCallbacks = (Callbacks) activity;
		mCallbacks.setFragment(this);
		if (titleToSet) {
			getActivity().setTitle(displayedMovie.title);
			titleToSet = false;
		}
		if (toFinish) {
			getActivity().finish();
			toFinish = false;
		}
	}

	public void shareMovie() {
		Intent sharingIntent = new Intent(android.content.Intent.ACTION_SEND);
		sharingIntent.setType("text/plain");
		sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT,
				displayedMovie.getSharingText(theater));

		startActivity(Intent.createChooser(sharingIntent, "Partager le film..."));
	}

	public void updateUI() {
		title.setText(displayedMovie.title);

		String extraString = "";
		extraString += "<strong>Durée</strong> : " + displayedMovie.getDuration() + "<br />";

		if (!displayedMovie.directors.equals(""))
			extraString += "<strong>Directeur</strong> : " + displayedMovie.directors + "<br />";
		if (!displayedMovie.actors.equals(""))
			extraString += "<strong>Acteurs</strong> : " + displayedMovie.actors + "<br />";
		extraString += "<strong>Genre</strong> : " + displayedMovie.genres;
		extra.setText(Html.fromHtml(extraString));
		display.setText(Html.fromHtml("<strong>" + theater + "</strong>"
				+ displayedMovie.getDisplayDetails() + "<br>" + displayedMovie.getDisplay()));
		if (displayedMovie.certificateString.equals(""))
			certificate.setVisibility(View.GONE);
		else
			certificate.setText(displayedMovie.certificateString);
		if (displayedMovie.poster != null) {
			imageLoader.DisplayImage(displayedMovie.poster, poster);
		}
		pressRating.setProgress(displayedMovie.getPressRating());
		userRating.setProgress(displayedMovie.getUserRating());
		synopsis.setText(displayedMovie.synopsis.equals("") ? "Chargement du synopsis..." : Html
				.fromHtml(displayedMovie.synopsis));
		if (getActivity() != null) {
			getActivity().setTitle(displayedMovie.title);
		} else {
			titleToSet = true;
		}
	}

	private class LoadMovieTask extends AsyncTask<String, Void, Movie> {
		@Override
		protected Movie doInBackground(String... queries) {
			return (new APIHelper(DetailsFragment.this)).findMovie(displayedMovie);
		}

		@Override
		protected void onPostExecute(Movie resultsList) {
			displayedMovie = resultsList;
			updateUI();
		}
	}

	@Override
	public void onLoadOver(ArrayList<Movie> movies) {
		// TODO Auto-generated method stub
	}

	@Override
	public void finish() {
		if (getActivity() != null) {
			getActivity().finish();
		} else {
			toFinish = true;
		}
	}

	@Override
	public void setArguments(Bundle args) {
		super.setArguments(args);
		if (getArguments().containsKey(ARG_ITEM_ID)) {
			idItem = getArguments().getInt(ARG_ITEM_ID);
			displayedMovie = MoviesFragment.getMovies().get(idItem);
		}
		if (getArguments().containsKey(ARG_THEATER_NAME)) {
			theater = getArguments().getString(ARG_THEATER_NAME);
		}
		if (displayedMovie.synopsis.equalsIgnoreCase("") && mTask == null) {
			mTask = new LoadMovieTask();
			mTask.execute(displayedMovie.code);
		}
	}
}
