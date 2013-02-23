package fr.neamar.cinetime.api;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;

import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;
import fr.neamar.cinetime.callbacks.TaskMoviesCallbacks;
import fr.neamar.cinetime.callbacks.TaskTheaterCallbacks;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.objects.Theater;

public class APIHelper {

	protected TaskMoviesCallbacks fragmentM;
	protected TaskTheaterCallbacks fragmentT;
	protected Context ctx;

	public APIHelper(TaskMoviesCallbacks fragment) {
		this.fragmentM = fragment;
	}

	public APIHelper(TaskTheaterCallbacks fragment) {
		this.fragmentT = fragment;
	}

	/**
	 * Retrieve base URL.
	 * 
	 * @param page
	 * @return
	 */
	protected String getBaseUrl(String page) {
		return "http://api.allocine.fr/rest/v3/" + page + "?partner=YW5kcm9pZC12M3M";
	}

	/**
	 * Download an url using GET.
	 * 
	 * @param url
	 * @return
	 */
	protected String downloadUrl(String url) {
		try {
			// Create a new HTTP Client
			DefaultHttpClient defaultClient = new DefaultHttpClient();
			// Setup the get request
			HttpGet httpGetRequest = new HttpGet(url);

			// Execute the request in the client
			HttpResponse httpResponse = defaultClient.execute(httpGetRequest);

			// Grab the response
			BufferedReader reader = new BufferedReader(new InputStreamReader(httpResponse
					.getEntity().getContent(), "UTF-8"));
			return reader.readLine();
		} catch (Exception e) {
			Toast.makeText(
					ctx,
					"Impossible de télécharger les données. Merci de vérifier votre connexion ou de réessayer dans quelques minutes.",
					Toast.LENGTH_SHORT).show();
			if (fragmentT != null) {
				fragmentT.finish();
			} else {
				fragmentM.finish();
			}
		}

		return "";

	}

	protected JSONArray downloadTheatersList(String query) {
		String url;
		try {
			url = getBaseUrl("search") + "&filter=theater&q=" + URLEncoder.encode(query, "UTF-8")
					+ "&format=json";
		} catch (UnsupportedEncodingException e1) {
			url = getBaseUrl("search") + "&filter=theater&q=" + query + "&format=json";
		}

		try {
			String json = downloadUrl(url);

			// Instantiate a JSON object from the request response
			JSONObject jsonObject = new JSONObject(json);

			JSONObject feed = jsonObject.getJSONObject("feed");

			if (feed.getInt("totalResults") > 0)
				return feed.getJSONArray("theater");
			else
				return new JSONArray();

		} catch (JSONException e) {
			// throw new RuntimeException("Unable to download theaters list.");
			return new JSONArray();
		}
	}

	protected JSONArray downloadMoviesList(String code) {
		String url = getBaseUrl("showtimelist") + "&theaters=" + code + "&format=json";

		try {
			String json = downloadUrl(url);

			// Instantiate a JSON object from the request response
			JSONObject jsonObject = new JSONObject(json);

			JSONObject feed = jsonObject.getJSONObject("feed");

			if (feed.getInt("totalResults") > 0)
				return feed.getJSONArray("theaterShowtimes").getJSONObject(0)
						.getJSONArray("movieShowtimes");
			else
				return new JSONArray();

		} catch (Exception e) {
			// throw new RuntimeException("Unable to download movies list.");
			return new JSONArray();
		}
	}

	public ArrayList<Theater> findTheaters(String query) {

		ArrayList<Theater> resultsList = new ArrayList<Theater>();

		JSONArray jsonResults = downloadTheatersList(query);

		for (int i = 0; i < jsonResults.length(); i++) {
			JSONObject jsonTheater;
			try {
				jsonTheater = jsonResults.getJSONObject(i);

				Theater theater = new Theater();
				theater.code = jsonTheater.getString("code");
				theater.title = jsonTheater.getString("name");
				theater.location = jsonTheater.getString("address");

				resultsList.add(theater);

			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
		return resultsList;
	}

	protected JSONObject downloadMovie(String code) {
		String url = getBaseUrl("movie") + "&code=" + code + "&profile=small&format=json";

		try {
			String json = downloadUrl(url);

			// Instantiate a JSON object from the request response
			JSONObject jsonObject = new JSONObject(json);

			return jsonObject.getJSONObject("movie");

		} catch (Exception e) {
			// throw new RuntimeException("Unable to download movies list.");
			return new JSONObject();
		}
	}

	public ArrayList<Movie> findMoviesFromTheater(String code) {
		ArrayList<Movie> resultsList = new ArrayList<Movie>();

		JSONArray jsonResults = downloadMoviesList(code);

		for (int i = 0; i < jsonResults.length(); i++) {
			JSONObject jsonMovie, jsonShow;

			try {
				jsonMovie = jsonResults.getJSONObject(i);
				jsonShow = jsonMovie.getJSONObject("onShow").getJSONObject("movie");

				Movie movie = new Movie();
				movie.code = jsonShow.getString("code");
				movie.title = jsonShow.getString("title");
				if (jsonShow.has("poster")) {
					movie.poster = "http://images.allocine.fr/r_150_500"
							+ jsonShow.getJSONObject("poster").getString("path");
					movie.posterHigh = "http://images.allocine.fr/r_320_500"
							+ jsonShow.getJSONObject("poster").getString("path");
				}
				movie.duration = jsonShow.optInt("runtime");

				if (jsonShow.has("statistics")) {
					JSONObject jsonStatistics = jsonShow.getJSONObject("statistics");
					movie.pressRating = jsonStatistics.optString("pressRating", "0");
					movie.userRating = jsonStatistics.optString("userRating", "0");
				}

				if (jsonShow.has("movieCertificate")) {
					JSONObject jsonCertificate = jsonShow.getJSONObject("movieCertificate")
							.getJSONObject("certificate");
					movie.certificate = jsonCertificate.getInt("code");
					movie.certificateString = jsonCertificate.optString("$", "");
				}

				if (jsonShow.has("castingShort")) {
					JSONObject jsonCasting = jsonShow.getJSONObject("castingShort");
					movie.directors = jsonCasting.optString("directors", "");
					movie.actors = jsonCasting.optString("actors", "");
				}

				if (jsonShow.has("genre")) {
					JSONArray jsonGenres = jsonShow.getJSONArray("genre");
					movie.genres = jsonGenres.getJSONObject(0).getString("$").toLowerCase();
					for (int j = 1; j < jsonGenres.length(); j++) {
						movie.genres += ", "
								+ jsonGenres.getJSONObject(j).getString("$").toLowerCase();
					}
				}

				movie.display = jsonMovie.getString("display");
				movie.isOriginalLanguage = jsonMovie.getJSONObject("version").getString("original")
						.equals("true");
				if (jsonMovie.has("screenFormat"))
					movie.is3D = jsonMovie.getJSONObject("screenFormat").getString("$")
							.equals("3D");
				resultsList.add(movie);

			} catch (JSONException e) {
				throw new RuntimeException("An error occured while loading datas for " + code
						+ ": " + e.getMessage());
			}
		}

		return resultsList;
	}

	public Movie findMovie(Movie movie) {
		JSONObject jsonMovie = downloadMovie(movie.code);
		movie.synopsis = jsonMovie.optString("synopsisShort", "");
		return movie;
	}
}
