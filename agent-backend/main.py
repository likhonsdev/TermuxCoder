import os
import requests
import json
import google.generativeai as genai
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from google.generativeai.types import HarmCategory, HarmBlockThreshold
from dotenv import load_dotenv

# --- Configuration & Setup ---
load_dotenv()
app = FastAPI()
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
PLAYWRIGHT_SERVICE_URL = "http://playwright-service:3000"

with open("system_prompt.txt", "r") as f:
    SYSTEM_PROMPT = f.read()

# --- Define the Agent's "Toolbelt" for Gemini ---
# This is the core of the Function Calling paradigm
tools = [
    {
        "name": "navigate_to_url",
        "description": "Navigates the browser to a specific URL.",
        "parameters": {
            "type": "object",
            "properties": {
                "url": {"type": "string", "description": "The full URL to navigate to."}
            }, "required": ["url"]
        }
    },
    {
        "name": "click_element",
        "description": "Clicks on an element on the page specified by a selector.",
        "parameters": {
            "type": "object",
            "properties": {
                "selector": {"type": "string", "description": "A robust Playwright selector (e.g., 'button:has-text(\"Submit\")')."},
                "reason": {"type": "string", "description": "Why you are clicking this element."}
            }, "required": ["selector", "reason"]
        }
    },
    {
        "name": "fill_field",
        "description": "Fills a text into an input field, specified by a selector.",
        "parameters": {
            "type": "object",
            "properties": {
                "selector": {"type": "string", "description": "A robust Playwright selector for the input field."},
                "text": {"type": "string", "description": "The text to type into the field."},
                "reason": {"type": "string", "description": "Why you are filling this field."}
            }, "required": ["selector", "text", "reason"]
        }
    },
    {
        "name": "press_key",
        "description": "Simulates a key press on a specific element.",
        "parameters": {
            "type": "object",
            "properties": {
                "selector": {"type": "string", "description": "A robust Playwright selector for the element."},
                "key": {"type": "string", "description": "The key to press (e.g., 'Enter', 'ArrowDown')."},
                "reason": {"type": "string", "description": "Why you are pressing this key."}
            }, "required": ["selector", "key", "reason"]
        }
    },
     {
        "name": "finish_task",
        "description": "Call this function when you believe the user's entire task is successfully completed.",
        "parameters": {
            "type": "object",
            "properties": {
                "summary": {"type": "string", "description": "A brief summary of what you accomplished."}
            }, "required": ["summary"]
        }
    }
]

# Configure the Gemini 2.5 Pro model
# We tell the model about the tools it can use
model = genai.GenerativeModel(
    model_name="gemini-1.5-pro-latest", # Use the real latest model name
    system_instruction=SYSTEM_PROMPT,
    tools=tools
)

# --- WebSocket Logic for Hybrid-UI ---
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    history = []

    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)

            if message['type'] == 'user_task':
                task = message['content']
                history.append({'role': 'user', 'parts': [task]})

                # Start the agent loop
                for i in range(15): # Safety break
                    # 1. PERCEIVE
                    screenshot_res = requests.get(f"{PLAYWRIGHT_SERVICE_URL}/screenshot")
                    screenshot_bytes = screenshot_res.content

                    # 2. REASON (with Function Calling)
                    prompt = [
                        "This is the current state of the browser. Your task is to continue progress on the user's request.",
                        {"mime_type": "image/png", "data": screenshot_bytes}
                    ]

                    # Gemini 2.5 Pro's long context allows sending the whole history
                    response = model.generate_content(history + prompt)

                    # 3. ACT
                    call = response.candidates[0].content.parts[0].function_call
                    thought_text = f"I need to use the `{call.name}` tool." # Simplified thought

                    await websocket.send_text(json.dumps({
                        "type": "thought", "content": thought_text
                    }))

                    await websocket.send_text(json.dumps({
                        "type": "action", "tool": call.name, "args": dict(call.args)
                    }))

                    if call.name == "finish_task":
                        summary = call.args['summary']
                        await websocket.send_text(json.dumps({"type": "result", "content": f"Task Finished: {summary}"}))
                        break

                    # Execute the tool via Playwright service
                    result = execute_playwright_tool(call.name, dict(call.args))

                    await websocket.send_text(json.dumps(result))

                    # Update history for the next loop
                    history.append({'role': 'model', 'parts': [response.candidates[0].content.parts[0]]})
                    history.append({
                        'role': 'tool',
                        'parts': [{"function_response": {"name": call.name, "response": result}}]
                    })

    except WebSocketDisconnect:
        print("Client disconnected")

def execute_playwright_tool(name, args):
    """Executes the corresponding Playwright action via a simple API call."""
    code_map = {
        "navigate_to_url": f"await page.goto('{args['url']}')",
        "click_element": f"await page.click('{args['selector']}')",
        "fill_field": f"await page.fill('{args['selector']}', '{args['text']}')",
        "press_key": f"await page.press('{args['selector']}', '{args['key']}')"
    }

    code = code_map.get(name)
    if not code:
        return {"type": "error", "content": f"Unknown tool: {name}"}

    try:
        res = requests.post(f"{PLAYWRIGHT_SERVICE_URL}/execute", json={"code": code}, timeout=10)
        res.raise_for_status()
        return {"type": "result", "content": f"Successfully executed {name}."}
    except requests.RequestException as e:
        return {"type": "error", "content": f"Failed to execute {name}: {e}"}
