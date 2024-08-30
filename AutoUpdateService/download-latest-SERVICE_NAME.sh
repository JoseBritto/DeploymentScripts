#!/bin/bash

SERVICE_NAME=
OUTPUT_DIR=
GITHUB_DOWNLOAD_TOKEN=
GITHUB_USER=
GITHUB_REPO=
ARTIFACT_NAME=

if [ ! -f 'current-version.txt' ]; then
    touch 'current-version.txt'
fi

echo "Checking for new versions of $SERVICE_NAME"

json=$(curl -s 'https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/actions/artifacts?per_page=50')
json=$(echo $json | jq 'del(.artifacts[] | select(.name != "$ARTIFACT_NAME"))')

remote_version=$(echo "$json" | jq '.artifacts[0].workflow_run.head_sha')

local_version=$(cat current-version.txt)

if [ "$remote_version" == "$local_version" ]; then
    echo "No new version found"
    exit
fi

download_url=$(echo "$json" | jq '.artifacts[0].archive_download_url' | tr -d '"')
echo "Downloading  from $download_url"

curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_DOWNLOAD_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$download_url" --output latest.zip

echo $remote_version > current-version.txt

# Extract zip
unzip latest.zip -d latest

if [ "$OUTPUT_DIR" == "" ]; then
    echo "OUTPUT_DIR not set"
    exit 1
fi

echo "Stoping $SERVICE_NAME"
systemctl --user stop $SERVICE_NAME

echo "Moving files to $OUTPUT_DIR"
cd latest

########################## !!EDIT THIS SECTION!!  ###########################
# mv Exe $OUTPUT_DIR/Exe
# chmod +x $OUTPUT_DIR/Exe
#############################################################################

cd..

echo "Restarting $SERVICE_NAME"
systemctl --user start $SERVICE_NAME

echo "Removing downloaded files"
rm latest.zip
rm -rf latest

echo "Shorty update complete"
