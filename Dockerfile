ARG DNSMASQ_VER=2.92

FROM debian:12-slim AS builder

ARG DNSMASQ_VER

RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    xz-utils \
    libcap-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN wget https://thekelleys.org.uk/dnsmasq/dnsmasq-${DNSMASQ_VER}.tar.xz \
    && tar -xJf dnsmasq-${DNSMASQ_VER}.tar.xz

WORKDIR /src/dnsmasq-${DNSMASQ_VER}

RUN make COPTS="-DNO_DNS -DNO_DHCP -DNO_DHCP6 -DNO_RA -DNO_LOOP -DNO_AUTH -DNO_IPSET -DNO_IDN -DNO_LUASCRIPT -DNO_DBUS -DNO_UBUS"

FROM gcr.io/distroless/base-debian12:nonroot

ARG DNSMASQ_VER
ARG BASE_DIGEST

LABEL org.opencontainers.image.version=$DNSMASQ_VER
LABEL org.opencontainers.image.base.digest=$BASE_DIGEST

COPY --from=builder /src/dnsmasq-${DNSMASQ_VER}/src/dnsmasq /usr/local/bin/dnsmasq

WORKDIR /tftpboot

# Port 69 für TFTP (UDP)
EXPOSE 69/udp

ENTRYPOINT [ \
    "/usr/local/bin/dnsmasq", \
    "-k", \
    "--port=0", \
    "--enable-tftp", \
    "--tftp-root=/var/lib/tftpboot", \
    "--tftp-no-fail", \
    "--read-ethers", \
    "--log-facility=-", \
    "--user=nonroot" \
]
