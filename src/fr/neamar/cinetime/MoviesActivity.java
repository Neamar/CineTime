package fr.neamar.cinetime;

import android.annotation.TargetApi;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import fr.neamar.cinetime.fragments.DetailsEmptyFragment;
import fr.neamar.cinetime.fragments.DetailsFragment;
import fr.neamar.cinetime.fragments.MoviesFragment;

public class MoviesActivity extends FragmentActivity implements
		MoviesFragment.Callbacks {

	private boolean mTwoPane;
	private MoviesFragment moviesFragment;
	private DetailsFragment detailsFragment;
	private String theater;
	private MenuItem shareItem;

	@TargetApi(14)
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_movies_list);
		mTwoPane = getResources().getBoolean(R.bool.mTwoPane);
		theater = getIntent().getStringExtra("theater");
		setTitle("Séances " + getIntent().getStringExtra("theater"));
		if(detailsFragment == null){
			getSupportFragmentManager()
			.beginTransaction()
			.replace(R.id.file_detail_container,
					new DetailsEmptyFragment()).commit();
		}else {
			getSupportFragmentManager().beginTransaction()
			.replace(R.id.file_detail_container, detailsFragment).commit();
		}
		// Title in action bar brings back one level
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		if (mTwoPane) {
			inflater.inflate(R.menu.activity_details, menu);
			shareItem = menu.findItem(R.id.menu_share);
			shareItem.setEnabled(false);
			return true;
		}
		return false;
	}

	@Override
	protected void onResume() {
		super.onResume();
		if (shareItem != null) {
			if (detailsFragment == null) {
				getSupportFragmentManager()
				.beginTransaction()
				.replace(R.id.file_detail_container,
						new DetailsEmptyFragment()).commit();
				shareItem.setEnabled(false);
			} else {
				shareItem.setEnabled(true);
			}
		}
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
	public void setFragment(Fragment fragment) {
		if (fragment instanceof MoviesFragment) {
			this.moviesFragment = (MoviesFragment) fragment;
		} else if (fragment instanceof DetailsFragment) {
			this.detailsFragment = (DetailsFragment) fragment;
			if(shareItem != null){
				shareItem.setEnabled(true);
			}
		}
	}

	@Override
	public void onBackPressed() {
		if (detailsFragment != null) {
			getSupportFragmentManager()
					.beginTransaction()
					.replace(R.id.file_detail_container,
							new DetailsEmptyFragment()).commit();
			detailsFragment = null;
			shareItem.setEnabled(false);
			setTitle("Séances " + getIntent().getStringExtra("theater"));
		} else {
			moviesFragment.clear();
			super.onBackPressed();
		}
	}

	@Override
	public void onItemSelected(int position) {
		if (mTwoPane) {
			Bundle arguments = new Bundle();
			arguments.putInt(DetailsFragment.ARG_ITEM_ID, position);
			arguments.putString(DetailsFragment.ARG_THEATER_NAME, theater);
			detailsFragment = new DetailsFragment();
			detailsFragment.setArguments(arguments);
			getSupportFragmentManager().beginTransaction()
					.replace(R.id.file_detail_container, detailsFragment).commit();
		} else {
			Intent details = new Intent(this, DetailsActivity.class);
			details.putExtra(DetailsFragment.ARG_ITEM_ID, position);
			details.putExtra(DetailsFragment.ARG_THEATER_NAME, theater);
			startActivity(details);
		}
	}

}
