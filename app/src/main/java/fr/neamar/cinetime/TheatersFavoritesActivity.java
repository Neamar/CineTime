package fr.neamar.cinetime;

import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import android.widget.Toast;

import java.util.ArrayList;

import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersFavoritesActivity extends TheatersActivity {
    public ArrayList<Theater> favorites;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setTitle(R.string.app_name);

        // Display warning when using alpha version
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            String version = pInfo.versionName;
            if (version.charAt(version.length() - 1) == 'a') {
                Toast.makeText(this, "Vous testez actuellement la version α de CinéTime.\nMerci de faire remonter les bugs rencontrés sur cinetime@neamar.fr.\nBons films !", Toast.LENGTH_LONG).show();
            }
        } catch (NameNotFoundException e) {
            e.printStackTrace();
        }


        favorites = DBHelper.getFavorites(this);

        if (favorites.size() > 0) {
            setTheaters(favorites);
        } else {
            // No favorites yet. Display theaters around
            Intent intent = new Intent(this, TheatersSearchGeoActivity.class);
            startActivity(intent);
            finish();
        }
    }

    @Override
    public void onResume() {
        favorites = DBHelper.getFavorites(this);
        setTheaters(favorites);

        super.onResume();
    }

    @Override
    protected ArrayList<Theater> retrieveResults(String... queries) {
        return null;
    }
}
