FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="40" \
    SERIAL="" \
    SOAPYSDR="" \
    SERVER="acarshub" \
    SERVER_PORT="5555" \
    VDLM_FILTER_ENABLE="TRUE" \
    VDLM_FILTER="all,-avlc_s,-acars_nodata,-x25_control,-idrp_keepalive,-esis"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,SC2039
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(automake) && \
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(wget) && \
    # packages for dumpvdl2
    TEMP_PACKAGES+=(libglib2.0-dev) && \
    KEPT_PACKAGES+=(libglib2.0-0) && \
    TEMP_PACKAGES+=(libzmq3-dev) && \
    KEPT_PACKAGES+=(libzmq5) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
    # install sdrplay
    curl --location --output /tmp/install_sdrplay.sh https://raw.githubusercontent.com/sdr-enthusiasts/install-libsdrplay/main/install_sdrplay.sh && \
    chmod +x /tmp/install_sdrplay.sh && \
    /tmp/install_sdrplay.sh && \
    # deploy airspyone host
    git clone https://github.com/airspy/airspyone_host.git /src/airspyone_host && \
    pushd /src/airspyone_host && \
    mkdir -p /src/airspyone_host/build && \
    pushd /src/airspyone_host/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON && \
    make && \
    make install && \
    ldconfig && \
    popd && popd && \
    # Deploy SoapySDR
    git clone https://github.com/pothosware/SoapySDR.git /src/SoapySDR && \
    pushd /src/SoapySDR && \
    BRANCH_SOAPYSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYSDR" && \
    mkdir -p /src/SoapySDR/build && \
    pushd /src/SoapySDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRTLTCP
    git clone https://github.com/pothosware/SoapyRTLTCP.git /src/SoapyRTLTCP && \
    pushd /src/SoapyRTLTCP && \
    mkdir -p /src/SoapyRTLTCP/build && \
    pushd /src/SoapyRTLTCP/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRTLSDR
    git clone https://github.com/pothosware/SoapyRTLSDR.git /src/SoapyRTLSDR && \
    pushd /src/SoapyRTLSDR && \
    BRANCH_SOAPYRTLSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYRTLSDR" && \
    mkdir -p /src/SoapyRTLSDR/build && \
    pushd /src/SoapyRTLSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Debug && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # install sdrplay support for soapy
    git clone https://github.com/pothosware/SoapySDRPlay.git /src/SoapySDRPlay && \
    pushd /src/SoapySDRPlay && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make && \
    make install && \
    popd && \
    popd && \
    ldconfig && \
    # Deploy Airspy
    git clone https://github.com/pothosware/SoapyAirspy.git /src/SoapyAirspy && \
    pushd /src/SoapyAirspy && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make    && \
    make install   && \
    popd && \
    popd && \
    ldconfig && \
    # Install dumpvdl2
    git clone https://github.com/szpajder/dumpvdl2.git /src/dumpvdl2 && \
    mkdir -p /src/dumpvdl2/build && \
    pushd /src/dumpvdl2/build && \
    # cmake ../ && \
    cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo -DRTLSDR=FALSE && \
    make -j "$(nproc)" && \
    make install && \
    popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*


COPY rootfs/ /

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
