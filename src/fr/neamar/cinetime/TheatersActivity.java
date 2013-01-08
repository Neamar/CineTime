package fr.neamar.cinetime;

import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;
import java.util.ArrayList;

import android.app.ListActivity;
import android.os.Bundle;
import android.view.Menu;
import android.widget.ListView;

public class TheatersActivity extends ListActivity {

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_theaters);
		
		//DBHelper.insertFavorite(this, "P0005", "UGC Astoria", "31, cours Vitton");
		
		ArrayList<Theater> theaters = DBHelper.getFavorites(this);
		TheaterAdapter adapter = new TheaterAdapter(this, R.layout.listitem_theater, theaters);
		setListAdapter(adapter);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		getMenuInflater().inflate(R.menu.activity_theaters, menu);
		return true;
	}
}
