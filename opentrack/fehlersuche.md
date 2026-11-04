# Fehlersuche: opentrack funktioniert im Fenster, aber nicht im Landwirtschafts-Simulator 25 (LS25)

Wenn sich der Oktopus im opentrack-Fenster bewegt, funktionieren deine Kamera und die Gesichtserkennung bereits einwandfrei!
Dass die Kopfbewegungen im Spiel noch nicht ankommen, liegt meistens an einer Kleinigkeit bei der Übergabe zwischen opentrack und dem Spiel.

Gehe diese Schritte bitte der Reihe nach durch – vom einfachsten Schnelltest bis zu den Systemeinstellungen:

---

## 1. Fahrerkabine prüfen (Innenansicht)

### Warum:
Am deutlichsten siehst du die Kopfbewegungen in der **Innenansicht der Fahrerkabine**. In der Außenansicht hinter dem Fahrzeug bleibt die Kamera starr – das ist normal und kein Fehler.

### So testest du es:
1. Steige im Spiel in ein Fahrzeug (z. B. einen Traktor).
2. Wechsle die Kameraansicht (Taste **C** auf der Tastatur oder die entsprechende Taste auf deinem Controller), bis du **in der Fahrerkabine** sitzt.
3. Bewege jetzt deinen Kopf.

---

## 2. Installations-Update einspielen (Wichtig!)

### Warum:
Der Landwirtschafts-Simulator 25 startet über einen kleinen Starter (`FarmingSimulator2025.exe`), der das eigentliche Spiel im Unterordner `x64` aufruft. Beendet sich dieser Starter, hat die alte Version unseres Installationsskripts opentrack gleich mit geschlossen. Das aktualisierte Skript lässt opentrack weiterlaufen, bis das eigentliche Spiel beendet ist, und opentrack Setup schlägt dir den richtigen Dateinamen vor.

