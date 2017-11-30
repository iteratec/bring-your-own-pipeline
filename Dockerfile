FROM debian:buster-slim as builder

RUN apt-get -qq update
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments git ca-certificates asciidoc hugo

RUN mkdir sample-blog
RUN hugo new site ./sample-blog

ADD README.md ./sample-blog/content/blog/
ADD src/config.toml ./sample-blog/
ADD src/static/ ./sample-blog/static/

RUN git clone https://github.com/jpescador/hugo-future-imperfect.git ./sample-blog/themes/future-imperfect
RUN cd sample-blog && hugo

RUN ls -la ./sample-blog/public/

FROM nginx:1.13-alpine
COPY --from=builder ./sample-blog/public/ /usr/share/nginx/html
RUN ls -la /usr/share/nginx/html