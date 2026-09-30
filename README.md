# Nameplate Dashboard

Lokales Qualitätsdashboard für Schiffs-Baugruppenberichte im Excel-Format (XLS, XLSX, XLSM, XLSB). Es werden nur Zeilen mit **Type = Armature** ausgewertet. Die Armaturennummer kommt aus **DisplayName (Spalte D)**, der Namensstatus aus **Armature_Nameplate_Check (Spalte G)**. Zusätzlich sind Armature Basic und Smart auswählbar.

**Funktionen:** Schiffs- und Baugruppenansicht, Kreisdiagramm, Baugruppenvergleich, nach Status filterbare Armaturenliste sowie CSV-Export. `OK` = Name vorhanden; `Name must be filled for Nameplate` = Name fehlt; leere Felder = ungeprüft. Die Statistik zählt pro Schiff und Armaturennummer nur einmal, zeigt doppelte Fundstellen aber weiterhin in der Liste an.

## Start auf Windows ohne Administratorrechte

1. Repository herunterladen oder klonen und in einen **festen Ordner** entpacken.
2. `Excel-Parser-installieren.bat` einmalig ausführen (optional, für Offline-Nutzung). Die IT kann alternativ eine geprüfte `xlsx.full.min.js` bereitstellen. Andernfalls wird SheetJS ggf. online vom CDN geladen.
3. Immer `Start-Dashboard.bat` starten. Dashboard unter **http://localhost:8765/** in Edge/Chrome öffnen. Nicht `file://`, `127.0.0.1` oder einen anderen Port verwenden.
4. Schiffsnummer eingeben und **Ordner dauerhaft verbinden** anklicken; den Lesezugriff gewähren. Alternativ einen Überordner wählen, bei dem direkte Unterordner die Schiffe repräsentieren.
5. Beim nächsten Start ist der gewählte Ordner **weiterhin gespeichert**. Je nach Browser-Sicherheitsentscheidung ist ein Klick auf **Zugriff erlauben** oder **Zugriff erneuern** nötig. Nach Erlaubnis liest das Dashboard die neuesten Dateistände.

Die Adresse ist nun immer `localhost:8765`. Frühere Versionen wechselten bei einem belegten Port auf 8766–8770: Browser-Datenbanken sind jedoch an die exakte Adresse **einschließlich Port** gebunden. Ein bereits gestartetes Dashboard wird deshalb erkannt und wiedergeöffnet statt den Port zu wechseln.

Es werden die gespeicherten Verzeichnishandles, Filter und ein zuletzt berechneter Analysestand im lokalen **IndexedDB-Browserprofil** gehalten. Wenn der Ordner nach einem Neustart noch keine Berechtigung hat, wird der alte Stand ausdrücklich als **möglicherweise veraltet** angezeigt. Die Live-Aktualisierung läuft alle 30 Sekunden, solange das Dashboard geöffnet ist.

**Browsergrenze:** Privater Modus, gelöschte Browserdaten oder Firmenrichtlinien können den Speicher entfernen. Der Browser darf Ordnerzugriff nach Neustart erneut bestätigen lassen; unbegrenzter Zugriff ohne Browserdialog ist mit einer reinen Webanwendung nicht garantiert.

## Datenschutz

Die Excel-Dateien werden **nicht hochgeladen**. Ausschließlich die Anwendung ist öffentlich; echte Schiffsberichte, Datenexporte und die Excel-Parser-Bibliothek sind über `.gitignore` ausgeschlossen. Im lokalen Browserprofil wird auch der letzte analysierte Stand mit Armaturennummern und Objektpfaden gespeichert. Zum Löschen die Website-Daten für localhost:8765 entfernen.

**Datenannahme:** `DiagramCheck_768.xls` wird vorläufig als „Baugruppe 768“ interpretiert. Diese Zuordnung und weitere Dateivarianten sollten noch anhand realer Originalberichte validiert werden.

## Weiterentwicklung

