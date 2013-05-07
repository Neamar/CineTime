package fr.neamar.cinetime;

import android.content.Context;
import android.text.Html;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.ui.ImageLoader;

public class MovieAdapter extends ArrayAdapter<Movie> {

	private Context context;
	public ImageLoader imageLoader;

	/**
	 * Array list containing all the movies currently displayed
	 */
	public ArrayList<Movie> movies = new ArrayList<Movie>();

	@SuppressWarnings("unchecked")
	public MovieAdapter(Context ac, int textViewResourceId, ArrayList<Movie> movies) {
		super(ac, textViewResourceId, movies);
		this.context = ac;
		this.movies = (ArrayList<Movie>) movies.clone();
		imageLoader = ImageLoader.getInstance(getContext());
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

		TextView movieTitle = (TextView) v.findViewById(R.id.listitem_movie_title);
		TextView movieExtra = (TextView) v.findViewById(R.id.listitem_movie_extra);
		ProgressBar movieRating = (ProgressBar) v.findViewById(R.id.listitem_movie_rating);
		TextView movieDisplay = (TextView) v.findViewById(R.id.listitem_movie_display);
		ImageView moviePoster = (ImageView) v.findViewById(R.id.listitem_movie_poster);

		movieTitle.setText(movie.title);

		String description = movie.getDuration();
		description += movie.getDisplayDetails();

		movieExtra.setText(Html.fromHtml(description));

		int rating = movie.getRating();
		if (rating > 0) {
			movieRating.setVisibility(View.VISIBLE);
			movieRating.setProgress(movie.getRating());
		} else {
			movieRating.setVisibility(View.INVISIBLE);
		}

		movieDisplay.setText(Html.fromHtml(movie.getDisplay(context)));

		imageLoader.DisplayImage(movie.poster, moviePoster, 1);

		return v;
	}
	
	public void clear(){
		movies.clear();
		notifyDataSetChanged();
	}
}
