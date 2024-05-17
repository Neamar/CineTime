import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/displayable_exception.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Display a card suggesting to update the app if an update is available.
/// If the user accepts, the app will be updated using native Play Store Immediate Update system.
/// /!\ Please mind that this CANNOT be tested locally (See https://github.com/jonasbark/flutter_in_app_update/issues/87).
class UpdateAppWidget extends StatelessWidget {
  const UpdateAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUpdateInfo>(
      future: InAppUpdate.checkForUpdate(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final appUpdateInfo = snapshot.data!;
        if (appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable && appUpdateInfo.immediateUpdateAllowed) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppResources.colorRed,
                    size: 40,
                  ),
                  AppResources.spacerSmall,
                  const Text(
                    'Cependant, une mise à jour est disponible.\nPeut-être que celle-ci résoudra le problème ?',
                    textAlign: TextAlign.center,
                  ),
                  AppResources.spacerMedium,
                  FilledButton(
                    onPressed: () async {
                      try {   // TODO use AsyncTaskBuilder
                        await InAppUpdate.performImmediateUpdate();
                      } catch(e, s) {
                        reportError(e, s);
                        if (context.mounted) showError(context, const DisplayableException('Impossible de mettre à jour l\'application\nVeuillez essayer manuellement depuis le Play Store.'));
                      }
                    },
                    child: const Text('Mettre à jour l\'application'),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
