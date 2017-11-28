# Über dieses Repository

Dieses Repository beschreibt wie Teams mittels Docker ihre gesamten Build-Abhängigkeiten mitbringen können. Es enthält Ausführbaren Beispiel-Code für verschiedene Ansätze sowie Beschreibungen und Vergleiche dieser.

# Bring Your Own Pipeline

Ein neuer Tag, ein neues unbekanntes Code Repository. Dank git ist dieses schnell gefunden und geklont. Um die Software jedoch auszuführen wird üblicherweise eine vielzahl an Build-Werkzeugen benötigt. Diese gilt es zunächst zu installieren. Welche das sind und wie ich das tue finde ich oft auf eine "Getting Started" Seite im Wiki. Bei älteren Java Projekten muss ich die `.war` Files dann auch noch in einen Lokalen Application-Server, welchen ich mir natürlich auch noch aufsetzen muss deployen. Mein Workflow sieht für solch ein Projekt dann im besten Falle so aus:

- Code klonen
- Wiki Anleitung öffnen
- Werkzeuge installieren.
- Software Bauen
- Lokalen Application-Server aufsetzen
- Software deployen

Eigentlich sind davon nur zwei Schritte gewollt.

1. Code klonen
2. Software laufen lassen

In unserem hier beschriebenen Ansatz machen wir exzessiven Gebrauch der Docker Technologie. Diese erlaubt es uns Werkzeuge und wie wir sehen werden auch Abläufe zu kapseln. Der naheliegendste Gebrauch von Docker ist für das Paketieren des Application-Servers. Ein gängiges Beispiel für ein Dockerfile in diesem Fall könnte wie folgt aussehen.
```
FROM tomcat:8
ADD "*.war" webapps/
```

Hier würde das Web-Archive zunächst mittels Maven oder Gradle gebaut und danach im `docker build` Schritt in das Docker image kopiert. Der Entwickler muss also zunächst diese Build-Tools installieren und gegebenenfalls noch konfigurieren bevor er das Docker-Image bauen kann. Das selbe trifft übrigens auf unseren Build- oder CI/CD-Server zu. Dieser muss ebenfalls alle Build-Abhängigkeiten der Projekte die er bauen soll lokal verfügbar haben.

Schauen wir uns jetzt an wie wir auch den Software-Build in Docker abbilden können.
