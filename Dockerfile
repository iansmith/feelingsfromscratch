FROM ubuntu:20.04
RUN mkdir -p /tools
WORKDIR /tools

RUN apt-get update
RUN apt-get install -y build-essential
COPY *.bash ./
COPY *.patch ./
COPY *.md ./
