FROM azul/zulu-openjdk:8

# set from build process or (-–build-arg)
ARG BACKEND_JAR
ARG FRONTEND_ASSETS_DIR

VOLUME /tmp

# Update Ubuntu
RUN \
  bash -c 'apt-get -qq update && apt-get -y upgrade && apt-get -y autoclean && apt-get -y autoremove' 

ENV USER_NAME kehowli
ENV APP_HOME /opt/poc-api/$USER_NAME

RUN \
  useradd -ms /bin/bash $USER_NAME && \
  mkdir -p $APP_HOME

ADD $BACKEND_JAR ${APP_HOME}/backend.jar

RUN mkdir ${APP_HOME}/public
ADD $FRONTEND_ASSETS_DIR ${APP_HOME}/public

RUN \
  chown $USER_NAME $APP_HOME/backend.jar && \
  bash -c 'touch ${APP_HOME}/backend.jar'

ENV JAVA_TOOL_OPTIONS "-Xms128M -Xmx128M -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

USER $USER_NAME
WORKDIR $APP_HOME
ENTRYPOINT ["java", "-jar", "backend.jar"]