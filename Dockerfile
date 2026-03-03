FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY app/pom.xml ./pom.xml
COPY app/src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:17-jdk
WORKDIR /opt/app
COPY --from=build /build/target/direct-memory-lab-1.0.0.jar /opt/app/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/opt/app/app.jar"]
