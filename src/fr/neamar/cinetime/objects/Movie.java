package fr.neamar.cinetime.objects;

public class Movie {
	public String code;

	public String title;
	public String poster;
	public int duration;
	public String pressRating = "0";
	public String userRating = "0";
	public Boolean isOriginalLanguage;
	public Boolean is3D = false;

	public String display;

	public String getDuration() {
		return (duration / 3600) + ":"
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
}
