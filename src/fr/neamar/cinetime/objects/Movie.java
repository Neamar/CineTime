package fr.neamar.cinetime.objects;

import java.util.ArrayList;

public class Movie {
	public String code;

	public String title;
	public String poster;
	public String directors = "";
	public String actors = "";
	public String genres = "";
	public int duration;
	
	public String pressRating = "0";
	public String userRating = "0";
	
	public Boolean isOriginalLanguage;
	public Boolean is3D = false;

	public String display;

	public String getDuration() {
		return (duration / 3600) + "h"
				+ String.format("%02d", (duration / 60) % 60);
	}

	public String getDisplay() {
		String optimisedDisplay = display;
		// "Séances du"
		optimisedDisplay = optimisedDisplay.replaceAll(
				"Séances du ([a-z]{2})[a-z]+ ([0-9]+) [a-z]+ 20[0-9]{2} :",
				"$1 $2 :");

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
			optimisedDisplay = "T.L.J : " + days[0];
		}

		return optimisedDisplay;
	}
	
	public int getPressRating()
	{
		return (int) (Float.parseFloat(pressRating) * 10);
	}
	
	public int getUserRating()
	{
		return (int) (Float.parseFloat(userRating) * 10);
	}
	
	public int getRating()
	{
		if(!pressRating.equals("0") && !userRating.equals("0"))
			return (int) ((Float.parseFloat(pressRating) * 10) + (Float.parseFloat(userRating) * 10)) / 2;
		else if(pressRating.equals("0") && !userRating.equals("0"))
			return getUserRating();
		else if(!pressRating.equals("0") && userRating.equals("0"))
			return getPressRating();
		
		return 0;
	}
}
