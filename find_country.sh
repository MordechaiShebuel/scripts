#!/usr/bin/env bash

# TODO: I'd like to determine what search pattern program to use, preferring ag / git grep then ack

# TODO: I'd like to display a help banner if the user enter some help string
# Command line args
country=$1
countries=''
Linux=$(uname -r)

if ! command -v jq >/dev/null 2>&1; then
    # install jq
    if [[ "$Linux" == *"omlx"* ]]; then # Need to verify this is correct
    ## Open Mandrive Update
    sudo dnf in jq
fi

if [[ "$Linux" == *"artix"* ]]; then
    ## Artix update
    sudo pacman -S jq
fi

if [[ "$Linux" == *"vendefoul"* ]]; then
    ## vendefoul
    sudo apt-get install jq
fi
fi

curl_command=$(curl -X GET "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/countries-codes/records?select=iso2_code%2C%20label_en&where=label_en%20like%20%22$country%22&limit=20")

RESULTS=$(echo $curl_command)
result_count=$(echo $RESULTS | jq '.total_count')
echo TOTAL_COUNT: $(echo $RESULTS | jq '.total_count')

if [[ $result_count -eq 1 ]]; then
    found_country=$(echo $RESULTS | jq '.results.[0].label_en')
    country_code=$(echo $RESULTS | jq '.results.[0] | .iso2_code')
else
    found_country=$(echo $RESULTS | jq '.results.[] | .label_en')
    country_code=$(echo $RESULTS | jq '.results.[] | .iso2_code')
fi

echo Search Term: $country
echo Results: $found_country
echo country_codes: $country_code
