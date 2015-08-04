package fr.neamar.cinetime.callbacks;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Movie;

public interface TaskMoviesCallbacks {

    public void updateListView(ArrayList<Movie> movies);

    public void finishNoNetwork();
}
