# pg.env

Simple bash scripts to manage multiple PostgreSQL connection settings
and installations.

Leverages the pg_service.conf file.

This setup has worked well for me and is idiosyncratic and
opinionated. While it's not intended to be a general purpose solution,
hopefully others may find bits and pieces useful for their own
particular circumstances.

## Installation

Clone the repo into `~/pg`. This is a easy-to-remember, short path
which we'll use often to switch between environments.

    git clone https://github.com/grzm/pg.env ~/pg

Add to `.profile`

    export PGSYSCONFDIR=~/pg
    . ${PGSYSCONFDIR}/env


## Local postgres installation

The `install.sh` file is a convenient way to build multiple PostgreSQL
versions locally. The `pg.env` script which switches between versions
also sets `PATH` to point to the binaries installed here. It also sets
`PGDATA` appropriately.

## Configuration

Update `conf.yml` to specify the configurations you want.

There are two main entries in the conf file: `default_service`, and
`services`.  The `defaults` key is not necessary, but it's
convenient to leverage YAML references to reduce duplication in the
file.

Here we have two service entries, `10`, and `96`, which define two
services.  The service name is used as the file name which is sourced
to switch services.  When the service and helper files are generated,
`~/pg/10` and `~/pg/96` files will be created.

```yaml
---
defaults:
  local: &local
    user: grzm
    dbname: postgres
default_service: "96"
services:
  "10":
    <<: *local
    version: "10"
    port: 5410
  "96":
    <<: *local
    version: "9.6"
    port: 5496
```

To regenerate environment files from `conf.yml`

    cd ~/pg
    rake regen

## Usage

To use to connect to service `10` (or whatever other service you want)

    . ~/pg/10
    psql


## License

© 2018 Michael Glaesemann

Released under the MIT License. See LICENSE for details.
