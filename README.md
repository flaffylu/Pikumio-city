# Pikumio City – Android-App

Das fertige Projekt für die APK. Das Spiel läuft darin komplett **offline**:
Three.js, die Schriftarten und alle 12 Lieder liegen mit in der App.

## So bekommst du die APK (ohne etwas zu installieren)

1. Auf [github.com](https://github.com) anmelden und ein **neues Repository** anlegen
   (z. B. `pikumio-city`). Keine Datei ankreuzen, einfach leer lassen.
2. Auf **„uploading an existing file"** klicken und **alle** Dateien und Ordner aus
   diesem Projekt ins Browserfenster ziehen (`.github`, `android`, `www`,
   `package.json`, `package-lock.json`, `capacitor.config.json`, …).
   Unten auf **Commit changes** klicken.
3. Oben auf den Reiter **Actions** gehen. Dort läuft „APK bauen" von selbst los.
   Beim ersten Mal musst du einmal auf **„I understand my workflows, go ahead and
   enable them"** klicken.
4. Nach etwa 5 Minuten ist der Punkt grün. Den Lauf anklicken und unten unter
   **Artifacts** `pikumio-city-apk` herunterladen. Darin liegt `pikumio-city.apk`.
5. Die Datei aufs Handy kopieren und antippen. Android fragt einmal, ob es Apps
   aus dieser Quelle installieren darf – erlauben, fertig.

## Gut zu wissen

* Es ist eine **Debug-APK**. Zum Selbst-Installieren und Weitergeben reicht das.
  Für den Play Store bräuchte es zusätzlich einen Signatur-Schlüssel.
* Die App braucht **kein Internet** und keine Berechtigungen.
* Größe: rund 40 MB, davon 34 MB Musik.
* Querformat, Vollbild, der Bildschirm schaltet sich beim Spielen nicht ab.
* Spielstände liegen im Speicher der App. Beim Deinstallieren sind sie weg.

## Wenn sich das Spiel ändert

```bash
python3 -I pack.py        # neue Spielversion nach www/ packen
npx cap copy android      # und in das Android-Projekt kopieren
```

Danach die geänderten Dateien wieder hochladen, der Build startet erneut.
Für eine neue Version in `android/app/build.gradle` `versionCode` und
`versionName` hochzählen.

## Projektaufbau

| Ordner / Datei | Inhalt |
| --- | --- |
| `www/` | das Spiel selbst: `index.html`, `vendor/three`, `fonts`, `music` |
| `android/` | das fertige Android-Projekt (Capacitor) |
| `.github/workflows/android.yml` | baut die APK bei GitHub |
| `pack.py` | packt eine neue Spielversion nach `www/` |
| `icons.py` | zeichnet App-Icon und Startbild neu |

## Selbst bauen statt bei GitHub

Mit Android Studio oder dem Android-SDK auf dem eigenen Rechner:

```bash
npm install
npx cap copy android
cd android && ./gradlew assembleDebug
# Ergebnis: android/app/build/outputs/apk/debug/app-debug.apk
```
