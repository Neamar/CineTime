package fr.neamar.cinetime;

import android.os.Bundle;
import android.app.Activity;
import android.view.Menu;

public class TheatersActivity extends Activity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_theaters);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_theaters, menu);
        return true;
    }
}
