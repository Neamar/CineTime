package fr.neamar.cinetime.api;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Calendar;

import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONArray;
import org.json.JSONObject;

import android.util.Log;

public class APIHelper {

	protected static String getBaseUrl(String page)
	{
		return "http://api.allocine.fr/rest/v3/" + page + "?partner=YW5kcm9pZC12M3M";
	}
	
	public static JSONArray findTheater(String query)
	{
		String url = getBaseUrl("search") + "&filter=theater&q=" + query.replace("&", "") + "&format=json";

		try {
			// Create a new HTTP Client
			DefaultHttpClient defaultClient = new DefaultHttpClient();
			// Setup the get request
			HttpGet httpGetRequest = new HttpGet(url);

			// Execute the request in the client
			HttpResponse httpResponse = defaultClient
					.execute(httpGetRequest);
			
			// Grab the response
			BufferedReader reader = new BufferedReader(
					new InputStreamReader(httpResponse.getEntity()
							.getContent(), "UTF-8"));
			String json = reader.readLine();

			// Instantiate a JSON object from the request response
			JSONObject jsonObject = new JSONObject(json);
			
			JSONObject feed = jsonObject.getJSONObject("feed");
			
			if(feed.getInt("totalResults") > 0)
				return feed.getJSONArray("theater");
			else
				return new JSONArray();
			
		} catch (Exception e) {
			Log.e("wtf", e.getMessage());
			e.printStackTrace();
		}
		
		return new JSONArray();
	}
	
	public static JSONArray findMovies(String code)
	{
		Calendar date = Calendar.getInstance();
		String today = date.get(Calendar.YEAR) + "-" + String.format("%02d", date.get(Calendar.MONTH) + 1) + "-" + String.format("%02d", date.get(Calendar.DAY_OF_MONTH));

		String url = getBaseUrl("showtimelist") + "&theaters=" + code + "&format=json";

		try {
			// Create a new HTTP Client
			DefaultHttpClient defaultClient = new DefaultHttpClient();
			// Setup the get request
			HttpGet httpGetRequest = new HttpGet(url);

			// Execute the request in the client
			HttpResponse httpResponse = defaultClient
					.execute(httpGetRequest);
			
			// Grab the response
			BufferedReader reader = new BufferedReader(
					new InputStreamReader(httpResponse.getEntity()
							.getContent(), "UTF-8"));
			String json = reader.readLine();

			// Instantiate a JSON object from the request response
			JSONObject jsonObject = new JSONObject(json);
			
			JSONObject feed = jsonObject.getJSONObject("feed");
			
			if(feed.getInt("totalResults") > 0)
				return feed.getJSONArray("theaterShowtimes").getJSONObject(0).getJSONArray("movieShowtimes");
			else
				return new JSONArray();
			
		} catch (Exception e) {
			Log.e("wtf", e.getMessage());
			e.printStackTrace();
		}
		
		return new JSONArray();
	}
}
