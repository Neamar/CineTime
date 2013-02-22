package fr.neamar.cinetime.callbacks;

import java.util.ArrayList;

import fr.neamar.cinetime.objects.Theater;

public interface TaskTheaterCallbacks {

	public void onLoadOver(ArrayList<Theater> theaters);

	public void finish();
}
