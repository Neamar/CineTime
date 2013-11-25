package fr.neamar.cinetime;

import java.io.IOException;
import java.util.ArrayList;

import org.apache.http.client.ClientProtocolException;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.Resources;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.provider.Settings;
import android.text.format.Time;
import android.util.Log;
import android.view.Menu;
import android.widget.TextView;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersSearchGeoActivity extends TheatersActivity {
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		((TextView) findViewById(android.R.id.empty)).setText("Activez le GPS !");

		setTitle("Cinémas à proximité");

		final LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
		final boolean locationEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);

		if (!hasLocationSupport()) {
			return;
		}

		// Check location is enabled
		if (!locationEnabled) {
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			Resources res = getResources();
			builder.setMessage(res.getString(R.string.location_dialog_mess)).setCancelable(true).setPositiveButton(res.getString(R.string.location_dialog_ok), new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialog, int id) {
					dialog.cancel();
					Intent settingsIntent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
					startActivity(settingsIntent);
				}
			}).setNegativeButton(res.getString(R.string.location_dialog_cancel), new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialog, int id) {
					dialog.cancel();
				}
			});
			builder.create().show();
			return;
		}

		Location oldLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
		Time t = new Time();
		t.setToNow();
		if (oldLocation != null && ((oldLocation.getTime() - t.toMillis(true)) < 3 * 60 * 60 * 1000)) {
			new LoadTheatersTask().execute(String.valueOf(oldLocation.getLatitude()), String.valueOf(oldLocation.getLongitude()));
		} else {
			((TextView) findViewById(android.R.id.empty)).setText("Récupération de la position. Vous pouvez aussi effectuer directement une recherche pour un nom de cinéma.");
			LocationListener listener = new LocationListener() {
				@Override
				public void onLocationChanged(Location location) {
					new LoadTheatersTask().execute(String.valueOf(location.getLatitude()), String.valueOf(location.getLongitude()));
					locationManager.removeUpdates(this);
					((TextView) findViewById(android.R.id.empty)).setText("Aucun résultat à proximité.");
				}

				@Override
				public void onProviderDisabled(String provider) {
				}

				@Override
				public void onProviderEnabled(String provider) {
				}

				@Override
				public void onStatusChanged(String provider, int status, Bundle extras) {
				}
			};
			locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 1000, 10, listener);
		}
	}

	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);
		menu.findItem(R.id.menu_search_geo).setVisible(false);

		return true;
	}

	protected ArrayList<Theater> retrieveResults(String... queries) {
		String lat = queries[0];
		String lon = queries[1];

		try {
			return (new APIHelper().findTheatersGeo(lat, lon));
		} catch (ClientProtocolException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return null;
	}
}
