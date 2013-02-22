package fr.neamar.cinetime.fragments;

import java.util.ArrayList;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.ListFragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;
import fr.neamar.cinetime.MovieAdapter;
import fr.neamar.cinetime.R;
import fr.neamar.cinetime.api.APIHelper;
import fr.neamar.cinetime.callbacks.TaskMoviesCallbacks;
import fr.neamar.cinetime.objects.Movie;

public class MoviesFragment extends ListFragment implements TaskMoviesCallbacks {

	private static final String STATE_ACTIVATED_POSITION = "activated_position";
	static public ArrayList<Movie> movies;

	private Callbacks mCallbacks = sDummyCallbacks;
	private int mActivatedPosition = ListView.INVALID_POSITION;
	private LoadMoviesTask mTask;
	private boolean toFinish = false;
	private boolean dialogPending = false;
	private ProgressDialog dialog;

	public interface Callbacks {

		public void onItemSelected(int position);

		public void setFragment(Fragment fragment);
	}

	private static Callbacks sDummyCallbacks = new Callbacks() {
		@Override
		public void onItemSelected(int position) {
		}

		@Override
		public void setFragment(Fragment fragment) {
		}
	};

	@Override
	public void onResume() {
		super.onResume();
		if (movies == null && mTask == null) {
			mTask = new LoadMoviesTask(this);
			mTask.execute(getActivity().getIntent().getStringExtra("code"));
		}
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		if (savedInstanceState != null && savedInstanceState.containsKey(STATE_ACTIVATED_POSITION)) {
			setActivatedPosition(savedInstanceState.getInt(STATE_ACTIVATED_POSITION));
		}
		return inflater.inflate(R.layout.fragment_movies, container, false);
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		this.setRetainInstance(true);
		if (movies == null && mTask == null) {
			mTask = new LoadMoviesTask(this);
			mTask.execute(getActivity().getIntent().getStringExtra("code"));
		}
	}

	@Override
	public void onAttach(Activity activity) {
		super.onAttach(activity);
		if (!(activity instanceof Callbacks)) {
			throw new IllegalStateException("Activity must implement fragment's callbacks.");
		}
		mCallbacks = (Callbacks) activity;
		mCallbacks.setFragment(this);
		if (toFinish) {
			getActivity().finish();
			toFinish = false;
		}
		if (dialogPending) {
			dialog = new ProgressDialog(activity);
			dialog.setMessage("Chargement des séances en cours...");
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

	@Override
	public void onListItemClick(ListView listView, View view, int position, long id) {
		super.onListItemClick(listView, view, position, id);
		mCallbacks.onItemSelected(position);
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

	public void finish() {
		if (getActivity() != null) {
			getActivity().finish();
		} else {
			toFinish = true;
		}
	}

	private class LoadMoviesTask extends AsyncTask<String, Void, ArrayList<Movie>> {
		private MoviesFragment fragment;
		private Context ctx;

		public LoadMoviesTask(MoviesFragment fragment) {
			super();
			this.fragment = fragment;
			this.ctx = fragment.getActivity();
		}

		@Override
		protected void onPreExecute() {
			dialog = new ProgressDialog(ctx);
			dialog.setMessage("Chargement des séances en cours...");
			dialog.show();
			dialogPending = true;
		}

		@Override
		protected ArrayList<Movie> doInBackground(String... queries) {
			return (new APIHelper(fragment)).findMoviesFromTheater(queries[0]);
		}

		@Override
		protected void onPostExecute(ArrayList<Movie> resultsList) {
			if (dialog != null) {
				if (dialog.isShowing())
					dialog.dismiss();
			}
			dialogPending = false;
			fragment.onLoadOver(resultsList);
		}
	}

	static public ArrayList<Movie> getMovies() {
		return movies;
	}

	public void clear() {
		movies.clear();
		movies = null;
	}

	@Override
	public void onLoadOver(ArrayList<Movie> movies) {
		MoviesFragment.movies = movies;
		setListAdapter(new MovieAdapter(getActivity(), R.layout.listitem_theater, movies));
		mTask = null;
	}
}
