FROM ubuntu:18.04

WORKDIR /app
COPY run.sh /app

RUN dpkg --add-architecture armv7
RUN apt update && apt -y dist-upgrade
RUN apt install -y gcc make gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi g++ autoconf gcc-arm-none-eabi gcc-arm-linux-gnueabihf mc git wget libtool

CMD ["/bin/bash", "run.sh"]
