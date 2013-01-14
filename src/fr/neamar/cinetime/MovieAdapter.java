package fr.neamar.cinetime;

import java.util.ArrayList;

import android.app.Activity;
import android.content.Context;
import android.text.Html;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.ui.ImageLoader;

public class MovieAdapter extends ArrayAdapter<Movie> {

	private Context context;
	public ImageLoader imageLoader;

	/**
	 * Array list containing all the movies currently displayed
	 */
	public ArrayList<Movie> movies = new ArrayList<Movie>();

	public MovieAdapter(Activity ac, int textViewResourceId,
			ArrayList<Movie> movies) {
		super(ac, textViewResourceId, movies);

		this.context = ac;
		this.movies = movies;
		imageLoader = new ImageLoader(ac.getApplicationContext());
	}

	@Override
	public int getCount() {
		return movies.size();
	}

	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;

		if (v == null) {
			LayoutInflater vi = (LayoutInflater) context
					.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
			v = vi.inflate(R.layout.listitem_movie, null);
		}

		Movie movie = movies.get(position);

		TextView movieTitle = (TextView) v
				.findViewById(R.id.listitem_movie_title);
		TextView movieExtra = (TextView) v
				.findViewById(R.id.listitem_movie_extra);
		ProgressBar moviePressRating = (ProgressBar) v
				.findViewById(R.id.listitem_movie_pressrating);
		ProgressBar movieUserRating = (ProgressBar) v
				.findViewById(R.id.listitem_movie_userrating);
		TextView movieDisplay = (TextView) v
				.findViewById(R.id.listitem_movie_display);
		ImageView moviePoster = (ImageView) v
				.findViewById(R.id.listitem_movie_poster);

		movieTitle.setText(movie.title);

		String description = movie.getDuration(); 
		description += (movie.isOriginalLanguage ? " <i>VO</i>" : "");
		description += (movie.is3D ? " <strong>3D</strong>" : "");
		
		movieExtra.setText(Html.fromHtml(description));
		moviePressRating
				.setProgress((int) (Float.parseFloat(movie.pressRating) * 10));
		movieUserRating
				.setProgress((int) (Float.parseFloat(movie.userRating) * 10));
		movieDisplay.setText(movie.getDisplay());

		imageLoader.DisplayImage(movie.poster, moviePoster);

		return v;
	}
}
