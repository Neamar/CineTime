package fr.neamar.cinetime.fragments;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.ProgressDialog;
import android.app.backup.BackupManager;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.Html;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.*;

import java.util.ArrayList;

import fr.neamar.cinetime.R;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.callbacks.TaskMoviesCallbacks;
import fr.neamar.cinetime.fragments.MoviesFragment.Callbacks;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.ui.ImageLoader;

public class DetailsFragment extends Fragment implements TaskMoviesCallbacks {

	public static final String ARG_ITEM_ID = "item_id";
	public static final String ARG_THEATER_NAME = "theater_name";
	static public Movie displayedMovie;

	private Callbacks mCallbacks = sDummyCallbacks;

	private int idItem;
	private TextView title;
	private TextView extra;
	private TextView display;
	private ImageView poster;
	private TextView certificate;
	private TextView synopsis;
	private ProgressBar pressRating;
	private TextView pressRatingText;
	private TableRow pressRatingRow;
	private ProgressBar userRating;
	private TextView userRatingText;
	private TableRow userRatingRow;
	public ImageLoader imageLoader;
	protected String theater = "";
	private LoadMovieTask mTask;
	private boolean titleToSet = false;
	private static boolean toFinish = false;
	private ProgressDialog dialog = null;

	public DetailsFragment() {
	}

	private static Callbacks sDummyCallbacks = new Callbacks() {
		@Override
		public void onItemSelected(int position, Fragment source) {

		}

		@Override
		public void setFragment(Fragment fragment) {
		}

		@Override
		public void setIsLoading(Boolean isLoading) {
		}

		@Override
		public void finishNoNetwork() {
			toFinish = true;
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
		if (displayedMovie != null
				&& displayedMovie.synopsis.equalsIgnoreCase("")
				&& mTask == null) {
			mTask = new LoadMovieTask(this);
			mTask.execute(displayedMovie.code);
		}
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.fragment_details, container,
				false);
		title = (TextView) view.findViewById(R.id.details_title);
		extra = (TextView) view.findViewById(R.id.details_extra);
		display = (TextView) view.findViewById(R.id.details_display);
		poster = (ImageView) view.findViewById(R.id.details_poster);
		pressRating = (ProgressBar) view.findViewById(R.id.details_pressrating);
		pressRatingText = (TextView) view
				.findViewById(R.id.details_pressrating_text);
		pressRatingRow = (TableRow) view
				.findViewById(R.id.details_pressrating_row);
		userRating = (ProgressBar) view.findViewById(R.id.details_userrating);
		userRatingText = (TextView) view
				.findViewById(R.id.details_userrating_text);
		userRatingRow = (TableRow) view
				.findViewById(R.id.details_userrating_row);
		synopsis = (TextView) view.findViewById(R.id.details_synopsis);
		certificate = (TextView) view.findViewById(R.id.details_certificate);
		if (displayedMovie != null) {
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
			throw new IllegalStateException(
					"Activity must implement fragment's callbacks.");
		}
		imageLoader = ImageLoader.getInstance(getActivity());
		mCallbacks = (Callbacks) activity;
		mCallbacks.setFragment(this);
		if (titleToSet) {
			getActivity().setTitle(displayedMovie.title);
			titleToSet = false;
		}
		if (toFinish) {
			mCallbacks.finishNoNetwork();
			toFinish = false;
		}
	}

	public void shareMovie() {
		Intent sharingIntent = new Intent(android.content.Intent.ACTION_SEND);
		sharingIntent.setType("text/plain");
		sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT,
				displayedMovie.getSharingText(getActivity(), theater));

