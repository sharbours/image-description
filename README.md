# image-describe.sh 📸🤖

A lightweight Bash utility to bridge local files (or remote URLs) with a vision-capable Large Language Model (LLM) hosted via **Ollama**. 

This script is designed for high-performance local environments (Proxmox/Nvidia GPU clusters) and provides agentic "eyes" for automation workflows, such as residential repair surveys, 3D printing documentation, or home automation.

---

## Features
* **Vision Analysis:** Sends images to a remote or local Ollama instance for text descriptions.
* **Remote URL Support:** Automatically detects URLs, downloads them to a temporary directory with a forged User-Agent, and cleans up after execution.
* **Metadata Extraction:** Optional flag to display existing EXIF data (GPS and Timestamp).
* **Metadata Tagging:** Optionally writes the AI-generated description back into the image's "Comment" or "ImageDescription" fields using ImageMagick.
* **Agent-Friendly:** Clean output parsing using `grep -P` (no `jq` dependency required) for easy integration into LLM tool-calling.
* **GPLv3 Licensed:** Open-source and copyleft protected.

---

## Prerequisites
* **Ollama:** A running instance with a vision model (e.g., `qwen3.5:0.8b`, `llava`, or `moondream`).
* **Dependencies:** `curl`, `base64`, and **ImageMagick** (specifically `identify` and `mogrify` for metadata features).
* **Operating System:** Linux / macOS.

---

## Installation
1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/whatisthis.git](https://github.com/your-username/whatisthis.git)
    cd whatisthis
    ```
2.  **Make the script executable:**
    ```bash
    chmod +x whatisthis.sh
    ```

---

## Usage

### Basic Analysis
```bash
./whatisthis.sh -i 192.168.0.122 ./my_photo.jpg
