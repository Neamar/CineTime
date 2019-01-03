package fr.neamar.cinetime.api;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Locale;

import fr.neamar.cinetime.BuildConfig;
import fr.neamar.cinetime.objects.Display;
import fr.neamar.cinetime.objects.DisplayList;
import fr.neamar.cinetime.objects.Movie;
import fr.neamar.cinetime.objects.Theater;

public class APIHelper {
    private static final String TAG = "APIHelper";

    /**
     * Retrieve base URL.
     *
     */
    private String getBaseUrl(String page) {
        return "http://api.allocine.fr/rest/v3/" + page + "?partner=YW5kcm9pZC12M3M";
    }

    /**
     * Download an url using GET.
     *
     */
    private String downloadUrl(String url) throws IOException {
        Log.v(TAG, "Downloading " + url);

        // Setup the get request
        URL httpGetRequest = new URL(url);

        HttpURLConnection urlConnection = (HttpURLConnection) httpGetRequest.openConnection();
        InputStream is = urlConnection.getInputStream();

        // Grab the response
        BufferedReader reader;
        try {
            reader = new BufferedReader(new InputStreamReader(is, "UTF-8"));

            StringBuilder builder = new StringBuilder();
            String aux;
            while ((aux = reader.readLine()) != null) {
                builder.append(aux);
            }

            return builder.toString();
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }

        return "";
    }

