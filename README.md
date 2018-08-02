# Row Level Security Performance
> A collection of Row Level Security-type schemas and performance tests

## Installation
You'll need the following things to make this work:
1. [Docker](https://www.docker.com/get-docker)

## Usage
You can do a few things with the `make` scripts built into this repository:

### `make run-db`
This runs the DB so that you can run a schema on it.

### `make seed-db schema=column|table|view`
This will run the schema and the sample-data query for the specified test. The seed data inserts 100 users and 100,000 items into the database automatically.

### `make destroy-db`
This tears down a running stack and drops the database so that you can run `make seed-db` all over again.

There are a few other commands which compose those documented but they are less interesting.

## Purpose
The purpose of this repository is the easily test the performance of access control strategies in PostgreSQL, primarily using Row Level Security.
