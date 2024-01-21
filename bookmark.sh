#!/bin/bash

set -eo pipefail
# load config function
source .config_profile
os_name=$(uname)

#############################################################
# PREPARE BOOKMAKR STORAGE DIRECTORIES AND FILES
#############################################################
BOOKMARK_DIRECTORY=$HOME/$( get_config '.bookmark_directory' )
# Get supported browser and convert JSON Array to bash array
supported_browsers=( $( echo $(get_config '.browsers[]') ))

for browser in ${supported_browsers[@]}
do
    mkdir -p ${BOOKMARK_DIRECTORY}/${browser}
    ln -sf "$HOME/$(get_config ".os.$os_name.${browser}")" "${BOOKMARK_DIRECTORY}/${browser}/Bookmarks"
    # Restrict other users from modifying the bookmark file except the root user and owner
    chmod +t ${BOOKMARK_DIRECTORY}/${browser}
done


############################################################
# GET BROWSER BOOKMARK METHODS
############################################################

# Declare JSON config
get_browser_json_method () {
    if [[ $1 == "Chrome" ]]; then
        echo "logChromeBookmarkToJson"
    elif [[ $1 == "FireFox" ]]; then
        echo "logFireFoxBookmarkToJson"
    else
        "Browser not supported"
        exit 1
    fi
}

# Declare TABLE config
get_browser_table_method () {
    if [[ $1 == "Chrome" ]]; then
        echo "logChromeBookmarkToTable"
    elif [[ $1 == "FireFox" ]]; then
        echo "logFireFoxBookmarkToTable"
    else
        "Browser not supported"
        exit 1
    fi
}

# Validate arguments
# $1 is the number of argument expected
validateGetArguments () # arguments 
{
    arguments=$1
    number_of_arguments=$( echo $arguments | wc -w | sed "s/ //g")
    output_format=$( echo get_config '.output_format' | sed "s/ //g" )

    if [[ $number_of_arguments != $2 ]]; then
        echo "Invalid number of argument\n"
        echo "use --help or -h to check options"
        exit 1;
    
    elif [[ $number_of_arguments == $2 ]] && [[ ${output_format[@]} =~ ${arguments[2]} ]]; then
        echo "Invalid format\n"
        echo "use --help or -h to check options"
        exit 1;
    fi
}

# arguments: $browsername $outputformat
logBookMarkToSreen ()
{
    expected_arguments=3
    arguments=$@
    validateGetArguments "${arguments}" ${expected_arguments}
    if [ $3 = "--json" ]; then
        browser=$(echo ${arguments} | awk '{print $2}' )
        $(get_browser_json_method $browser) $browser
    else
        $(get_browser_table_method $browser) $browser
    fi
}

logChromeBookmarkToJson () {
    browser=$1
    cat "$HOME/$( get_config '.bookmark_directory' )/$browser/Bookmarks" | \
        jq -r '.roots.bookmark_bar.children[] | {name,url}'
}

############################################################
# Search bookmark
############################################################

# Declare JSON config
search_browser_json_method () {
    if [[ $1 == "Chrome" ]]; then
        echo "searchChromeBrowserBookmark"
    elif [[ $1 == "FireFox" ]]; then
        echo "searchFireBrowserBookmark"
    else
        "Browser not supported"
        exit 1
    fi
}

validateSearchArguments () # arguments 
{
    arguments=$1
    number_of_arguments=$( echo $arguments | wc -w | sed "s/ //g" )
    output_format=$( echo get_config '.output_format' | sed "s/ //g" )

    if [[ $number_of_arguments != $2 ]]; then
        echo "Invalid number of argument\n"
        echo "use --help or -h to check options"
        exit 1;
    fi
}

searchBrowserBookmark () {
    expected_arguments=3
    arguments=$@
    validateSearchArguments "${arguments}" ${expected_arguments}
    browser=$(echo ${arguments} | awk '{print $2}' )
    keyword=$(echo ${arguments} | awk '{print $3}' )
    $(search_browser_json_method $browser) $browser $keyword
}

searchChromeBrowserBookmark ()
{
    cat $BOOKMARK_DIRECTORY/$1/Bookmarks | \
        jq -r '.roots.bookmark_bar.children[]' | \
        jq --arg keyword "$2" '{name,url} | ($keyword | ascii_upcase) as $k | select(.name | ascii_upcase| contains($k))'
}

if [[ $1 == 'get' ]]; then
    logBookMarkToSreen $@
elif [[ $1 == 'search' ]]; then
    searchBrowserBookmark $@
else
    echo "Invalid command; use --help"
    exit 1
fi
