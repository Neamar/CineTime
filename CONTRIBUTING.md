# Contribuer à CinéTime

## Installation locale
Le projet est codé en Flutter. `git clone`, puis importer le projet dans Android Studio ou VSCode avec le plugin Flutter installé.

## Publier une nouvelle version sur le Play Store
Mettre à jour `pubspec.yaml` avec une nouvelle version.

S'assurer que l'on a un fichier `key.properties` dans le dossier Android:

```
storePassword=<pwd>
keyPassword=<pwd>
keyAlias=<key>
storeFile=/home/path/to/keystore
```

S'assurer que tout fonctionne sur un émulateur (qui utilisera des données de mock), puis:

```sh
flutter build appbundle
```

Envoyer l'aab sur le Play Store, idéalement en "Open Testing".
