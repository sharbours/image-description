{
  "name": "analyze_image",
  "description": "Describe a local or remote image using a vision LLM.",
  "parameters": {
    "type": "object",
    "properties": {
      "image_input": { 
        "type": "string", 
        "description": "The absolute file path or quoted URL." 
      }
    },
    "required": ["image_input"]
  }
}
