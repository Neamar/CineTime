package fr.neamar.cinetime;

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
		
		ArrayList<Theater> theaters = new ArrayList<Theater>();
		Theater theater = new Theater();
		theater.name = "UGC Confluence";
		theater.location = "Centre commercial La Part-Dieu Niveau 2 et 4";
		theaters.add(theater);
		
		theater = new Theater();
		theater.name = "UGC Cinécité";
		theater.location = "117, cours Emile-Zola";
		theaters.add(theater);
		
		TheaterAdapter adapter = new TheaterAdapter(this, R.layout.listitem_theater, theaters);
		setListAdapter(adapter);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		getMenuInflater().inflate(R.menu.activity_theaters, menu);
		return true;
	}
}
