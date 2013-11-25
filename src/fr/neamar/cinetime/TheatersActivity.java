package fr.neamar.cinetime;

import java.util.ArrayList;

import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.ListView;

import com.google.analytics.tracking.android.EasyTracker;

import fr.neamar.cinetime.objects.Theater;

public class TheatersActivity extends ListActivity {
	private ProgressDialog dialog;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		setContentView(R.layout.activity_theaters);
		setTitle(R.string.title_activity_theaters);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.activity_theaters, menu);
		return true;
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case R.id.menu_search:
			onSearchRequested();
			return true;
		case R.id.menu_search_geo:
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
	protected void onStart() {
		super.onStart();
		EasyTracker.getInstance().activityStart(this);
	}

	@Override
	protected void onStop() {
		super.onStop();
		EasyTracker.getInstance().activityStop(this);
	}
	
	protected ArrayList<Theater> retrieveResults(String... queries) {
		//TODO: abstract
		return null;
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
			
			setListAdapter(new TheaterAdapter(TheatersActivity.this, R.layout.listitem_theater, theaters));
		}
	}
}
