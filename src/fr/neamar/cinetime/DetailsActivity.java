package fr.neamar.cinetime;

import android.annotation.SuppressLint;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import fr.neamar.cinetime.fragments.DetailsFragment;
import fr.neamar.cinetime.fragments.MoviesFragment;

public class DetailsActivity extends FragmentActivity implements MoviesFragment.Callbacks {

	DetailsFragment detailsFragment;

	@SuppressLint("NewApi")
	@Override
	public void onCreate(Bundle savedInstanceState) {
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
			arguments.putInt(DetailsFragment.ARG_ITEM_ID,
					getIntent().getIntExtra(DetailsFragment.ARG_ITEM_ID, -1));
			arguments.putString(DetailsFragment.ARG_THEATER_NAME,
					getIntent().getStringExtra(DetailsFragment.ARG_THEATER_NAME));
			fragment.setArguments(arguments);
			getSupportFragmentManager().beginTransaction()
					.add(R.id.file_detail_container, fragment).commit();
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.activity_details, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Click on title in actionbar
		switch (item.getItemId()) {
		case android.R.id.home:
			finish();
			return true;
		case R.id.menu_share:
			detailsFragment.shareMovie();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	@Override
	public void onItemSelected(int position) {
		// TODO Auto-generated method stub

	}

	@Override
	public void setFragment(Fragment fragment) {
		detailsFragment = (DetailsFragment) fragment;
	}

}
