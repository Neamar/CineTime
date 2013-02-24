package fr.neamar.cinetime.fragments;

import java.util.ArrayList;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.ListFragment;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemLongClickListener;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ListView;
import android.widget.TextView;
import fr.neamar.cinetime.R;
import fr.neamar.cinetime.TheaterAdapter;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.callbacks.TaskTheaterCallbacks;
import fr.neamar.cinetime.db.DBHelper;
import fr.neamar.cinetime.objects.Theater;

public class TheatersFragment extends ListFragment implements TaskTheaterCallbacks{

	private static final String STATE_ACTIVATED_POSITION = "activated_position";

	private Callbacks mCallbacks = sDummyCallbacks;
	private int mActivatedPosition = ListView.INVALID_POSITION;
	private boolean toFinish = false;
	private boolean dialogPending = false;
	private ProgressDialog dialog;
	public EditText searchText;
	public ImageButton searchButton;
	static private Context ctx;
	static private String query;

	public interface Callbacks {

		public void onItemSelected(int position, Fragment source);
		
		public void onLongItemSelected(int position, Fragment source);

		public void setFragment(Fragment fragment);
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
			// TODO Auto-generated method stub
			
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
		searchText.setText(query);
		// Display favorites :
		searchButton.performClick();
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
				searchForTheater(searchText.getText().toString().trim());
			}
		});

		// When searching from keyboard
		searchText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
			@Override
			public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
				InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
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
	
	public ArrayList<Theater> getTheaters(){
		return ((TheaterAdapter)getListView().getAdapter()).theaters;
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
			getActivity().finish();
			toFinish = false;
		}
		if (dialogPending) {
			dialog = new ProgressDialog(activity);
			dialog.setMessage("Recherche en cours...");
			dialog.show();
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
		new LoadTheatersTask(ctx).execute(query);
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
	
	public boolean goBack(){
		// When pressing back, if a query is entered redisplay favorites.
		// Else perform default back action.
		if (searchText.getText().toString().equals("")) {
			return true;
		} else {
			searchText.setText("");
			searchButton.performClick();
			return false;
		}
	}

	@Override
	public void finish() {
		if (getActivity() != null) {
			getActivity().finish();
		} else {
			toFinish = true;
		}
	}
	
	private class LoadTheatersTask extends AsyncTask<String, Void, ArrayList<Theater>> {
		private Boolean isLoadingFavorites = false;
		private Context ctx;
		
		public LoadTheatersTask(Context ctx) {
			super();
			this.ctx = ctx;
		}

		@Override
		protected void onPreExecute() {
			dialog = new ProgressDialog(ctx);
			dialogPending = true;
			dialog.setMessage("Recherche en cours...");
			dialog.show();
		}

		@Override
		protected ArrayList<Theater> doInBackground(String... queries) {
			if (queries[0].equals("")) {
				isLoadingFavorites = true;
				return DBHelper.getFavorites(ctx);
			}

			return (new APIHelper(TheatersFragment.this)).findTheaters(queries[0]);
		}

		@Override
		protected void onPostExecute(ArrayList<Theater> resultsList) {
			if (dialog != null) {
				if (dialog.isShowing())
					dialog.dismiss();
			}
			dialogPending = false;

			if (!isLoadingFavorites) {
				((TextView) getListView().getEmptyView())
						.setText("Aucun résultat pour cette recherche.");
			}
			TheatersFragment.this.onLoadOver(resultsList);
		}
	}

	@Override
	public void onLoadOver(ArrayList<Theater> theaters) {
		setListAdapter(new TheaterAdapter(ctx, R.layout.listitem_theater,
				theaters));

		if (theaters.size() > 0) {
			getListView().requestFocus();
		}
	}
}
