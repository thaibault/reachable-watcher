#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# [Project page](https://tsickert.com/reachableWatcher)

# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# See https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
# shellcheck disable=SC1004,SC2016,SC2034,SC2155
shopt -s expand_aliases
# region import
alias rw.download=rw_download
rw_download() {
    local -r __documentation__='
        Simply downloads missing modules.

        >>> rw.download --silent https://domain.tld/path/to/file.ext; echo $?
        6
    '
    command curl --insecure "$@"
    return $?
}

if [ -f "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh" ]; then
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
elif [ -f "/usr/lib/bashlink/module.sh" ]; then
    # shellcheck disable=SC1091
    source "/usr/lib/bashlink/module.sh"
else
    declare -g RW_CACHE_PATH=/tmp/reachableWatcherInstallCache/
    declare -gr BL_MODULE_REMOTE_MODULE_CACHE_PATH="${RW_CACHE_PATH}bashlink"
    mkdir --parents "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"
    declare -gr BL_MODULE_RETRIEVE_REMOTE_MODULES=true
    if ! (
        [ -f "${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/module.sh" ] || \
        rw.download \
            https://raw.githubusercontent.com/thaibault/bashlink/main/module.sh \
                >"${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/module.sh"
    ); then
        echo Needed bashlink library could not be retrieved. 1>&2
        rm \
            --force \
            --recursive \
            "${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/module.sh"
        exit 1
    fi
    # shellcheck disable=SC1091
    source "${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/module.sh"
fi
# NOTE: Shortens this module's scope to "rw_*" and "RW_*" names.
BL_MODULE_FUNCTION_SCOPE_REWRITES+=('^reachable\.watcher$/rw/')
BL_MODULE_GLOBAL_SCOPE_REWRITES+=('^REACHABLE_WATCHER$/RW/')
bl.module.import bashlink.array
bl.module.import bashlink.exception
bl.module.import bashlink.logging
bl.module.import bashlink.tools
# endregion
# region variables
declare -gr RW__DOCUMENTATION__='
    Watches a list of urls and sends mails to configured email addresses if one
    does not fit the expected status code.

    You have to install program `msmtp` to get this script working. A proper
    user specific "~/.msmtprc" or global "/etc/msmtprc" have to be present on
    your distribution. A sample configuration using simple gmail account to
    send mails (Replace "ACCOUNT_NAME", "ACCOUNT_E_MAIL_ADDRESS",
    "ACCOUNT_PASSWORD"):

    ```
        defaults
        auth           on
        tls            on
        tls_starttls   on
        tls_trust_file /etc/ssl/certs/ca-certificates.crt
        logfile        /tmp/msmtpLog

        account        gmail
        host           smtp.gmail.com
        port           587
        from           ACCOUNT_E_MAIL_ADDRESS
        user           ACCOUNT_NAME@gmail.com
        password       ACCOUNT_PASSWORD

        account        default : gmail
    ```

    Furthermore you should create a file "/etc/reachableWatcher" to overwrite
    the following variables. You need to set values for
    `RW_URLS_TO_CHECK` and
    `RW_SENDER_E_MAIL_ADDRESS` at least:

    ```bash
        RW_SENDER_E_MAIL_ADDRESS="ACCOUNT_E_MAIL_ADDRESS"
        declare -A RW_URLS_TO_CHECK=(
            ["URL1"]="200 RECIPIENT_E_MAIL_ADDRESS"
            ["URL2"]="200 RECIPIENT_E_MAIL_ADDRESS ANOTHER_RECIPIENT_E_MAIL_ADDRESS"
            ...
        )
    ```
'
declare -agr RW__DEPENDENCIES__=(
    bash
    curl
    date
    msmtp
    sleep
)
declare -gr RW__DOCTEST_SETUP__='
    # Mocks the status code request (configurable via
    # "RW_DOCTEST_STATUS_CODE") and prints only the receiver and subject of
    # each sent e-mail.
    curl() {
        echo -n "${RW_DOCTEST_STATUS_CODE:-200}"
    }
    msmtp() {
        command grep --extended-regexp "^(To|Subject):"
    }
