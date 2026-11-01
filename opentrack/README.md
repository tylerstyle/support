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

### 6. First start

Start the game (in Desktop Mode the first time, that makes setup easier). The opentrack window opens
together with the game. Choose your tracker as **Input** and usually **freetrack 2.0 Enhanced** as
**Output**, then press **Start**. opentrack remembers the settings separately for each game.

The first start of each game takes a little longer because a start script is created for it.

In Game Mode you usually only see the game, the opentrack window can be hidden behind it.
That's why the first setup is easier in Desktop Mode.

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

Your opentrack settings live inside each game's Proton prefix and are **not** deleted.

If you want to do it by hand instead:

```bash
rm -f ~/.local/bin/opentrack-launcher
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
   - no longer crashes (and stops the game from starting) when GitHub can't be reached.
5. Downloads the latest opentrack and checks that `icuuc.dll` is in place.

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

### 6. Erster Start

Das Spiel starten (beim ersten Mal am besten im Desktop-Modus, dann ist das Einrichten einfacher).
Das opentrack-Fenster geht zusammen mit dem Spiel auf. Bei **Input** deinen Tracker wählen, bei **Output**
meistens **freetrack 2.0 Enhanced**, dann auf **Start** klicken. opentrack merkt sich die Einstellungen
für jedes Spiel einzeln.

Der erste Start eines Spiels dauert etwas länger, weil dafür ein Startskript angelegt wird.

Im Spielmodus siehst du meistens nur das Spiel, das opentrack-Fenster kann dahinter versteckt sein.
Deshalb ist das erste Einrichten im Desktop-Modus einfacher.

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

Deine opentrack-Einstellungen liegen im Proton-Prefix des jeweiligen Spiels und werden **nicht** gelöscht.

Falls du es lieber von Hand machen willst:

```bash
rm -f ~/.local/bin/opentrack-launcher
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
   - nicht mehr abstürzt (und damit den Spielstart verhindert), wenn GitHub nicht erreichbar ist.
5. Lädt das neueste opentrack herunter und prüft, ob `icuuc.dll` an ihrem Platz ist.
