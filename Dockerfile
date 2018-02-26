FROM alpine:3.6

ENV JAVA_HOME=/usr/lib/jvm/default-jvm/jre

ENV JRE_HOME=${JAVA_HOME} \
    PENTAHO_JAVA_HOME=${JAVA_HOME} \
    PENTAHO_HOME=/opt/pentaho

ENV PDI_HOME=${PENTAHO_HOME}/data-integration \
    KETTLE_HOME=${PENTAHO_HOME}/kettle-home \
    TMP_DOCKER_BUILD_DIR=/tmp/tmp-build \
    PATH=${PATH}:${JAVA_HOME}/bin:${PDI_HOME}

# To make pdi-8-slim, take a copy of PDI-8 CE and use these instructions to slim it down:
# https://gist.github.com/matthewtckr/5e9167f283f2267a4890

# TODO: use a multi-stage build to get JDBC libraries into cleaner target image.
# TODO: use a multi-stage build to create pdi-slim from a download.
# Location of PDI:
# wget /tmp/pdi-ce.zip https://sourceforge.net/projects/pentaho/files/Pentaho%208.0/client-tools/pdi-ce-8.0.0.0-28.zip && \

RUN apk update && \
    apk add openjdk8-jre bash webkitgtk curl && \
    apk add --virtual build-dependencies ca-certificates openssl && \
    update-ca-certificates && \
    mkdir -p ${PENTAHO_HOME} && \
    mkdir -p ${TMP_DOCKER_BUILD_DIR} && \
    cd ${TMP_DOCKER_BUILD_DIR} && \
    curl -Lo pdi-ce-6.1.0.1-196.zip https://sourceforge.net/projects/pentaho/files/Data%20Integration/6.1/pdi-ce-6.1.0.1-196.zip && \
    unzip pdi-ce-6.1.0.1-196.zip && \
    mv data-integration ${PENTAHO_HOME} && \
    echo "Sliming the build down..." && \
    echo "<listeners></listeners>" > ${PDI_HOME}/classes/kettle-lifecycle-listeners.xml && \
    echo "<registry-extensions></registry-extensions>" > ${PDI_HOME}/classes/kettle-registry-extensions.xml && \
    cd ${PDI_HOME}/lib && \
    rm blueprints*.jar org.apache.aries.*.jar org.apache.felix.*.jar org.apache.karaf.*.jar pdi-osgi-bridge-*.jar pentaho-osgi-*.jar && \
    rm -r ${PDI_HOME}/plugins/kettle5-log4j-plugin && \
    echo "We could also remove plugins/pentaho-big-data-plugin but this contains the S3 output plugin." && \
    echo "Get drivers..." && \
    cd ${TMP_DOCKER_BUILD_DIR} && \
    curl -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.45.tar.gz | tar xz -C ${PDI_HOME}/lib/ mysql-connector-java-5.1.45/mysql-connector-java-5.1.45-bin.jar && \
    curl -Lo jtds-1.3.1-dist.zip https://sourceforge.net/projects/jtds/files/jtds/1.3.1/jtds-1.3.1-dist.zip/download && \
    unzip jtds-1.3.1-dist.zip && \
    cp -p jtds-1.3.1.jar ${PDI_HOME}/lib && \
    cd / && \
    rm -rf ${TMP_DOCKER_BUILD_DIR} && \
    apk del build-dependencies && \
    chmod -R g+w ${PENTAHO_HOME}

VOLUME ["/opt/pentaho/repository","opt/pentaho/kettle-home"]

WORKDIR $PDI_HOME

CMD ["/bin/bash"]
