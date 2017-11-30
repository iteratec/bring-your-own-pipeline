+++
date = "2017-11-28T18:19:03+07:00"
+++
# Über dieses Repository

Dieses Repository beschreibt wie Teams mittels Docker ihre gesamten Build-Abhängigkeiten mitbringen können. Es enthält Ausführbaren Beispiel-Code für verschiedene Ansätze sowie Beschreibungen und Vergleiche dieser.

# Bring Your Own Pipeline

Ein neuer Tag, ein neues Projekt. Ähnlich schnell wie die Lebenszyklen von Technologien wechselt mitunter der Projektkontext eines Software Developers. Mit diesem Wechsel einher ergeben sich in den meisten Fällen Umstellungen auf andere Programmiersprachen, Technologien und Build Tools. Dank Git ist das projektspezifische Code Repository schnell gefunden und geklont. Um die Software nun jedoch zu modifizieren und dann auszuführen zu können, wird üblicherweise eine Vielzahl an Build-Werkzeugen benötigt, welche zunächst installiert werden müssen. Wie genau die Entwicklungs- und Buildumgebung aussieht, aufgesetzt und ausgeführt wird ist oft auf eine "Getting Started" Seite im Wiki-Space beschrieben. Bei älteren Java Projekten beispielsweise folgt anschließend noch das Setup eines Applikationsservers oder einer Runtime Umgebung. Der eigentlich einfache Workflow "Code klonen, Software laufen lassen und entwickeln" wächst zu einer langen ToDo-Liste an, welche zunächst abgearbeitet werden muss, um die erste produktive Zeile Code zu schreiben. In der heutigen Zeit ein No-Go! Doch wie kann dieser Setup Aufwand minimiert werden?
   
## Software mit Docker kapseln

Ein möglicher Ansatz basiert auf dem exzessiven Gebrauch der Docker Technologie. 

In vielen Projekten wird Docker bereits für das Paketieren des Application-Servers verwendet. Ein gängiges Beispiel für ein Dockerfile in diesem Fall könnte wie folgt aussehen.
```dockerfile
FROM tomcat:8
ADD "*.war" webapps/
```

Nach einem lokalen Build mit Maven oder Gradle wird über `docker build` das Artefakt in das Docker Image kopiert. Damit ist zwar der lokale Applikationsserver gekapselt, jedoch muss der Entwickler alle nötigen Build-Tools vorinstalliert und gegebenenfalls noch vorkonfiguriert haben, bevor er das Docker-Image bauen kann. Das selbe trifft übrigens auf einen existierenden Build- oder CI/CD-Server zu. Ebenfalls wie beim Entwickler müssen dort sämtliche Build-Abhängigkeiten der Projekte, welche gebaut werden sollen, verfügbar sein. Dieses Problem sorgt neben dem hohen Setup Aufwand für Entwickler zudem zu kontinuierlichen Aufwänden in der CI/CD, da neben der Installation auch Wartung und Pflege dieser Build Tools von Nöten ist.

Somit fehlt neben der Abstraktion des Applikationsservers noch die Abstraktion der Build Tools und viel mehr die Abstraktion des kompletten Software Builds, damit sowohl lokal beim Entwickler als auch in einer CI/CD Umgebung der Code, ohne das aufwändige Setup, gebaut werden kann.

## Der Software Build als Black-Box

Ziel ist es also die Fähigkeiten der Virtualisierung und Containerisierung von Docker zu nutzen, um nicht nur Software Komponenten, wie den Applikationsserver, zu abstrahieren, sondern eine komplette Build-Umgebung bereitzustellen in der der Code gebaut werden kann.
 
Ein möglicher Weg ist Kapselung des Setups der Build-Umgebung mit einem "Single Command" Docker `run` wie im folgenden Beispiel dargestellt.
```bash
docker run --rm -v `pwd`:/ <base-image> bash -c "setup build-env && build software"
```
Bereitgestellt in einer `build.sh` sorgt der Docker `run` für das Setup der Build Umgebung und dem anschließenden Build der Software. Das Code Repository wird dafür als "Volume" in den Container via `-v` inkludiert und erlaubt lesende und schreibende Zugriffe auf das Code Repository aus dem Container heraus. Abschließend wird der Container per `--rm` gestoppt und entfernt. Als Ergebnis liegt das gebaute Artefakt vor und kann anschließend in einen containerisierten Applikationsserver deployt werden.

Dieses Vorgehen sorgt dafür, dass neben der Abstraktion der Build-Umgebung zudem der Bauplan der Software in einer `build.sh` zentralisiert und transparent ist. Dadurch eröffnet sich die Möglichkeit lokal sowie in einer CI/CD Umgebung gleichermaßen die Software zu bauen, ohne das nötige Vorbereitungen und Setup getätigt werden müssen. Lediglich die Verfügbarkeit von Docker ist eine harte Bedingung.

Doch gerade in einer CI/CD Umgebung birgt dieses Vorgehen Probleme, da die Software Builds durch den "Volume Mount" auf dem Dateisystem des Build-Servers arbeiten und womöglich dort eine Vielzahl an Dateien in unterschiedlichen Größen ablegen und persistieren. Dies sorgt dafür, dass der Speicherbedarf stetig steigt und manueller Bereinigungsaufwand entsteht. Die ersparten Setup und Wartungsaufwände werden somit wieder relativiert.   

## Zustandslos durch Multi-Stage Builds

Seit der Version 17.05 schafft Docker für diese Problematik jedoch ebenfalls Abhilfe und führt die Multi-Stage Builds ein. Wie das folgende Beispiel zeigt, ist ein "Shared Volume" nicht mehr nötig. Vielmehr existiert die Möglichkeit innerhalb eines Docker Builds Dateien zwischen "Build Stages" auszustauschen.
 
```dockerfile
FROM <base-image> as builder

RUN install build tools
RUN build application

FROM <base-image>
# copy dist
COPY --from=builder <app-target> <destination>
```
Dies hat zur Folge, dass die gebaute Software nicht mehr zwischengespeichert werden muss und auch die komplette Build Umgebung nur temporär in der ersten Build-Stage existiert. Nach Abschluss des Docker Builds wird die gesamte Build Umgebung verworfen und hinterlässt keine Spuren auf dem Dateisystem. Anschließendes Bereinigen von Verzeichnissen ist somit nicht nötig. 

Die komplette Build Strecke ist nun zentral in einem Dockerfile beschrieben und kann in einer beliebigen Umgebung per `docker build` zum Build der Software genutzt werden. Als Resultat entsteht ein Docker Image, welches nur die gebauten Artefakte enthält und diese unter anderem gleich in eine containerisierte Umgebung wie z.B einen Applikationsserver deployt. Dadurch wird keinerlei Wissen über die Software und dessen Build Pipeline benötigt, was die lokale Arbeit deutlich vereinfacht und nötige Abhängigkeiten innerhalb der CI/CD reduziert. Sowohl lokal als auch in einer CI/CD Umgebung sorgt der Workflow "Git klonen, Docker Image bauen und in einer Umgebung ausführen" für lauffähige Software.
