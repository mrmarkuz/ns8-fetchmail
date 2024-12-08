# ns8-fetchmail

This is a fetchmail module for [NethServer 8](https://github.com/NethServer/ns8-core).

## Install

Instantiate the module with:

    add-module ghcr.io/mrmarkuz/fetchmail:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "fetchmail1", "image_name": "fetchmail", "image_url": "ghcr.io/mrmarkuz/fetchmail:latest"}

## Configure

In the app settings page just enter a hostname and click save to start the service. The hostname is available as environment variable MAIL_HOST in the container and the user environment.

## Setup

Enter the environment (in this example the instance is named fetchmail1)

    runagent -m fetchmail1

You'll find 2 directories `fetchmail` and `cron` that point to the container directories `/etc/fetchmail` and `/etc/cron.d` so you could put your config files there.

There's another directory `log` that maps `/var/log` in the container to be able to check the log file(s).

An example cronjob file to put to `cron/examplecronjob` that runs fetchmail every 5 minutes:

```
*/5 * * * * root /usr/bin/fetchmail -f /etc/fetchmail/fetchmailrc -L /var/log/fetchmail.log
```

An example fetchmail config file to put to `fetchmail/fetchmailrc`:

```
set no bouncemail
set no spambounce
set properties ""

poll pop.server tracepolls proto pop3 uidl auth password port 995 timeout 60
user "<USER_NAME>" password "<PASSWORD>" ssl keep is <localmailuser@localmailserver.com> smtphost <Neth_IP>
```

The fetchmailrc file needs to have permission 700.

    chmod 700 fetchmail/fetchmailrc

## Uninstall

To uninstall the instance:

    remove-module --no-preserve fetchmail1

## Smarthost setting discovery

Some configuration settings, like the smarthost setup, are not part of the
`configure-module` action input: they are discovered by looking at some
Redis keys.  To ensure the module is always up-to-date with the
centralized [smarthost
setup](https://nethserver.github.io/ns8-core/core/smarthost/) every time
fetchmail starts, the command `bin/discover-smarthost` runs and refreshes
the `state/smarthost.env` file with fresh values from Redis.

Furthermore if smarthost setup is changed when fetchmail is already
running, the event handler `events/smarthost-changed/10reload_services`
restarts the main module service.

See also the `systemd/user/fetchmail.service` file.

This setting discovery is just an example to understand how the module is
expected to work: it can be rewritten or discarded completely.

## Debug

some CLI are needed to debug

- The module runs under an agent that initiate a lot of environment variables (in /home/fetchmail1/.config/state), it could be nice to verify them
on the root terminal

    `runagent -m fetchmail1 env`

- you can become runagent for testing scripts and initiate all environment variables
  
    `runagent -m fetchmail1`

 the path become : 
```
    echo $PATH
    /home/fetchmail1/.config/bin:/usr/local/agent/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/
```

- if you want to debug a container or see environment inside
 `runagent -m fetchmail1`
 ```
podman ps
CONTAINER ID  IMAGE                                      COMMAND               CREATED        STATUS        PORTS                    NAMES
d292c6ff28e9  localhost/podman-pause:4.6.1-1702418000                          9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  80b8de25945f-infra
d8df02bf6f4a  docker.io/library/mariadb:10.11.5          --character-set-s...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  mariadb-app
9e58e5bd676f  docker.io/library/nginx:stable-alpine3.17  nginx -g daemon o...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  fetchmail-app
```

you can see what environment variable is inside the container
```
podman exec  fetchmail-app env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM=xterm
PKG_RELEASE=1
MARIADB_DB_HOST=127.0.0.1
MARIADB_DB_NAME=fetchmail
MARIADB_IMAGE=docker.io/mariadb:10.11.5
MARIADB_DB_TYPE=mysql
container=podman
NGINX_VERSION=1.24.0
NJS_VERSION=0.7.12
MARIADB_DB_USER=fetchmail
MARIADB_DB_PASSWORD=fetchmail
MARIADB_DB_PORT=3306
HOME=/root
```

you can run a shell inside the container

```
podman exec -ti   fetchmail sh
/ # 
```
## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/fetchmail:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
