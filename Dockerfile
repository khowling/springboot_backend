FROM azul/zulu-openjdk:8

VOLUME /tmp

# Update Ubuntu
RUN \
  bash -c 'apt-get -qq update && apt-get -y upgrade && apt-get -y autoclean && apt-get -y autoremove' 

ENV USER_NAME kehowli
ENV APP_HOME /opt/poc-api/$USER_NAME

RUN \
  useradd -ms /bin/bash $USER_NAME && \
  mkdir -p $APP_HOME

ADD build/libs/*.jar ${APP_HOME}/backend-0.0.1-SNAPSHOT.jar
RUN \
  chown $USER_NAME $APP_HOME/backend-0.0.1-SNAPSHOT.jar && \
  bash -c 'touch ${APP_HOME}/backend-0.0.1-SNAPSHOT.jar'

ENV JAVA_TOOL_OPTIONS "-Xms128M -Xmx128M -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

USER $USER_NAME
WORKDIR $APP_HOME
ENTRYPOINT ["java", "-jar", "backend-0.0.1-SNAPSHOT.jar"]