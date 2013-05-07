package fr.neamar.cinetime;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.Window;
import android.widget.Toast;

import com.google.analytics.tracking.android.EasyTracker;

import fr.neamar.cinetime.fragments.DetailsFragment;
import fr.neamar.cinetime.fragments.MoviesFragment;

public class DetailsActivity extends FragmentActivity implements
		MoviesFragment.Callbacks {

	DetailsFragment detailsFragment;
    private MenuItem trailerItem;

	@SuppressLint("NewApi")
	@Override
	public void onCreate(Bundle savedInstanceState) {
		requestWindowFeature(Window.FEATURE_INDETERMINATE_PROGRESS);
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_details);
		// Title in action bar brings back one level
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
		if (savedInstanceState == null) {
			Bundle arguments = new Bundle();
			// FileCodeMirrorFragment fragment = new FileCodeMirrorFragment();
			DetailsFragment fragment = new DetailsFragment();
			arguments.putInt(DetailsFragment.ARG_ITEM_ID, getIntent()
					.getIntExtra(DetailsFragment.ARG_ITEM_ID, -1));
			arguments.putString(DetailsFragment.ARG_THEATER_NAME, getIntent()
					.getStringExtra(DetailsFragment.ARG_THEATER_NAME));
			fragment.setArguments(arguments);
			getSupportFragmentManager().beginTransaction()
					.add(R.id.file_detail_container, fragment).commit();
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.activity_details, menu);
        trailerItem = menu.findItem(R.id.menu_play);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case android.R.id.home:
			finish();
			return true;
		case R.id.menu_share:
			detailsFragment.shareMovie();
			return true;
		case R.id.menu_play:
			detailsFragment.displayTrailer();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}



	@Override
	public void onItemSelected(int position, Fragment source) {
		if (source instanceof DetailsFragment) {
			startActivity(new Intent(this, PosterViewerActivity.class));
		}
	}

	@Override
	public void setFragment(Fragment fragment) {
		detailsFragment = (DetailsFragment) fragment;
        if(DetailsFragment.displayedMovie.trailerCode.isEmpty() && trailerItem != null){
            trailerItem.setEnabled(false);
            trailerItem.setVisible(false);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                invalidateOptionsMenu();
            }
        }
	}

	@Override
	public void setIsLoading(Boolean isLoading) {
		setProgressBarIndeterminateVisibility(isLoading);
	}

	@Override
	public void finishNoNetwork() {
		Toast.makeText(
				this,
				getString(R.string.no_network),
				Toast.LENGTH_SHORT).show();
		finish();
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
