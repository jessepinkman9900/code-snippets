FROM debian:12.11

# Basic system stuff
RUN apt-get -qy update && \
    apt-get -qy install \
        apt-transport-https

# Install packages
RUN apt-get -qy update && \
    apt-get -qy install \
        dos2unix openssh-server pwgen

# When run, boot-debian-base will call this script, which does final
# per-db-node setup stuff.
ADD docker/node/setup-jepsen.sh /usr/local/preinit/setup-jepsen
RUN chmod +x /usr/local/preinit/setup-jepsen

# Configure SSHD
RUN sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config

# Enable SSH server
ENV DEBBASE_SSH enabled

# Install Jepsen deps
RUN apt-get -qy update && \
    apt-get -qy install \
        build-essential bzip2 ca-certificates curl dirmngr dnsutils faketime iproute2 iptables iputils-ping libzip4 logrotate lsb-release man man-db netcat-openbsd net-tools ntpdate psmisc python3 rsyslog sudo tar tcpdump unzip vim wget

EXPOSE 22

CMD ["tail", "-f", "/dev/null"]
