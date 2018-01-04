package fr.neamar.cinetime;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;

import com.nostra13.universalimageloader.core.ImageLoader;

import fr.neamar.cinetime.fragments.DetailsFragment;

public class PosterViewerActivity extends Activity {

    public static String POSTER_LOADED = "fr.neamar.cinetime.POSTER_LOADED";
    public ImageLoader imageLoader;

    @SuppressLint("NewApi")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        setContentView(R.layout.poster_viewer);
        ImageView poster = findViewById(R.id.posterView);
        findViewById(R.id.spinner).setVisibility(View.VISIBLE);

        BroadcastReceiver receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                findViewById(R.id.spinner).setVisibility(View.INVISIBLE);
                try {
                    unregisterReceiver(this);
                } catch (IllegalArgumentException e) {
                    // Nothing
                }
            }

        };
        registerReceiver(receiver, new IntentFilter(POSTER_LOADED));
        ImageLoader.getInstance().displayImage(DetailsFragment.displayedMovie.getPosterUrl(3), poster);
    }
}
