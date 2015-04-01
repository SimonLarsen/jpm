jpm
===

A Jolie package manager

## Installation ##

Two configuration files are required to be present on the system:

* `rc.yaml`: A configuration file containing authorized logins for the web interface as well as misc. configuration options.
* `servers.yaml`: A list of package repositories prefixed with their protocol e.g. "sodep://location:port"

These two files must be located in `/home/USERNAME/.jpm/`
Example files are included in the "configs" directory.

## Starting servers ##

Two package servers are included: one HTTP server and one SODEP server.
The servers are located in the "core_server" and "extra_server" folders.
Simply cd to their respective directories and run 

    jolie main.ol

## Running the command line interface ##

To use the command line interface, make sure the servers are running,
then cd to the "client" folder and run

    jolie cli.o [COMMAND] [ARGS]

### Commands ###

```
update
    Updates the package database.
    Must be run before running any other commands.

install [PACKAGES]
    Installs one or more packages.
    Example: "jolie cli.ol install username cowsay"
	
search [QUERY]
    Lists all available packages matching QUERY.
	
list
    Lists all installed packages matching QUERY.
```

## Running web client ##

As with CLI client make sure servers are running,
then cd to the "client" folder and run

    jolie web.ol

The command line interface can then be accessed at `localhost:4000`.

To log in use the following credentials:

* username: `admin`
* password" `hunter2`

unless credentials in `rc.yaml` have been changed.

## Making packages available to Jolie ##

To make packages accesible to Jolie the launcher in `/usr/bin/jolie`
must be changed to the following: (replace [USERNAME])

    #!/bin/sh

    JPM_DATA="/home/[USERNAME]/.jpm/data"

    java -ea:jolie... -ea:joliex... -Djava.rmi.server.codebase=file:/$JOLIE_HOME/extensions/rmi.jar -cp $JOLIE_HOME/lib/libjolie.jar:$JOLIE_HOME/jolie.jar jolie.Jolie -l ./lib/*:$JOLIE_HOME/lib:$JOLIE_HOME/javaServices/*:$JOLIE_HOME/extensions/*:$JPM_DATA/lib -i $JOLIE_HOME/include:$JPM_DATA/include "$@"
