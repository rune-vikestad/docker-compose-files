# Contoso Docker Compose

This repository contains a collection of docker compose files that I've used extensively for local development.

# Environment Variables

You can use `.env` file to control a set of environment variables used by docker compose, including;

 - `COMPOSE_PROJECT_NAME` to set the top-level compose project name
 - `COMPOSE_PROFILES`
 - `COMPOSE_FILE`
 - `COMPOSE_PATH_SEPARATOR`
 - `COMPOSE_MENU`

## Services

You'll find the available services in the root `compose.*.yml` files. 

You can modify `COMPOSE_FILE` and `COMPOSE_PROFILES` in `.env` to add or remove the files and profiles required for the service you'd like to run.

Then simply run `docker compose up -d --build`, and wait for them to spin up.

# Health Checks

Many services utilize `depends_on` to ensure dependant services are running and healthy before we start it. 

I've tried to write as dependable health checks as I could, but sometimes such healthchecks are difficult to write.

In those case I've instead just checked whether a service's port is ready and accepting connections, e.g.;

```sh
healthcheck:
  test: ["CMD", "bash", "-lc", "exec 3<>/dev/tcp/127.0.0.1/9092 && exec 3>&- 3<&-"]
  interval: 5s
  timeout: 3s
  retries: 30
  start_period: 20s
```
