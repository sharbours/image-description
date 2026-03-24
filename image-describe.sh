#!/usr/bin/env bash
#
# image-describe.sh - Image analysis via Ollama Vision API
# Copyright (C) 2026 [S. Harbour - Silicon Forest]
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# --- Default Variables ---
OLLAMA_IP="127.0.0.1"
OLLAMA_PORT="11434"
MODEL="qwen3.5:0.8b"
PROMPT="What is in this image? Be brief, use three sentences or less to describe the objects and surroundings, unless there is OCR text, then include all the image text in the description."
VERBOSE=0
TAG_METADATA=0
SHOW_GPS=0
IMAGE_INPUT=""
IS_REMOTE=0

# A standard Windows/Chrome User-Agent
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

# --- Functions ---
show_help() {
    echo "Usage: $(basename "$0") [OPTIONS] <image_file_or_url>"
    echo ""
    echo "Options:"
    echo "  -i, --ip <address>    Remote Ollama IP (default: $OLLAMA_IP)"
    echo "  -m, --model <model>   Vision model (default: $MODEL)"
    echo "  -t, --tag             Write AI description to image metadata (local files only)"
    echo "  -g, --get-meta        Extract and display existing GPS/DateTime metadata"
    echo "  -v, --verbose         Enable verbose output"
    echo "  -h, --help            Show help"
}

log() { [[ "$VERBOSE" -eq 1 ]] && echo -e "[INFO] $1"; }
error_exit() { echo -e "[ERROR] $1" >&2; exit 1; }

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--ip) OLLAMA_IP="$2"; shift ;;
        -m|--model) MODEL="$2"; shift ;;
        -t|--tag) TAG_METADATA=1 ;;
        -g|--get-meta) SHOW_GPS=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) show_help; exit 0 ;;
        *) IMAGE_INPUT="$1" ;;
    esac
    shift
done

[[ -z "$IMAGE_INPUT" ]] && { show_help; exit 1; }

# --- Setup Cleanup Trap ---
TMP_JSON=$(mktemp /tmp/ollama_req_XXXXXX.json)
TMP_IMAGE=""
trap 'rm -f "$TMP_JSON" "$TMP_IMAGE"; log "Cleanup complete."' EXIT

# --- Input Handling (Local vs Remote) ---
if [[ "$IMAGE_INPUT" =~ ^http ]]; then
    log "URL detected. Downloading image..."
    IS_REMOTE=1
    
    # 1. Extract just the extension (e.g., jpg) by stripping everything after a '?' or '&'
    # and taking only the last 3-4 chars after the final dot.
    CLEAN_URL="${IMAGE_INPUT%%\?*}"
    EXT="${CLEAN_URL##*.}"
    
    # 2. Safety check: If the extension is longer than 4 chars (e.g. it failed to strip), 
    # default to 'img' to keep mktemp happy.
    if [[ ${#EXT} -gt 4 ]]; then EXT="img"; fi

    # 3. mktemp requires the XXXXXX to be at the very end of the string.
    # We will append the extension AFTER mktemp creates the base file.
    TMP_BASE=$(mktemp /tmp/ollama_dl_XXXXXX)
    TMP_IMAGE="${TMP_BASE}.${EXT}"
    
    # Use -A for User-Agent and -L for redirects. Quote "$IMAGE_INPUT" heavily!
    curl -s -L -A "$USER_AGENT" -o "$TMP_IMAGE" "$IMAGE_INPUT"
    
    if [[ $? -ne 0 || ! -s "$TMP_IMAGE" ]]; then
        error_exit "Failed to download image from remote URL. Check quotes or connectivity."
    fi
    IMAGE_FILE="$TMP_IMAGE"
else
    IMAGE_FILE="$IMAGE_INPUT"
    [[ ! -f "$IMAGE_FILE" ]] && error_exit "File '$IMAGE_FILE' not found."
fi
# --- Metadata Extraction ---
if [[ "$SHOW_GPS" -eq 1 ]]; then
    echo "--- Existing File Metadata ---"
    DT=$(identify -format "%[exif:DateTimeOriginal]" "$IMAGE_FILE" 2>/dev/null)
    LAT=$(identify -format "%[exif:GPSLatitude]" "$IMAGE_FILE" 2>/dev/null)
    LON=$(identify -format "%[exif:GPSLongitude]" "$IMAGE_FILE" 2>/dev/null)
    [[ -n "$DT" ]] && echo "Captured: $DT" || echo "Captured: Unknown"
    [[ -n "$LAT" ]] && echo "GPS: $LAT, $LON" || echo "GPS: Unknown"
    echo "------------------------------"
fi

# --- Process Request ---
IMAGE_BASE64=$(base64 -w 0 "$IMAGE_FILE")

cat <<EOF > "$TMP_JSON"
{
  "model": "$MODEL",
  "prompt": "$PROMPT",
  "stream": false,
  "options": { "reasoning_effort": "none" },
  "images": ["$IMAGE_BASE64"]
}
EOF

log "Sending request to http://$OLLAMA_IP:$OLLAMA_PORT..."
RESPONSE=$(curl -s -m 60 "http://$OLLAMA_IP:$OLLAMA_PORT/api/generate" -H "Content-Type: application/json" -d @"$TMP_JSON")
[[ $? -ne 0 ]] && error_exit "Ollama connection failed."

PARSED_TEXT=$(echo "$RESPONSE" | grep -oP '"response":"\K.*?(?=","thinking":)')

if [[ -n "$PARSED_TEXT" ]]; then
    echo -e "\nAI Analysis:"
    echo "$PARSED_TEXT"
    
    if [[ "$TAG_METADATA" -eq 1 ]]; then
        if [[ "$IS_REMOTE" -eq 1 ]]; then
            log "Skipping metadata tag: Input was a remote URL."
        else
            log "Updating local image metadata..."
            mogrify -set comment "$PARSED_TEXT" "$IMAGE_FILE"
        fi
    fi
else
    error_exit "Analysis failed. Raw response: $RESPONSE"
fi
