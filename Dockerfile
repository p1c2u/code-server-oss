FROM node:18 as builder

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

# Proxy is only needed during git clone and yarn
ENV HTTP_PROXY=$HTTP_PROXY
ENV HTTPS_PROXY=$HTTPS_PROXY
ENV PATH=/usr/src/bin:$PATH
ENV VSCODE_TAG=$VSCODE_TAG

RUN git clone --progress --filter=tree:0 https://github.com/microsoft/vscode.git --branch=$VSCODE_TAG /usr/src/vscode

WORKDIR /usr/src/vscode

COPY ./bin/code-server-deps-install /usr/src/bin/code-server-deps-install
RUN code-server-deps-install

COPY ./bin/code-server-src-patch /usr/src/bin/code-server-src-patch
RUN code-server-src-patch

COPY ./bin/code-server-compile /usr/src/bin/code-server-compile
RUN code-server-compile

FROM node:18

WORKDIR /code-server-oss

COPY --from=builder /usr/src/vscode/.build ./
COPY --from=builder /usr/src/vscode/extensions ./
COPY --from=builder /usr/src/vscode/node_modules ./
COPY --from=builder /usr/src/vscode/out-vscode-reh-web-min ./out
COPY --from=builder /usr/src/vscode/product.json ./
COPY --from=builder /usr/src/vscode/package.json ./
COPY --from=builder /usr/src/vscode/resources ./

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["./entrypoint.sh"]