    private JSONArray downloadTheatersList(String query) throws IOException {
        String url;
        try {
            url = getBaseUrl("search") + "&filter=theater&q=" + URLEncoder.encode(query, "UTF-8") + "&count=25&format=json";
        } catch (UnsupportedEncodingException e1) {
            url = getBaseUrl("search") + "&filter=theater&q=" + query + "&count=25&format=json";
        }

        if(BuildConfig.USE_MOCKS) {
            url = "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/cinemas-search.json";
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

    private JSONArray downloadTheatersListGeo(String lat, String lon) throws IOException {
        String url;
        try {
            url = getBaseUrl("theaterlist") + "&lat=" + URLEncoder.encode(lat, "UTF-8") + "&long=" + URLEncoder.encode(lon, "UTF-8") + "&radius=50" + "&count=25&format=json";
        } catch (UnsupportedEncodingException e1) {
            url = getBaseUrl("theaterlist") + "&lat=" + lat + "&long=" + lon + "&radius=25" + "&count=25&format=json";
        }

        if(BuildConfig.USE_MOCKS) {
            url = "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/cinemas-gps.json";
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

    /**
     * Download all movies for the specified theater.
     *
     * @param theaterCode Code, or a comma separated list of code to load.
     */
    public DisplayList downloadMoviesList(String theaterCode) {

        DisplayList displayList = new DisplayList();

        String url = getBaseUrl("showtimelist") + "&theaters=" + theaterCode + "&format=json";

        if(BuildConfig.USE_MOCKS) {
            url = "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/6f2ae30320e9e93807268f3a3772cdd8bba90987/cinema.json";
        }

        String json;
        try {
            json = downloadUrl(url);
        } catch (Exception e) {
            displayList.noDataConnection = true;
            return displayList;
        }

        try {
            // Instantiate a JSON object from the request response
            JSONObject jsonObject = new JSONObject(json);
            JSONObject feed = jsonObject.getJSONObject("feed");

            JSONArray theaters = feed.getJSONArray("theaterShowtimes");
            // Iterate over each theaters
            for (int i = 0; i < theaters.length(); i++) {
                JSONObject theater = theaters.getJSONObject(i);
                String theaterName = theater.getJSONObject("place").getJSONObject("theater").getString("name");

                if (theater.has("movieShowtimes")) {
                    JSONArray showtimes = theater.getJSONArray("movieShowtimes");
                    for (int j = 0; j < showtimes.length(); j++) {
                        JSONObject showtime = showtimes.getJSONObject(j);

                        if (theaters.length() > 1) {
                            // Add theater name when multiple theaters returned
                            showtime.put("theater", theaterName);
                        }
                        displayList.jsonArray.put(showtime);
                    }
                }
            }

            // Only return theater when it is unique
            if (theaters.length() == 1) {
                JSONObject jsonTheater = theaters.getJSONObject(0).getJSONObject("place").getJSONObject("theater");
                displayList.theater.code = jsonTheater.getString("code");
                displayList.theater.title = jsonTheater.getString("name");
                displayList.theater.location = jsonTheater.getString("address");
                displayList.theater.zipCode = jsonTheater.getString("postalCode");
            }
        } catch (JSONException e) {
            Log.e("JSON", "Error parsing JSON for " + theaterCode);
            e.printStackTrace();
            // Keep our default empty array for displayList.jsonArray
        }

        return displayList;
    }

    public ArrayList<Theater> findTheaters(String query) throws IOException {
        ArrayList<Theater> resultsList = new ArrayList<>();

        JSONArray jsonResults = downloadTheatersList(query);

        for (int i = 0; i < jsonResults.length(); i++) {
            JSONObject jsonTheater;
            try {
                jsonTheater = jsonResults.getJSONObject(i);


                Theater theater = new Theater();
                theater.code = jsonTheater.getString("code");
                theater.title = jsonTheater.getString("name");
                theater.location = jsonTheater.getString("address");
                theater.city = jsonTheater.getString("city");

                resultsList.add(theater);

            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return resultsList;
    }

    public ArrayList<Theater> findTheatersGeo(String lat, String lon) throws IOException {

        ArrayList<Theater> resultsList = new ArrayList<>();

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

    private JSONObject downloadMovie(String movieCode) {
        String url = getBaseUrl("movie") + "&code=" + movieCode + "&profile=small&format=json";

        if(BuildConfig.USE_MOCKS) {
            url = "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/film.json";
        }

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
        HashMap<String, Movie> moviesHash = new HashMap<>();

        for (int i = 0; i < jsonResults.length(); i++) {
            JSONObject jsonMovie, jsonShow;

            try {
                jsonMovie = jsonResults.getJSONObject(i);
                jsonShow = jsonMovie.getJSONObject("onShow").getJSONObject("movie");

                String code = jsonShow.getString("code");

                Movie movie;
                if (moviesHash.containsKey(code)) {
                    movie = moviesHash.get(code);
                } else {
                    movie = new Movie();
                }

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
                    JSONObject jsonCertificate = jsonShow.getJSONObject("movieCertificate").getJSONObject("certificate");
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
                    movie.genres = jsonGenres.getJSONObject(0).getString("$").toLowerCase(Locale.FRANCE);
                    for (int j = 1; j < jsonGenres.length(); j++) {
                        movie.genres += ", " + jsonGenres.getJSONObject(j).getString("$").toLowerCase(Locale.FRANCE);
                    }
                }

                if (jsonShow.has("trailer")) {
                    JSONObject jsonTrailer = jsonShow.getJSONObject("trailer");
                    movie.trailerCode = jsonTrailer.optString("code", "");
                }

                Display display = new Display();
                try {
                    display.display = jsonMovie.getString("display");
                } catch (JSONException e) {
                    // This movie is not displayed this week, skip.
                    continue;
                }

                display.isOriginalLanguage = jsonMovie.getJSONObject("version").getString("original").equals("true");
                if (jsonMovie.has("screenFormat") && jsonMovie.getJSONObject("screenFormat").has("$")) {
                    display.is3D = jsonMovie.getJSONObject("screenFormat").getString("$").contains("3D");
                    display.isIMAX = jsonMovie.getJSONObject("screenFormat").getString("$").contains("IMAX");
                }
                if(jsonMovie.has("screen") && jsonMovie.getJSONObject("screen").has("$")) {
                    display.screen = jsonMovie.getJSONObject("screen").getString("$");
                }

                if (jsonMovie.has("theater")) {
                    // displaying unified view, need to remind the display of
                    // the theater.
                    display.theater = jsonMovie.getString("theater");
                }
                movie.displays.add(display);
                moviesHash.put(code, movie);

            } catch (JSONException e) {
                throw new RuntimeException("An error occured while loading datas for " + theaterCode + ": " + e.getMessage());
            }
        }

        // Build final ArrayList, to be used in adapter
        ArrayList<Movie> resultsList = new ArrayList<>(moviesHash.values());

        // Sort displays
        for (Movie movie : resultsList) {
            Collections.sort(movie.displays, Collections.reverseOrder());
        }

        // Sort movies by rating
        Collections.sort(resultsList, Collections.reverseOrder());
        return resultsList;
    }

    public Movie findMovie(Movie movie) {
        JSONObject jsonMovie = downloadMovie(movie.code);
        movie.synopsis = jsonMovie.optString("synopsisShort", "");
        return movie;
    }

    public String downloadTrailerUrl(Movie movie) {
        if (movie.trailerCode.equals(""))
            return null;

        String url = getBaseUrl("media") + "&mediafmt=mp4-lc&code=" + movie.trailerCode + "&format=json";
        try {
            String json = downloadUrl(url);
            JSONObject jsonTrailer = new JSONObject(json).getJSONObject("media");
            if (jsonTrailer.has("rendition"))
                return jsonTrailer.getJSONArray("rendition").getJSONObject(0).getString("href");
            return null;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }

    }
}
