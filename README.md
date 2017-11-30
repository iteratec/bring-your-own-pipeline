# Über dieses Repository

Dieses Repository beschreibt wie Teams mittels Docker ihre gesamten Build-Abhängigkeiten mitbringen können. Es enthält Ausführbaren Beispiel-Code für verschiedene Ansätze sowie Beschreibungen und Vergleiche dieser.

## Ausführen der Beispielsoftware

Wie wir in unserem [Artikel](./src/content/blog/pipeline.md) propagieren wird für die Ausführung nur [git](https://git-scm.com/) und [docker](https://docker.io) benötigt.

```bash
git clone https://github.com/iteratec/bring-your-own-pipeline.git
docker build -t byop .
docker run -p 8080:80 byop
firefox -url 'localhost:8080'
```
