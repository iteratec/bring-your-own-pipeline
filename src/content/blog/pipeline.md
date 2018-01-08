+++
date = "2017-11-28T18:19:03+07:00"
author = "Benjamin Brunzel & Marko Rühle"
title = "Bring your own pipeline"
description = "How to provide whole deployment pipeline with docker."
categories = ["Docker"]
type = "post"
featured = "docker_logo.png"
featuredalt = "Docker Logo" 
featuredpath = "img"
+++

# Bring Your Own Pipeline

Ein neuer Tag, ein neues Projekt. Ähnlich schnell wie die Lebenszyklen von Technologien wechselt mitunter der Projektkontext eines Software Developers. Mit diesem Wechsel einher ergeben sich in den meisten Fällen Umstellungen auf andere Programmiersprachen, Technologien und Build Tools. Dank Git ist das projektspezifische Code Repository schnell gefunden und lokal geklont. Um die Software nun jedoch zu modifizieren und dann auszuführen zu können, wird üblicherweise eine Vielzahl an Build-Werkzeugen benötigt, welche zunächst installiert werden müssen. Wie genau die Entwicklungs- und Buildumgebung aussieht, aufgesetzt und ausgeführt wird ist oft auf eine "Getting Started" Seite im Wiki-Space oder in einer "README" Datei beschrieben. Bei älteren Java Projekten beispielsweise folgt anschließend noch das Setup eines Applikationsservers oder einer Runtime Umgebung. Der eigentlich einfache Workflow "Code klonen, Software bauen und laufen lassen" wächst zu einer langen ToDo-Liste an, welche zunächst abgearbeitet werden muss, bevor die erste produktive Zeile Code geschrieben werden kann. In der heutigen Zeit ein No-Go! Doch wie kann dieser Setup Aufwand minimiert werden?

