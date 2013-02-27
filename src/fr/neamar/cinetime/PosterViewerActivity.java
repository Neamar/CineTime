package fr.neamar.cinetime;

import com.google.analytics.tracking.android.EasyTracker;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import fr.neamar.cinetime.fragments.DetailsFragment;
import fr.neamar.cinetime.ui.ImageLoader;

public class PosterViewerActivity extends Activity{

	private ImageView poster;
	public ImageLoader imageLoader;
	public static String POSTER_LOADED = "fr.neamar.cinetime.POSTER_LOADED";
	
	@SuppressLint("NewApi")
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.poster_viewer);
		imageLoader = CineTimeApplication.getImageLoader(this);
		poster = (ImageView) findViewById(R.id.posterView);
		findViewById(R.id.spinner).setVisibility(View.VISIBLE);
		setTitle(DetailsFragment.displayedMovie.title);
		BroadcastReceiver receiver = new BroadcastReceiver(){
			@Override
			public void onReceive(Context context, Intent intent) {
				findViewById(R.id.spinner).setVisibility(View.INVISIBLE);
				try{
					unregisterReceiver(this);
				}catch(IllegalArgumentException e){
					//Nothing
				}
			}
			
		};
		registerReceiver(receiver, new IntentFilter(POSTER_LOADED));
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
			getActionBar().hide();
		}
		if(DetailsFragment.displayedMovie.poster != null){
			imageLoader.DisplayImage(DetailsFragment.displayedMovie.poster, poster, 3);
		}
	}
	
	@Override
	protected void onStart() {
		super.onStart();
		EasyTracker.getInstance().activityStart(this);
	}

	@Override
	protected void onStop() {
		super.onStop();
		EasyTracker.getInstance().activityStop(this);
	}
	
}
