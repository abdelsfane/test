#!/bin/bash

results=""
GIT_REPO_URL="${GIT_REPO_URL%.*}"

echo "LICATION_ARTIFACT_URL: ${LICATION_ARTIFACT_URL}"
echo "ART_USERNAME: ${ART_USERNAME}"
echo "ART_PASSWORD: ${ART_PASSWORD}"
echo "GIT_REPO_URL: ${GIT_REPO_URL}"
echo "BUILD_NUMBER: ${BUILD_NUMBER}"
echo "GIT_TOKEN: ${GIT_TOKEN}"
echo "LICATION_BACKEND: ${LICATION_BACKEND}"
echo "CHECKSUM: ${CHECKSUM}"


curl -XPOST -H 'Content-type: application/json' -d "{
        \"artifactUrl\": \"${LICATION_ARTIFACT_URL}\",
        \"artifactUser\": \"${ART_USERNAME}\",
        \"artifactPass\": \"${ART_PASSWORD}\",
        \"githubUrl\": \"${GIT_REPO_URL}\",
        \"jenkinsJobID\": \"${BUILD_NUMBER}\",
        \"githubCreds\": \"${GIT_TOKEN}\"
        }" "${LICATION_BACKEND}"

while [ "$results" = "" ]
do 
    echo "Checking scan status..."
    response=$(curl -s '${LICATION_BACKEND}/sha/${CHECKSUM}' | jq -r '.scanStatus')
    echo ${response}
    echo "response above"
    results=${response}

    if [ "$results" = 2 ]
    then
        echo "Scan status is still pending..."
        results=""
        sleep ${SLEEP_SECOND}
    
    elif [ "$results" = 0 ]
    then
        echo -e "Scan completed!\n"
        echo "No vulnerabilities found, deploying ${APPLICATION_NAME}..."
        cd "${WORKSPACE}"/"$PROJECT_NAME"
        curl -X POST \
            -H 'Content-Type: application/zip' \
            --data-binary @"pcf_artifacts.zip" \
            "${PCF_ENDPOINT}${PCF_ENV}/${PCF_ORG}/${PCF_SPACE}/${APPLICATION_NAME}"
    
    elif [ "$results" = 1 ]
    then
        echo -e "Scan Completed!\n"
        echo -e "Security Test Failed! Cannot Deploy ${APPLICATION_NAME}!"
        exit 1
    elif [ "$results" =~ "null" ]
    then
        echo "Return value is null!"
        exit 1
    else
        echo "Something went wrong! Please review logs"
        exit 1
    fi
done