# VERSION 1.8.1
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM debian:jessie
MAINTAINER Puckel_

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.8.1
ARG AIRFLOW_HOME=/usr/local/airflow

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN set -ex \
    && buildDeps=' \
        python-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        python-pip \
        python-requests \
        apt-utils \
        curl \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && python -m pip install -U pip \
    && pip install Cython \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,hdfs,jdbc]==$AIRFLOW_VERSION \
    && pip install celery[redis]==3.1.17 \
    && apt-get remove --purge -yqq $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

# gcloud
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y curl python2.7 apt-transport-https lsb-release
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
ENV HOME /
RUN  apt-get update && apt-get install -y google-cloud-sdk

RUN gcloud config set core/disable_usage_reporting true
RUN gcloud config set component_manager/disable_update_check true
VOLUME ["/.config"]

ENV KUBECTL_VERSION 1.3.0

RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && chmod +x /usr/local/bin/kubectl

COPY script/entrypoint.sh ${AIRFLOW_HOME}/entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME} \
    && chmod +x ${AIRFLOW_HOME}/entrypoint.sh

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["./entrypoint.sh"]
