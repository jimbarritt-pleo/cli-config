#!/bin/bash

# Decode JWT token from clipboard and print formatted output
# Usage: sh scripts/decode-jwt.sh

set -e

# Get JWT from clipboard
JWT=$(pbpaste)

if [ -z "$JWT" ]; then
    echo "Error: No content found in clipboard"
    exit 1
fi

# Remove any whitespace
JWT=$(echo "$JWT" | tr -d '[:space:]')

# Validate JWT format (should have 3 parts separated by dots)
if [ $(echo "$JWT" | grep -o '\.' | wc -l) -ne 2 ]; then
    echo "Error: Invalid JWT format. Expected format: header.payload.signature"
    exit 1
fi

# Extract parts
HEADER=$(echo "$JWT" | cut -d'.' -f1)
PAYLOAD=$(echo "$JWT" | cut -d'.' -f2)
SIGNATURE=$(echo "$JWT" | cut -d'.' -f3)

# Function to decode base64url (JWT uses base64url encoding)
decode_base64url() {
    local input=$1
    # Add padding if needed
    local padded="$input"
    case $((${#input} % 4)) in
        2) padded="${input}==" ;;
        3) padded="${input}=" ;;
    esac
    # Replace base64url chars with base64 and decode
    echo "$padded" | tr '_-' '/+' | base64 -d 2>/dev/null
}

echo "========================================="
echo "JWT Token Decoder"
echo "========================================="
echo ""

echo "HEADER:"
echo "-------"
decode_base64url "$HEADER" | jq . 2>/dev/null || echo "Failed to decode header"
echo ""

echo "PAYLOAD:"
echo "--------"
DECODED_PAYLOAD=$(decode_base64url "$PAYLOAD")
echo "$DECODED_PAYLOAD" | jq . 2>/dev/null || echo "$DECODED_PAYLOAD"
echo ""

# Pretty print timestamps if present
if command -v jq &> /dev/null; then
    IAT=$(echo "$DECODED_PAYLOAD" | jq -r '.iat // empty' 2>/dev/null)
    EXP=$(echo "$DECODED_PAYLOAD" | jq -r '.exp // empty' 2>/dev/null)
    NBF=$(echo "$DECODED_PAYLOAD" | jq -r '.nbf // empty' 2>/dev/null)

    if [ ! -z "$IAT" ]; then
        echo "Issued At (iat):  $IAT -> $(date -r "$IAT" 2>/dev/null || echo 'invalid')"
    fi
    if [ ! -z "$EXP" ]; then
        echo "Expires (exp):    $EXP -> $(date -r "$EXP" 2>/dev/null || echo 'invalid')"

        # Check if expired
        NOW=$(date +%s)
        if [ "$EXP" -lt "$NOW" ]; then
            echo "⚠️  Token has EXPIRED"
        else
            REMAINING=$((EXP - NOW))
            echo "✓ Token valid for $((REMAINING / 3600))h $((REMAINING % 3600 / 60))m"
        fi
    fi
    if [ ! -z "$NBF" ]; then
        echo "Not Before (nbf): $NBF -> $(date -r "$NBF" 2>/dev/null || echo 'invalid')"
    fi
    echo ""
fi

echo "SIGNATURE:"
echo "----------"
echo "$SIGNATURE"
echo ""
echo "========================================="