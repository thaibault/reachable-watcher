#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# [Project page](https://torben.website/reachableWatcher)

# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC1004,SC2016,SC2034,SC2155
# region import
if [ -f "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh" ]; then
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
elif [ -f "/usr/lib/bashlink/module.sh" ]; then
    # shellcheck disable=SC1091
    source "/usr/lib/bashlink/module.sh"
else
    declare -gr RW_BASHLINK_PATH="$(
        mktemp --directory --suffix -reachable-watcher-bashlink
    )/bashlink/"
    mkdir "$RW_BASHLINK_PATH"
    if wget \
        https://torben.website/bashlink/data/distributionBundle/module.sh \
        --output-document "${RW_BASHLINK_PATH}module.sh"
    then
        declare -gr BL_MODULE_RETRIEVE_REMOTE_MODULES=true
        # shellcheck disable=SC1091
        source "${RW_BASHLINK_PATH}/module.sh"
        rm --force --recursive "$RW_BASHLINK_PATH"
    else
        echo Needed bashlink library not found 1>&2
        rm --force --recursive "$RW_BASHLINK_PATH"
        exit 1
    fi
fi
bl.module.import bashlink.array
bl.module.import bashlink.dictionary
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
    grep
    msmtp
    sleep
)
## region default options
declare -ag RW_URLS_TO_CHECK=()
# Wait for 5 minutes (60 * 5 = 300).
declare -ig RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS=300
declare -g RW_DATE_TIME_FORMAT='%T:%N at %d.%m.%Y'
declare -g RW_SENDER_E_MAIL_ADDRESS=''
declare -g RW_REPLIER_E_MAIL_ADDRESS="$RW_SENDER_E_MAIL_ADDRESS"
declare -g RW_VERBOSE=false
declare -g RW_NAME=NODE_NAME
## endregion
## region load options if present
if [ -f /etc/reachableWatcher ]; then
    # shellcheck disable=SC1091
    source /etc/reachableWatcher
fi
## endregion
# endregion
# region functions
alias rw.is_status_valid=rw_is_status_valid
rw_is_status_valid() {
    local -r __documentation__='
        Checks if given and expected status codes results in valid state.

        >>> rw.is_status_valid 200 200; echo $?
        0

        >>> rw.is_status_valid 200 "000"; echo $?
        0

        >>> rw.is_status_valid 200 0; echo $?
        0

        >>> rw.is_status_valid "000" 200; echo $?
        0

        >>> rw.is_status_valid "000" 206; echo $?
        0

        >>> rw.is_status_valid 206 "000"; echo $?
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
    if \
        (( expected_status_code == given_status_code )) || \
        (( given_status_code == 0 ))
    then
        return 0
    fi
    if \
        bl.array.contains "${valid_ok_codes[*]}" "$expected_status_code" &&
        bl.array.contains "${valid_ok_codes[*]}" "$given_status_code"
    then
        return 0
    fi
    return 1
}
## region controller
alias rw.main=rw_main
rw_main() {
    local -r __documentation__='
        Main entry point.
    '
    $RW_VERBOSE && \
        bl.logging.set_level info
    while true; do
        local url_to_check
        for url_to_check in "${!RW_URLS_TO_CHECK[@]}"; do
            local -i expected_status_code="$(
                echo "${RW_URLS_TO_CHECK[$url_to_check]}" | \
                    grep '^[^ ]+' --only-matching --extended-regexp)"
            bl.logging.debug "Check url \"$url_to_check\" for status code $expected_status_code."
            local -i given_status_code="$(
                curl \
                    --head \
                    --insecure \
                    --output /dev/null \
                    --silent \
                    --write-out '%{http_code}' \
                    "$url_to_check"
            )"
            local normalized_url_to_check="$(
                echo "$url_to_check" | sed 's/[:/.]/_/g')"
            if rw.is_status_valid \
                "$expected_status_code" \
                "$given_status_code"
            then
                local message="Requested URL \"$url_to_check\" returns valid status code $given_status_code on $(date +"$RW_DATE_TIME_FORMAT")."
                bl.logging.debug "$message"
                if [ "$(bl.dictionary.get state "$normalized_url_to_check")" = invalid ]; then
                    bl.logging.info "Status has changed to \"valid\" for \"$url_to_check\". Do notification."
                    local e_main_address
                    for e_mail_address in $(
                        echo "${RW_URLS_TO_CHECK[$url_to_check]}" | \
                            grep ' .+$' --only-matching --extended-regexp)
                    do
                        msmtp -t <<EOF
From: $RW_SENDER_E_MAIL_ADDRESS
To: $e_mail_address
Reply-To: $RW_REPLIER_E_MAIL_ADDRESS
Date: $(date)
Subject: $RW_NAME registers: "$url_to_check" responses with valid status code $given_status_code.

$message

EOF
                    done
                    bl.dictionary.set state "$normalized_url_to_check" valid
                else
                    bl.logging.debug "Status unchanged."
                fi
            else
                local message="Requested URL \"$url_to_check\" returns status code $given_status_code (instead of \"$expected_status_code\") on $(date +"$RW_DATE_TIME_FORMAT")."
                bl.logging.debug "$message"
                if \
                    [ "$(bl.dictionary.get state "$normalized_url_to_check")" = valid ] ||
                    [ "$(bl.dictionary.get state "$normalized_url_to_check")" = '' ]
                then
                    bl.logging.info "Status has changed to \"invalid for \"$url_to_check\". Do notification."
                    local e_main_address
                    for e_mail_address in $(
                        echo "${RW_URLS_TO_CHECK[$url_to_check]}" | \
                            grep ' .+$' --only-matching --extended-regexp)
                    do
                        msmtp -t <<EOF
From: $RW_SENDER_E_MAIL_ADDRESS
To: $e_mail_address
Reply-To: $RW_REPLIER_E_MAIL_ADDRESS
Date: $(date)
Subject: $RW_NAME registers: "$url_to_check" responses with invalid status code $given_status_code!

$message

EOF
                    done
                    bl.dictionary.set state "$normalized_url_to_check" invalid
                else
                    bl.logging.debug "Status unchanged."
                fi
            fi
        done
        bl.logging.debug "Wait for $RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS seconds until next check."
        sleep "$RW_DELAY_BETWEEN_TWO_CONSEQUTIVE_REQUESTS_IN_SECONDS"
    done
}
## endregion
# endregion
if bl.tools.is_main; then
    bl.exception.activate
    bl.exception.try
        rw.main "$@"
    bl.exception.catch_single
    {
        [ -d "$RW_BASHLINK_PATH" ] && \
            rm --recursive "$RW_BASHLINK_PATH"
        # shellcheck disable=SC2154
        [ -d "$BL_MODULE_REMOTE_MODULE_CACHE_PATH" ] && \
            rm --recursive "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"
        # shellcheck disable=SC2154
        bl.logging.error "$bl_exception_last_traceback"
    }
    [ -d "$RW_BASHLINK_PATH" ] && \
        rm --recursive "$RW_BASHLINK_PATH"
    # shellcheck disable=SC2154
    [ -d "$BL_MODULE_REMOTE_MODULE_CACHE_PATH" ] && \
        rm --recursive "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
