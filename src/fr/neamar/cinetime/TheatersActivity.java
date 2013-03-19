package fr.neamar.cinetime;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
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
			title = getResources().getString(R.string.title_activity_theaters);
		}
		setTitle(title);
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
			Toast.makeText(this, "Installez Google Maps pour afficher le plan !",
					Toast.LENGTH_SHORT).show();
		}
	}

	@Override
	public void finishNoNetwork() {
		Toast.makeText(
				this,
				"Impossible de télécharger les données. Merci de vérifier votre connexion ou de réessayer dans quelques minutes.",
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
