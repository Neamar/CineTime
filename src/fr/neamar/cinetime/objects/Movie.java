package fr.neamar.cinetime.objects;

import java.util.ArrayList;

import android.text.Html;

/**
 * Holds datas for one movie.
 * 
 * @author neamar
 * 
 */
public class Movie implements Comparable<Movie> {
	public String code;
	public String trailerCode = "";

	public String title;
	public String poster = null;
	public String directors = "";
	public String actors = "";
	public String genres = "";
	public String synopsis = "";
	public int duration;
	public int certificate = 0;
	public String certificateString = "";

	public String pressRating = "0";
	public String userRating = "0";

	public ArrayList<Display> displays = new ArrayList<Display>();

	public String getDuration() {
		if (duration > 0)
			return (duration / 3600) + "h" + String.format("%02d", (duration / 60) % 60);
		else
			return "NC";
	}

	public String getShortCertificate() {
		switch (this.certificate) {
		case 14004:
			return "-18";
		case 14002:
			return "-16";
		case 14044:
			return "-12!";
		case 14001:
			return "-12";
		case 14031:
			return "-10";
		case 14035:
			return "!";
		default:
			return "";
		}
	}

	public int getPressRating() {
		return (int) (Float.parseFloat(pressRating) * 10);
	}

	public int getUserRating() {
		return (int) (Float.parseFloat(userRating) * 10);
	}

	public int getRating() {
		if (!pressRating.equals("0") && !userRating.equals("0"))
			return (int) ((Float.parseFloat(pressRating) * 10) + (Float.parseFloat(userRating) * 10)) / 2;
		else if (pressRating.equals("0") && !userRating.equals("0"))
			return getUserRating();
		else if (!pressRating.equals("0") && userRating.equals("0"))
			return getPressRating();

		return 0;
	}

	public String getDisplays() {
		String ret = "";
		for (int i = 0; i < displays.size(); i++) {
			String displayDetails = displays.get(i).getDisplayDetails();
			if (displayDetails.equals("")) {
				displayDetails = "VF";
			}
			displayDetails = "<u>" + displayDetails + "</u> :<br>";

			ret += displayDetails;
			ret += displays.get(i).getDisplay();

			if (i < displays.size() - 1) {
				ret += "<br><br>";
			}
		}
		return ret;
	}

	public String getDisplayDetails() {
		return (certificate != 0 ? " <font color=\"#8B0000\">" + getShortCertificate() + "</font>" : "");
	}

	/**
	 * Generate a short text to be shared. Needs the theater this instance
	 * refers to.
	 * 
	 * @param theater
	 * @return
	 */
	public String getSharingText(String theater) {
		String sharingText = "";
		sharingText += this.title + " (" + getDuration() + ")\r\n";

		String htmlDisplayDetails = "<strong>" + theater + "</strong>" + this.getDisplayDetails() + " :<br>" + this.getDisplays();

		sharingText += Html.fromHtml(htmlDisplayDetails).toString();
		return sharingText;
	}

	@Override
	public int compareTo(Movie movie) {
		return this.getRating() - movie.getRating();
	}
}
