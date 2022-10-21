<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
endregion -->

Project status
--------------

[![npm](https://img.shields.io/npm/v/reachable-watcher?color=%23d55e5d&label=npm%20package%20version&logoColor=%23d55e5d)](https://www.npmjs.com/package/reachable-watcher)
[![npm downloads](https://img.shields.io/npm/dy/reachable-watcher.svg)](https://www.npmjs.com/package/reachable-watcher)
[![documentation website](https://img.shields.io/website-up-down-green-red/https/torben.website/reachable-watcher.svg?label=documentation-website)](https://torben.website/reachable-watcher)

Use case
--------

This module checks reachability of webservers. You can map a list of urls to
their expected http status codes and a list of email addresses to inform if one
of the url does not return the expected status code. A check interval is also
configurable.

Features
--------

- Configurable interval to check for expected http status codes
- Can be run on any linux machine (minimal dependencies)
- Configure an email address to get notified if any resource doesn't work as
  expected or isn't even available.

Usage
-----

Run this script to initialize the watcher.

```sh
./reachableWatcher.sh
```

or after installation:

```sh
reachable-watcher
```

Configuration
-------------

Simply edit the constants region of the provided shell script.

Installation (under systemd)
----------------------------

Copy the script file "reachableWatcher.sh" to "/usr/bin/reachable-watcher" and
the provided service file ("reachableWatcher.service") to
"/etc/systemd/system/reachable-watcher.service" run:

```sh
systemctl enable reachable-watcher
```

to enable the checking logic. After running:

```sh
systemctl start reachable-watcher
```

you can see the worker running in your system logs.

<!-- region vim modline
vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:
endregion -->
