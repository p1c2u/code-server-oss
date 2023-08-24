FROM node:16 as base

ARG VSCODE_TAG=main
ARG HTTP_PROXY
ARG HTTPS_PROXY

# Build deps
RUN apt-get update && \
    apt-get autoclean && \
    apt-get install -y \
        libxkbfile-dev \
        pkg-config \
        libsecret-1-dev \
        libxss1 \
        dbus \
        xvfb \
        libgtk-3-0 \
        libgbm1

FROM base as builder

# Proxy is only needed during git clone and yarn
ENV HTTP_PROXY=$HTTP_PROXY
ENV HTTPS_PROXY=$HTTPS_PROXY
ENV PATH=/usr/src/bin:$PATH
ENV VSCODE_TAG=$VSCODE_TAG

RUN git clone --progress --filter=tree:0 https://github.com/microsoft/vscode.git --branch=$VSCODE_TAG /usr/src/vscode

WORKDIR /usr/src/vscode

RUN yarn config set registry https://registry.npmjs.org/
RUN yarn config set network-timeout 1200000

COPY ./bin/code-server-deps-install /usr/src/bin/code-server-deps-install
RUN code-server-deps-install

COPY ./bin/code-server-src-patch /usr/src/bin/code-server-src-patch
RUN code-server-src-patch

COPY ./bin/code-server-compile /usr/src/bin/code-server-compile
RUN code-server-compile

COPY ./bin/code-server-postbuild /usr/src/bin/code-server-postbuild
RUN code-server-postbuild

FROM base as release

RUN apt-get update && \
    apt-get autoclean && \
    apt-get install -y \
        vim \
        zsh \
        fish \
        tmux

COPY --from=builder /usr/src/code-server-oss /code-server-oss
RUN chmod +x /code-server-oss/out/server-main.js

WORKDIR /code-server-oss

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
