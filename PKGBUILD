#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# See https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
pkgname=reachable-watcher
pkgver=1.0.128
pkgrel=1
pkgdesc='Check status codes of web servers and sends notification e-mails'
arch=(any)
url=https://tsickert.com/reachable-watcher
license=(CC-BY-4.0)
depends=(bash bash-link coreutils curl grep)
optdepends=('msmtp: for automatic email notifications on missing sources')
provides=(reachable-watcher)
source=("https://registry.npmjs.org/reachable-watcher/-/reachable-watcher-${pkgver}.tgz")
sha256sums=(2d2e846668407be3ba2ba55f49451ee8498b522a27c05fa7a7648fe24034d178)
copy_to_aur=true

package() {
    cd "${srcdir}/package"
    install \
        -D \
        --mode 755 \
        reachable-watcher.sh \
        "${pkgdir}/usr/bin/reachable-watcher"
    install \
        -D \
        --mode 644 \
        reachable-watcher.service \
        "${pkgdir}/usr/lib/systemd/system/reachable-watcher.service"
    install \
        -D \
        --mode 644 \
        readme.md \
        "${pkgdir}/usr/share/doc/reachable-watcher/readme.md"
}
