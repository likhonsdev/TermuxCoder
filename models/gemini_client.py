#!/usr/bin/env python3
"""
TermuxCoder - Gemini API client

This script provides a client for interacting with the Google AI Gemini API.
It supports both streaming and non-streaming responses.

Usage:
  python3 gemini_client.py API_KEY MODEL PROMPT [TEMPERATURE] [MAX_TOKENS]
  
Examples:
  python3 gemini_client.py "your-api-key" "gemini-1.5-pro" "Write a Python script"
  python3 gemini_client.py "your-api-key" "gemini-1.5-flash" "Explain Docker" 0.3 2048
"""

import sys
import json
import time
import textwrap
import re
from datetime import datetime
import requests
from typing import Optional, Dict, Any, List


class GeminiClient:
    """Client for interacting with Google AI Gemini API"""
    
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    def __init__(self, api_key: str, model: str = "gemini-1.5-pro"):
        self.api_key = api_key
        self.model = model
        self.session = requests.Session()
        self.session.headers.update({
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        })
    
    def generate_content(
        self, 
        prompt: str, 
        temperature: float = 0.7, 
        max_tokens: int = 8192,
        stream: bool = True
    ) -> str:
        """Generate content from the Gemini API
        
        Args:
            prompt: The text prompt to send to the API
            temperature: Controls randomness (0.0 to 1.0)
            max_tokens: Maximum number of tokens to generate
            stream: Whether to stream the response or not
            
        Returns:
            Generated text from the API
        """
        url = f"{self.BASE_URL}/{self.model}:generateContent"
        
        # Prepare request data
        request_data = {
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {
                            "text": prompt
                        }
                    ]
                }
            ],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens
            }
        }
        
        if stream:
            return self._stream_response(url, request_data)
        
        return self._full_response(url, request_data)
    
    def _full_response(self, url: str, data: Dict[str, Any]) -> str:
        """Get full response from API (non-streaming)"""
        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            
            result = response.json()
            
            # Extract text from result
            if "candidates" in result and result["candidates"]:
                if "content" in result["candidates"][0]:
                    if "parts" in result["candidates"][0]["content"]:
                        parts = result["candidates"][0]["content"]["parts"]
                        return "".join(part["text"] for part in parts if "text" in part)
            
            return "Error: Could not extract text from response"
            
        except requests.RequestException as e:
            error_msg = f"API request failed: {e}"
            try:
                if response.json().get("error"):
                    error_msg = f"API error: {response.json()['error']['message']}"
            except:
                pass
            
            return f"Error: {error_msg}"
    
    def _stream_response(self, url: str, data: Dict[str, Any]) -> str:
        """Stream response from API and process chunks"""
        try:
            # Add streaming parameter to URL
            stream_url = f"{url}?alt=sse"
            
            # Set up streaming request
            response = self.session.post(
                stream_url,
                json=data,
                stream=True
            )
            response.raise_for_status()
            
            # Track collected text and code blocks
            full_text = ""
            in_code_block = False
            
            # Process streaming response
            for line in response.iter_lines():
                if not line or not line.startswith(b"data: "):
                    continue
                
                # Extract JSON from SSE data line
                json_str = line[6:].decode("utf-8")
                if json_str == "[DONE]":
                    break
                
                try:
                    chunk = json.loads(json_str)
                    
                    # Extract text from chunk
                    if "candidates" in chunk and chunk["candidates"]:
                        candidate = chunk["candidates"][0]
                        if "content" in candidate and "parts" in candidate["content"]:
                            parts = candidate["content"]["parts"]
                            
                            for part in parts:
                                if "text" in part:
                                    text_chunk = part["text"]
                                    
                                    # Format code blocks nicely
                                    if "```" in text_chunk:
                                        lines = text_chunk.split("\n")
                                        for line in lines:
                                            if line.startswith("```"):
                                                in_code_block = not in_code_block
                                                if in_code_block:  # Start of code block
                                                    sys.stdout.write("\n" + line + "\n")
                                                else:  # End of code block
                                                    sys.stdout.write(line + "\n\n")
                                            else:
                                                sys.stdout.write(line + "\n")
                                    else:
                                        sys.stdout.write(text_chunk)
                                    sys.stdout.flush()
                                    
                                    full_text += text_chunk
                
                except json.JSONDecodeError:
                    continue
            
            return full_text
            
        except requests.RequestException as e:
            error_msg = f"API request failed: {e}"
            try:
                if response.json().get("error"):
                    error_msg = f"API error: {response.json()['error']['message']}"
            except:
                pass
            
            print(f"Error: {error_msg}", file=sys.stderr)
            return f"Error: {error_msg}"


def highlight_code_blocks(text: str) -> str:
    """Add syntax highlighting to markdown code blocks using ANSI colors
    
    This function currently just adds basic formatting for code blocks,
    which works well enough in terminals that don't support full ANSI color.
    """
    lines = text.split("\n")
    result = []
    in_code_block = False
    
    for line in lines:
        if line.startswith("```"):
            in_code_block = not in_code_block
            # Add ANSI colors for code block delimiters
            result.append(f"\033[1;36m{line}\033[0m")
        else:
            if in_code_block:
                # Format code block content
                result.append(f"\033[0;37m{line}\033[0m")
            else:
                result.append(line)
    
    return "\n".join(result)


def main():
    """Main entry point for the script"""
    # Check arguments
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} API_KEY MODEL PROMPT [TEMPERATURE] [MAX_TOKENS]", file=sys.stderr)
        print(f"Example: {sys.argv[0]} your-api-key gemini-1.5-pro 'Write a Python script'", file=sys.stderr)
        sys.exit(1)
    
    # Extract arguments
    api_key = sys.argv[1]
    model = sys.argv[2]
    prompt = sys.argv[3]
    
    # Optional arguments
    temperature = float(sys.argv[4]) if len(sys.argv) > 4 else 0.7
    max_tokens = int(sys.argv[5]) if len(sys.argv) > 5 else 8192
    
    # Create client and generate content
    client = GeminiClient(api_key, model)
    try:
        response = client.generate_content(prompt, temperature, max_tokens)
        if response.startswith("Error:"):
            print(response, file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