Basierend auf einer [Beispielanwendung](https://github.com/iteratec/bring-your-own-pipeline) und dem exzessiven Gebrauch der Docker Container Laufzeitumgebung und deren Kommandozeilen Werkzeugen, soll dies im Folgenden illustiert werden. 
   
## Software mit Docker kapseln

In vielen Projekten wird Docker bereits für das Paketieren des Application-Servers verwendet. Ein gängiges Beispiel für ein Dockerfile in diesem Fall könnte wie folgt aussehen.
```dockerfile
FROM tomcat:8
ADD "*.war" webapps/
```

Nach einem lokalen Build mit Maven oder Gradle wird über `docker build` das Artefakt in das Docker Image kopiert. Damit ist zwar der lokale Applikationsserver gekapselt, jedoch muss der Entwickler alle nötigen Build-Tools vorinstalliert, und gegebenenfalls, vorkonfiguriert haben, bevor er das Docker-Image bauen kann. Das selbe trifft übrigens auf einen existierenden Build- oder CI/CD (Continous Integration / Continous Deployment)-Server zu. Denn auch dort müssen, wie auf den Entwickler-PCs, sämtliche Build-Abhängigkeiten der zu bauenden Projekte verfügbar sein. Dadurch wird, neben dem Aufwand für das Setup jedes Entwicklers, kontinuierlicher Aufwand für die Wartung und Pflege eben dieser Build-Tools in der CI/CD erzeugt.

Durch das Kapseln des Applikationsservers müssen sich die Entwickler nicht mehr um die Details der Installation und Konfiguration von z.B. Tomcat machen. Man könnte also sagen diese Details werden durch den Einsatz von Docker abstrahiert.

## Der Software Build als Black-Box

Wir wollen aber noch einen Schritt weiter gehen und nicht nur den Einsatz des Applikationsservers sondern auch die Details des gesamten Software Builds auf ähnliche Art abstrahieren. Ziel ist es die Fähigkeiten der Container-Virtualisierung durch Docker zu nutzen, um eine komplette Build-Umgebung bereitzustellen in der der Code gebaut werden kann.
 
Ein möglicher Weg ist Kapselung des Setups der Build-Umgebung mit einem "Single Command" Docker `run` wie im folgenden Beispiel dargestellt.
```bash
docker run --rm -v `pwd`:/build debian:buster-slim bash -c "cd /build && sudo apt-get install build-deps && ./build.sh"
```
Bereitgestellt in einer `build.sh` sorgt der Docker `run` für das Setup der Build Umgebung und dem anschließenden Build der Software. Das Code Repository wird dafür als "Volume" in den Container via `-v` inkludiert und erlaubt lesende und schreibende Zugriffe auf das Code Repository aus dem Container heraus. Abschließend wird der beendete Container durch `--rm` entfernt. Als Ergebnis liegt das gebaute Artefakt vor und kann anschließend in einen containerisierten Applikationsserver deployt werden.

Dieses Vorgehen sorgt dafür, dass neben der Abstraktion der Build-Umgebung zudem der Bauplan der Software in einer `build.sh` zentralisiert und transparent ist. Dadurch eröffnet sich die Möglichkeit lokal sowie in einer CI/CD Umgebung gleichermaßen die Software zu bauen, ohne das nötige Vorbereitungen und Setup getätigt werden müssen. Lediglich die Verfügbarkeit von Docker ist eine harte Bedingung.

Doch gerade in einer CI/CD Umgebung birgt dieses Vorgehen auch Probleme, da die Software Builds durch den "Volume Mount" auf dem Dateisystem des Build-Servers arbeiten und womöglich dort eine Vielzahl an Dateien in unterschiedlichen Größen ablegen und persistieren. Dies sorgt dafür, dass der Speicherbedarf stetig steigt und manueller Bereinigungsaufwand entsteht. Das Vorgehen ist dadurch zustandsbehaftet. Im folgenden wollen wir diesen persitenten Zustand ablegen.   

## Zustandslos durch Multi-Stage Builds

Seit der Version 17.05 schafft Docker für diese Problematik ebenfalls Abhilfe und führt die Multi-Stage Builds ein. Wie das folgende Beispiel zeigt, ist ein "Shared Volume" nicht mehr nötig. Vielmehr existiert die Möglichkeit innerhalb eines Docker Builds Dateien zwischen verschiedenen Image-Layern, unseren "Build Stages", auszustauschen.

```dockerfile
FROM debian:buster-slim as builder

# Install Build Tools
RUN apt-get -qq update
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      -y --no-install-recommends \
      python-pygments \
      git \
      ca-certificates \
      asciidoc \
      hugo

# Generate Sources
RUN mkdir sample-blog
RUN hugo new site ./sample-blog

# Copy Source Code
ADD src/ ./sample-blog/

# Perform Build
RUN git clone \
      https://github.com/jpescador/hugo-future-imperfect.git \
      ./sample-blog/themes/future-imperfect
RUN cd sample-blog && hugo

# Start new layer from differen base image
FROM nginx:1.13-alpine

# Copy Build Results from Builder
COPY --from=builder ./sample-blog/public/ /usr/share/nginx/html
```
Die grundsätzliche Struktur unterscheidet sich hierbei nicht von den Dockerfiles wie wir sie kennen. Neu ist jedoch dass zusätzliche Image layer mit erneutem `FROM` eingefügt werden können. Diese können wie im beispiel auch benamt werden. Wichtig ist dass jeweils nur die letzte "Build Stage" in das resultierende Image übernommen wird. Der Clou ist jedoch dass einzelne Dateien oder Verzeichnisse aus vorhergehenden Stages übernommen werden können. Dazu bietet die `COPY` Instruktion nun einen zusätzlichen `--from` Parameter. Nähere Details zu dem Feature gibt es im [Docker User Guide](https://docs.docker.com/engine/userguide/eng-image/multistage-build/).

Mit einem Multi-Stage Docker Build muss die gebaute Software nicht mehr auf dem Host zwischengespeichert werden. Zudem existiert die komplette Build Umgebung nur temporär in der ersten Build-Stage. Nach Abschluss des Docker Builds wird die gesamte Build Umgebung verworfen und hinterlässt keine Spuren auf dem Dateisystem. Anschließendes Bereinigen von Verzeichnissen ist somit nicht nötig. 

Die komplette Build Strecke ist nun zentral in einem Dockerfile beschrieben und kann in einer beliebigen Umgebung per `docker build` zum Build der Software genutzt werden. Als Resultat entsteht ein Docker Image, welches nur die gebauten Artefakte enthält und diese unter anderem gleich in eine containerisierte Umgebung wie z.B einen Applikationsserver deployt. Dadurch wird keinerlei Wissen über die Software und dessen Build Pipeline benötigt, was die lokale Arbeit deutlich vereinfacht und nötige Abhängigkeiten innerhalb der CI/CD reduziert. Sowohl lokal als auch in einer CI/CD Umgebung sorgt der Workflow "Git klonen, Docker Image bauen und in einer Umgebung ausführen" für lauffähige Software.

## Ausblick: Trennung von Base Image und Software-Artefakt Image

Es ist jedoch nicht immer von Vorteil, wenn das Software-Artefakt stark mit einer festen Version des Base Images verwoben ist. Wurde beispielsweise ein wichtiger Security Patch durch eine neue Version im Nginx Base Images ausgerollt, so zieht das Update des Base Images einen komplett neuen Build der Software nach sich. Oftmals sind die Builds jedoch nicht reproduzierbar und liefern unterschiedliche Ergebnisse oder schlagen im schlimmsten Fall fehl. Dieses Problem wird vorallem interessant, sobald mehrere Teams auf einer Plattform arbeiten und eine Trennung zwischen Entwicklung und Betrieb entsteht. In diesem Szenario ist es oftmals nötig Software Artefakte in beliebigen Version in beliebige Base Images integrieren zu können. Doch wie legt man beispielsweise ganze Websites wie die Beispielapplikation versioniert ab?

Aber auch für dieses Problem liefert Docker einen Lösungsansatz, welcher auf den Multi-Stage Docker Build setzt. Wie im Dockerfile ersichtlich kann der Multi-Stage Build ebenfalls genutzt werden, um das Software Artefakt zu bauen und anschließend in einem Docker Image zu bündeln. Hierbei empfielt sich das "Scratch" Image. Dadurch bleibt das eigentlich Artefakt Image minimal klein und belegt keinen unnötigen Speicher, was besonders beim Cloud-Hosting interessant ist. 
```dockerfile
FROM <base-image> as bundler
ADD source code
RUN install build tools
RUN build application
RUN extract version

FROM scratch
COPY --from=bundler /app/build /
COPY --from=bundler /version /
```
Durch diesen Schritt wird das eigentliche Software Artefakt in ein Docker Image gebündelt und kann anschließend in einer Docker Registry versioniert abgelegt werden. Da das Docker Image selbst jedoch keinen Bezug zum Inhalt hat, muss vor dem Upload in die Docker Registry das Image passend zur Version des Artefakts getaggt werden. Diese Information kann das Docker Image selbst zum Beispiel "by convention" in einem Version-File bereitstellen und nach dem `docker build` über `docker export` extrahiert werden.   
```bash
docker build . -t blog-app-target:latest

id=$(docker create blog-app-target:latest '')
APP_VERSION=$(docker export ${id} | tar -xO version)
docker rm -v ${id}

docker tag blog-app-target:${APP_VERSION}
docker push blob-app-target:${APP_VERSION}
```
Dieses Vorgehen ermöglicht somit das Bauen und versionierte Ablegen diverser Software Artefakte unabhängig von verwendeten Technologien und Build Tools. Zudem vereinfacht es die Systemlandschaft und Komplexität, da nicht für diverse Software Artefakte passende "Registries" oder "Artifact Stores" bereitgestellt und gewartet werden müssen. Alles was benötigt wird sind Docker und eine Docker Registry.

Um eines dieser Artefakt-Images in ein Base-Image zu integrieren, ist es möglich ein generisches Dockerfile aus der Entwicklersicht bereitzustellen. Auch hier bietet Docker durch die "Build Arguments" und natürlich den Multi-Stage Build Unterstützung. Die Build Argumente agieren als Platzhalter, welche zum Buildzeitpunkt des Dockerfiles ersetzt werden können. In diesem Fall sogar als Platzhalter für das Artefakt-Image, welches in das Base-Image integriert werden soll.
```dockerfile
ARG APP_DIST_IMAGE
FROM $APP_DIST_IMAGE as dist
FROM nginx:latest
COPY --from=dist / /usr/share/nginx/html
```

Durch diese Kapselung und Trennung von Artefakt-Image und Base-Image Erzeugung ist es anschließend für den Betrieb jederzeit möglich das Artefakt in ein Base-Image zu integrieren oder auch das Base-Image zu aktualisieren, ohne die Artefakte neu bauen zu müssen. Nötig dafür ist lediglich ein `docker build`. 
```bash
docker build . -t blog-app:1.0.0 --build-arg APP_DIST_IMAGE=blog-app-target:1.0.0
```
Als Ergebnis resultiert ebenfalls ein lauffähiges Docker Image welches auf einer beliebigen Instanz ausgeführt werden kann.  

## Fazit

Durch Docker und die Fähigkeit der Multi-Stage Docker Builds ist es möglich den Software Build vollständig zu abstrahieren. Teils aufwändige Setup's von Build Umgebungen können eingespart werden und ermöglichen frühzeitig die erste produktive Zeile Code eines Entwicklers. Auch Aufwände innerhalb der CI/CD entfallen, da keine Vielzahl an Build Tools gepflegt und gewartet werden müssen. Zudem weichen die Abhängigkeiten zwischen Entwicklung und Betrieb auf, da die Entwickler selbst die verwendeten Technologien bestimmen können ohne durch Umgebungen limitiert zu sein. Ein wesentlicher Faktor in der Zeit des verteilten kollaborativen Arbeitens. Durch die Definition der Dockerfiles durch einen Entwickler wird der Software Build zur Black-Box und funktioniert auf jeder Umgebung gleich. Einzig und allein nötig sind Git und Docker!
