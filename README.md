# image-describe.sh 📸🤖

A lightweight Bash utility to bridge local files (or remote URLs) with a vision-capable Large Language Model (LLM) hosted via **Ollama**. 

This script is designed for high-performance local home lab environments (Proxmox/Nvidia GPU clusters) and provides agentic "eyes" for automation workflows, such as OCR, residential security cams, image batch updates, or home automation. It can read files locally or from a provided URL (URLs are downloaded into /tmp and then cleaned up after the script exits). Response time is around 5 to 20 seconds with qwen3.5:0.8b hosted on a GTX1060. Theoretically, it 'should' work with Ollama on a CPU only host, but you may have to fiddle with the timeouts. My first use case is to automate detailed daily logs of security cam footage.

New -f option "focus-on" allows the prompt to be interactively modified for follow up questions. Example:
image-describe -f "the house architecture style" -i my-vision-server-ip-or-dns-name http://www.example.com/housepicture3.jpg

Requirements - Some reasonably recent version of Linux or MacOS (Tested on Debian 13 Trixie). Imagemagick is optional if you want to be able to update the metadata on the images to include the description returned by Qwen.

---

## Features
* **Vision Analysis:** Sends images to a remote or local Ollama instance for text descriptions.
* **Remote URL Support:** Automatically detects URLs, downloads them to a temporary directory, and cleans up after execution.
* **Metadata Extraction:** Optional flag to display existing EXIF data (GPS and Timestamp).
* **Metadata Tagging:** Optionally writes the AI-generated description back into the image's "Comment" or "ImageDescription" fields using ImageMagick.
* **Agent-Friendly:** Clean output parsing using `grep -P` (no `jq` dependency required) for easy integration into LLM tool-calling.
* **GPLv3 Licensed:** Open-source and copyleft protected.

---

## Prerequisites
* **Ollama:** A running instance with a vision model (e.g., `qwen3.5:0.8b` (tested), `llava`, or `moondream`).
* **Dependencies:** `curl`, `base64`, and optionally **ImageMagick** (specifically `identify` and `mogrify` for metadata features).
* **Operating System:** Linux / macOS.

---

## Installation
1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/sharbours/image-description.git](https://github.com/sharbours/imagedescription.git)
    cd image-description
    ```
2.  **Make the script executable:**
    ```bash
    chmod +x image-describe.sh
    ```

---

## Usage

### Basic Analysis
```bash
./image-describe.sh -i 192.168.0.123 ./my_photo.jpg
./image-describe.sh -i 192.168.0.123 http://www.website.us/photos/photo123.png
