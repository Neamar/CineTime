import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ShowtimeDialog extends StatelessWidget {
  ShowtimeDialog({
    Key? key,
    this.movie,
    required this.theater,
    required this.showtime,
  }) :  movieTitle = movie?.title ?? 'Titre inconnu',
        dateDisplay = AppResources.formatterFullDateTime.format(showtime.dateTime), super(key: key);

  final Movie? movie;
  final String movieTitle;
  final Theater theater;
  final ShowTime showtime;
  final String dateDisplay;

  static void open({required BuildContext context, Movie? movie, required Theater theater, required ShowTime showtime}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          clipBehavior: Clip.antiAlias,
          child: ShowtimeDialog(
            movie: movie,
            theater: theater,
            showtime: showtime,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            movieTitle,
            style: context.textTheme.headline4,
            textAlign: TextAlign.center,
          ),
          AppResources.spacerLarge,
          Text(
            theater.name,
            style: context.textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          AppResources.spacerSmall,
          Text(
            dateDisplay,
            style: context.textTheme.subtitle1,
            textAlign: TextAlign.center,
          ),
          AppResources.spacerSmall,
          Text(
            showtime.spec.toString(),
            style: context.textTheme.headline6,
          ),
          AppResources.spacerLarge,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Partager la séance',
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _share,
                ),
              ),
              if (showtime.ticketingUrl != null)...[
                AppResources.spacerLarge,
                Tooltip(
                  message: 'Réserver la séance',
                  child: IconButton(
                    icon: const Icon(Icons.confirmation_number_outlined),
                    onPressed: _openBookingUrl,
                  ),
                ),
              ],
              AppResources.spacerLarge,
              Tooltip(
                message: 'Ajouter au calendrier',
                child: IconButton(
                  icon: const Icon(CineTimeIcons.calendar),
                  onPressed: _addToCalendar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _share() => Share.share(
'''$movieTitle [${showtime.spec}]
${theater.name}
$dateDisplay'''
  );

  Future<void> _openBookingUrl() => launchUrlString(showtime.ticketingUrl!, mode: LaunchMode.externalApplication);

  Future<void> _addToCalendar() => Add2Calendar.addEvent2Cal(Event(
    title: movieTitle,
    description: 'Séance de cinéma pour $movieTitle en ${showtime.spec}' + (showtime.ticketingUrl != null ? '\n\nRéservation:\n${showtime.ticketingUrl}' : ''),
    location: theater.name + '\n' + theater.fullAddress,
    startDate: showtime.dateTime,
    endDate: showtime.dateTime.add(movie?.duration ?? const Duration(hours: 2)),
  ));
}