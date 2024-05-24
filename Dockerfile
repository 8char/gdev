FROM --platform=$TARGETOS/$TARGETARCH debian:bullseye-slim as base
LABEL author='Matteo Krans Dusic' maintainer='matteokrantz@gmail.com'

RUN dpkg --add-architecture i386 \
    && apt update \
    && apt upgrade -y \
    && apt install -y tar curl gcc g++ lib32gcc-s1 libgcc1 libcurl4-gnutls-dev:i386 libssl1.1:i386 libcurl4:i386 lib32tinfo6 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses5:i386 libcurl3-gnutls:i386 libsdl2-2.0-0:i386 iproute2 gdb libsdl1.2debian libfontconfig1 telnet net-tools netcat tzdata numactl tini \
    && groupadd -g 999 container \
    && useradd -m -d /home/container -u 999 -g container container \
    && mkdir -p /home/container/steam_cache \
    && mkdir -p /home/container/garrysmod/cache

# SETUP GAME
FROM base AS install-gameserver
WORKDIR /tmp

RUN curl -o ./steamcmd_linux.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && mkdir ./steamcmd \
    && tar -xvzf steamcmd_linux.tar.gz -C ./steamcmd \
    && rm steamcmd_linux.tar.gz \
    && ./steamcmd/steamcmd.sh +quit \
    && mkdir -p ./.steam/sdk32 \
    && cp -v ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so \
    && mkdir -p ./.steam/sdk64 \
    && cp -v ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so

RUN ./steamcmd/steamcmd.sh \
    +force_install_dir /home/container \
    +login anonymous +app_update 4020 \
    -validate \
    -beta NONE \
    +quit

# SETUP CONTENT
FROM install-gameserver AS install-content
WORKDIR /home/container

# here i omitted some of our internal links and operations such as installing
# games content (css and such), dlls and such

# RUN GAMESERVER
FROM base AS run

USER container
ENV USER=container HOME=/home/container
ENV LD_LIBRARY_PATH=/home/container/bin
COPY --from=install-content --chown=container:container /home/container /home/container
WORKDIR /home/container

RUN chmod -R 777 /home/container

STOPSIGNAL SIGINT

ENV GMOD_TICKRATE=16
ENV GMOD_PORT=27015
ENV GMOD_GAMEMODE=sandbox
ENV GMOD_MAP=gm_construct
ENV GMOD_PLAYERS=16
ENV GMOD_HIBERNATE_THINK=true
ENV GMOD_ALLOW_LOCAL_HTTP=false
ENV GMOD_KEYS_SERVER_ACCOUNT=

COPY ./entrypoint.sh /entrypoint.sh
CMD /bin/bash /entrypoint.sh