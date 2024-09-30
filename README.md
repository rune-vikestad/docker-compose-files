# Contoso Docker Compose

This repository contains a collectio of docker compose files that I've used extensively for local development.

# Environment Variables

You can use `.env` file to control a set of environment variables used by docker compose, including;

 - `COMPOSE_PROJECT_NAME` to set the top-level compose project name
 - `COMPOSE_PROFILES`
 - `COMPOSE_FILE`
 - `COMPOSE_PATH_SEPARATOR`
 - `COMPOSE_MENU`

## Services

The following profiles are av

| Service                    | Base Image                                            | Ports (Internal)          | Ports (External) | 
|----------------------------|-------------------------------------------------------|---------------------------|------------------|
| apicurio-registry          | `apicurio/apicurio-registry`:`3.0.12`                 | - `8080` - HTTP           | -  `8080` - HTTP  |
| apicurio-registry-ui       | `apicurio-registry-ui`:`3.0.12`                       | - `8080` - HTTP           | -  `8888` - HTTP  |
| kafka-controller           | `apache/kafka-native`:`4.0.0`                         | - `9093` - HTTP           | -  `9093` - TCP   |
| kafka-broker-1             | `apache/kafka-native`:`4.0.0`                         | - `9092` - TCP            | - `19094` - TCP   |
| kafka-broker-2             | `apache/kafka-native`:`4.0.0`                         | - `9092` - TCP            | - `19095` - TCP   |

| opentelemetry-collector    | `opentelemetry-collector-contrib`:`0.133.0`           | - `4317` - gRPC Receiver  | |

# Health Checks

Many services utilize `depends_on` to ensure dependant services are running and healthy before we start it. 

However, sometimes such healthchecks are difficult to write.

In those case you can often get away with just checking whether a service's port is ready and accepting connections, e.g.;

```sh
healthcheck:
  test: ["CMD", "bash", "-lc", "exec 3<>/dev/tcp/127.0.0.1/9092 && exec 3>&- 3<&-"]
  interval: 5s
  timeout: 3s
  retries: 30
  start_period: 20s
```
