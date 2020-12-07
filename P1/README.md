# P1

## How to run

### Setting up database

#### Option 1: Docker and Docker-compose

> Requires Docker and Docker-compose

```bash
docker-compose up
```

#### Option 2: Install PostgreSQL locally

Download and install the latest stable version of PostgreSQL from the official [website](https://www.postgresql.org/download/).
Then you should run the application and create a database, named whatever you want. 

### Running init or queries

The first thing after creating the database should be running the adequate init script, found in `init-db/`. Each part requires different init files.

To run this script or the solution files (or test queries), a connection to the db needs to be made.

If the docker option is used the credentials should be:

```
url: localhost:5432
database: postgres
user: postgres
pass: postgres
```

If you installed PostgreSQL locally, you probably set them up yourself.

#### Option 1: Database IDEs/Tools

Use a database IDE/tool to connect to your database and run queries.

Some options: 
1. Datagrip (personal favorite, paid but might be free with student e-mail)
2. pgAdmin (free, also good just not as polished)

Add the database credentials to the tool and you should have access to a console or a way to load files and run them in the database.

#### Option 2: CLI-tools

CLI-tools such as `psql` can also be used — less practical.