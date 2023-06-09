# CDDBAPI

This application is designed for use in DevOps and SRE training.

The application is a simple personal CD Database application using Python Flask with a MySQL Database backend, and a separate Python script that will retrieve CD information from Deezer API to populate tracks for a given CD information.

The Python Flask API allows for;
* Full listing of the CDs in the database
* Listing a specific CD by id
* Adding CDs
* Updating CDs
* Deleting CDs

## The components

The following components are created as containers:

* [MySQL Database](Database/Dockerfile)
  * The initial Database set up
  * Loads top level CD data, but not the tracks
* [Python API](Python/Dockerfile)
  * The Web API service that communicates with the DB
* [Python DB Updater](Python/Dockerfile-dbupdate)
  * You should run this container after initial setup
  * This container is used to load the tracks for each CD
  * It also updates the number of tracks in the compact_discs table
  * As part of the system this should be used as a chronological task to check the tracks are up to date.

### Python container environment files

If you change the database configuration, see **[.env](Python/.envdocker)** for format and values, you should map a folder on your system containing a file called .env to **/app/env** in the container.

e.g.
```
docker run -d -v $HOME/myenv:/app/env ....
```

Where **$HOME/myenv** contains the **.env** file.

## Building and Running

The system is built to use Docker as we wish to use microservices and scalability.  This application may have a web frontend applied.  The whole system can be ran locally on system running Docker to test using **docker compose**.

The system is also set up to run in Kubernetes and also built using a Jenkins pipeline.

### Building and running on a Docker machine

To use this method you will need to have **docker compose** installed.

- Change to the **CDDBAPI** directory
- Use the following **docker compose** command to start
  ```
  docker compose up -d
  ```
  This will build and launch all containers.
  
#### Rebuild container

If you make a change to any of your code and need to rebuild the containers, do the following:

```
docker compose build
```

The above rebuilds any changed containers

For a specific container:
```
docker compose build cdapi
```

The above will rebuild only the **cdapi** container.

#### Build and run in Jenkins

TBD

#### Run in Kubernetes

TBD

## The API

### Listing all CDs

```
$ curl -H 'Content-Type: application/json' localhost:8080/api/cds
```

### List a CD

```
$ curl -H 'Content-Type: applicaiton/json' localhost:8080/api/cds/1
```

### Adding a CD without tracks

```
$ curl -X POST -H 'Content-Type: application/json' localhost:8080/api/cds -d '{
"title": "This is Steve",
"artists": "Me",
"price": 12.99
}'
```

Returns:
```
{'status': 'OK', 'ID':2, 'firstTrackId':}
```

### Adding a CD with tracks
```
$ curl -X POST -H 'Content-Type: application/json' localhost:8080/api/cds -d '
{
    "title": "Steve Does That",
    "artist": "Steve",
    "tracks": 2,
    "price": 20.99,
    "trackTitles": [
        "Baa Baa Baby", 
        "Baby Ewe Love Me"
    ]
}'
```

Returns:

```
{'status': 'OK', 'ID':2, 'firstTrackId':23}
```

### Updating CD

```
$ curl -X PUT -H 'Content-Type: application/json' localhost:8080/api/cds/2 -d '
{
    "title": "Steve Does That",
    "artist": "Steve",
    "tracks": 2,
    "price": 20.99,
    "trackTitles": [
        { { 'currentTitle': 'Baa Baa Baby', 'newTitle': 'Born to be Ewe' },
          { 'currentTitle': 'Baby Ewe Love Me', 'Ewe Left Me Just When I Needed Ewe Moss': newtitlename }
    ]
}'
```

Returns:
```
{"status": "Tracks updated OK"}
```