package fr.neamar.cinetime.callbacks;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Theater;

public interface TaskTheaterCallbacks {

	public void finishNoNetwork();

	void onLoadOver(ArrayList<Theater> theaters, boolean isFavorite, boolean isGeoSearch);
}
