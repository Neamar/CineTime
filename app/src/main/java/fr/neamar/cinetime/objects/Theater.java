package fr.neamar.cinetime.objects;

/**
 * Holkds datas for one theater
 *
 * @author neamar
 */
public class Theater {
    public String code;
    public String title;
    public String location;
    public String zipCode;
    public String city;
    public double distance = -1;

    @Override
    public String toString() {
        return title;
    }
}
