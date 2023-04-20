# https://help.github.com/en/actions/building-actions/creating-a-docker-container-action

# Container image that runs your code
# FROM vvakame/review:5.5
FROM paperist/texlive-ja:2022-debian

# install Re:VIEW environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      lmodern fonts-lmodern cm-super tex-gyre fonts-texgyre \
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


# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# ラベルの内容を増やす必要があるときは\（継続マーカー）を利用すること（LABELで始まるLABEL命令を増やさない）
LABEL maintainer="mhidaka <rabbitlog@gmail.com>"

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
