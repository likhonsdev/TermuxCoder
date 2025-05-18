import requests
import json
import os

def main():
    # WARNING: Keep your API key secret! Use environment variables or a secret management service in production.
    # Replace 'YOUR_PIPE_API_KEY' with your actual Pipe Secret API Key.
    apiKey = os.environ.get('PIPE_API_KEY', 'YOUR_PIPE_API_KEY')

    if apiKey == 'YOUR_PIPE_API_KEY':
        print("Please replace 'YOUR_PIPE_API_KEY' with your actual API key or set the PIPE_API_KEY environment variable.")
        return

    url = 'https://api.langbase.com/v1/pipes/run'

    data = {
        'messages': [{'role': 'user', 'content': 'Hello!'}],
		'stream': True
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {apiKey}"
    }

    try:
        response = requests.post(url, headers=headers, data=json.dumps(data), stream=True)
        response.raise_for_status() # Raise an HTTPError for bad responses (4xx or 5xx)

        if not response.ok:
            print(f"Error: {response.status_code}")
            print(response.json())
            return

        for line in response.iter_lines():
            if line:
                try:
                    decoded_line = line.decode('utf-8')
                    if decoded_line.startswith('data: '):
                        json_str = decoded_line[6:]
                        if json_str.strip() and json_str != '[DONE]':
                            data = json.loads(json_str)
                            if data['choices'] and len(data['choices']) > 0:
                                delta = data['choices'][0].get('delta', {})
                                if 'content' in delta and delta['content']:
                                    print(delta['content'], end='', flush=True)
                except json.JSONDecodeError:
                    print("Failed to parse JSON from line")
                    continue
                except Exception as e:
                    print(f"Error processing line: {e}")

    except requests.exceptions.RequestException as e:
        print(f"Request Error: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


if __name__ == "__main__":
    main()
