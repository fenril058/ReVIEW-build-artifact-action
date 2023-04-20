# https://help.github.com/en/actions/building-actions/creating-a-docker-container-action

# Container image that runs your code
FROM debian:bullseye-slim
LABEL maintainer="vvakame@gmail.com"

# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH

ENV REVIEW_VERSION 5.7.0
ENV REVIEW_PEG_VERSION 0.2.2
ENV NODEJS_VERSION 16

ENV PANDOC_VERSION 2.17.1.1
ENV PANDOC_DEB_VERSION 2.17.1.1-1

ENV LANG en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

# setup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    locales git-core curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen en_US.UTF-8 && update-locale en_US.UTF-8

# for Debian Bug#955619
RUN mkdir -p /usr/share/man/man1

# TexLive
RUN apt-get install perl --no-install-recommends && \
    apt-get install tar && \
    mkdir /tmp/install-tl-unx && \
    curl -L ftp://tug.org/historic/systems/texlive/2023/install-tl-unx.tar.gz | \
    tar -xz -C /tmp/install-tl-unx --strip-components=1 && \
    printf "%s\n" \
    "selected_scheme scheme-basic" \
    "tlpdbopt_install_docfiles 0" \
    "tlpdbopt_install_srcfiles 0" \
    > /tmp/install-tl-unx/texlive.profile && \
    /tmp/install-tl-unx/install-tl \
    --profile=/tmp/install-tl-unx/texlive.profile && \
    tlmgr install \
    collection-latexextra \
    collection-fontsrecommended \
    collection-langjapanese \
    latexmk && \
    rm -fr /tmp/install-tl-unx && \

ENV PATH /usr/local/texlive/2022/bin/x86_64-linuxmusl:$PATH

# for additional modules
ARG TEXMFLOCAL=/usr/local/texlive/texmf-local/tex/latex
RUN chmod -R 755 /usr/local/texlive

# relax exported file permission
ARG UID=1000
RUN adduser -D -u ${UID} latex
USER ${UID}

# install Re:VIEW environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    zip ruby-zip \
    ruby-nokogiri mecab ruby-mecab mecab-ipadic-utf8 poppler-data \
    graphviz gnuplot python3-blockdiag plantuml \
    ruby-dev build-essential \
    mecab-jumandic- mecab-jumandic-utf8- \
    poppler-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
## if you want to use ipa font instead of haranoaji font, use this settings
# RUN kanji-config-updmap ipaex

# setup Re:VIEW
RUN gem install bundler rake -N && \
    gem install review -v "$REVIEW_VERSION" -N && \
    gem install pandoc2review -N && \
    gem install rubyzip -N
#   gem install review-peg -v "$REVIEW_PEG_VERSION" -N

# install node.js environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash -
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g yarn

# install noto font
# RUN apt-get update && apt-get -y install fonts-noto-cjk-extra && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

## if you want to use noto font instead of haranoaji font, use this settings
# RUN kanji-config-updmap-sys noto-otc

RUN kanji-config-updmap-sys haranoaji

## install pandoc
RUN curl -sL -o /tmp/pandoc.deb "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_DEB_VERSION}-${TARGETARCH}.deb" && \
    dpkg -i /tmp/pandoc.deb && \
    rm /tmp/pandoc.deb

## set cache folder to work folder (disabled by default)
# RUN mkdir -p /etc/texmf/texmf.d && echo "TEXMFVAR=/work/.texmf-var" > /etc/texmf/texmf.d/99local.cnf

# FROM fenril058/docker-review@develop

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# ラベルの内容を増やす必要があるときは\（継続マーカー）を利用すること（LABELで始まるLABEL命令を増やさない）
LABEL maintainer="mhidaka <rabbitlog@gmail.com>"

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
