#!/usr/bin/env bash

curl https://korol-i-shut.su/albums/ 2> /dev/null | grep -e "<a href=\"https.*</a>" | awk -F '"' '$0=$2' | xargs curl 2> /dev/null | grep -e "<a href=\"https.*songs.*</a>" | awk -F '"' '$0=$2' | xargs curl 2> /dev/null | grep "<article>" | grep -i $1 | awk '{gsub("<br/>", "\n"); gsub("<article>", ""); gsub("</article>", ""); gsub("<p>", "\n"); gsub("</p>", ""); print}'