package fr.neamar.cinetime;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.Toast;

import com.google.analytics.tracking.android.EasyTracker;

import fr.neamar.cinetime.fragments.TheatersFragment;

public class TheatersActivity extends FragmentActivity implements TheatersFragment.Callbacks {

	TheatersFragment theatersFragment;
	static String title = "";

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_theaters_list);
		if (title.equalsIgnoreCase("")) {
			title = getString(R.string.title_activity_theaters);
		}
		setTitle(title);
	}

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.activity_theater, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Click on title in actionbar
        switch (item.getItemId()) {
            case R.id.menu_settings:
                startActivity(new Intent(this, SettingsActivity.class));
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

	@Override
	public void onBackPressed() {
		if (theatersFragment.goBack()) {
			super.onBackPressed();
		}
	}

	@Override
	public void onItemSelected(int position, Fragment source) {
		String code = theatersFragment.getTheaters().get(position).code;

		String title = theatersFragment.getTheaters().get(position).title;

		Intent intent = new Intent(this, MoviesActivity.class);
		intent.putExtra("code", code);
		intent.putExtra("theater", title);
		startActivity(intent);
	}

	@Override
	public void setFragment(Fragment fragment) {
		theatersFragment = (TheatersFragment) fragment;
	}

	@Override
	public void onLongItemSelected(int position, Fragment source) {
		String uri = "geo:0,0?q=" + theatersFragment.getTheaters().get(position).location;

		try {
			startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
		} catch (ActivityNotFoundException e) {
			Toast.makeText(this, getString(R.string.install_maps),
					Toast.LENGTH_SHORT).show();
		}
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

	@Override
	public void updateTitle(String title) {
		TheatersActivity.title = title;
		setTitle(title);
	}
}
