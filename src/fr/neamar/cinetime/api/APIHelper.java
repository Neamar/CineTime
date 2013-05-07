package fr.neamar.cinetime.api;

import android.content.Context;
import android.preference.PreferenceManager;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Locale;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import fr.neamar.cinetime.R;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.objects.Theater;

public class APIHelper {

	protected Context ctx;

    public APIHelper(Context ctx) {
        this.ctx = ctx;
    }

    /**
	 * Retrieve base URL.
	 * 
	 * @param page
	 * @return
	 */
	protected String getBaseUrl(String page) {
        String country = PreferenceManager.getDefaultSharedPreferences(ctx).
                getString("country", ctx.getString(R.string.default_country));
        String url;
        if(country.equalsIgnoreCase("uk")){
            url = ctx.getResources().getString(R.string.api_url_uk);
        }else if(country.equalsIgnoreCase("fr")){
            url = ctx.getResources().getString(R.string.api_url_fr);
        }else if(country.equalsIgnoreCase("de")){
            url = ctx.getResources().getString(R.string.api_url_de);
        }else if(country.equalsIgnoreCase("es")){
            url = ctx.getResources().getString(R.string.api_url_es);
        }else {
            throw new UnsupportedOperationException("Locale unkown " + country);
        }
        return "http://" + url +"/rest/v3/" + page + "?partner=aXBhZC12MQ";
	}

	/**
	 * Download an url using GET.
	 * 
	 * @param url
	 * @return
	 * @throws IOException
	 * @throws ClientProtocolException
	 */
	protected String downloadUrl(String url) throws ClientProtocolException, IOException {
		// Create a new HTTP Client
		DefaultHttpClient defaultClient = new DefaultHttpClient();
		// Setup the get request
		HttpGet httpGetRequest = new HttpGet(url);

		// Execute the request in the client
		HttpResponse httpResponse = defaultClient.execute(httpGetRequest);

		// Grab the response
		BufferedReader reader = new BufferedReader(new InputStreamReader(httpResponse.getEntity()
				.getContent(), "UTF-8"));
		return reader.readLine();
	}

	protected JSONArray downloadTheatersList(String query) throws ClientProtocolException,
			IOException {
		String url;
		try {
			url = getBaseUrl("search") + "&filter=theater&q=" + URLEncoder.encode(query, "UTF-8")
					+ "&count=25&format=json";
		} catch (UnsupportedEncodingException e1) {
			url = getBaseUrl("search") + "&filter=theater&q=" + query + "&count=25&format=json";
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

	protected JSONArray downloadTheatersListGeo(String lat, String lon)
			throws ClientProtocolException, IOException {
		String url;
		try {
			url = getBaseUrl("theaterlist") + "&lat=" + URLEncoder.encode(lat, "UTF-8") + "&long="
					+ URLEncoder.encode(lon, "UTF-8") + "&radius=50" + "&count=25&format=json";
		} catch (UnsupportedEncodingException e1) {
			url = getBaseUrl("theaterlist") + "&lat=" + lat + "&long=" + lon + "&radius=25"
					+ "&count=25&format=json";
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

	public JSONArray downloadMoviesList(String theaterCode) {
		String url = getBaseUrl("showtimelist") + "&theaters=" + theaterCode + "&format=json";

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

	public ArrayList<Theater> findTheaters(String query) throws ClientProtocolException,
			IOException {

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

	public ArrayList<Theater> findTheatersGeo(String lat, String lon)
			throws ClientProtocolException, IOException {

		ArrayList<Theater> resultsList = new ArrayList<Theater>();

		JSONArray jsonResults = downloadTheatersListGeo(lat, lon);

		for (int i = 0; i < jsonResults.length(); i++) {
			JSONObject jsonTheater;
			try {
				jsonTheater = jsonResults.getJSONObject(i);

				Theater theater = new Theater();
				theater.code = jsonTheater.getString("code");
				theater.title = jsonTheater.getString("name");
				theater.location = jsonTheater.getString("address");
				theater.distance = jsonTheater.getDouble("distance");

				resultsList.add(theater);

			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
		return resultsList;
	}

	protected JSONObject downloadMovie(String movieCode) {
		String url = getBaseUrl("movie") + "&code=" + movieCode + "&profile=small&format=json";

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

	public ArrayList<Movie> formatMoviesList(JSONArray jsonResults, String theaterCode) {
		ArrayList<Movie> resultsList = new ArrayList<Movie>();

		for (int i = 0; i < jsonResults.length(); i++) {
			JSONObject jsonMovie, jsonShow;

			try {
				jsonMovie = jsonResults.getJSONObject(i);
				jsonShow = jsonMovie.getJSONObject("onShow").getJSONObject("movie");

				Movie movie = new Movie();
				movie.code = jsonShow.getString("code");
				movie.title = jsonShow.getString("title");
				if (jsonShow.has("poster")) {
					movie.poster = jsonShow.getJSONObject("poster").getString("path");
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
					movie.genres = jsonGenres.getJSONObject(0).getString("$")
							.toLowerCase(Locale.FRANCE);
					for (int j = 1; j < jsonGenres.length(); j++) {
						movie.genres += ", "
								+ jsonGenres.getJSONObject(j).getString("$")
										.toLowerCase(Locale.FRANCE);
					}
				}
				
				if (jsonShow.has("trailer")) {
					JSONObject jsonTrailer = jsonShow.getJSONObject("trailer");
					movie.trailerCode = jsonTrailer.optString("code", "");
				}

				movie.display = jsonMovie.getString("display");
                if(jsonMovie.has("version")){
                    movie.isOriginalLanguage = jsonMovie.getJSONObject("version").getString("original")
                            .equals("true");
                }
				if (jsonMovie.has("screenFormat"))
					movie.is3D = jsonMovie.getJSONObject("screenFormat").getString("$")
							.equals("3D");
				resultsList.add(movie);

			} catch (JSONException e) {
				throw new RuntimeException("An error occured while loading datas for "
						+ theaterCode + ": " + e.getMessage());
			}
		}

		return resultsList;
	}

	public Movie findMovie(Movie movie) {
		JSONObject jsonMovie = downloadMovie(movie.code);
		movie.synopsis = jsonMovie.optString("synopsisShort", "");
		return movie;
	}
	
	public String downloadTrailerUrl(Movie movie) {
		if(movie.trailerCode.equals(""))
			return null;
		String url = getBaseUrl("media") + "&mediafmt=mp4-hip&code=" + movie.trailerCode + "&format=json";
		try {
			String json = downloadUrl(url);
			JSONObject jsonTrailer = new JSONObject(json).getJSONObject("media");
			if(jsonTrailer.has("rendition")){
				JSONArray rendition = jsonTrailer.getJSONArray("rendition");
                if (PreferenceManager.getDefaultSharedPreferences(ctx).getBoolean("hd_trailer", false)) {
                    return rendition.getJSONObject(rendition.length()-1).getString("href");
                }else {
                    return rendition.getJSONObject(0).getString("href");
                }
            }
			return null;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}

	}
}
