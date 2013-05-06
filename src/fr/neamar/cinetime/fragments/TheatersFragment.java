package fr.neamar.cinetime.fragments;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.v4.app.Fragment;
import android.support.v4.app.ListFragment;
import android.text.format.Time;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.*;
import android.widget.AdapterView.OnItemLongClickListener;

import java.io.IOException;
import java.util.ArrayList;

import org.apache.http.client.ClientProtocolException;

import fr.neamar.cinetime.R;
import fr.neamar.cinetime.TheaterAdapter;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.callbacks.TaskTheaterCallbacks;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersFragment extends ListFragment implements TaskTheaterCallbacks {

	private static final String STATE_ACTIVATED_POSITION = "activated_position";

	private Callbacks mCallbacks = sDummyCallbacks;
	private int mActivatedPosition = ListView.INVALID_POSITION;
	private static boolean toFinish = false;
	private boolean dialogPending = false;
	private ProgressDialog dialog;
	public EditText searchText;
	public ImageButton searchButton;
	static private Context ctx;
	static private String query = "";
	static private String previousQuery = "";
	static private String lat = "";
	static private String lon = "";
	static private String parentTitle = "";

	public interface Callbacks {

		public void onItemSelected(int position, Fragment source);

		public void onLongItemSelected(int position, Fragment source);

		public void setFragment(Fragment fragment);

		public void finishNoNetwork();

		public void updateTitle(String title);
	}

	private static Callbacks sDummyCallbacks = new Callbacks() {
		@Override
		public void onItemSelected(int position, Fragment source) {
		}

		@Override
		public void setFragment(Fragment fragment) {
		}

		@Override
		public void onLongItemSelected(int position, Fragment source) {
		}

		@Override
		public void finishNoNetwork() {
			toFinish = true;
		}

		@Override
		public void updateTitle(String title) {
			parentTitle = title;
		}
	};

	@Override
	public void onResume() {
		super.onResume();
		getListView().setLongClickable(true);
		getListView().setOnItemLongClickListener(new OnItemLongClickListener() {

			public boolean onItemLongClick(AdapterView<?> parent, View view, int position, long id) {
				mCallbacks.onLongItemSelected(position, TheatersFragment.this);
				return true;
			}
		});
		if (lat.equalsIgnoreCase("") || lon.equalsIgnoreCase("")) {
			searchText.setText(query);
			// Display favorites :
			searchButton.performClick();
		}
	}

	@Override
	public void onPause() {
		query = searchText.getText().toString().trim();
		super.onPause();
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		if (savedInstanceState != null && savedInstanceState.containsKey(STATE_ACTIVATED_POSITION)) {
			setActivatedPosition(savedInstanceState.getInt(STATE_ACTIVATED_POSITION));
		}
		View root = inflater.inflate(R.layout.fragment_theaters, container, false);

		searchText = (EditText) root.findViewById(R.id.theaters_search);
		searchButton = (ImageButton) root.findViewById(R.id.theaters_search_button);

		searchButton.setOnClickListener(new View.OnClickListener() {

			@Override
			public void onClick(View v) {
				lat = "";
				lon = "";
				query = searchText.getText().toString().trim();
				if (!query.equalsIgnoreCase("")) {
					searchForTheater(query);
				} else {
					onLoadOver(DBHelper.getFavorites(ctx), true, false);
				}
			}
		});
		if (hasLocationSupport()) {
			root.findViewById(R.id.theaters_search_geo_button).setOnClickListener(
					new OnClickListener() {

						@Override
						public void onClick(View v) {
							final LocationManager locationManager = (LocationManager) ctx
									.getSystemService(Context.LOCATION_SERVICE);
							final boolean locationEnable = locationManager
									.isProviderEnabled(LocationManager.NETWORK_PROVIDER);

							if (!locationEnable) {
								AlertDialog.Builder builder = new AlertDialog.Builder(ctx);
								builder.setMessage(getString(R.string.location_dialog_mess))
										.setCancelable(true)
										.setPositiveButton(
												getString(R.string.location_dialog_ok),
												new DialogInterface.OnClickListener() {
													public void onClick(DialogInterface dialog,
															int id) {
														dialog.cancel();
														Intent settingsIntent = new Intent(
																Settings.ACTION_LOCATION_SOURCE_SETTINGS);
														startActivity(settingsIntent);
													}
												})
										.setNegativeButton(
												getString(R.string.location_dialog_cancel),
												new DialogInterface.OnClickListener() {
													public void onClick(DialogInterface dialog,
															int id) {
														dialog.cancel();
													}
												});
								builder.create().show();
							} else {
								query = "";
								previousQuery = "";
								searchText.setText("");
								Location oldLocation = locationManager
										.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
								Time t = new Time();
								t.setToNow();
								if (oldLocation == null
										|| ((oldLocation.getTime() - t.toMillis(true)) > 300000)) {
									LocationListener listener = new LocationListener() {

										@Override
										public void onLocationChanged(Location location) {
											if (location.getAccuracy() < 1000) {
												new LoadTheatersTask(ctx).execute(
														String.valueOf(location.getLatitude()),
														String.valueOf(location.getLongitude()));
												locationManager.removeUpdates(this);
											}
										}

										@Override
										public void onProviderDisabled(String provider) {
										}

										@Override
										public void onProviderEnabled(String provider) {
										}

										@Override
										public void onStatusChanged(String provider, int status,
												Bundle extras) {
										}
									};
									locationManager.requestLocationUpdates(
											LocationManager.NETWORK_PROVIDER, 1000, 10, listener);
								} else {
									new LoadTheatersTask(ctx).execute(
											String.valueOf(oldLocation.getLatitude()),
											String.valueOf(oldLocation.getLongitude()));
								}
							}
						}
					});
		} else {
			root.findViewById(R.id.theaters_search_geo_button).setVisibility(View.GONE);
		}

		// When searching from keyboard
		searchText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
			@Override
			public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
				InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(
						Context.INPUT_METHOD_SERVICE);
				imm.hideSoftInputFromWindow(searchText.getWindowToken(), 0);
				return searchButton.performClick();
			}

		});
		return root;
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		this.setRetainInstance(true);
	}

	public ArrayList<Theater> getTheaters() {
		return ((TheaterAdapter) getListView().getAdapter()).theaters;
	}

	@Override
	public void onAttach(Activity activity) {
		super.onAttach(activity);
		if (!(activity instanceof Callbacks)) {
			throw new IllegalStateException("Activity must implement fragment's callbacks.");
		}
		mCallbacks = (Callbacks) activity;
		mCallbacks.setFragment(this);
		ctx = activity;
		if (toFinish) {
			mCallbacks.finishNoNetwork();
			toFinish = false;
		}
		if (dialogPending) {
			dialog = new ProgressDialog(activity);
			dialog.setMessage(getString(R.string.searching));
			dialog.show();
		}
		if (!parentTitle.equalsIgnoreCase("")) {
			mCallbacks.updateTitle(parentTitle);
		}
	}

	@Override
	public void onDetach() {
		super.onDetach();
		if (dialog != null) {
			dialog.dismiss();
			dialog = null;
		}
		mCallbacks = sDummyCallbacks;
	}

	private void searchForTheater(String query) {
		if (!previousQuery.equalsIgnoreCase(query)) {
			previousQuery = query;
			new LoadTheatersTask(ctx).execute(query);
		}
	}

	@Override
	public void onListItemClick(ListView listView, View view, int position, long id) {
		super.onListItemClick(listView, view, position, id);
		mCallbacks.onItemSelected(position, this);
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		if (mActivatedPosition != ListView.INVALID_POSITION) {
			outState.putInt(STATE_ACTIVATED_POSITION, mActivatedPosition);
		}
	}

	public void setActivateOnItemClick(boolean activateOnItemClick) {
		getListView().setChoiceMode(
				activateOnItemClick ? ListView.CHOICE_MODE_SINGLE : ListView.CHOICE_MODE_NONE);
	}

	public void setActivatedPosition(int position) {
		if (position == ListView.INVALID_POSITION) {
			getListView().setItemChecked(mActivatedPosition, false);
		} else {
			getListView().setItemChecked(position, true);
		}
		mActivatedPosition = position;
	}

	public boolean goBack() {
		// When pressing back, if a query is entered redisplay favorites.
		// Else perform default back action.
		if (!lat.equalsIgnoreCase("") && !lon.equalsIgnoreCase("")) {
			lat = "";
			lon = "";
			query = "";
			previousQuery = "";
			searchText.setText("");
			searchButton.performClick();
			return false;
		} else if (searchText.getText().toString().equals("")) {
			return true;
		} else {
			query = "";
			previousQuery = "";
			searchText.setText("");
			searchButton.performClick();
			return false;
		}
	}

	@Override
	public void finishNoNetwork() {
		mCallbacks.finishNoNetwork();
	}

	private class LoadTheatersTask extends AsyncTask<String, Void, ArrayList<Theater>> {
		private Boolean isLoadingFavorites = false;
		private Boolean isGeoSearch = false;
		private Context ctx;

		public LoadTheatersTask(Context ctx) {
			super();
			this.ctx = ctx;
		}

		@Override
		protected void onPreExecute() {
			if (dialog != null && dialog.isShowing()) {
				dialog.dismiss();
			}
			dialog = new ProgressDialog(ctx);
			dialogPending = true;
			dialog.setMessage(getString(R.string.searching));
			dialog.show();
		}

		@Override
		protected ArrayList<Theater> doInBackground(String... queries) {
			try {
				if (queries.length == 1) {
					if (queries[0].equals("")) {
						isLoadingFavorites = true;
						return DBHelper.getFavorites(ctx);
					}
					return (new APIHelper(ctx).findTheaters(queries[0]));
				} else if (queries.length == 2) {
					lat = queries[0];
					lon = queries[1];
					isGeoSearch = true;
					return (new APIHelper(ctx).findTheatersGeo(queries[0], queries[1]));
				}
			} catch (ClientProtocolException e) {

			} catch (IOException e) {

			}
			return null;
		}

		@Override
		protected void onPostExecute(ArrayList<Theater> resultsList) {
			if (dialog != null) {
				if (dialog.isShowing())
					dialog.dismiss();
			}
			dialogPending = false;

			if (resultsList != null) {
				if (!isLoadingFavorites) {
					((TextView) getListView().getEmptyView())
							.setText(getString(R.string.no_results));
				}
				TheatersFragment.this.onLoadOver(resultsList, isLoadingFavorites, isGeoSearch);
			} else {
				finishNoNetwork();
			}
		}
	}

	@Override
	public void onLoadOver(ArrayList<Theater> theaters, boolean isFavorite, boolean isGeoSearch) {
		setListAdapter(new TheaterAdapter(ctx, R.layout.listitem_theater, theaters));
		if (theaters.size() > 0) {
			getListView().requestFocus();
		}
		if (isFavorite) {
			mCallbacks.updateTitle(getString(R.string.title_activity_theaters));
		} else if (isGeoSearch) {
			mCallbacks.updateTitle(getString(R.string.title_activity_theaters_geo));
		} else {
			mCallbacks.updateTitle(getString(R.string.title_activity_theaters_search) + query);
		}
	}

	@SuppressLint("InlinedApi")
	private boolean hasLocationSupport() {
		PackageManager pm = getActivity().getPackageManager();
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
			return pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_NETWORK);
		}
		return false;
	}
}
