package fr.neamar.cinetime.api;

import android.content.Context;
import android.util.Base64;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLEncoder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.MessageFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.CoreProtocolPNames;
import org.apache.http.params.HttpParams;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.objects.Theater;

public class APIHelper {

    private static final String MAGIC_STRING = "29d185d98c984a359e6e6f26a0474269";
    private static final String SED_FORMAT = "yyyyMMdd";
    private static final String SED = "&sed=";
    private static final String URL_FORMAT_WITH_SED_SIG = "{0}" + SED + "{1}&sig={2}";

	protected Context ctx;

    private static URI encode(URI uri) throws URISyntaxException, NoSuchAlgorithmException, UnsupportedEncodingException {
        String uriAsString = uri.toString();
        String[] splittedUri = uriAsString.split("\\?");
        if (splittedUri.length == 2) {
            String tokens = splittedUri[1];
            String sed = getSed();
            String sid = getSig(tokens, sed);
            return new URI(MessageFormat.format(URL_FORMAT_WITH_SED_SIG, uriAsString, sed, sid));
        } else {
            throw new URISyntaxException(uriAsString, "Multiple '?'");
        }
    }

    private static String getSed() {
        return new SimpleDateFormat(SED_FORMAT).format(new Date());
    }

    private static String getSig(String tokens, String sed) throws NoSuchAlgorithmException, UnsupportedEncodingException {
        MessageDigest md = MessageDigest.getInstance("SHA1");
        String toDigest = toDigest(tokens, sed);
        md.update(toDigest.getBytes());
        String sig = Base64.encodeToString(md.digest(), Base64.NO_WRAP);
        return URLEncoder.encode(sig, "UTF-8");
    }

    private static String toDigest(String tokens, String sed) {
        return MessageFormat.format("{0}{1}{2}{3}", MAGIC_STRING, tokens, SED, sed);
    }

	/**
	 * Retrieve base URL.
	 * 
	 * @param page
	 * @return
	 */
	protected String getBaseUrl(String page) {
		return "http://api.allocine.fr/rest/v3/" + page + "?partner=100043982026";
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

        final HttpParams httpParameters = new BasicHttpParams();
        httpParameters.setParameter(CoreProtocolPNames.USER_AGENT, "Dalvik/1.6.0 (Linux; U; Android 4.2.2; Nexus 4 Build/JDQ39E)");

        final HttpClient httpclient = new DefaultHttpClient(httpParameters);

		// Setup the get request
        HttpGet httpGetRequest = null;
        try {
            httpGetRequest = new HttpGet(encode(new URI(url)));
        } catch (URISyntaxException e) {
            e.printStackTrace();
            return null;
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            return null;
        }

        // Execute the request in the client
		HttpResponse httpResponse = httpclient.execute(httpGetRequest);

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
				movie.isOriginalLanguage = jsonMovie.getJSONObject("version").getString("original")
						.equals("true");
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
		
		String url = getBaseUrl("media") + "&mediafmt=mp4-lc&code=" + movie.trailerCode + "&format=json";
		try {
			String json = downloadUrl(url);
			JSONObject jsonTrailer = new JSONObject(json).getJSONObject("media");
			if(jsonTrailer.has("rendition"))
				return jsonTrailer.getJSONArray("rendition").getJSONObject(0).getString("href");
			return null;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}

	}
}
