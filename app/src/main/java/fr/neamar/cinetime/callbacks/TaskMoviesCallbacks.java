package fr.neamar.cinetime.callbacks;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Movie;

public interface TaskMoviesCallbacks {

    void updateListView(ArrayList<Movie> movies);

    void finishNoNetwork();
}
