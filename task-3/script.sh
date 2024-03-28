#!/bin/bash

############################################################################################################################################################
# Description: 
# It is a Bash script for checking the website's load time using cURL and sending Slack alerts 
# based on a specified threshold. Optionally, logs can be simultaneously saved to the text file.
#
# Usage:
# 1) run ./script.sh domain.tld (or "bash script.sh domain.tld")
# 2) run ./script.sh (or "bash script.sh") and you will be asked to enter the domain manually
#
# What should be configured for a personal usage?
# - Set your Slack Webhook URL (line 24)
# - Set the desired threshold (in seconds) for alerts to be sent (line 27)
# - (optional) Configure the frequency of cURL requests (line 28)
# - (optional) Enable logging to the text file (lines 31, 86, 87)
#
# Other notes:
# - The current threshold is configured for "pleasegoho.me"
# - You can check the previous alerts here: https://join.slack.com/t/srechallengec-bih4494/shared_invite/zt-2fjweyvf9-dIeZn3oBQorr~RHZwJoSAA (#monitoring-alerts)
# - A hidden appreciation to those who worked on developing these interesting tasks for the selection
############################################################################################################################################################

webhook_link="your_link" # put your Slack Webhook URL here (Slack's security doesn't allow it to be available publicly)

# stable values that can be configured up to your needs
alert_threshold=0.492 # if the load time is greater than this value, alerts will be triggered
loop_delay=2 # frequency of cURL requests

# ↓ see line 16 for explanations
#main() {
    # Part 1.1: Accepting the argument for the domain value and declining the empty value
    if [ -n "$1" ]; then # accepting the domain value from "./script.sh DOMAIN"
        domain=$1
    else
        while true; do # continuous cycle unless the domain is entered
            read -p "Enter the website's domain for checking: " domain
            if [ -n "$domain" ]; then
                break
            else
                echo "¯\_(ツ)_/¯ The domain cannot be empty. Please enter a valid domain."
            fi
        done
    fi

    # Part 1.2: Checking the HTTP status of the website and exiting the script if the website is not reachable or the domain is not correct.
    response_code=$(curl -o /dev/null -s -w "%{http_code}" -L $domain)
    case $response_code in
    200|301|302|303|304|307|308)
        ;;
    *)
        echo "¯\_(ツ)_/¯ HTTP status: $response_code. Please check the domain's availability or correctness."
        exit 1
        ;;
    esac

    # Displaying the successful start of script's work
    echo 
    echo "*** Starting the script ***"
    echo

    # Part 2: Getting the website load time, displaying the results to the user, triggering Slack alerts if the condition is met
    while true; do # continuous cycle unless the script is stopped
        result=$(curl -o /dev/null -s -w "%{time_total}" -L $domain) # receiving the website load time

        compare=$(echo "$result > $alert_threshold" | bc) # comparing the values to check if the alerts should be triggered

        # If the website load time is greater than the threshold, the log is shown and the alert is sent.
        if [ $compare -eq 1 ]; then
            echo "[$(date "+%d-%m-%Y %H:%M:%S")] Total load time for ${domain}: ${result}s, sending an alert to Slack." # template of the log output for the user
            alert_message=":red_circle: *Alert:* $domain exceeded load time threshold. Load time: *${result}s*." # template of the alert for Slack
            webhook_response=$(curl -s -X POST -H 'Content-type: application/json' --data '{"text":"'"$alert_message"'"}'  $webhook_link) # sending an alert to Slack
            if [ "$webhook_response" != "ok" ]; then # checking if the Alert was sent properly
                echo "¯\_(ツ)_/¯ It seems that a Slack alert cannot be sent. Slack's response: $webhook_response" # template of the error log output for the user 
            fi
        # Otherwise, if everything is OK, only the log is printed.
        else
            echo "[$(date "+%d-%m-%Y %H:%M:%S")] Total load time for ${domain}: ${result}s, no alert."
        fi

        # Delay X seconds before the next checking
        sleep $loop_delay
    done

# ↓ related to line 16 as well
#}
#main | tee -a "script_log.txt"