package fr.neamar.cinetime.ui;

import android.graphics.Bitmap;

public class Poster {
	public int level;
	public int levelRequested;
	public Bitmap bmp;
	
	public Poster(int level, int levelRequested, Bitmap bmp) {
		super();
		this.level = level;
		this.levelRequested = levelRequested;
		this.bmp = bmp;
	}
	
	public boolean continueLoading(){
		return (level < levelRequested);
	}
}
