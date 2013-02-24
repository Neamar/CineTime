package fr.neamar.cinetime;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import fr.neamar.cinetime.fragments.TheatersFragment;

public class TheatersActivity extends FragmentActivity implements TheatersFragment.Callbacks{

	TheatersFragment theatersFragment;
	
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_theaters_list);
		setTitle(R.string.title_activity_theaters);
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
		String uri = "geo:0,0?q="
				+ theatersFragment.getTheaters().get(position).location;
		startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
	}
}
