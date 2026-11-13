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

Copy the script and the systemd unit into place and enable the service:
<!--deDE:
    Kopieren Sie das Skript und die systemd-Unit an ihren Platz und
    aktivieren Sie den Dienst:
-->
<!--frFR:
    Copiez le script et l'unité systemd à leur place et activez le service:
-->

```bash
install -D --mode 755 reachable-watcher.sh /usr/bin/reachable-watcher
install -D --mode 644 reachable-watcher.service \
    /etc/systemd/system/reachable-watcher.service
systemctl enable --now reachable-watcher
```

The script needs "bash", "curl" and "msmtp" and downloads its library
[bashlink](https://tsickert.com/bashlink) if it is not installed. It is also
available via "npm install reachable-watcher".
`journalctl -u reachable-watcher` shows what the service does.
<!--deDE:
    Das Skript benötigt "bash", "curl" und "msmtp" und lädt seine Bibliothek
    [bashlink](https://tsickert.com/bashlink) herunter, wenn sie nicht
    installiert ist. Es ist auch über "npm install reachable-watcher"
    erhältlich. `journalctl -u reachable-watcher` zeigt, was der Dienst
    tut.
-->
<!--frFR:
    Le script nécessite "bash", "curl" et "msmtp" et télécharge sa
    bibliothèque [bashlink](https://tsickert.com/bashlink) si elle n'est pas
    installée. Il est aussi disponible via "npm install reachable-watcher".
    `journalctl -u reachable-watcher` montre ce que fait le service.
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
RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS=300
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

- its status code equals the expected one,<!--deDE:ihr Statuscode dem erwarteten entspricht,--><!--frFR:son code de statut est égal à celui attendu,-->
- both are one of "200" and "206" or<!--deDE:beide einer von "200" und "206" sind oder--><!--frFR:les deux font partie de "200" et "206" ou-->
- "000" is expected (not reachable) and "000", "200" or "206" is returned.<!--deDE:"000" erwartet wird (nicht erreichbar) und "000", "200" oder "206" zurückkommt.--><!--frFR:"000" est attendu (inaccessible) et "000", "200" ou "206" est renvoyé.-->

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
