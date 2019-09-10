FROM quay.io/bashell/ubuntu:arm
LABEL maintainer "Josh Sunnex <jsunnex@gmail.com>"


###############################################################
#
# Configure
#
###############################################################

# Version of Tizonia to be installed
ARG TIZONIA_VERSION=0.18.0-1

# Configure username for executing process
ENV UNAME tizonia

# A list of dependencies installed with
ARG PYTHON_DEPENDENCIES=" \
        fuzzywuzzy>=0.17.0 \
        gmusicapi>=12.1.1 \
        pafy>=0.5.4 \
        pycountry>=18.12.8 \
        python-levenshtein>=0.12.0 \
        soundcloud>=0.5.0 \
        spotipy>=2.4.4 \
        titlecase>=0.12.0 \
        youtube-dl>=2019.8.2 \
    "

ARG RUN_DEPENDENCIES=" \
        libxml2 \
        locales \
    "

# Build Dependencies (not required in final image)
ARG BUILD_DEPENDENCIES=" \
        build-essential \
        curl \
        gnupg \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        python-dev \
        python-pip \
        python-pkg-resources \
        python-setuptools \
        python-wheel \
    "

# Missing packages from armhf index
ARG MISSING_PACKAGES=" \
        tizilheaders \
        python-tizgmusicproxy \
        python-tizsoundcloudproxy \
        python-tizdirbleproxy \
        python-tizyoutubeproxy \
        python-tizplexproxy \
        python-tizchromecastproxy \
        python-tizspotifyproxy \
    "
ARG REPO_URL="https://dl.bintray.com/tizonia/ubuntu/pool/main/t/tizonia-bionic"

###############################################################



# Exec build step
RUN \
    echo "**** Update sources ****" \
       && apt-get update \
    && \
    echo "**** Install runtime dependencies ****" \
        && apt-get install -y --no-install-recommends \
            ${RUN_DEPENDENCIES} \
    && \
    echo "**** setup locales ****" \
        && sed -i -e 's/^# en_US\.UTF-8/en_US.UTF-8/g' /etc/locale.gen \
        && sed -i -e 's/^# th_TH\.UTF-8/th_TH.UTF-8/g' /etc/locale.gen \
        && locale-gen \
    && \
    echo "**** Install package build tools ****" \
        && apt-get install -y --no-install-recommends \
            ${BUILD_DEPENDENCIES} \
    && \
    echo "**** Add additional apt repos ****" \
        && curl -ksSL 'http://apt.mopidy.com/mopidy.gpg' | apt-key add - \
        && echo "deb http://apt.mopidy.com/ stable main contrib non-free" > /etc/apt/sources.list.d/libspotify.list \
        && curl -ksSL 'https://bintray.com/user/downloadSubjectPublicKey?username=tizonia' | apt-key add - \
        && echo "deb https://dl.bintray.com/tizonia/ubuntu bionic main" > /etc/apt/sources.list.d/tizonia.list \
        && apt-get update \
    && \
    echo "**** Install python dependencies ****" \
        && python -m pip install --no-cache-dir --upgrade ${PYTHON_DEPENDENCIES} \
    && \
    echo "**** Install tizonia ****" \
        && apt-get install -y \
            pulseaudio-utils \
            libspotify12 \
        && for pkg in ${MISSING_PACKAGES}; do curl -sLO ${REPO_URL}/${pkg}_${TIZONIA_VERSION}_all.deb; done \
        && dpkg -i *.deb \
        && rm -f *.deb \
        && apt-get install -y \
            tizonia-all=${TIZONIA_VERSION} \
    && \
    echo "**** create ${UNAME} user and make our folders ****" \
        && mkdir -p \
            /home/${UNAME} \
        && groupmod -g 1000 users \
        && useradd -u 1000 -U -d /home/${UNAME} -s /bin/false ${UNAME} \
        && usermod -G users ${UNAME} \
    && \
    echo "**** Cleanup ****" \
        && apt-get purge -y --auto-remove \
	        ${BUILD_DEPENDENCIES} \
        && apt-get clean \
        && rm -rf \
            /tmp/* \
            /var/tmp/* \
            /var/lib/apt/lists/* \
            /etc/apt/sources.list.d/* \
    && \
    echo


# Copy run script
COPY run.sh /run.sh


# Run Tizonia as non privileged user
USER ${UNAME}
ENV HOME=/home/${UNAME}
WORKDIR ${HOME}


ENTRYPOINT [ "/run.sh" ]
