# Bareos director Dockerfile (fork of barcus/bareos-director
FROM debian:bullseye

LABEL maintainer="admin@zerix.at"

ENV DEBIAN_FRONTEND noninteractive
ENV BAREOS_KEY http://download.bareos.org/current/Debian_11/Release.key
ENV BAREOS_REPO http://download.bareos.org/current/Debian_11/
ENV BAREOS_DPKG_CONF bareos-database-common bareos-database-common

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -qq
RUN apt-get -qq -y install --no-install-recommends curl tzdata gnupg
RUN curl -Ls $BAREOS_KEY -o /tmp/bareos.key
RUN apt-key --keyring /etc/apt/trusted.gpg.d/bareos-keyring.gpg add /tmp/bareos.key
RUN echo "deb $BAREOS_REPO /" > /etc/apt/sources.list.d/bareos.list
RUN echo "${BAREOS_DPKG_CONF}/dbconfig-install boolean false" | debconf-set-selections
RUN echo "${BAREOS_DPKG_CONF}/install-error select ignore" | debconf-set-selections
RUN echo "${BAREOS_DPKG_CONF}/database-type select pgsql" | debconf-set-selections
RUN echo "${BAREOS_DPKG_CONF}/missing-db-package-error select ignore" | debconf-set-selections
RUN echo 'postfix postfix/main_mailer_type select No configuration' | debconf-set-selections
RUN apt-get update -qq
RUN apt-get install -qq -y --no-install-recommends bareos postgresql-client bareos-tools
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN tar czf /bareos-dir.tgz /etc/bareos

COPY webhook-notify /usr/local/bin/webhook-notify
RUN chmod u+x /usr/local/bin/webhook-notify

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh

EXPOSE 9101

VOLUME /etc/bareos

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/bareos-dir", "-u", "bareos", "-f"]
