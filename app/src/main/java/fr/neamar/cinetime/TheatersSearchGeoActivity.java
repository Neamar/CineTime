package fr.neamar.cinetime;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.provider.Settings;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.text.format.Time;
import android.view.Menu;
import android.widget.TextView;

import java.io.IOException;
import java.util.ArrayList;

import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersSearchGeoActivity extends TheatersActivity {
    static final int WAITING_TO_ENABLE_LOCATION_PROVIDER = 0;
    static final int ON_LOCATION_PERMISSION_CHANGED = 1;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ((TextView) findViewById(android.R.id.empty)).setText("Aucun cinéma à proximité, utilisez la recherche.");

        setTitle("Cinémas à proximité");

        if (hasRestoredFromNonConfigurationInstance) {
            return;
        }

        retrieveLocation();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           String permissions[], int[] grantResults) {
        if (requestCode == ON_LOCATION_PERMISSION_CHANGED) {
            retrieveLocation();
        }
    }

    public void retrieveLocation() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{android.Manifest.permission.ACCESS_COARSE_LOCATION}, ON_LOCATION_PERMISSION_CHANGED);
            return;
        }

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
                    startActivityForResult(settingsIntent, WAITING_TO_ENABLE_LOCATION_PROVIDER);
                }
            }).setNegativeButton(res.getString(R.string.location_dialog_cancel), new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int id) {
                    onSearchRequested();
                    ((TextView) findViewById(android.R.id.empty)).setText(R.string.aucune_info_localisation);
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
            ((TextView) findViewById(android.R.id.empty)).setText(R.string.recuperation_position);
            LocationListener listener = new LocationListener() {
                @Override
                public void onLocationChanged(Location location) {
                    new LoadTheatersTask().execute(String.valueOf(location.getLatitude()), String.valueOf(location.getLongitude()));
                    locationManager.removeUpdates(this);
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

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == WAITING_TO_ENABLE_LOCATION_PROVIDER) {
            retrieveLocation();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.findItem(R.id.menu_search_geo).setVisible(false);

        return true;
    }

    @Override
    protected ArrayList<Theater> retrieveResults(String... queries) {
        String lat = queries[0];
        String lon = queries[1];

        try {
            return (new APIHelper().findTheatersGeo(lat, lon));
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }

        return null;
    }
}
