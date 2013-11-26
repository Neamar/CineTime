package fr.neamar.cinetime;

import java.util.ArrayList;

import android.annotation.SuppressLint;
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
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;

import com.google.analytics.tracking.android.EasyTracker;

import fr.neamar.cinetime.objects.Theater;

public abstract class TheatersActivity extends ListActivity {
	private ProgressDialog dialog;
	protected Boolean hasRestoredFromNonConfigurationInstance = false;

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

		Button unified = (Button) findViewById(R.id.unified);
		unified.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				ArrayList<Theater> theaters = ((TheaterAdapter) getListAdapter()).theaters;
				
				ArrayList<String> codes = new ArrayList<String>();
				for (Theater t : theaters)
				{
					codes.add(t.code);
				}
				
				Intent intent = new Intent(TheatersActivity.this, MoviesActivity.class);
				intent.putExtra("code", TextUtils.join(",", codes));
				intent.putExtra("theater", TextUtils.join(", ", theaters));
				startActivity(intent);
			}
		});
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.activity_theaters, menu);
		menu.findItem(R.id.menu_search_geo).setVisible(hasLocationSupport());
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case R.id.menu_search:
			onSearchRequested();
			return true;
		case R.id.menu_search_geo:
			Intent intent = new Intent(this, TheatersSearchGeoActivity.class);
			startActivity(intent);
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	protected void onListItemClick(ListView l, View v, int position, long id) {
		Theater theater = ((TheaterAdapter) getListAdapter()).theaters.get(position);

		Intent intent = new Intent(this, MoviesActivity.class);
		intent.putExtra("code", theater.code);
		intent.putExtra("theater", theater.title);
		startActivity(intent);
	}

	@Override
	public Object onRetainNonConfigurationInstance() {
		return ((TheaterAdapter) getListAdapter()).theaters;
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

	protected void setTheaters(ArrayList<Theater> theaters) {
		setListAdapter(new TheaterAdapter(TheatersActivity.this, R.layout.listitem_theater, theaters));
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
