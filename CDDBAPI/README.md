# CDDBAPI

This application is designed for use in DevOps and SRE training.

The application is a simple CD Database application using Spring Boot with a MySQL Database backend.  The current state as of March 2021 is that there is an API server and MySQL database.  The API allows for;
* Full listing
* Listing a specific CD by id
* Adding CDs
* Deleting CDs

A Jenkinsfile is supplied to enable the use of pipelines through Jenkins Blue Ocean, where by providing this GIT repo will automatically build the pipeline.

## Setting up Jenkins

For Jenkins to understand the pipeline you will need to add the following plugins and server configurations.

### Plugins and configurations

Plugins:

* Maven Integration
  - Jenkins automated installation ID = **maven-plugin**
  - Also installs **javadoc**.
* Pipeline Maven Integration
  - Jenkins automated installation ID = **pipeline-maven**
  - Required for the withMaven() in the Jenkinsfile
    - Also installs
      - H2 API
      - Config File Provider

Global Tool Configurations:
 * Add a Maven installation
   - Name: mvn363
     - This name aligns with the Jenkinsfile in the repo
   - Install from Apache version 3.6.3
   - Save

### Adding the GIT repo

Click the **Create a new Pipeline** button when it pops up.

Select GIT not GitHub as the connection to the repository and use your HTTPS connection.

Ignore the login unless your repo is private, this one is not.

Click **Create Pipeline**.

## The API

Listing all CDs
```
$ curl -H 'Content-Type: application/json' localhost:8080/api/compactdiscs
```

Adding a CD without tracks;
```
$ curl -X POST -H 'Content-Type: application/json' localhost:8080/api/compactdiscs -d '{
"title": "This is Steve",
"artists": "Me",
"price": 12.99
}'
```

Adding a CD with tracks;
```
$ curl -X POST -H 'Content-Type: application/json' localhost:8080/api/compactdiscs -d '
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