#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "jq is required for this script. Please install jq and try again."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: ./update-segment.sh <segment_name>"
    exit 1
fi

API_KEY="${MAUTIC_AUTH}"
SEGMENT_NAME="$1"
CSV_FILE="emails.txt"
MAUTIC_BASE_URL="${MAUTIC_BASE_URL}"

if [ -z "${API_KEY}" ]; then
    echo "API_KEY is not set. Please check your MAUTIC_AUTH environment variable."
    exit 1
fi

if [ -z "${MAUTIC_BASE_URL}" ]; then
    echo "MAUTIC_BASE_URL is not set. Please check your environment variables."
    exit 1
fi

API_RESPONSE=$(curl -s -X GET "${MAUTIC_BASE_URL}/api/segments?search=${SEGMENT_NAME}" -H "Authorization: Basic ${API_KEY}")
SEGMENT_ID=$(echo "${API_RESPONSE}" | jq ".lists[] | select(.name == \"${SEGMENT_NAME}\") | .id" 2>/dev/null)

if [ -z "${SEGMENT_ID}" ]; then
    echo "Creating segment ${SEGMENT_NAME}"
    API_RESPONSE=$(curl -s -X POST "${MAUTIC_BASE_URL}/api/segments/new" \
    -H "Authorization: Basic ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${SEGMENT_NAME}\"}")
    SEGMENT_ID=$(echo "${API_RESPONSE}" | jq ".list.id" 2>/dev/null)
fi

if [ -z "${SEGMENT_ID}" ]; then
    echo "Unable to retrieve or create segment. Please check your API_KEY and MAUTIC_BASE_URL."
    exit 1
fi

echo "Segment ID: ${SEGMENT_ID}"

while IFS= read -r email || [[ -n "$email" ]]; do
    email=$(echo "${email}" | tr -d '\r')
    if [ -n "${email}" ]; then
        echo "Processing ${email}"
        API_RESPONSE=$(curl -s -X GET "${MAUTIC_BASE_URL}/api/contacts?search=email:${email}" -H "Authorization: Basic ${API_KEY}")
        CONTACT_ID=$(echo "${API_RESPONSE}" | jq ".contacts[] | select(.fields.core.email.value == \"${email}\") | .id" 2>/dev/null)
        echo "Extracted Contact ID: ${CONTACT_ID}"

        if [ -z "${CONTACT_ID}" ]; then
            echo "Creating contact ${email}"
            API_RESPONSE=$(curl -s -X POST "${MAUTIC_BASE_URL}/api/contacts/new" \
            -H "Authorization: Basic ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "{\"email\":\"${email}\"}")
            CONTACT_ID=$(echo "${API_RESPONSE}" | jq ".contact.id" 2>/dev/null)
        fi

        if [ -z "${CONTACT_ID}" ]; then
            echo "Unable to retrieve or create contact. Please check your API_KEY and MAUTIC_BASE_URL."
            continue
        fi

        echo "Adding contact ${email} to segment ${SEGMENT_NAME}"
        curl -s -X POST "${MAUTIC_BASE_URL}/api/segments/${SEGMENT_ID}/contact/${CONTACT_ID}/add" \
        -H "Authorization: Basic ${API_KEY}" > /dev/null
    fi
done < "${CSV_FILE}"

echo "Done!"
