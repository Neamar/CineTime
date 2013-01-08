package fr.neamar.cinetime;

import java.util.ArrayList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;
import fr.neamar.cinetime.objects.Theater;

public class TheaterAdapter extends ArrayAdapter<Theater> {

	private Context context;
	
	/**
	 * Array list containing all the theaters currently displayed
	 */
	private ArrayList<Theater> theaters = new ArrayList<Theater>();

	public TheaterAdapter(Context context, int textViewResourceId,
			ArrayList<Theater> theaters) {
		super(context, textViewResourceId, theaters);

		this.context = context;
		this.theaters = theaters;
	}

	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;

		if(v == null)
		{
			LayoutInflater vi = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
			v = vi.inflate(R.layout.listitem_theater, null);
		}
		
		Theater theater = theaters.get(position);

		TextView theaterName = (TextView) v.findViewById(R.id.listitem_theater_name);
		TextView theaterLocation = (TextView) v.findViewById(R.id.listitem_theater_location);

		theaterName.setText(theater.title);
		theaterLocation.setText(theater.location);
		
		return v;
	}
}
