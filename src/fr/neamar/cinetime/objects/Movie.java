package fr.neamar.cinetime.objects;

import android.content.Context;
import android.text.Html;

import java.util.Calendar;

import fr.neamar.cinetime.R;

public class Movie {
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

	public Boolean isOriginalLanguage = false;
	public Boolean is3D = false;

	public String display;

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

	public String getDisplay(Context ctx) {
		String optimisedDisplay = display;
		// "Séances du"
		optimisedDisplay = optimisedDisplay.replaceAll(
				"Séances du ([a-z]{2})[a-z]+ ([0-9]+) [a-zéû]+ 20[0-9]{2} :", "$1 $2 :");

        //TODO optimise times on uk results
        optimisedDisplay = optimisedDisplay.replaceAll(
                "Séances du", ctx.getString(R.string.showtimes_on));

		// "(film à ..)"
		optimisedDisplay = optimisedDisplay.replaceAll(" \\([^\\)]+\\)", "");

		// "15:30, "
		optimisedDisplay = optimisedDisplay.replaceAll(",", "");

		// Same display each day ?
		String[] days = optimisedDisplay.replaceAll(".+ : ", "").split("\r\n");
		Boolean isSimilar = true;
		String firstOne = days[0];
		for (int i = 1; i < days.length; i++) {
			if (!firstOne.equals(days[i])) {
				isSimilar = false;
				break;
			}
		}

		String today = Integer.toString((Calendar.getInstance().get(Calendar.DAY_OF_MONTH)));

		if (isSimilar && days.length == 7) {
			if (!optimisedDisplay.contains(" " + today + " :")) {
				optimisedDisplay = lowlightHour(ctx.getString(R.string.next_week)+
                        "<br>"+ctx.getString(R.string.everyday)+" : " + days[0]) + "";
			} else {
				optimisedDisplay = lowlightHour(ctx.getString(R.string.everyday) +" : " + days[0]) + "";
			}
		} else {
			// Lowlight every days but today.

			days = optimisedDisplay.split("\r\n");
			optimisedDisplay = "";
			for (int i = 0; i < days.length; i++) {
				if (!days[i].contains(" " + today + " :")) {
					optimisedDisplay += lowlightDay(days[i]) + "<br>";
				} else {
					// Note : it isn't "+=", but "=" : we remove past entries.
					optimisedDisplay = lowlightHour(days[i]) + " <br>"; // Space
																		// required
																		// to
																		// fixing
																		// trimming
																		// bug.
				}
			}

			// Remove final <br>
			optimisedDisplay = optimisedDisplay.substring(0, optimisedDisplay.length() - 5);
		}

		return optimisedDisplay;
	}

	protected String lowlightDay(String day) {
		return "<font color=\"silver\">" + day + "</font>";
	}

	protected String lowlightHour(String day) {
		// Today : lowlight display in the past hours
		Calendar now = Calendar.getInstance();
		int current_hour = now.get(Calendar.HOUR_OF_DAY);
		int current_minute = now.get(Calendar.MINUTE);

		String[] hours = day.replaceAll(".+ : ", "").split(" ");

		String nextVisibleDisplay = "$"; // By default, last one.
		for (int j = 0; j < hours.length; j++) {
			String[] parts = hours[j].split(":");
			int hour = Integer.parseInt(parts[0]);
			int minute = Integer.parseInt(parts[1]);
			if (hour > current_hour || (hour == current_hour && minute > current_minute)) {
				nextVisibleDisplay = hours[j];
				break;
			}
		}

		return day.replaceAll("(.+ :)(.+)(" + nextVisibleDisplay + ")",
				"<strong>$1</strong><font color=\"#9A9A9A\">$2</font>$3");
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

	public String getDisplayDetails() {
		return (isOriginalLanguage ? " <i>VO</i>" : "")
				+ (is3D ? " <strong>3D</strong>" : "")
				+ (certificate != 0 ? " <font color=\"#8B0000\">" + getShortCertificate()
						+ "</font>" : "");
	}

	/**
	 * Generate a short text to be shared. Needs the theater this instance
	 * refers to.
	 * 
	 * @param theater
	 * @return
	 */
	public String getSharingText(Context ctx, String theater) {
		String sharingText = "";
		sharingText += this.title + " (" + getDuration() + ")\r\n";

		if (!this.synopsis.equals(""))
			sharingText += this.synopsis + "\r\n\r\n";

		String htmlDisplayDetails = "<strong>" + theater + "</strong>" + this.getDisplayDetails()
				+ " :<br>" + this.getDisplay(ctx);

		sharingText += Html.fromHtml(htmlDisplayDetails).toString();
		return sharingText;
	}
}