Der vollständig lesbare JavaScript-Quelltext steht direkt in `app.js`; das Dashboard benötigt keinen Build-Schritt und kann offline mit lokal bereitgestelltem Excel-Parser betrieben werden. Änderungen an der Analyse- oder Speicherlogik erfolgen direkt in `app.js`.


### Baugruppenfilter und CSV (Version 2.2)

- Das Suchfeld in der **Armaturenliste** sucht ausschließlich nach **Baugruppennummern**. Die aufklappbare Liste enthält alle Baugruppen des ausgewählten Schiffs. Beim Auswählen synchronisiert sich auch die Baugruppenauswahl oberhalb der Diagramme. Die Eingabe von Teilnummern filtert die Liste sofort.
- **Download gefiltert** exportiert genau die Treffer gemäß Schiff, Baugruppe/Baugruppensuche, Prüfkategorie und Statusfilter. Auch Treffer oberhalb der auf dem Bildschirm angezeigten ersten 500 Zeilen sind enthalten.
- **Download alle** exportiert alle fehlerhaften Armaturen für das ausgewählte Schiff und die gewählte Prüfkategorie, unabhängig von Baugruppen- und Tabellenfilter. Bei „Alle Schiffe“ umfasst er alle Schiffe.


## Automatischer Updater (Windows)

Ab jetzt genügt **`Update-Dashboard.bat`** im Programmordner. Das Skript prüft über HTTPS, ob auf dem offiziellen GitHub-Repository `andeteyker/Nameplate-Dashboard` eine neuere Version von `main` verfügbar ist, zeigt den Commit-Stand und fragt vor der Installation nach. **Keine Administratorrechte erforderlich.**

1. Wenn das Dashboard geöffnet ist, den Browser schließen und idealerweise das laufende Serverfenster mit `Strg+C` beenden.
2. `Update-Dashboard.bat` im bestehenden Programmordner doppelklicken.
3. Die Versionsanzeige prüfen und die Installation mit `J` bestätigen.
4. Danach `Start-Dashboard.bat` starten, Browser ggf. mit `Strg+F5` neu laden.

Für eine reine Update-Prüfung ohne Installation: `Update-Dashboard.bat -CheckOnly`. Bei einem Git-Klon verwendet der Updater `git fetch` und `git merge --ff-only`; bei einer ZIP-Installation lädt er den von GitHub bestätigten **konkreten Commit** herunter, validiert die benötigten Programmdateien, legt eine Sicherung unter `update-backups/` an und aktualisiert nur die Dateien der Anwendung. Bei Kopierfehlern versucht er, den vorherigen Stand wiederherzustellen.

**Deine Daten bleiben erhalten:** Excel-/CSV-Dateien, die separat bereitgestellte `xlsx.full.min.js` und die gespeicherten Browser-Verzeichnishandles (gleiche Adresse `http://localhost:8765/` und dasselbe Browserprofil vorausgesetzt) werden nicht ersetzt oder gelöscht. Lokale Änderungen an Programmdateien eines ZIP-Downloads werden vor dem Ersetzen in `update-backups/` gesichert; bei Git-Klonen bricht der Updater bei ungesicherten Änderungen ab. Für Updates ist eine Internetverbindung zu `api.github.com` und `codeload.github.com` bzw. beim Git-Klon Zugriff auf das Git-Remote notwendig.

**Erste Installation bei einer bereits heruntergeladenen älteren ZIP-Version:** Die beiden Dateien `Update-Dashboard.bat` und `Update-Dashboard.ps1` in den bisherigen Programmordner kopieren und einmalig starten. Der Versionsstand wird danach in der lokalen, nicht veröffentlichten Datei `.nameplate-version` gespeichert. Bei bestehenden **Git-Klonen** zunächst einmal `git pull --ff-only origin main` ausführen, um den Updater als regulär versionierte Dateien zu erhalten.

**Hinweis:** Der Browser kann aus Sicherheitsgründen auch nach einem Programmupdate beim nächsten Öffnen wieder nach dem Ordnerzugriff fragen. Das lässt sich durch den Updater nicht umgehen.
