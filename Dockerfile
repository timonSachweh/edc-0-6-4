FROM gradle:8.5.0-jdk17 AS build

COPY --chown=gradle:gradle . /app
WORKDIR /app

# USER root                # This changes default user to root
# RUN chown -R gradle /app # This changes ownership of folder
# USER gradle              # This changes the user back to the default user "gradle"

RUN ./gradlew clean :connector:build --no-daemon -x test

FROM amazoncorretto:21-alpine
WORKDIR /app

COPY --from=build /app/connector/build/libs/roms-connector.jar /app/app.jar

COPY ./connector/resources/certs /app/resources/certs
COPY ./connector/resources/gaia-x /app/resources/gaia-x
COPY ./connector/resources/configuration/consumer-vault.properties /app/resources/configuration/vault.properties
COPY ./connector/resources/configuration/docker-connector.properties /app/resources/configuration/connector.properties



EXPOSE 19191
EXPOSE 19192
EXPOSE 19193
EXPOSE 19194
EXPOSE 19291

ENTRYPOINT ["java", "-Dedc.keystore=resources/certs/cert.pfx", "-Dedc.keystore.password=123456", "-Dedc.vault=resources/configuration/vault.properties", "-Dedc.fs.config=resources/configuration/connector.properties", "-jar", "./app.jar"]