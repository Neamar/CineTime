package fr.neamar.cinetime.callbacks;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Theater;

public interface TaskTheaterCallbacks {

    void finishNoNetwork();

    void onLoadOver(ArrayList<Theater> theaters, boolean isFavorite, boolean isGeoSearch);
}
