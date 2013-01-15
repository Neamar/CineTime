package fr.neamar.cinetime;

import fr.neamar.cinetime.objects.Movie;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class DetailsActivity extends Activity {
	protected Movie displayedMovie = new Movie();
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_details);
		
		//Build movie using current informations
		displayedMovie.code = getIntent().getStringExtra("code");
		displayedMovie.title = getIntent().getStringExtra("title");
		displayedMovie.poster = getIntent().getStringExtra("poster");
		displayedMovie.duration = getIntent().getIntExtra("duration", 0);
		displayedMovie.pressRating = getIntent().getStringExtra("pressRating");
		displayedMovie.userRating = getIntent().getStringExtra("userRating");
		displayedMovie.display = getIntent().getStringExtra("display");
		
		updateUI();
	}
	
	public void updateUI()
	{
		TextView title = ((TextView) findViewById(R.id.details_title));
		title.setText(displayedMovie.title);
		
		TextView display = ((TextView) findViewById(R.id.details_display));
		display.setText(displayedMovie.display);
	}
}
