
getReleaseVersions () {
    publisherExtension="$1"
    writeTo="$2"
    
req=$(cat <<EOF
    {
        "assetTypes": [],
        "filters": [
            {
                "criteria": [
                    {
                        "filterType": 8,
                        "value": "Microsoft.VisualStudio.Code"
                    },
                    {
                        "filterType": 7,
                        "value": "$publisherExtension"
                    }
                ],
                "pageNumber": 1,
                "pageSize": 2
            }
        ],
        "flags": 1073
    }
EOF
)
    printf "%s" "$req" \
        | curl -sSL -H 'Accept: application/json;api-version=6.1-preview.1' -H 'Content-Type: application/json' https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery -d @- \
        > "$writeTo"
}

getLatestVersion () {
    publisherExtension="$1"
    writeTo="$2"

req=$(cat <<EOF
    {
        "assetTypes": [],
        "filters": [
            {
                "criteria": [
                    {
                        "filterType": 8,
                        "value": "Microsoft.VisualStudio.Code"
                    },
                    {
                        "filterType": 7,
                        "value": "$publisherExtension"
                    },
                    {
                        "filterType": 12,
                        "value": "4096"
                    }
                ],
                "sortBy": 4,
                "sortOrder": 2,
                "pageNumber": 1,
                "pageSize": 3
            }
        ],
        "assetTypes": [],
        "flags": 946
    }
EOF
)
    printf "%s" "$req" \
        | curl -sSL -H 'Accept: application/json;api-version=6.1-preview.1' -H 'Content-Type: application/json' https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery -d @- \
        > "$writeTo"
}

mkdir -p tmp

publisher="AdaCore"
name="ada"

getReleaseVersions "${publisher}.${name}" "tmp/${name}.versions.json"
jq -M . tmp/${name}.versions.json > tmp/formatted
cat tmp/formatted > tmp/${name}.versions.json

getLatestVersion "${publisher}.${name}" "tmp/${name}.latest.json"
jq -M . tmp/${name}.latest.json > tmp/formatted
cat tmp/formatted > tmp/${name}.latest.json

rm tmp/formatted