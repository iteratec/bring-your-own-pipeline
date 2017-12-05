FROM debian:buster-slim as builder

# install build tools
RUN apt-get -qq update
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments git ca-certificates asciidoc hugo

# Generate Sources
RUN mkdir sample-blog
RUN hugo new site ./sample-blog

# Copy source code
ADD src/ ./sample-blog/

# Perform Build
RUN git clone https://github.com/jpescador/hugo-future-imperfect.git ./sample-blog/themes/future-imperfect
RUN cd sample-blog && hugo

# ----------- Cut Here ------------

FROM nginx:1.13-alpine

# Copy Build Results from builder
COPY --from=builder ./sample-blog/public/ /usr/share/nginx/html
