import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ShowtimeDialog extends StatefulWidget {
  const ShowtimeDialog({
    super.key,
    this.movie,
    required this.theater,
    required this.showtime,
  });

  final Movie? movie;
  final Theater theater;
  final ShowTime showtime;

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
  State<ShowtimeDialog> createState() => _ShowtimeDialogState();
}

class _ShowtimeDialogState extends State<ShowtimeDialog> {
  late final movieTitle = widget.movie?.title ?? 'Titre inconnu';
  late final dateDisplay = AppResources.formatterFullDateTime.format(widget.showtime.dateTime);

  late DateTime? endDate = widget.movie?.duration != null ? widget.showtime.dateTime.add(widget.movie!.duration) : null;
  bool isEndDateApprox = true;
  String? get endTimeDisplay => endDate != null ? AppResources.formatterTime.format(endDate!) : null;

  Future<void> _getEndTime() async {
    final ticketingUri = Uri.tryParse(widget.showtime.ticketingUrl ?? '-');
    if (ticketingUri != null) {
      try {
        final endTimeDate = await ApiClient.getShowEndTime(widget.showtime.dateTime, widget.movie?.duration, ticketingUri).timeout(const Duration(seconds: 15));
        if (endTimeDate != null) {
          endDate = endTimeDate;
          isEndDateApprox = false;
        }
      } catch (e, s) {
        // Ignore error, use default end time
        reportError(e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Movie title
          Text(
            movieTitle,
            style: context.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),

          // Theater name
          AppResources.spacerLarge,
          Text(
            widget.theater.name,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          // Start date and time
          AppResources.spacerSmall,
          Text(
            dateDisplay,
            style: context.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),

          // End time
          AppResources.spacerTiny,
          FutureBuilder<void>(
            future: _getEndTime(),
            builder: (context, snapshot) {
              return Tooltip(
                message: isEndDateApprox ? 'Heure approximative basée sur la durée' : 'Heure donnée par le cinéma',
                triggerMode: endDate != null ? TooltipTriggerMode.tap : null,
                showDuration: const Duration(seconds: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Caption
                    Text(
                      endDate == null
                          ? 'heure de fin inconnue'
                          : 'fin ${isEndDateApprox ? 'après' : 'à'} $endTimeDisplay',
                      style: context.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),

                    // Info icon
                    if (endDate != null)...[
                      AppResources.spacerTiny,
                      const Icon(Icons.info_outline),
                    ],

                    // Loader
                    if (snapshot.connectionState == ConnectionState.waiting)...[
                      AppResources.spacerTiny,
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Language
          AppResources.spacerSmall,
          Text(
            widget.showtime.spec.toDisplayString(widget.movie?.isFrench == true),
            style: context.textTheme.titleLarge,
          ),

          // Buttons
          AppResources.spacerLarge,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Share
              Tooltip(
                message: 'Partager la séance',
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _share,
                ),
              ),

              // Ticketing
              if (widget.showtime.ticketingUrl != null)...[
                AppResources.spacerLarge,
                Tooltip(
                  message: 'Réserver la séance',
                  child: IconButton(
                    icon: const Icon(Icons.local_activity_outlined, size: 28),
                    onPressed: _openBookingUrl,
                  ),
                ),
              ],

              // Agenda
              AppResources.spacerLarge,
              Tooltip(
                message: 'Ajouter au calendrier',
                child: IconButton(
                  icon: const Icon(Icons.calendar_month, size: 28),
                  onPressed: _addToCalendar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _share() => SharePlus.instance.share(ShareParams(
    text: '''$movieTitle [${widget.showtime.spec.toDisplayString(widget.movie?.isFrench == true)}]
${widget.theater.name}
$dateDisplay''',
  ));

  Future<void> _openBookingUrl() => launchUrlString(widget.showtime.ticketingUrl!, mode: LaunchMode.externalApplication);

  Future<void> _addToCalendar() => Add2Calendar.addEvent2Cal(Event(
    title: 'Cinema : $movieTitle',    // Adding 'Cinema' to the title makes Google Calendar show a nice picture automatically, make it easier to find in the calendar
    description: 'Séance de cinéma pour $movieTitle en ${widget.showtime.spec}${widget.showtime.ticketingUrl != null ? '\n\nRéservation:\n${widget.showtime.ticketingUrl}' : ''}\n\nRemarque: ${isEndDateApprox ? 'Heure de fin de séance approximative basée sur la durée du film' : 'Heure de fin de séance donnée par le cinéma'}',
    location: '${widget.theater.name}\n${widget.theater.fullAddress}',
    startDate: widget.showtime.dateTime,
    endDate: endDate ?? widget.showtime.dateTime.add(const Duration(hours: 2)),
  ));
}