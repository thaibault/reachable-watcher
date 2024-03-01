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
    declare -gr reachableWatcher_bashlink_path="$(
        mktemp --directory --suffix -reachable-watcher-bashlink
    )/bashlink/"
    mkdir "$reachableWatcher_bashlink_path"
    if wget \
        https://torben.website/bashlink/data/distributionBundle/module.sh \
        --output-document "${reachableWatcher_bashlink_path}module.sh"
    then
        declare -gr bl_module_retrieve_remote_modules=true
        # shellcheck disable=SC1091
        source "${reachableWatcher_bashlink_path}/module.sh"
        rm --force --recursive "$reachableWatcher_bashlink_path"
    else
        echo Needed bashlink library not found 1>&2
        rm --force --recursive "$reachableWatcher_bashlink_path"
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
declare -gr reachableWatcher__documentation__='
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
    `reachableWatcher_urls_to_check` and
    `reachableWatcher_sender_e_mail_address` at least:

    ```bash
        reachableWatcher_sender_e_mail_address="ACCOUNT_E_MAIL_ADDRESS"
        declare -A reachableWatcher_urls_to_check=(
            ["URL1"]="200 RECIPIENT_E_MAIL_ADDRESS"
            ["URL2"]="200 RECIPIENT_E_MAIL_ADDRESS ANOTHER_RECIPIENT_E_MAIL_ADDRESS"
            ...
        )
    ```
'
declare -agr reachableWatcher__dependencies__=(
    bash
    curl
    date
    grep
    msmtp
    sleep
)
## region default options
declare -ag reachableWatcher_urls_to_check=()
# Wait for 5 minutes (60 * 5 = 300).
declare -ig reachableWatcher_delay_between_two_consequtive_requests_in_seconds=300
declare -g reachableWatcher_date_time_format='%T:%N at %d.%m.%Y'
declare -g reachableWatcher_sender_e_mail_address=''
declare -g reachableWatcher_replier_e_mail_address="$reachableWatcher_sender_e_mail_address"
declare -g reachableWatcher_verbose=false
declare -g reachableWatcher_name=NODE_NAME
## endregion
## region load options if present
if [ -f /etc/reachableWatcher ]; then
    # shellcheck disable=SC1091
    source /etc/reachableWatcher
fi
## endregion
# endregion
# region functions
alias reachableWatcher.is_status_valid=reachableWatcher_is_status_valid
reachableWatcher_is_status_valid() {
    local -r __documentation__='
        Checks if given and expected status codes results in valid state.

        >>> reachableWatcher.is_status_valid 200 200; echo $?
        0

        >>> reachableWatcher.is_status_valid 200 "000"; echo $?
        0

        >>> reachableWatcher.is_status_valid 200 0; echo $?
        0

        >>> reachableWatcher.is_status_valid "000" 200; echo $?
        0

        >>> reachableWatcher.is_status_valid "000" 206; echo $?
        0

        >>> reachableWatcher.is_status_valid 206 "000"; echo $?
        0

        >>> reachableWatcher.is_status_valid 206 200; echo $?
        0

        >>> reachableWatcher.is_status_valid 200 206; echo $?
        0

        >>> reachableWatcher.is_status_valid 201 206; echo $?
        1

        >>> reachableWatcher.is_status_valid 206 201; echo $?
        1

        >>> reachableWatcher.is_status_valid 201 506; echo $?
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
alias reachableWatcher.main=reachableWatcher_main
reachableWatcher_main() {
    local -r __documentation__='
        Main entry point.
    '
    $reachableWatcher_verbose && \
        bl.logging.set_level info
    while true; do
        local url_to_check
        for url_to_check in "${!reachableWatcher_urls_to_check[@]}"; do
            local -i expected_status_code="$(
                echo "${reachableWatcher_urls_to_check[$url_to_check]}" | \
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
            if reachableWatcher.is_status_valid \
                "$expected_status_code" \
                "$given_status_code"
            then
                local message="Requested URL \"$url_to_check\" returns valid status code $given_status_code on $(date +"$reachableWatcher_date_time_format")."
                bl.logging.debug "$message"
                if [ "$(bl.dictionary.get state "$normalized_url_to_check")" = invalid ]; then
                    bl.logging.info "Status has changed to \"valid\" for \"$url_to_check\". Do notification."
                    local e_main_address
                    for e_mail_address in $(
                        echo "${reachableWatcher_urls_to_check[$url_to_check]}" | \
                            grep ' .+$' --only-matching --extended-regexp)
                    do
                        msmtp -t <<EOF
From: $reachableWatcher_sender_e_mail_address
To: $e_mail_address
Reply-To: $reachableWatcher_replier_e_mail_address
Date: $(date)
Subject: $reachableWatcher_name registers: "$url_to_check" responses with valid status code $given_status_code.

$message

EOF
                    done
                    bl.dictionary.set state "$normalized_url_to_check" valid
                else
                    bl.logging.debug "Status unchanged."
                fi
            else
                local message="Requested URL \"$url_to_check\" returns status code $given_status_code (instead of \"$expected_status_code\") on $(date +"$reachableWatcher_date_time_format")."
                bl.logging.debug "$message"
                if \
                    [ "$(bl.dictionary.get state "$normalized_url_to_check")" = valid ] ||
                    [ "$(bl.dictionary.get state "$normalized_url_to_check")" = '' ]
                then
                    bl.logging.info "Status has changed to \"invalid for \"$url_to_check\". Do notification."
                    local e_main_address
                    for e_mail_address in $(
                        echo "${reachableWatcher_urls_to_check[$url_to_check]}" | \
                            grep ' .+$' --only-matching --extended-regexp)
                    do
                        msmtp -t <<EOF
From: $reachableWatcher_sender_e_mail_address
To: $e_mail_address
Reply-To: $reachableWatcher_replier_e_mail_address
Date: $(date)
Subject: $reachableWatcher_name registers: "$url_to_check" responses with invalid status code $given_status_code!

$message

EOF
                    done
                    bl.dictionary.set state "$normalized_url_to_check" invalid
                else
                    bl.logging.debug "Status unchanged."
                fi
            fi
        done
        bl.logging.debug "Wait for $reachableWatcher_delay_between_two_consequtive_requests_in_seconds seconds until next check."
        sleep "$reachableWatcher_delay_between_two_consequtive_requests_in_seconds"
    done
}
## endregion
# endregion
if bl.tools.is_main; then
    bl.exception.activate
    bl.exception.try
        reachableWatcher.main "$@"
    bl.exception.catch_single
    {
        [ -d "$reachableWatcher_bashlink_path" ] && \
            rm --recursive "$reachableWatcher_bashlink_path"
        # shellcheck disable=SC2154
        [ -d "$bl_module_remote_module_cache_path" ] && \
            rm --recursive "$bl_module_remote_module_cache_path"
        # shellcheck disable=SC2154
        bl.logging.error "$bl_exception_last_traceback"
    }
    [ -d "$reachableWatcher_bashlink_path" ] && \
        rm --recursive "$reachableWatcher_bashlink_path"
    # shellcheck disable=SC2154
    [ -d "$bl_module_remote_module_cache_path" ] && \
        rm --recursive "$bl_module_remote_module_cache_path"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
