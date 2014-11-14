package fr.neamar.cinetime;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.ActivityOptions;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.NavUtils;
import android.util.Pair;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.widget.Toast;

import fr.neamar.cinetime.fragments.DetailsEmptyFragment;
import fr.neamar.cinetime.fragments.DetailsFragment;
import fr.neamar.cinetime.fragments.MoviesFragment;
import fr.neamar.cinetime.objects.Theater;

public class MoviesActivity extends FragmentActivity implements MoviesFragment.Callbacks {

	private boolean mTwoPane;
	private MoviesFragment moviesFragment;
	private DetailsFragment detailsFragment;
	private String theater;
	private String theaterLocation = "";
	private MenuItem shareItem;
	private MenuItem trailerItem;

	@TargetApi(14)
	@Override
	public void onCreate(Bundle savedInstanceState) {
		requestWindowFeature(Window.FEATURE_INDETERMINATE_PROGRESS);
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_movies_list);

		mTwoPane = getResources().getBoolean(R.bool.mTwoPane);
		theater = getIntent().getStringExtra("theater");
		setTitle(getIntent().getStringExtra("theater"));
		if (mTwoPane) {
			if (detailsFragment == null) {
				getSupportFragmentManager().beginTransaction().replace(R.id.file_detail_container, new DetailsEmptyFragment()).commit();
			} else {
				getSupportFragmentManager().beginTransaction().replace(R.id.file_detail_container, detailsFragment).commit();
			}
		}
		// Title in action bar brings back one level
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			getActionBar().setHomeButtonEnabled(true);
			getActionBar().setDisplayHomeAsUpEnabled(true);
		}
	}

	@Override
	public void setIsLoading(Boolean isLoading) {
		setProgressBarIndeterminateVisibility(isLoading);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		if (mTwoPane) {
			inflater.inflate(R.menu.activity_details, menu);
			shareItem = menu.findItem(R.id.menu_share);
			trailerItem = menu.findItem(R.id.menu_play);
			if (detailsFragment == null) {
				desactivateDetailsMenu(false);
			} else {
				activateDetailsMenu(false);
			}
		} else {
			inflater.inflate(R.menu.activity_movies, menu);
			if (!theaterLocation.equals("")) {
				menu.findItem(R.id.menu_map).setVisible(true);
			}
			return true;
		}

		return true;
	}

	@Override
	protected void onResume() {
		super.onResume();
		if (mTwoPane) {
			if (detailsFragment == null) {
				getSupportFragmentManager().beginTransaction().replace(R.id.file_detail_container, new DetailsEmptyFragment()).commit();
				desactivateDetailsMenu(true);
			} else {
				activateDetailsMenu(true);
			}
		}
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case android.R.id.home:
			moviesFragment.clear();
			NavUtils.navigateUpFromSameTask(this);
			return true;
		case R.id.menu_share:
			detailsFragment.shareMovie();
			return true;
		case R.id.menu_play:
			detailsFragment.displayTrailer();
			return true;
		case R.id.menu_map:
			String uri = "geo:0,0?q=" + theaterLocation;

			try {
				startActivity(new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(uri)));
			} catch (ActivityNotFoundException e) {
				Toast.makeText(this, "Installez Google Maps pour afficher le plan !", Toast.LENGTH_SHORT).show();
			}
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	@TargetApi(Build.VERSION_CODES.HONEYCOMB)
	@Override
	public void setFragment(Fragment fragment) {
		if (fragment instanceof MoviesFragment) {
			this.moviesFragment = (MoviesFragment) fragment;
		} else if (fragment instanceof DetailsFragment) {
			this.detailsFragment = (DetailsFragment) fragment;
			activateDetailsMenu(true);
			if (DetailsFragment.displayedMovie == null || DetailsFragment.displayedMovie.trailerCode.isEmpty() && trailerItem != null) {
				trailerItem.setEnabled(false);
				trailerItem.setVisible(false);
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
					invalidateOptionsMenu();
				}
			}
		}
	}

	@TargetApi(Build.VERSION_CODES.HONEYCOMB)
	public void setTheaterLocation(Theater theater) {
		theaterLocation = theater.title + ", " + theater.location + " " + theater.zipCode;
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB && !mTwoPane) {
			invalidateOptionsMenu();
		}
	}

	@Override
	public void onBackPressed() {
		if (mTwoPane && detailsFragment != null) {
			getSupportFragmentManager().beginTransaction().replace(R.id.file_detail_container, new DetailsEmptyFragment()).commit();
			detailsFragment = null;
			desactivateDetailsMenu(true);
		} else {
			moviesFragment.clear();
			super.onBackPressed();
		}
	}

	@Override
	@TargetApi(21)
	public void onItemSelected(int position, Fragment source, View currentView) {
		if (source instanceof MoviesFragment) {
			if (mTwoPane) {
				Bundle arguments = new Bundle();
				arguments.putInt(DetailsFragment.ARG_ITEM_ID, position);
				arguments.putString(DetailsFragment.ARG_THEATER_NAME, theater);
				detailsFragment = new DetailsFragment();
				detailsFragment.setArguments(arguments);
				getSupportFragmentManager().beginTransaction().replace(R.id.file_detail_container, detailsFragment).commit();
			} else {
				Intent details = new Intent(this, DetailsActivity.class);
				details.putExtra(DetailsFragment.ARG_ITEM_ID, position);
				details.putExtra(DetailsFragment.ARG_THEATER_NAME, theater);
				if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
						startActivity(details);
				}
				else {
					// Animation time!
					ActivityOptions options = null;
					if (currentView != null) {
				  final View moviePoster = currentView.findViewById(R.id.listitem_movie_poster);
					  final View movieName = currentView.findViewById(R.id.listitem_movie_title);
					  if (moviePoster != null) {
						  options = ActivityOptions.makeSceneTransitionAnimation(this, Pair.create(moviePoster, "moviePoster"), Pair.create(movieName, "movieName"));
						}
					}
					startActivity(details, options.toBundle());
				}
			}
		} else if (source instanceof DetailsFragment) {
			startActivity(new Intent(this, PosterViewerActivity.class));
		}
	}

	@Override
	public void finishNoNetwork() {
		Toast.makeText(this, "Impossible de télécharger les données. Merci de vérifier votre connexion ou de réessayer dans quelques minutes.", Toast.LENGTH_SHORT).show();
		finish();
	}

	@SuppressLint("NewApi")
	private void activateDetailsMenu(boolean rebuild) {
		if (shareItem != null) {
			shareItem.setVisible(true);
			shareItem.setEnabled(true);
		}
		if (trailerItem != null) {
			trailerItem.setVisible(true);
			trailerItem.setEnabled(true);
		}
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB && rebuild) {
			invalidateOptionsMenu();
		}
	}

	@SuppressLint("NewApi")
	private void desactivateDetailsMenu(boolean rebuild) {
		if (shareItem != null) {
			shareItem.setEnabled(false);
			shareItem.setVisible(false);
		}
		if (trailerItem != null) {
			trailerItem.setEnabled(false);
			trailerItem.setVisible(false);
		}
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB && rebuild) {
			invalidateOptionsMenu();
		}
	}
}
