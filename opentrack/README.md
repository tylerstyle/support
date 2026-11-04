# opentrack on Steam Machine / SteamOS

**[English](#english) · [Deutsch](#deutsch)**

One script that installs [opentrack](https://github.com/opentrack/opentrack) head tracking for Steam games
via [opentrack-launcher](https://github.com/markx86/opentrack-launcher), removes old installs, and fixes the
missing `icuuc.dll` problem of opentrack 2026
([opentrack-launcher#14](https://github.com/markx86/opentrack-launcher/issues/14)).

---

## English

### 1. Switch to Desktop Mode

Press the **Steam button** → **Power** → **Switch to Desktop**.

### 2. Open a terminal

Click the app launcher at the bottom left → **System** → **Konsole**.

### 3. Run the installer

Copy this line, paste it into Konsole with **Ctrl+Shift+V**, and press **Enter**:

```bash
curl -fsSL https://raw.githubusercontent.com/tylerstyle/support/main/opentrack/install-opentrack.sh | bash
```

If it finds an old install, it shows you what it will delete and asks first. Press **Enter** to confirm.
It takes a few minutes (opentrack is about 190 MB). At the end it says **All done!**

If it stops with **ERROR**, read the message. If you can't fix it yourself, send a screenshot of the window.

### 4. Remove a system-wide copy (only if the script told you to)

If the script printed a warning about `/usr/local/bin/opentrack-launcher`, an old copy was installed with
`sudo` and the script can't delete it. Remove it yourself:

1. SteamOS has no password set by default. If you have never set one, set one now (you won't see the
   characters as you type, that's normal):

   ```bash
   passwd
   ```

2. Delete the old copy (type the password from step 1 when asked):

   ```bash
   sudo rm /usr/local/bin/opentrack-launcher
   ```

   If that fails with `Read-only file system`, run this instead:

   ```bash
   sudo steamos-readonly disable
   sudo rm /usr/local/bin/opentrack-launcher
   sudo steamos-readonly enable
   ```

### 5. Set the launch options in Steam

For **every game** you want head tracking in:

1. In Steam, right-click the game → **Properties** → **General**.
2. In **LAUNCH OPTIONS**, delete anything opentrack-related that is already there and paste:

   ```
   ~/.local/bin/opentrack-launcher %command%
   ```

3. Under **Compatibility**, make sure the game runs with **Proton** (opentrack only works with the Windows
   version of a game).

### 6. Set up opentrack (once per game)

While a game is running, the game takes all clicks, so you **can't** set up opentrack next to the game.
Do it beforehand, with the game closed:

1. In Desktop Mode, double-click **opentrack Setup** on the desktop (it's also in the app menu under Games).
2. Pick the game. A short reminder of the following steps appears, click **OK** and opentrack opens.
3. Under **Input** choose your tracker, under **Output** usually **freetrack 2.0 Enhanced**.
4. Click **Options** → tab **Game detection** → tick *Start profiles from game executable names in this
   list* → click **+** → enter the game's `.exe` name (opentrack Setup tells you which) and pick your
   profile. This makes tracking **start by itself** whenever the game runs.
   Some games start through a small launcher, then it's the real game's `.exe`, not the one Steam
   starts (Farming Simulator 25: `FarmingSimulator2025Game.exe`). opentrack Setup shows the right one.
5. Press **Start** to test it, then close opentrack.

If the game is missing in the list, or opentrack Setup doesn't show the `.exe` name, start the game once
from Steam, quit it, and open opentrack Setup again.

Now just play: opentrack starts together with the game (in Game Mode it stays hidden behind the game)
and begins tracking on its own. The first start of each game takes a little longer because a start
script is created for it.

> **Don't touch the opentrack window with the touchscreen!** opentrack closes immediately when you tap it
> (a bug in Proton, it doesn't support touch input for opentrack). Use the **trackpad** (R2 = click) or a
> mouse. If it happened, just start opentrack Setup (or the game) again.

### Tracking doesn't register in the game (Farming Simulator 25 / LS25)

If opentrack tracks your movements in its window, but the game does not react, see our step-by-step
troubleshooting guide: **[Troubleshooting guide (German)](fehlersuche.md)**.

### opentrack doesn't start sometimes

Very rarely opentrack crashes right at startup (we saw it once in testing). Usually it's enough to just
**quit the game and start it again**.

If it keeps happening, change the launch option of that game to this. It turns off Proton's gamepad
helper "Xalia", which was involved in the crash:

```
PROTON_USE_XALIA=0 ~/.local/bin/opentrack-launcher %command%
```

### Updating / when something breaks

Just run the command from step 3 again. It deletes everything and installs fresh. opentrack also updates
itself automatically when a game starts, and the `icuuc.dll` fix is applied again after every update.

### What the script removes

| Path | What it is |
|---|---|
| `~/.local/bin/opentrack-launcher` | the old launcher script |
| `~/.local/share/opentrack-launcher/` | downloaded opentrack, per-game start scripts, manually added DLLs |
| `~/.local/bin/opentrack-setup`, `~/Desktop/opentrack-setup.desktop`, `~/.local/share/applications/opentrack-setup.desktop` | opentrack Setup |

Your opentrack settings live inside each game's Proton prefix and are **not** deleted.

If you want to do it by hand instead:

```bash
rm -f ~/.local/bin/opentrack-launcher ~/.local/bin/opentrack-setup
rm -f ~/Desktop/opentrack-setup.desktop ~/.local/share/applications/opentrack-setup.desktop
rm -rf ~/.local/share/opentrack-launcher
```

Leftovers from the **flatpak** version of Steam (only if you ever used it) are not touched by the script:

```bash
rm -rf ~/.var/app/com.valvesoftware.Steam/.local/share/opentrack-launcher
rm -f ~/.var/app/com.valvesoftware.Steam/bin/opentrack-launcher ~/.var/app/com.valvesoftware.Steam/bin/7z
```

An `icuuc.dll` you may have copied into a game's Proton prefix by hand can stay. It does no harm.

### What the script does, technically

1. Deletes the old install (see above).
2. Downloads `icuuc.dll` from [FaithLife-Community/icu](https://github.com/FaithLife-Community/icu)
   (checksum-verified). opentrack 2026 needs it, but Proton only ships `icu.dll`. This `icuuc.dll` is a
   small file that forwards to Proton's `icu.dll`.
3. If the system has no `7z`, downloads the official [7-Zip](https://github.com/ip7z/7zip) (checksum-verified).
4. Installs the latest opentrack-launcher and patches it so that it:
   - puts `icuuc.dll` next to `opentrack.exe` after every install/update (matching 32/64 bit),
   - uses the bundled 7-Zip if needed,
   - no longer crashes (and stops the game from starting) when GitHub can't be reached,
   - keeps opentrack running for games that start through a small launcher that quits right away
     (Farming Simulator: `FarmingSimulator2025.exe` → `x64\FarmingSimulator2025Game.exe`). Without this,
     the per-game start script closes opentrack as soon as the launcher quits.
5. Installs **opentrack Setup** (desktop icon + app menu). It opens opentrack without the game, in that
   game's Proton prefix (where opentrack keeps its settings), using the same Proton the game last ran with.
6. Downloads the latest opentrack and checks that `icuuc.dll` is in place.

---

## Deutsch

### 1. In den Desktop-Modus wechseln

**Steam-Taste** → **Ein/Aus** → **Zum Desktop wechseln**.

### 2. Ein Terminal öffnen

Unten links auf das Startmenü klicken → **System** → **Konsole**.

### 3. Den Installer starten

Diese Zeile kopieren, mit **Strg+Umschalt+V** in die Konsole einfügen und **Enter** drücken:

```bash
curl -fsSL https://raw.githubusercontent.com/tylerstyle/support/main/opentrack/install-opentrack.sh | bash
```

Findet das Skript eine alte Installation, zeigt es an, was gelöscht wird, und fragt vorher nach.
Mit **Enter** bestätigen. Das Ganze dauert ein paar Minuten (opentrack ist ca. 190 MB groß).
Am Ende steht **All done!**

Bricht es mit **ERROR** ab, die Meldung lesen. Wenn du nicht weiterkommst, schick einen Screenshot vom Fenster.

### 4. Systemweite Kopie entfernen (nur wenn das Skript es sagt)

Hat das Skript eine Warnung zu `/usr/local/bin/opentrack-launcher` ausgegeben, wurde früher eine Kopie mit
`sudo` installiert, die das Skript nicht löschen darf. Die musst du selbst entfernen:

1. SteamOS hat standardmäßig kein Passwort. Falls du nie eins gesetzt hast, jetzt eins setzen
   (beim Tippen sieht man keine Zeichen, das ist normal):

   ```bash
   passwd
   ```

2. Die alte Kopie löschen (nach dem Passwort aus Schritt 1 wird gefragt):

   ```bash
   sudo rm /usr/local/bin/opentrack-launcher
   ```

   Kommt dabei `Read-only file system`, stattdessen das hier ausführen:

   ```bash
   sudo steamos-readonly disable
   sudo rm /usr/local/bin/opentrack-launcher
   sudo steamos-readonly enable
   ```

### 5. Startoptionen in Steam setzen

Für **jedes Spiel**, in dem du Headtracking willst:

1. In Steam Rechtsklick aufs Spiel → **Eigenschaften** → **Allgemein**.
2. Unter **STARTOPTIONEN** alles löschen, was mit opentrack zu tun hat, und das hier einfügen:

   ```
   ~/.local/bin/opentrack-launcher %command%
   ```

3. Unter **Kompatibilität** sicherstellen, dass das Spiel mit **Proton** läuft (opentrack funktioniert nur
   mit der Windows-Version eines Spiels).

### 6. opentrack einrichten (einmal pro Spiel)

Solange ein Spiel läuft, schnappt sich das Spiel alle Klicks, du kannst opentrack also **nicht** neben dem
Spiel einrichten. Das passiert vorher, bei geschlossenem Spiel:

1. Im Desktop-Modus auf dem Desktop doppelt auf **opentrack Setup** klicken (steht auch im Startmenü unter
   Spiele).
2. Das Spiel auswählen. Es erscheint eine kurze Erinnerung an die folgenden Schritte, mit **OK**
   bestätigen, dann öffnet sich opentrack.
3. Bei **Input** deinen Tracker wählen, bei **Output** meistens **freetrack 2.0 Enhanced**.
4. Auf **Options** klicken → Reiter **Game detection** → Haken bei *Start profiles from game executable
   names in this list* → auf **+** klicken → den `.exe`-Namen des Spiels eintragen (opentrack Setup sagt
   dir welchen) und dein Profil wählen. Dadurch **startet das Tracking von selbst**, sobald das Spiel läuft.
   Manche Spiele starten über einen kleinen Starter, dann ist es die `.exe` des eigentlichen Spiels, nicht
   die, die Steam startet (Landwirtschafts-Simulator 25: `FarmingSimulator2025Game.exe`). opentrack Setup
   zeigt dir die richtige an.
5. Mit **Start** testen, danach opentrack schließen.

Fehlt das Spiel in der Liste oder zeigt opentrack Setup keinen `.exe`-Namen an, starte das Spiel einmal über
Steam, beende es und öffne opentrack Setup nochmal.

Jetzt einfach spielen: opentrack startet zusammen mit dem Spiel (im Spielmodus bleibt es hinter dem Spiel
versteckt) und beginnt von selbst mit dem Tracking. Der erste Start eines Spiels dauert etwas länger, weil
dafür ein Startskript angelegt wird.

> **Das opentrack-Fenster nicht mit dem Touchscreen antippen!** opentrack schließt sich sofort, wenn man
> darauf tippt (ein Fehler in Proton, das Touch-Eingaben für opentrack nicht unterstützt). Das **Trackpad**
> benutzen (R2 = Klick) oder eine Maus. Ist es passiert, opentrack Setup (oder das Spiel) einfach nochmal
> starten.

### Tracking kommt im Spiel nicht an (Landwirtschafts-Simulator 25 / LS25)

Wenn sich der Oktopus im opentrack-Fenster bewegt, das Spiel aber nicht auf Kopfbewegungen reagiert, hilft unsere Schritt-für-Schritt-Anleitung: **[Fehlersuche (Deutsch)](fehlersuche.md)**.

### opentrack startet manchmal nicht

Sehr selten stürzt opentrack direkt beim Start ab (beim Testen einmal passiert). Meistens reicht es,
**das Spiel zu beenden und einfach nochmal zu starten**.

Passiert das öfter, die Startoption des Spiels auf das hier ändern. Damit wird Protons Controller-Helfer
„Xalia“ abgeschaltet, der an dem Absturz beteiligt war:

```
PROTON_USE_XALIA=0 ~/.local/bin/opentrack-launcher %command%
```

### Aktualisieren / wenn etwas kaputt ist

Einfach den Befehl aus Schritt 3 nochmal ausführen. Er löscht alles und installiert neu. opentrack
aktualisiert sich außerdem beim Spielstart automatisch selbst, und der `icuuc.dll`-Fix wird nach jedem
Update wieder eingespielt.

### Was das Skript löscht

| Pfad | Was das ist |
|---|---|
| `~/.local/bin/opentrack-launcher` | das alte Launcher-Skript |
| `~/.local/share/opentrack-launcher/` | heruntergeladenes opentrack, Startskripte pro Spiel, von Hand hinzugefügte DLLs |
| `~/.local/bin/opentrack-setup`, `~/Desktop/opentrack-setup.desktop`, `~/.local/share/applications/opentrack-setup.desktop` | opentrack Setup |

Deine opentrack-Einstellungen liegen im Proton-Prefix des jeweiligen Spiels und werden **nicht** gelöscht.

Falls du es lieber von Hand machen willst:

```bash
rm -f ~/.local/bin/opentrack-launcher ~/.local/bin/opentrack-setup
rm -f ~/Desktop/opentrack-setup.desktop ~/.local/share/applications/opentrack-setup.desktop
rm -rf ~/.local/share/opentrack-launcher
```

Reste der **Flatpak**-Version von Steam (nur falls du die mal benutzt hast) lässt das Skript in Ruhe:

```bash
rm -rf ~/.var/app/com.valvesoftware.Steam/.local/share/opentrack-launcher
rm -f ~/.var/app/com.valvesoftware.Steam/bin/opentrack-launcher ~/.var/app/com.valvesoftware.Steam/bin/7z
```

Eine `icuuc.dll`, die du vielleicht von Hand in den Proton-Prefix eines Spiels kopiert hast, kann bleiben.
Sie schadet nicht.

### Was das Skript technisch macht

1. Löscht die alte Installation (siehe oben).
2. Lädt `icuuc.dll` von [FaithLife-Community/icu](https://github.com/FaithLife-Community/icu) herunter
   (mit Prüfsumme). opentrack 2026 braucht sie, Proton liefert aber nur `icu.dll` mit. Diese `icuuc.dll`
   ist eine kleine Datei, die an Protons `icu.dll` weiterleitet.
3. Wenn kein `7z` auf dem System ist, lädt es das offizielle [7-Zip](https://github.com/ip7z/7zip) herunter
   (mit Prüfsumme).
4. Installiert den neuesten opentrack-launcher und passt ihn so an, dass er:
   - nach jeder Installation/jedem Update `icuuc.dll` neben `opentrack.exe` legt (passend für 32/64 Bit),
   - bei Bedarf das mitgelieferte 7-Zip benutzt,
   - nicht mehr abstürzt (und damit den Spielstart verhindert), wenn GitHub nicht erreichbar ist,
   - opentrack bei Spielen weiterlaufen lässt, die über einen kleinen Starter starten, der sich gleich wieder
     beendet (Landwirtschafts-Simulator: `FarmingSimulator2025.exe` → `x64\FarmingSimulator2025Game.exe`).
     Ohne das schließt das Startskript des Spiels opentrack, sobald sich der Starter beendet.
5. Installiert **opentrack Setup** (Desktop-Symbol + Startmenü). Es öffnet opentrack ohne das Spiel im
   Proton-Prefix des Spiels (dort speichert opentrack seine Einstellungen), mit dem Proton, mit dem das
   Spiel zuletzt lief.
6. Lädt das neueste opentrack herunter und prüft, ob `icuuc.dll` an ihrem Platz ist.
