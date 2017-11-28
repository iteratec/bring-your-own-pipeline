FROM debian:buster-slim as builder

RUN apt-get -qq update
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments git ca-certificates asciidoc hugo

RUN mkdir site
RUN hugo new site ./site
ADD README.md ./site/content/
ADD config.toml ./site/
RUN git clone https://github.com/tummychow/lanyon-hugo.git ./site/themes/lanyon
RUN cd site && hugo
RUN ls -la ./site/public/

FROM nginx:1.13-alpine
COPY --from=builder ./site/public/readme/index.html /usr/share/nginx/html
COPY --from=builder ./site/public/css /usr/share/nginx/html/css
RUN ls -la /usr/share/nginx/html
