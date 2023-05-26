#!/bin/bash

# Wait for DB to start
counter=0

while ! java $JAVA_OPTS -Djava.security.egd=file:/dev/urandom -jar /app.jar
do
  if (( counter > 10 ))
  then
    echo "Failed to connect with database" 1>&2
    exit 1
  fi
  ((counter=counter+1))
  sleep 15
done