		startActivity(Intent.createChooser(sharingIntent,
				getString(R.string.share_movie)));
	}

	public void displayTrailer() {
		class RetrieveTrailerTask extends AsyncTask<Movie, Void, String> {
			protected String doInBackground(Movie... movies) {
				return new APIHelper(getActivity())
						.downloadTrailerUrl(movies[0]);
			}

			protected void onPostExecute(String trailerUrl) {

				// Dismiss dialog
				if (dialog != null) {
					try {
						dialog.dismiss();
					} catch (Exception e) {

					}
				}

				if (trailerUrl == null) {
					Toast.makeText(getActivity(),
							getString(R.string.trailer_unavailable),
							Toast.LENGTH_SHORT).show();
				} else {
					try {
						Intent intent = new Intent(Intent.ACTION_VIEW);
						intent.setDataAndType(Uri.parse(trailerUrl),
								"video/mp4");
						startActivity(intent);
					} catch (ActivityNotFoundException e) {
						Toast.makeText(
								getActivity(),
								getString(R.string.no_player),
								Toast.LENGTH_SHORT).show();
					}
				}
			}
		}

		new RetrieveTrailerTask().execute(DetailsFragment.displayedMovie);
		dialog = new ProgressDialog(getActivity());
		dialog.setMessage(getString(R.string.loading_trailer));
		dialog.show();
	}

	public void updateUI() {
		title.setText(displayedMovie.title);

		String extraString = "";
		extraString += "<strong>" + getString(R.string.length) + "</strong> : "
				+ displayedMovie.getDuration() + "<br />";

		if (!displayedMovie.directors.equals(""))
			extraString += "<strong>" + getString(R.string.director)
					+ "</strong> : " + displayedMovie.directors + "<br />";
		if (!displayedMovie.actors.equals(""))
			extraString += "<strong>" + getString(R.string.actors)
					+ "</strong> : " + displayedMovie.actors + "<br />";
		extraString += "<strong>" + getString(R.string.genre) + "</strong> : "
				+ displayedMovie.genres;
		extra.setText(Html.fromHtml(extraString));
		display.setText(Html.fromHtml("<strong>" + theater + "</strong>"
				+ displayedMovie.getDisplayDetails() + "<br>"
				+ displayedMovie.getDisplay(getActivity())));
		if (displayedMovie.certificateString.equals(""))
			certificate.setVisibility(View.GONE);
		else
			certificate.setText(displayedMovie.certificateString);
		imageLoader.DisplayImage(displayedMovie.poster, poster, 2);
		poster.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				mCallbacks.onItemSelected(-1, DetailsFragment.this);
			}
		});

		pressRating.setProgress(displayedMovie.getPressRating());
		if (displayedMovie.pressRating.equals("0"))
			pressRatingText.setText("");
		else if (displayedMovie.pressRating.length() > 3)
			pressRatingText.setText(displayedMovie.pressRating.substring(0, 3));
		else
			pressRatingText.setText(displayedMovie.pressRating);

		userRating.setProgress(displayedMovie.getUserRating());
		if (displayedMovie.userRating.equals("0"))
			userRatingText.setText("");
		else if (displayedMovie.userRating.length() > 3)
			userRatingText.setText(displayedMovie.userRating.substring(0, 3));
		else
			userRatingText.setText(displayedMovie.userRating);

		synopsis.setText(displayedMovie.synopsis.equals("") ? getString(R.string.loading_synopsis)
				: Html.fromHtml(displayedMovie.synopsis));
		if (getActivity() != null) {
			getActivity().setTitle(displayedMovie.title);
		} else {
			titleToSet = true;
		}
	}

	private class LoadMovieTask extends AsyncTask<String, Void, Movie> {
		private SharedPreferences preferences;
		private Context ctx;

		public LoadMovieTask(DetailsFragment fragment) {
			super();
			this.ctx = fragment.getActivity();
			this.preferences = ctx.getSharedPreferences("synopsis",
					Context.MODE_PRIVATE);
			mCallbacks.setIsLoading(true);
		}

		@Override
		@SuppressLint("NewApi")
		protected Movie doInBackground(String... queries) {
			// Try to read synopsis from cache
			String movieCode = displayedMovie.code;
			String cache = preferences.getString(movieCode, "");
			if (!cache.equals("")) {
				Log.i("cache-hit", "Getting synopsis from cache for "
						+ movieCode);
				displayedMovie.synopsis = cache;
			} else {
				Log.i("cache-miss", "Remote loading synopsis for " + movieCode);
				displayedMovie = (new APIHelper(getActivity()))
						.findMovie(displayedMovie);
				String synopsis = displayedMovie.synopsis;
				SharedPreferences.Editor ed = preferences.edit();
				ed.putString(movieCode, synopsis);
				ed.commit();
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
					new BackupManager(ctx).dataChanged();
				}
			}

			return displayedMovie;
		}

		@Override
		protected void onPostExecute(Movie resultsList) {
			mCallbacks.setIsLoading(false);
			displayedMovie = resultsList;
			updateUI();
		}
	}

	@Override
	public void updateListView(ArrayList<Movie> movies) {
		// TODO Auto-generated method stub
	}

	@Override
	public void finishNoNetwork() {
		mCallbacks.finishNoNetwork();
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
	}
}
