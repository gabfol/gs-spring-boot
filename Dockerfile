FROM openjdk:8-jdk-alpine
LABEL author="Gabriele Folchi <gabriele.folchi@gmail.com>" name="DevToolBox"

# ----
# define parameters (can be overridden by "docker build --build-args key=value...")
ARG MAVEN_VERSION=3.5.2  
ARG USER_HOME_DIR="/root"
# set as env vars to be reused inside dockerfile and app instance....
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Install Maven
RUN apk add --no-cache curl tar bash
RUN mkdir -p /usr/share/maven && \
	curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -xzC /usr/share/maven --strip-components=1 && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
# ----

# ----
# prepare local project folder structure: 
ARG app_dir														
ENV PROJ_DIR=/usr/src/app/$app_dir

RUN mkdir -p $PROJ_DIR
WORKDIR $PROJ_DIR
# ----

# ----
# one-time load maven repository executing pom default dependencies 
ADD pom.xml $PROJ_DIR
RUN ["mvn", "verify", "clean", "--fail-never"]
# ----

# ---- docker build -t $APP_IMG --build-arg app_dir=$APP_DIR --build-arg MAVEN_VERSION=3.5.2 .
# ---- docker build -t devtoolbox --build-arg app_dir="$(PWD)" --build-arg MAVEN_VERSION=3.5.2 .

# ---- docker run --rm -itd  --name $APP_INSTANCE -e "APP_PORT=$APP_PORT" -p $APP_PORT:$APP_PORT  -v "$PWD":/usr/src/app/$APP_DIR  $APP_IMG  bash  
# ---- WIN: docker run --rm -itd  --name devtoolbox-inst -e "APP_PORT=8080" -p 8080:8080  -v d:\demos\gs-spring-boot:/usr/src/app/gs-spring-boot  devtoolbox  bash
# ----- docker attach devtoolbox
# ----- when in the container, run "mvn clean install" to build src and "java -jar ......" to run app