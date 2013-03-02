package fr.neamar.cinetime;

import android.content.Context;
import fr.neamar.cinetime.ui.ImageLoader;

public class CineTimeApplication {
	static protected ImageLoader imageLoader;

	public static ImageLoader getImageLoader(Context ctx) {
		if (imageLoader == null) {
			imageLoader = new ImageLoader(ctx);
		}
		return imageLoader;
	}

}
