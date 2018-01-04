package fr.neamar.cinetime.adapters;

import android.content.Context;
import android.text.Html;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.RatingBar;
import android.widget.TextView;

import java.util.ArrayList;

import fr.neamar.cinetime.R;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.ui.ImageLoader;

public class MovieAdapter extends ArrayAdapter<Movie> {

    private ImageLoader imageLoader;
    /**
     * Array list containing all the movies currently displayed
     */
    private ArrayList<Movie> movies = new ArrayList<Movie>();
    private Context context;

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
            LayoutInflater vi = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            v = vi.inflate(R.layout.listitem_movie, null);
        }

        Movie movie = movies.get(position);

        TextView movieTitle = v.findViewById(R.id.listitem_movie_title);
        TextView movieExtra = v.findViewById(R.id.listitem_movie_extra);
        RatingBar movieRating = v.findViewById(R.id.listitem_movie_rating);
        TextView movieDisplay = v.findViewById(R.id.listitem_movie_display);
        ImageView moviePoster = v.findViewById(R.id.listitem_movie_poster);

        movieTitle.setText(movie.title);

        String description = movie.getDuration();
        description += movie.getDisplayDetails();

        int rating = movie.getRating();
        if (rating > 0) {
            movieRating.setVisibility(View.VISIBLE);
            movieRating.setProgress(movie.getRating());
        } else {
            movieRating.setVisibility(View.INVISIBLE);
        }

        if (movie.displays.size() == 1 && movie.displays.get(0).theater == null) {
            // Optimize layout when only one display available
            description += movie.displays.get(0).getDisplayDetails();
            movieDisplay.setText(Html.fromHtml(movie.displays.get(0).getDisplay()));
        } else {
            movieDisplay.setText(Html.fromHtml(movie.getDisplays()));
        }

        movieExtra.setText(Html.fromHtml(description));
        imageLoader.DisplayImage(movie.poster, moviePoster, 1);

        return v;
    }

    @Override
    public void clear() {
        movies.clear();
        notifyDataSetChanged();
    }
}
