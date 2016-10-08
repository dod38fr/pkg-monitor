# Purpose

# Installation


# Usage

Once the vagrant image is installed and running, open the page http://127.0.0.1:8084/

The connection with the server is closed after 20mns without
traffic. In this case, a button appears to let user reconnect and
resume monitoring.

Only package that are added or removed from the system are
listed. Upgraded packages are not.

# Design

## Webserver and communication

The webserver is in charge of:
* serving the main package monitor page
* polling the package manager log file for package installation and removal events
* sending these events to the package monitor page

To get very fast update from server to the web page, the most critical
point is the communication between the server and the web
browser. Triggering web page reload is too long. Frequent Ajax polling
may work with a local VM but would require too much network and server
load in a real case. Real-time communication between browser and
server can be done with websocket or SSE. Both are suitable in this
case.

I've choosen Websocket because I've already worked with them in a
former project. They are best served by asynchronous web server.

In Perl world, the best candidates for an asynchronous web server are
Catalyst, Mojolicious and Dancer. Given the expected workload, any
asynchronous server will do.  I've choosen Mojolicious because I've
already
[worked with it](http://connect.ed-diamond.com/GNU-Linux-Magazine/GLMF-169/Creer-une-application-Perl-autour-de-MySQL-Integration-avec-Mojolicious-HTML-Tiny-et-HTML-FormHandler-3-3).

## Scanning the system for package changes

Let's see how to get package change from the system to the Mojolicious
application.

Package installation and removal events are extracted from
`/var/log/dpkg.log`, the log file used by dpkg. Other log files like
`/var/apt/log` or `/var/log/aptitude` are not suitable because they
are updated only by their respective package management tools. Only
`dpkg.log` lists the actions done by all package management tools
(`apt-get`, `aptitude`, `synaptic`).

Mojolicious has no facility to monitor a file. File monitor can be
based on file polling or on Linux Inotify events.

Using Inotify events is the most efficient solution but was not
choosen because only one file needs to be monitored. Linux::Inotify2
is more complex to setup and is overkill for this case.

The monitoring of `dpkg.log` is based io IO::Async::FileStream which
polls the status of the file. This poll is done 5 times per second which
"feels" real time and does not load significantly the system.

There's no need to have more than one object in the web server to
monitor `dpkg.log`. So this object is stored in a lexical variables in
PkgMonit::Controller::Main (`$filestream`). This object is created as
soon as there's is one active connection from a browser to the server
and is destroyed when all connections are closed.

## Web client

On client side, websocket handling is implemented using native
websocket. Since Mojolicious supports websocket, there's no need to
use a compatibility library like socket.io.

A minimal amount of styling is done with the well-known libraries
Jquery and bootstrap. They are quite easy to use and getting a decent
result is quite simple.

## System integration

The webserver is setup with systemd to restart the server when the VM
is rebooted.

Logrotate configuration is modified to restart the server when
`dpkg.log` is rotated. Otherwise, the web server will go on monitoring
the rotated log file which is not written to anymore.

