package fr.neamar.cinetime;

import java.util.ArrayList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.TextView;
import android.widget.Toast;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheaterAdapter extends ArrayAdapter<Theater> {

	private LayoutInflater inflater;

	/**
	 * Array list containing all the theaters currently displayed
	 */
	public ArrayList<Theater> theaters = new ArrayList<Theater>();

	public TheaterAdapter(Context context, int textViewResourceId, ArrayList<Theater> theaters) {
		super(context, textViewResourceId, theaters);

		this.inflater = LayoutInflater.from(context);
		this.theaters = theaters;
	}

	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;

		if (v == null) {
			v = inflater.inflate(R.layout.listitem_theater, null);
		}

		final Theater theater = theaters.get(position);

		TextView theaterName = (TextView) v.findViewById(R.id.listitem_theater_name);
		TextView theaterLocation = (TextView) v.findViewById(R.id.listitem_theater_location);

		final CheckBox fav = (CheckBox) v.findViewById(R.id.listitem_theater_fav);
		fav.setChecked(DBHelper.isFavorite(theater.code));
		fav.setOnClickListener(new View.OnClickListener() {

			@Override
			public void onClick(View v) {
				if (fav.isChecked()) {
					DBHelper.insertFavorite(v.getContext(), theater.code, theater.title,
							theater.location);
					Toast.makeText(getContext(), "Cinéma ajouté aux favoris", Toast.LENGTH_SHORT)
							.show();
				} else {
					DBHelper.removeFavorite(v.getContext(), theater.code);
					Toast.makeText(getContext(), "Cinéma retiré des favoris", Toast.LENGTH_SHORT)
							.show();
				}
			}
		});

		theaterName.setText(theater.title);
		theaterLocation.setText(theater.location);

		return v;
	}
}
