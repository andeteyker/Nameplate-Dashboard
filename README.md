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
