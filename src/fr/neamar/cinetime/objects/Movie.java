package fr.neamar.cinetime.objects;

import java.util.Calendar;

public class Movie {
	public String code;

	public String title;
	public String poster;
	public String directors = "";
	public String actors = "";
	public String genres = "";
	public String synopsis = "";
	public int duration;

	public String pressRating = "0";
	public String userRating = "0";

	public Boolean isOriginalLanguage;
	public Boolean is3D = false;

	public String display;

	public String getDuration() {
		return (duration / 3600) + "h" + String.format("%02d", (duration / 60) % 60);
	}

	public String getDisplay() {
		String optimisedDisplay = display;
		// "Séances du"
		optimisedDisplay = optimisedDisplay.replaceAll(
				"Séances du ([a-z]{2})[a-z]+ ([0-9]+) [a-zéû]+ 20[0-9]{2} :", "$1 $2 :");

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

		if (isSimilar && days.length == 7) {
			optimisedDisplay = lowlightHour("TLJ : " + days[0]) + "";
		} else {
			// Lowlight every days but today.
			String today = Integer.toString((Calendar.getInstance().get(Calendar.DAY_OF_MONTH)));
			days = optimisedDisplay.split("\r\n");
			optimisedDisplay = "";
			for (int i = 0; i < days.length; i++) {
				if (!days[i].contains(" " + today + " :")) {
					optimisedDisplay += lowlightDay(days[i]) + "<br>";
				} else {
					optimisedDisplay += lowlightHour(days[i]) + "<br>";
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
		return (isOriginalLanguage ? " <i>VO</i>" : "") + (is3D ? " <strong>3D</strong>" : "");
	}
}
