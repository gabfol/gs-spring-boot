#### FIRST STAGE BUILD: to create a "dev toolbox" and to compile app for next stage

FROM openjdk:8-jdk-alpine as builder 
LABEL author="Gabriele Folchi <gabriele.folchi@gmail.com>" name="DevToolBox"

# ----
# define some parameters (can be overridden by "docker build --build-args key=value...")
ARG MAVEN_VERSION=3.5.2  
ARG USER_HOME_DIR="/root"
# set as env vars to be reused inside dockerfile and app instance....
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV stage="development"

# Install Maven and basic tools:
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
# first build, just to create maven repo in a separate docker UFS layer  
ADD pom.xml $PROJ_DIR
RUN ["mvn", "verify", "clean", "--fail-never"]

# first build of the project, to create a binary version for next build stage    
ADD src $PROJ_DIR/src
RUN ["mvn", "clean", "install"]


# ---- CL USAGE: 
# ---- docker build -t $APP_DEV_IMG --build-arg app_dir=$APP_DIR --build-arg MAVEN_VERSION=3.5.2 .
# ---- docker build -t devtoolbox --build-arg app_dir="$(PWD)" --build-arg MAVEN_VERSION=3.5.2 .

# ---- docker run --rm -itd  --name $APP_INSTANCE -e "APP_PORT=$APP_PORT" -p $APP_PORT:$APP_PORT  -v "$PWD":/usr/src/app/$APP_DIR  $APP_DEV_IMG  bash  
# ---- WIN: docker run --rm -itd  --name devtoolbox-inst -e "APP_PORT=8080" -p 8080:8080  -v d:\demos\gs-spring-boot:/usr/src/app/gs-spring-boot  devtoolbox  bash

# ----- docker attach devtoolbox
# ----- when in the container, run "mvn clean install" to build src and "java -jar target/*.jar......" to run app


###############################################################################
#### SECOND STASGE BUILD: to create a smaller image suitable for test & prod deployments   

FROM openjdk:8-jdk-alpine as packager  
MAINTAINER Gabriele Folchi <gabriele.folchi@gmail.com>

# prepare local project folder structure: 
ARG app_dir														
ENV PROJ_DIR=/usr/src/app/$app_dir
RUN mkdir -p $PROJ_DIR											 
WORKDIR $PROJ_DIR

# define prod container's parameters and runtime env vars : 
ARG app_port=8080												
ENV app_port=$app_port											 
ENV stage="production"
EXPOSE $app_port												

# copy the app binaries from previous build stage:
COPY --from=builder $PROJ_DIR/target/$app_dir-0.1.0.jar .
# plumb the entrypoint for prod container: 
ENTRYPOINT ["java", "-jar", "gs-spring-boot-0.1.0.jar"]