### So spielst du das Update ein:
1. Beende das Spiel und wechsle auf dem Steam Deck / SteamOS in den **Desktop-Modus** (**Steam-Taste** → **Ein/Aus** → **Zum Desktop wechseln**).
2. Öffne die **Konsole** (**Anwendungsmenü** unten links → **System** → **Konsole**).
3. Kopiere diesen Befehl, füge ihn in die Konsole ein (**Strg+Umschalt+V**) und drücke **Enter**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/tylerstyle/support/main/opentrack/install-opentrack.sh | bash
   ```
4. Das Skript zeigt an, was es von der alten Installation löscht, und fragt nach: mit **Enter** bestätigen. Deine opentrack-Einstellungen bleiben dabei erhalten. Warte, bis der Vorgang mit der Meldung **`All done!`** abgeschlossen ist (das dauert ein paar Minuten).
5. **Wichtig:** Starte den Landwirtschafts-Simulator 25 jetzt einmal kurz ganz normal über Steam und beende ihn wieder. Dadurch wird das Startskript des Spiels im Hintergrund auf den neuen Stand gebracht.

---

## 3. Ist die Startoption in Steam aktiv?

### Warum:
opentrack muss im selben geschützten Bereich (Proton-Prefix) wie das Spiel gestartet werden. Wenn die Startoption in Steam fehlt, startet opentrack beim Spielstart nicht mit.

### So prüfst du es:
1. Öffne im Desktop-Modus **opentrack Setup** (Symbol auf dem Desktop).
2. Schau in die Auswahlliste der Spiele:
   - Steht hinter Farming Simulator 25 der Zusatz **`(opentrack launch option set)`**?
   - **Ja:** Die Startoption ist bereits aktiv! Klicke auf **Abbrechen** und gehe weiter zu Schritt 4.
   - **Nein (Zusatz fehlt):** Trage die Startoption in Steam ein:
     1. Öffne Steam → Rechtsklick auf **Farming Simulator 25** → **Eigenschaften** → Reiter **Allgemein**.
     2. Trage im Feld **Startoptionen** genau diese Zeile ein:
        ```bash
        ~/.local/bin/opentrack-launcher %command%
        ```
     3. Starte das Spiel einmal kurz über Steam, beende es wieder und öffne opentrack Setup erneut.

---

## 4. Spielerkennung auf die Spieldatei anpassen (Game detection)

### Warum:
Damit opentrack automatisch mit dem Tracking beginnt, muss es auf die Datei des Hauptspiels (`FarmingSimulator2025Game.exe`) warten, nicht auf den Starter.

> [!CAUTION]
> **Wichtig für das Steam Deck:** Berühre das opentrack-Fenster **nicht** mit dem Touchscreen! Durch einen Fehler in Proton schließt sich opentrack bei Berührung sofort. Verwende immer das **rechte Trackpad** (Taste R2 = Klick) oder eine angeschlossene Maus.

### So passt du es an:
1. Öffne **opentrack Setup** auf dem Desktop (Spiel vorher beenden).
2. Wähle **Farming Simulator 25** aus und bestätige das Hinweisfenster mit **OK**.
3. Klicke im opentrack-Hauptfenster unten links auf **Options**.
4. Klicke oben auf den Reiter **Game detection** (Spielerkennung).
5. Stelle sicher, dass ganz oben bei **Start profiles from game executable names in this list** ein Haken gesetzt ist.
6. Steht in der Liste schon eine Zeile mit `FarmingSimulator2025.exe` (ohne „Game“), klicke doppelt auf diesen Namen, um ihn zu ändern. Sonst klicke auf das **+** Symbol, um eine Zeile hinzuzufügen, und klicke doppelt in das Feld unter **Executable**.
7. Trage den Namen ein, den dir das Hinweisfenster beim Öffnen genannt hat. Normalerweise ist das:
   - `FarmingSimulator2025Game.exe`
   - *(Hinweis: Falls du die deutsche DVD- oder GIANTS-Direktkauf-Version nutzt, trage stattdessen `LandwirtschaftsSimulator2025Game.exe` ein).*

   *(Keine Tastatur angeschlossen? Die Bildschirmtastatur öffnest du mit **Steam-Taste + X**.)*
8. Wähle in derselben Zeile unter **Profile** dein gewünschtes Profil aus (in der Regel `default.ini`).
9. Klicke unten auf **OK** und schließe opentrack.

---

## 5. Hintergrund-Test: Bleibt opentrack während des Spiels offen?

### Warum:
Dieser kurze Test bestätigt, dass unser Update aus Schritt 2 greift und opentrack während des Spielens stabil im Hintergrund aktiv bleibt.

### So testest du es:
1. Starte den LS25 im **Desktop-Modus** aus Steam.
2. Sobald du im Hauptmenü des Spiels bist, drücke **Alt + Tab** auf einer Tastatur oder schau in die Taskleiste am unteren Bildschirmrand:
   - **opentrack ist verschwunden:** opentrack wurde ungewollt beendet. Prüfe in diesem Fall nochmals Schritt 2 (Update ausführen) oder kontaktiere uns.
   - **opentrack ist noch da:** Wechsle mit **Alt + Tab** zum opentrack-Fenster (nur anschauen, nicht antippen!) und bewege den Kopf:
     - **Der Oktopus bewegt sich:** Perfekt, opentrack hat das Tracking von selbst gestartet. Wechsle mit **Alt + Tab** zurück ins Spiel und mach mit Schritt 6 weiter.
     - **Der Oktopus bewegt sich nicht:** Die Spielerkennung greift nicht. Prüfe Schritt 4 nochmal (Name genau so geschrieben? Haken gesetzt?).

---

## 6. Ausgabe-Einstellungen in opentrack prüfen (Output)

### Warum:
opentrack muss die Kopfbewegungen im passenden TrackIR-Format ausgeben und darf die Registrierung beim Beenden nicht löschen.

### So prüfst du es:
1. Öffne wieder **opentrack Setup** auf dem Desktop (Spiel vorher beenden) und klicke im Hinweisfenster auf **OK**.
2. Prüfe das Feld **Output**:
   - Hier muss **`freetrack 2.0 Enhanced`** ausgewählt sein.
3. Klicke auf das kleine Werkzeug-Symbol (Hammer/Schraubenschlüssel) direkt neben dem Feld Output:
   - Bei **Select interface** muss **`Enable both`** ausgewählt sein.
   - Stelle sicher, dass bei **`Clear location when tracking is stopped`** **KEIN Haken** gesetzt ist! *(Ein gesetzter Haken würde bei jedem Stoppen die Erkennungsinformationen für das Spiel löschen).*
4. Klicke auf **OK** und schließe opentrack.

---

## 7. Blickverfolgung im Spielmenü prüfen

### Warum:
Im Menü des Landwirtschafts-Simulators 25 gibt es eine Empfindlichkeitseinstellung für Kopf- und Blickverfolgung. Steht dieser Regler auf 0 %, werden Kopfbewegungen ignoriert.

### So prüfst du es:
1. Starte den LS25 und öffne im Hauptmenü die **Einstellungen** (Zahnrad-Symbol).
2. Suche in den allgemeinen Optionen nach der Einstellung für **Blickverfolgung** bzw. **Head Tracking / Eye Tracking**.
3. Stelle sicher, dass die Empfindlichkeit bzw. der Regler **nicht auf 0 %** steht.
4. Speichere die Einstellungen ab.

---

## 8. Hilfe zur Selbsthilfe: `log.txt` an uns schicken

Wenn es danach immer noch nicht funktioniert, protokolliert der LS25 beim Starten genau, was schiefgelaufen ist:

1. Öffne im Desktop-Modus den Dateimanager **Dolphin**.
2. Drücke **Strg + L**, um die Adresszeile oben einzublenden.
   *(Tipp: Auf dem Steam Deck öffnest du die Bildschirmtastatur mit **Steam-Taste + X**).*
3. Kopiere folgenden Pfad, füge ihn mit **Strg + V** ein und drücke **Enter**:
   ```
   ~/.local/share/Steam/steamapps/compatdata/2300320/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/
   ```
   *(Liegt dein Spiel auf der microSD-Karte, befindet sich der Ordner im entsprechenden compatdata-Verzeichnis auf der Speicherkarte).*
4. Öffne dort die Datei **`log.txt`** (z. B. durch Doppelklick mit KWrite).
5. Drücke **Strg + F** und suche nach dem Begriff `track`.
6. Schicke uns die Zeilen rund um diesen Treffer oder einfach die gesamte `log.txt` – wir schauen uns das sofort an!
