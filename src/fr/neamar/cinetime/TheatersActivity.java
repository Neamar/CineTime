package fr.neamar.cinetime;

import java.util.ArrayList;
import java.util.List;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.ListView;
import android.widget.TextView;

import com.google.analytics.tracking.android.EasyTracker;

import fr.neamar.cinetime.objects.Theater;

public abstract class TheatersActivity extends ListActivity {
	private ProgressDialog dialog;
	protected Boolean hasRestoredFromNonConfigurationInstance = false;

	@SuppressWarnings({ "deprecation", "unchecked" })
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		setContentView(R.layout.activity_theaters);
		setTitle(R.string.title_activity_theaters);

		ArrayList<Theater> theaters = (ArrayList<Theater>) getLastNonConfigurationInstance();
		if (theaters != null) {
			setListAdapter(new TheaterAdapter(this, R.layout.listitem_theater, theaters));
			hasRestoredFromNonConfigurationInstance = true;
		}
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.activity_theaters, menu);
		menu.findItem(R.id.menu_search_geo).setVisible(hasLocationSupport());
		menu.findItem(R.id.menu_unified).setEnabled(getTheaters().size() > 1);

		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case R.id.menu_search:
			onSearchRequested();
			return true;
		case R.id.menu_search_geo:
			Intent geoIntent = new Intent(this, TheatersSearchGeoActivity.class);
			geoIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
			startActivity(geoIntent);
			return true;
		case R.id.menu_unified:
			ArrayList<Theater> theaters = getTheaters();
			List<Theater> unified = theaters.subList(0, Math.min(7, theaters.size()));

			ArrayList<String> codes = new ArrayList<String>();
			for (Theater t : unified) {
				codes.add(t.code);
			}

			int c = 0x2460 + unified.size() - 1;
			String count = Character.toString((char) c) + " ";

			Intent unifiedIntent = new Intent(TheatersActivity.this, MoviesActivity.class);
			unifiedIntent.putExtra("code", TextUtils.join(",", codes));
			unifiedIntent.putExtra("theater", count + TextUtils.join(", ", unified));
			startActivity(unifiedIntent);
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	@Override
	protected void onListItemClick(ListView l, View v, int position, long id) {
		Theater theater = getTheaters().get(position);

		Intent intent = new Intent(this, MoviesActivity.class);
		intent.putExtra("code", theater.code);
		intent.putExtra("theater", theater.title);
		startActivity(intent);
	}

	@Override
	public Object onRetainNonConfigurationInstance() {
		if(getListAdapter() != null) {
			return null;
		}
		else {
			return ((TheaterAdapter) getListAdapter()).theaters;
		}
	}

	@Override
	protected void onStart() {
		super.onStart();
		EasyTracker.getInstance().activityStart(this);
	}

	@Override
	protected void onPause() {
		super.onPause();
		// Remove dialog when leaving activity
		dialog = null;
	}
	@Override
	protected void onStop() {
		super.onStop();
		EasyTracker.getInstance().activityStop(this);
	}

	@TargetApi(Build.VERSION_CODES.HONEYCOMB)
	protected void setTheaters(ArrayList<Theater> theaters) {
		setListAdapter(new TheaterAdapter(TheatersActivity.this, R.layout.listitem_theater, theaters));

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
			invalidateOptionsMenu();
		}
	}

	protected ArrayList<Theater> getTheaters() {
		TheaterAdapter adapter = ((TheaterAdapter) getListAdapter());

		if (adapter != null) {
			return adapter.theaters;
		} else {
			return new ArrayList<Theater>();
		}
	}

	protected abstract ArrayList<Theater> retrieveResults(String... queries);

	@SuppressLint("InlinedApi")
	protected boolean hasLocationSupport() {
		PackageManager pm = getPackageManager();
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
			return pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_NETWORK);
		}
		return false;
	}

	protected class LoadTheatersTask extends AsyncTask<String, Void, ArrayList<Theater>> {
		public LoadTheatersTask() {
			super();
		}

		@Override
		protected void onPreExecute() {
			if (dialog != null && dialog.isShowing()) {
				dialog.dismiss();
			}
			dialog = new ProgressDialog(TheatersActivity.this);
			dialog.setMessage("Recherche en cours...");
			dialog.show();
		}

		@Override
		protected ArrayList<Theater> doInBackground(String... queries) {
			return retrieveResults(queries);
		}

		@Override
		protected void onPostExecute(ArrayList<Theater> theaters) {
			if (dialog != null && dialog.isShowing()) {
				dialog.dismiss();
			}

			if (theaters != null) {
				setTheaters(theaters);
			} else {
				((TextView) findViewById(android.R.id.empty)).setText("Aucune connexion Internet :\\");
			}
		}
	}
}
