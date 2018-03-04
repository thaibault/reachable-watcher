#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
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
    reachableWatcher_bashlink_path="$(mktemp --directory --suffix -reachable-watcher-bashlink)/bashlink/"
    mkdir "$reachableWatcher_bashlink_path"
    echo wget \
        https://goo.gl/UKF5JG \
        --output-document "${reachableWatcher_bashlink_path}module.sh"
    if wget \
        https://goo.gl/UKF5JG \
        --output-document "${reachableWatcher_bashlink_path}module.sh"
    then
        bl_module_retrieve_remote_modules=true
        # shellcheck disable=SC1090
        source "${reachableWatcher_bashlink_path}/module.sh"
    else
        echo Needed bashlink library not found 1>&2
        rm --force --recursive "$reachableWatcher_bashlink_path"
        exit 1
    fi
fi
bl.module.import bashlink.exception
bl.module.import bashlink.logging
bl.module.import bashlink.tools
# endregion
# region variables
reachableWatcher__dependencies__=(
    bash
    curl
    date
    grep
    msmtp
    sleep
)
reachableWatcher__documentation__='
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
## region default options
declare -A reachableWatcher_urls_to_check=()
# Wait for 5 minutes (60 * 5 = 300).
reachableWatcher_delay_between_two_consequtive_requests_in_seconds=300
reachableWatcher_date_time_format='%T:%N at %d.%m.%Y'
reachableWatcher_sender_e_mail_address=''
reachableWatche_replier_e_mail_address="$sender_e_mail_address"
reachableWatcher_verbose=false
reachableWatcher_name=NODE_NAME
## endregion
## region load options if present
if [ -f /etc/reachableWatcher ]; then
    source /etc/reachableWatcher
fi
## endregion
# endregion
# region functions
## region controller
alias reachableWatcher.main=reachableWatcher_main
reachableWatcher_main() {
    while true; do
        local url_to_check
        for url_to_check in "${!reachableWatcher_urls_to_check[@]}"; do
            local expected_status_code="$(
                echo "${reachableWatcher_urls_to_check[$url_to_check]}" | \
                    grep '^[^ ]+' --only-matching --extended-regexp)"
            $reachableWatcher_verbose && \
                echo "Check url \"$url_to_check\" for status code $expected_status_code."
            local given_status_code="$(
                curl \
                    --head \
                    --insecure \
                    --output /dev/null \
                    --silent \
                    --write-out '%{http_code}' \
                    "$url_to_check"
            )"
            if [[ "$given_status_code" != "$expected_status_code" ]]; then
                local message="Requested URL \"$url_to_check\" returns status code $given_status_code (instead of \"$expected_status_code\") on $(date +"$reachableWatcher_date_time_format")."
                for e_mail_address in $(
                    echo "${reachableWatcher_urls_to_check[$url_to_check]}" | \
                        grep ' .+$' --only-matching --extended-regexp)
                do
                    $reachableWatcher_verbose && \
                        echo "$message" >/dev/stderr
                    msmtp -t <<EOF
    From: $reachableWatcher_sender_e_mail_address
    To: $reachableWatcher_e_mail_address
    Reply-To: $reachableWatche_replier_e_mail_address
    Date: $(date)
    Subject: $reachableWatcher_name registers: "$url_to_check" responses with status code $given_status_code!

    $message

    EOF
                done
            fi
        done
        $reachableWatcher_verbose && echo "Wait for $reachableWatcher_delay_between_two_consequtive_requests_in_seconds seconds until next check."
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
