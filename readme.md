<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

License
-------

This library written by Torben Sickert stands under a creative commons naming
4.0 international license.
See https://creativecommons.org/licenses/by/4.0/deed.de
endregion -->

<!--|deDE:Projektstatus-->
<!--|frFR:Statut du projet-->
Project status
--------------

[![npm](https://img.shields.io/npm/v/reachable-watcher?color=%23d55e5d&label=npm%20package%20version&logoColor=%23d55e5d&style=for-the-badge)](https://www.npmjs.com/package/reachable-watcher)
[![npm downloads](https://img.shields.io/npm/dy/reachable-watcher.svg?style=for-the-badge)](https://www.npmjs.com/package/reachable-watcher)

[![build push package](https://img.shields.io/github/actions/workflow/status/thaibault/reachable-watcher/build-package-and-push.yaml?label=build%20push%20package&style=for-the-badge)](https://github.com/thaibault/reachable-watcher/actions/workflows/build-package-and-push.yaml)

[![lint](https://img.shields.io/github/actions/workflow/status/thaibault/reachable-watcher/lint.yaml?label=lint&style=for-the-badge)](https://github.com/thaibault/reachable-watcher/actions/workflows/lint.yaml)
[![test](https://img.shields.io/github/actions/workflow/status/thaibault/reachable-watcher/test.yaml?label=test&style=for-the-badge)](https://github.com/thaibault/reachable-watcher/actions/workflows/test.yaml)

[![deploy web documentation](https://img.shields.io/github/actions/workflow/status/thaibault/reachable-watcher/deploy-web-documentation.yaml?label=deploy%20web%20documentation&style=for-the-badge)](https://github.com/thaibault/reachable-watcher/actions/workflows/deploy-web-documentation.yaml)
[![web documentation](https://img.shields.io/website-up-down-green-red/https/tsickert.com/reachable-watcher.svg?label=web-documentation&style=for-the-badge)](https://tsickert.com/reachable-watcher)

<!--|deDE:Einsatzmöglichkeiten-->
<!--|frFR:Cas d'utilisation-->
Use case
--------

Watches the reachability of web servers with a single Bash script. Each
configured URL is mapped to its expected HTTP status code and to e-mail
addresses, which get notified as soon as the URL stops responding as expected
and again when it recovers.
<!--deDE:
    Überwacht die Erreichbarkeit von Webservern mit einem einzigen
    Bash-Skript. Jede konfigurierte URL wird ihrem erwarteten HTTP-Statuscode
    und E-Mail-Adressen zugeordnet, die benachrichtigt werden, sobald die URL
    nicht mehr wie erwartet antwortet, und erneut, wenn sie sich erholt.
-->
<!--frFR:
    Surveille l'accessibilité de serveurs web avec un seul script Bash.
    Chaque URL configurée est associée à son code de statut HTTP attendu et
    à des adresses e-mail, qui sont notifiées dès que l'URL ne répond plus
    comme prévu, puis à nouveau lorsqu'elle se rétablit.
-->

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

Installation
------------

On Arch Linux, build and install the "PKGBUILD" of this repository (it needs
the "bash-link" package) and enable the service:
<!--deDE:
    Unter Arch Linux bauen und installieren Sie das "PKGBUILD" dieses
    Repositorys (es benötigt das Paket "bash-link") und aktivieren den
    Dienst:
-->
<!--frFR:
    Sous Arch Linux, construisez et installez le "PKGBUILD" de ce dépôt (il
    nécessite le paquet "bash-link") et activez le service:
-->

```bash
makepkg --install --syncdeps
systemctl enable --now reachable-watcher
```

Anywhere else, install it globally via npm, which brings its library
[bashlink](https://tsickert.com/bashlink) along, and link the shipped unit:
<!--deDE:
    Überall sonst installieren Sie es global über npm, das seine Bibliothek
    [bashlink](https://tsickert.com/bashlink) mitbringt, und verlinken die
    mitgelieferte Unit:
-->
<!--frFR:
    Partout ailleurs, installez-le globalement via npm, qui apporte sa
    bibliothèque [bashlink](https://tsickert.com/bashlink), et liez l'unité
    fournie:
-->

```bash
npm install --global reachable-watcher
systemctl link \
    "$(npm root --global)/reachable-watcher/reachable-watcher.service"
systemctl enable --now reachable-watcher
```

The unit starts "reachable-watcher" from "/usr/local/bin" or "/usr/bin". The
script alone works as well: it needs "bash" and "curl" and downloads bashlink
on its first start if it is missing. E-mails need "msmtp".
`journalctl -u reachable-watcher` shows what the service does.
<!--deDE:
    Die Unit startet "reachable-watcher" aus "/usr/local/bin" oder
    "/usr/bin". Das Skript allein funktioniert ebenfalls: Es benötigt "bash"
    und "curl" und lädt bashlink beim ersten Start herunter, wenn es fehlt.
    E-Mails benötigen "msmtp". `journalctl -u reachable-watcher` zeigt, was
    der Dienst tut.
-->
<!--frFR:
    L'unité démarre "reachable-watcher" depuis "/usr/local/bin" ou
    "/usr/bin". Le script seul fonctionne aussi: il nécessite "bash" et
    "curl" et télécharge bashlink à son premier démarrage s'il manque. Les
    e-mails nécessitent "msmtp". `journalctl -u reachable-watcher` montre ce
    que fait le service.
-->

Configuration
-------------

"/etc/reachableWatcher" is a Bash file which overrides the defaults. At least
the URLs to check and the sender address have to be set. Each URL maps to its
expected status code, followed by the e-mail addresses to notify:
<!--deDE:
    "/etc/reachableWatcher" ist eine Bash-Datei, die die Standardwerte
    überschreibt. Mindestens die zu prüfenden URLs und die Absenderadresse
    müssen gesetzt werden. Jede URL wird ihrem erwarteten Statuscode
    zugeordnet, gefolgt von den zu benachrichtigenden E-Mail-Adressen:
-->
<!--frFR:
    "/etc/reachableWatcher" est un fichier Bash qui remplace les valeurs par
    défaut. Il faut au minimum définir les URL à vérifier et l'adresse de
    l'expéditeur. Chaque URL est associée à son code de statut attendu,
    suivi des adresses e-mail à notifier:
-->

```bash
RW_SENDER_E_MAIL_ADDRESS=watcher@example.com
declare -A RW_URLS_TO_CHECK=(
    ['https://example.com']='200 admin@example.com'
    ['https://example.com/missing']='404 admin@example.com dev@example.com'
)
# Optional settings with their defaults:
RW_DELAY_BETWEEN_TWO_CONSECUTIVE_REQUESTS_IN_SECONDS=300
RW_NAME=NODE_NAME
RW_REPLIER_E_MAIL_ADDRESS="$RW_SENDER_E_MAIL_ADDRESS"
RW_VERBOSE=false
```

"RW_NAME" names this machine in the e-mail subjects, "RW_VERBOSE=true" logs
every state change. Run "reachable-watcher" once by hand to check the
configuration.
<!--deDE:
    "RW_NAME" benennt diesen Rechner in den E-Mail-Betreffs,
    "RW_VERBOSE=true" protokolliert jeden Zustandswechsel. Führen Sie
    "reachable-watcher" einmal von Hand aus, um die Konfiguration zu prüfen.
-->
<!--frFR:
    "RW_NAME" nomme cette machine dans les objets des e-mails,
    "RW_VERBOSE=true" journalise chaque changement d'état. Lancez
    "reachable-watcher" une fois à la main pour vérifier la configuration.
-->

<!--|deDE:Statuscodes-->
<!--|frFR:Codes de statut-->
### Status codes

Every interval each URL is requested via "HEAD" (certificates are not
verified). The response is valid if:
<!--deDE:
    In jedem Intervall wird jede URL per "HEAD" angefragt (Zertifikate werden
    nicht geprüft). Die Antwort ist gültig, wenn:
-->
<!--frFR:
    À chaque intervalle, chaque URL est demandée via "HEAD" (les certificats
    ne sont pas vérifiés). La réponse est valide si:
-->

- its status code equals the expected one or<!--deDE:ihr Statuscode dem erwarteten entspricht oder--><!--frFR:son code de statut est égal à celui attendu ou-->
- both are one of "200" and "206".<!--deDE:beide einer von "200" und "206" sind.--><!--frFR:les deux font partie de "200" et "206".-->

An unreachable URL results in "000", which is only valid if "000" is expected,
e.g. to make sure that an internal service stays hidden.
<!--deDE:
    Eine nicht erreichbare URL ergibt "000", was nur gültig ist, wenn "000"
    erwartet wird, z. B. um sicherzustellen, dass ein interner Dienst
    verborgen bleibt.
-->
<!--frFR:
    Une URL inaccessible donne "000", ce qui n'est valide que si "000" est
    attendu, par exemple pour s'assurer qu'un service interne reste caché.
-->

Recipients are only notified when the state of a URL changes, from valid to
invalid or back. A URL which is valid on the first check sends nothing.
<!--deDE:
    Empfänger werden nur benachrichtigt, wenn sich der Zustand einer URL
    ändert, von gültig zu ungültig oder zurück. Eine URL, die bei der ersten
    Prüfung gültig ist, verschickt nichts.
-->
<!--frFR:
    Les destinataires ne sont notifiés que lorsque l'état d'une URL change,
    de valide à invalide ou inversement. Une URL valide lors de la première
    vérification n'envoie rien.
-->

<!--|deDE:E-Mails-->
<!--|frFR:E-mails-->
### E-mails

E-mails are sent via "msmtp", so it needs a working "~/.msmtprc" or
"/etc/msmtprc", e.g.:
<!--deDE:
    E-Mails werden über "msmtp" verschickt, es braucht also eine
    funktionierende "~/.msmtprc" oder "/etc/msmtprc", z. B.:
-->
<!--frFR:
    Les e-mails sont envoyés via "msmtp", il faut donc un "~/.msmtprc" ou un
    "/etc/msmtprc" fonctionnel, par exemple:
-->

```
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /tmp/msmtpLog

account        mail
host           smtp.example.com
port           587
from           watcher@example.com
user           watcher@example.com
password       PASSWORD

account        default : mail
```

<!--|deDE:Entwicklung-->
<!--|frFR:Développement-->
Development
-----------

```bash
yarn install
yarn lint
yarn test
```

"yarn test" runs the examples in the script's documentation as tests,
"yarn document" renders this documentation as HTML.
<!--deDE:
    "yarn test" führt die Beispiele aus der Dokumentation des Skripts als
    Tests aus, "yarn document" erzeugt diese Dokumentation als HTML.
-->
<!--frFR:
    "yarn test" exécute les exemples de la documentation du script comme
    tests, "yarn document" génère cette documentation en HTML.
-->
