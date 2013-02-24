package fr.neamar.cinetime;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.widget.ImageView;
import fr.neamar.cinetime.fragments.DetailsFragment;
import fr.neamar.cinetime.ui.ImageLoader;

public class PosterViewerActivity extends Activity{

	private ImageView poster;
	public ImageLoader imageLoader;
	
	@SuppressLint("NewApi")
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.poster_viewer);
		imageLoader = CineTimeApplication.getImageLoader(this);
		poster = (ImageView) findViewById(R.id.posterView);
		setTitle(DetailsFragment.displayedMovie.title);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
			getActionBar().hide();
		}
		if(DetailsFragment.displayedMovie.poster != null){
			imageLoader.DisplayImage(DetailsFragment.displayedMovie.poster, poster, 3);
		}
	}
	
}