'
## region default options
# Maps each url to its expected status code followed by its recipients.
declare -Ag RW_URLS_TO_CHECK=()
# Wait for 5 minutes (60 * 5 = 300).
declare -ig RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS=300
declare -g RW_DATE_TIME_FORMAT='%T:%N at %d.%m.%Y'
declare -g RW_SENDER_E_MAIL_ADDRESS=''
# Falls back to the sender address when empty.
declare -g RW_REPLIER_E_MAIL_ADDRESS=''
declare -g RW_VERBOSE=false
declare -g RW_NAME=NODE_NAME
## endregion
## region load options if present
if \
    [ "${BL_DOCTEST_RUNNING:-false}" != true ] && \
    [ -f /etc/reachableWatcher ]
then
    # shellcheck disable=SC1091
    source /etc/reachableWatcher
fi
## endregion
# Last determined state ("valid" or "invalid") of each checked url.
declare -Ag RW_STATES=()
# endregion
# region helper
alias rw.is_status_valid=rw_is_status_valid
rw_is_status_valid() {
    local -r __documentation__='
        Checks if given and expected status codes results in valid state.

        >>> rw.is_status_valid 200 200; echo $?
        0

        >>> rw.is_status_valid 200 "000"; echo $?
        1

        >>> rw.is_status_valid 200 0; echo $?
        1

        >>> rw.is_status_valid "000" 200; echo $?
        0

        >>> rw.is_status_valid "000" 206; echo $?
        0

        >>> rw.is_status_valid 206 "000"; echo $?
        1

        >>> rw.is_status_valid "000" "000"; echo $?
        0

        >>> rw.is_status_valid 206 200; echo $?
        0

        >>> rw.is_status_valid 200 206; echo $?
        0

        >>> rw.is_status_valid 201 206; echo $?
        1

        >>> rw.is_status_valid 206 201; echo $?
        1

        >>> rw.is_status_valid 201 506; echo $?
        1
    '
    # NOTE: Given state "000" resolves to "0" as interpreted integer.
    local -ir expected_status_code=$1
    local -ir given_status_code=$2
    local -ar valid_ok_codes=(0 200 206)
    if (( expected_status_code == given_status_code )); then
        return 0
    fi
    # NOTE: Status code "000" indicates that the url is not reachable.
    if (( given_status_code == 0 )); then
        return 1
    fi
    if \
        bl.array.contains "$expected_status_code" "${valid_ok_codes[@]}" &&
        bl.array.contains "$given_status_code" "${valid_ok_codes[@]}"
    then
        return 0
    fi
    return 1
}
alias rw.get_expected_status_code=rw_get_expected_status_code
rw_get_expected_status_code() {
    local -r __documentation__='
        Determines the expected status code of given url configuration.

        >>> rw.get_expected_status_code "200 a@domain.tld b@domain.tld"
        200

        >>> rw.get_expected_status_code "  206   a@domain.tld"
        206

        >>> rw.get_expected_status_code 404
        404
    '
    local -a parts
    read -r -a parts <<<"$1"
    echo "${parts[0]}"
}
alias rw.get_recipients=rw_get_recipients
rw_get_recipients() {
    local -r __documentation__='
        Determines all recipients of given url configuration (one per line).

        >>> rw.get_recipients "200 a@domain.tld  b@domain.tld"
        a@domain.tld
        b@domain.tld

        >>> rw.get_recipients 200 | wc --lines
        0
    '
    local -a parts
    read -r -a parts <<<"$1"
    if (( ${#parts[@]} > 1 )); then
        printf '%s\n' "${parts[@]:1}"
    fi
}
alias rw.request_status_code=rw_request_status_code
rw_request_status_code() {
    local -r __documentation__='
        Requests given url and prints the resulting status code ("000" if no
        response could be retrieved).

        >>> rw.request_status_code https://domain.tld
        200

        >>> RW_DOCTEST_STATUS_CODE=503
        >>> rw.request_status_code https://domain.tld
        503

        >>> unset -f curl
        >>> rw.request_status_code http://127.0.0.1:1
        000
    '
    # NOTE: Declaring and assigning at once ignores the exit code of failing
    # requests so that they do not trigger an exception.
    local -r status_code="$(
        curl \
            --head \
            --insecure \
            --output /dev/null \
            --silent \
            --write-out '%{http_code}' \
            "$1"
    )"
    echo "$status_code"
}
alias rw.notify=rw_notify
rw_notify() {
    local -r __documentation__='
        Sends an e-mail with given subject and message to given recipient.

        >>> msmtp() { cat; }
        >>> RW_SENDER_E_MAIL_ADDRESS=sender@domain.tld
        >>> rw.notify a@domain.tld "A subject" "A message." | \
        >>>     grep --invert-match --extended-regexp "^(Date:.*)?$"
        From: sender@domain.tld
        To: a@domain.tld
        Reply-To: sender@domain.tld
        Subject: A subject
        A message.

        >>> msmtp() { grep "^Reply-To:"; }
        >>> RW_SENDER_E_MAIL_ADDRESS=sender@domain.tld
        >>> RW_REPLIER_E_MAIL_ADDRESS=replier@domain.tld
        >>> rw.notify a@domain.tld "A subject" "A message."
        Reply-To: replier@domain.tld
    '
    local -r recipient="$1"
    local -r subject="$2"
    local -r message="$3"
    msmtp -t <<EOF
From: $RW_SENDER_E_MAIL_ADDRESS
To: $recipient
Reply-To: ${RW_REPLIER_E_MAIL_ADDRESS:-$RW_SENDER_E_MAIL_ADDRESS}
Date: $(date)
Subject: $subject

$message

EOF
}
# endregion
# region controller
alias rw.check_url=rw_check_url
rw_check_url() {
    local -r __documentation__='
        Checks given url once and notifies all its recipients if its state has
        changed. An initially valid state is not notified.

        >>> RW_URLS_TO_CHECK=(["https://domain.tld"]="200 a@domain.tld")
        >>> rw.check_url https://domain.tld
        >>> echo "${RW_STATES[https://domain.tld]}"
        valid

        >>> RW_URLS_TO_CHECK=(["https://domain.tld"]="200 a@domain.tld")
        >>> RW_DOCTEST_STATUS_CODE=503
        >>> rw.check_url https://domain.tld
        >>> echo "${RW_STATES[https://domain.tld]}"
        To: a@domain.tld
        Subject: NODE_NAME registers: "https://domain.tld" responses with invalid status code 503!
        invalid

        >>> RW_URLS_TO_CHECK=(["https://domain.tld"]="200 a@domain.tld")
        >>> RW_DOCTEST_STATUS_CODE=000
        >>> rw.check_url https://domain.tld
        >>> echo "${RW_STATES[https://domain.tld]}"
        To: a@domain.tld
        Subject: NODE_NAME registers: "https://domain.tld" is not reachable!
        invalid

        >>> RW_URLS_TO_CHECK=(
        >>>     ["https://domain.tld/?a=b&c"]="200 a@domain.tld b@domain.tld"
        >>> )
        >>> rw.check_url "https://domain.tld/?a=b&c"
        >>> RW_DOCTEST_STATUS_CODE=500
        >>> rw.check_url "https://domain.tld/?a=b&c"
        >>> rw.check_url "https://domain.tld/?a=b&c"
        >>> RW_DOCTEST_STATUS_CODE=206
        >>> rw.check_url "https://domain.tld/?a=b&c"
        >>> rw.check_url "https://domain.tld/?a=b&c"
        To: a@domain.tld
        Subject: NODE_NAME registers: "https://domain.tld/?a=b&c" responses with invalid status code 500!
        To: b@domain.tld
        Subject: NODE_NAME registers: "https://domain.tld/?a=b&c" responses with invalid status code 500!
        To: a@domain.tld
        Subject: NODE_NAME registers: "https://domain.tld/?a=b&c" responses with valid status code 206.
        To: b@domain.tld
        Subject: NODE_NAME registers: "https://domain.tld/?a=b&c" responses with valid status code 206.
    '
    local -r url="$1"
    local -r configuration="${RW_URLS_TO_CHECK[$url]}"
    local -ir expected_status_code="$(
        rw.get_expected_status_code "$configuration")"
    bl.logging.debug "Check url \"$url\" for status code $expected_status_code."
    local -ir given_status_code="$(rw.request_status_code "$url")"
    local -r now="$(date +"$RW_DATE_TIME_FORMAT")"
    local state message subject
    if rw.is_status_valid "$expected_status_code" "$given_status_code"; then
        state=valid
        message="Requested URL \"$url\" returns valid status code $given_status_code on ${now}."
        subject="$RW_NAME registers: \"$url\" responses with valid status code ${given_status_code}."
    elif (( given_status_code == 0 )); then
        state=invalid
        message="Requested URL \"$url\" is not reachable (instead of returning status code \"$expected_status_code\") on ${now}."
        subject="$RW_NAME registers: \"$url\" is not reachable!"
    else
        state=invalid
        message="Requested URL \"$url\" returns status code $given_status_code (instead of \"$expected_status_code\") on ${now}."
        subject="$RW_NAME registers: \"$url\" responses with invalid status code ${given_status_code}!"
    fi
    bl.logging.debug "$message"
    local -r last_state="${RW_STATES[$url]:-valid}"
    RW_STATES[$url]="$state"
    if [ "$state" = "$last_state" ]; then
        bl.logging.debug "Status unchanged."
        return 0
    fi
    bl.logging.info "Status has changed to \"$state\" for \"$url\". Do notification."
    local recipient
    for recipient in $(rw.get_recipients "$configuration"); do
        rw.notify "$recipient" "$subject" "$message"
    done
}
alias rw.main=rw_main
rw_main() {
    local -r __documentation__='
        Main entry point: Checks all configured urls periodically.

        >>> RW_URLS_TO_CHECK=(
        >>>     ["https://a.tld"]="200 a@domain.tld"
        >>>     ["https://b.tld"]="404 b@domain.tld"
        >>> )
        >>> sleep() { exit; }
        >>> rw.main
        To: b@domain.tld
        Subject: NODE_NAME registers: "https://b.tld" responses with invalid status code 200!
    '
    $RW_VERBOSE && \
        bl.logging.set_level info
    while true; do
        local url
        for url in "${!RW_URLS_TO_CHECK[@]}"; do
            rw.check_url "$url"
        done
        bl.logging.debug "Wait for $RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS seconds until next check."
        sleep "$RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS"
    done
}
# endregion
if bl.tools.is_main; then
    bl.exception.activate
    bl.exception.try
        rw.main "$@"
    bl.exception.catch_single
    # region clean up
    {
        [ -f "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH" ] && \
            rm "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH"
        # shellcheck disable=SC2154
        [ -d "$BL_MODULE_REMOTE_MODULE_CACHE_PATH" ] && \
            rm --recursive "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"
        # shellcheck disable=SC2154
        bl.logging.error "$BL_EXCEPTION_LAST_TRACEBACK"
    }
    [ -f "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH" ] && \
        rm "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH"
    # shellcheck disable=SC2154
    [ -d "$BL_MODULE_REMOTE_MODULE_CACHE_PATH" ] && \
        rm --recursive "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"
    # endregion
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
