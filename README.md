# deis-cleanup
It's [Deis](https://github.com/deis/deis/) specific approach to `docker image`
cleanup. Currently available solutions are too io heavy or aren't configurable
enough.

## Usage
### Configuration
Use environment variables to pass the configuration. For example:
```
docker run --env "ENV_NAME=value" ...`
```

Possible options:

- `KEEP_LAST_VERSIONS` - the number of releases to keep for each repository (default: `2`).
- `DRY_RUN` - just print the commands (default: `false`).
- `EXCLUDE_REGEX` - regex filter for repository name (default: `alpine|deis|blackhole|none|datadog|cleanup|heroku|python`).
- `CLEANUP_CONTAINERS` - cleanup exited containers (default: `true`)

### deis-builder

1. Log onto the `deis-builder` container:

  ```
  $ fleetctl ssh deis-builder
  $ nse deis-builder
  ```
1. Pull `deis-cleanup` image:

  ```
  $ docker pull twobox/deis-cleanup
  ```
1. Run `deis-cleanup`:

  ```
  $ docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm twobox/deis-cleanup
  ```

### Regular Deis node
#### Manual

Repeat for each Deis node:

1. Log onto a node:

  ```
  $ fleetctl ssh <machine id>
  ```
1. Follow steps 2. and 3. from usage on `deis-builder`.

#### Service

1. Load the service:

  ```
  $ fleetctl load deis-cleanup.service
  ```
1. Start the service:

  ```
  $ fleetctl start deis-cleanup.service
  ```
1. Wait until the process will finish and destroy it (optional):

  ```
  $ fleetctl destroy deis-cleanup.service
  ```

## Development

1. Update the code.
1. Build:

  ```
  $ docker build -t deis-cleanup .
  ...
  Successfully built 902499c7cfb8
  ```
1. Tag:

  ```
  $ docker images | grep deis-cleanup
  deis-cleanup        latest              902499c7cfb8        6 minutes ago       143.5 MB
  $ docker tag 902499c7cfb8 twobox/deis-cleanup:latest
  $ docker images | grep deis-cleanup
  deis-cleanup          latest              902499c7cfb8        10 minutes ago      143.5 MB
  twobox/deis-cleanup   latest              902499c7cfb8        10 minutes ago      143.5 MB
  ```
1. Login (optional, it has to be done only once):

  ```
  $ docker login --username=<login> --email=<email>
  Password:
  WARNING: login credentials saved in <home>/.docker/config.json
  Login Succeeded
  ```
1. Push:

  ```
  $ docker push twobox/deis-cleanup
  The push refers to a repository [docker.io/twobox/deis-cleanup]
  ...
  latest: digest: sha256:cdc617c74cc2b8332eaa0f844571309e7b291f1b483a7372a316d62395e0b3f1 size: 12968
  ```
