# Bring Your Own Pipeline

Dieses Repository beschreibt wie Teams mittels Docker ihre gesamten Build-Abhängigkeiten mitbringen können. Es enthält Ausführbaren Beispiel-Code für verschiedene Ansätze sowie Beschreibungen und Vergleiche dieser.

#####Wie bekommen man nun das Problem mit Docker in den Griff?

In den meisten Fällen führen viele Wege nach Rom. Die Virtualisierung und Containerisierung durch Docker eröffnet die Möglichkeit die Build-Strecke zu abstrahieren und durch durch das Entwicklerteam bereitstellen zu lassen. Dies sorgt dafür, dass die zyklische Abhängigkeit zwischen Entwicklungsteam und Infrastrukturteam aufgeweicht werden kann, weil der Software-Build zur Black-Box wird.  

#####Wie stellt man diese Black-Box bereit?

Ein möglicher Weg ist Kapselung des Software-Builds mit einem "Single Command" Docker `run` und anschließendem Clean-Up, welches als Resultat die gebaute Software im Datei-System ablegt. Bereitgestelllt durch eine `build.sh` kann der Bauplan der Software vollständig durch das Entwicklungsteam bestimmt werden.         

Folgender Ausschnitt zeigt beispielhaft, wie die `build.sh` mit einem `docker run` aussehen kann. Über `-v` wird das aktuelle Verzeichnis als Volume in den Container gereicht, sodass bidirectionale Lese und Schreibrechte existieren und sowohl die Sourcen gelesen als auch die gebauten Artefakte im Verzeichnis abgelegt werden können. Mittels `bash -c` kann ein beliebiger Shell Befehl ausgeführt werden, welche die Build Umgebung aufsetzt, die Applikation baut und abschließend das Verzeichnis bereinigt. Voraussetzung ist jedoch, dass das Base Image eine Shell Unterstützung bereitstellt. Mittels `--rm` wird der ausgeführte Container anschließend entfernt und das Dateisystem bereinigt.   

```bash
docker run --rm -v `pwd`:/application -w /application <base-image> bash -c "build software && rm -rf temp folder"
```
Mittels `docker build` kann anschließend lokal und auch in einer beliebigen CI/CD dieses Verzeichnis in ein Docker Image verpackt und auf einer beliebigen Instanz ausgeführt werden. 

Was sich im ersten Moment als elegante Lösung herausstellt, birgt auf den zweiten Blick jedoch mögliche Gefahren. Gerade mit Hinblick auf eine Integration in eine CI/CD ist die Arbeit auf dem Dateisystem problemtatisch, da oftmals Build Reste zurückbleiben und somit der Speicher- und Aufräumaufwand exponentiell steigt.

Seit der Version 17.05 schafft Docker für diese Problematik jedoch Abhilfe und führt die Multi-Stage Builds ein. Wie das folgende Beispiel zeigt, ist ein "Shared Volume" nicht mehr nötig. Vielmehr existiert die Möglichkeit innerhalb eines Docker Builds Dateien zwischen "Build Stages" auszustauschen.
 
```dockerfile
FROM <base-image> as builder

RUN install build tools
RUN build application

FROM <base-image>
# copy dist
COPY --from=builder <app-target> <destination>
```
Dies hat zur Folge, dass die gebaute Software nicht mehr zwischengespeichert werden muss und auch die komplette Build Umgebung nur temporär in der ersten Build-Stage existiert. Nach Abschluss des Docker Builds wird die gesamte Build Umgebung verworfen und hinterlässt keine Spuren auf dem Dateisystem. Anschließendes Bereinigen von Verzeichnissen ist somit nicht nötig.

Die komplette Build Strecke ist nun zentral in einem Dockerfile beschrieben und kann in einer beliebigen Umgebung zum Build der Software genutzt werden. Durch diesen Schritt erreicht man eine starke Entkopplung zwischen Entwicklung und Infrastrukturbetrieb. Sowohl der Quellcode als auch das Dockerfile mit dem Bauplan werden durch das Entwicklungsteam über Git bereitgestellt. Ein später Build und anschließendes Deployment auf einer Umgebung durch das Operations-Team benötigt keinerlei Wissen über die Software und dessen Build Pipeline.  