FROM debian:12.11

RUN apt-get update && apt-get install -y git dos2unix openjdk-17-jdk libjna-java gnuplot graphviz curl openssh-client

# install lein
ENV LEIN_ROOT=true
RUN curl https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -o /usr/local/bin/lein && \
    chmod a+x /usr/local/bin/lein && \
    lein


ADD docker/control/bashrc /root/.bashrc
ADD docker/control/init.sh /init.sh
RUN dos2unix /init.sh /root/.bashrc \
    && chmod +x /init.sh

CMD /init.sh
