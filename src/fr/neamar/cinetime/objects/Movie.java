package fr.neamar.cinetime.objects;

import android.util.Log;

public class Movie {
	public String title;
	public int duration;
	public String pressRating;
	public String userRating;
	public Boolean isOriginalLanguage;
	public Boolean is3D;
	
	public String display;
	
	public String getDuration()
	{
		return (duration / 3600) + ":" + String.format("%02d", (duration / 60) % 60);
	}
	
	public String getDisplay()
	{
		String optimisedDisplay = display;
		// "Séances du"
		optimisedDisplay = optimisedDisplay.replaceAll("Séances du ([a-z]{2})[a-z]+ ([0-9]+) [a-z]+ 20[0-9]{2} :", "$1 $2 :");
		
		// "(film à ..)"
		optimisedDisplay = optimisedDisplay.replaceAll(" \\([^\\)]+\\)", "");
		
		//Same display each day ?
		String[] days = optimisedDisplay.replaceAll(".+ : ", "").split("\r\n");
		Boolean isSimilar = true;
		String firstOne = days[0];
		for(int i = 1; i < days.length; i++)
		{
			if(!firstOne.equals(days[i]))
			{
				isSimilar = false;
				break;
			}
		}
		
		if(isSimilar)
		{
			optimisedDisplay = "T.L.J : " + days[0];
		}
		
		
		return optimisedDisplay;
	}
}
