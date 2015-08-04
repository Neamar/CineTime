package fr.neamar.cinetime;

import android.app.ListActivity;
import android.content.Intent;
import android.content.Intent.ShortcutIconResource;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.Toast;

import java.util.ArrayList;

import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class ShortcutActivity extends ListActivity {
    private ArrayList<Theater> theaters;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        theaters = DBHelper.getFavorites(this);

        if (theaters.size() > 0) {
            setListAdapter(new ArrayAdapter<Theater>(this, android.R.layout.simple_list_item_1, theaters));
        } else {
            Toast.makeText(this, "Ajoutez un cinéma aux favoris pour l'ajouter directement à l'écran d'accueil.", Toast.LENGTH_LONG).show();
            finish();
        }
    }

    @Override
    protected void onListItemClick(ListView l, View v, int position, long id) {
        // The meat of our shortcut
        Intent shortcutIntent = new Intent(this, MoviesActivity.class);
        shortcutIntent.putExtra("code", theaters.get(position).code);
        shortcutIntent.putExtra("theater", theaters.get(position).title);
        ShortcutIconResource iconResource = Intent.ShortcutIconResource.fromContext(this, R.drawable.ic_launcher);

        // The result we are passing back from this activity
        Intent intent = new Intent();
        intent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent);
        intent.putExtra(Intent.EXTRA_SHORTCUT_NAME, theaters.get(position).title);
        intent.putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, iconResource);
        setResult(RESULT_OK, intent);

        finish();
    }
}
