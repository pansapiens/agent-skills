---
name: pushbullet
priority: 5
description: >-
  Interact with the Pushbullet API to send push notifications, links, files, and
  SMS to phones and devices. Use curl/jq on the command line or write Python
  scripts. Keywords: pushbullet, push notification, send to phone, send to device,
  push message, push link, push file, list devices, SMS via pushbullet.
license: MIT
metadata:
  author: AI Agent
  version: 1.0.0
  created: 2026-05-02
  last_reviewed: 2026-05-02
  review_interval_days: 90
  dependencies:
    - url: https://api.pushbullet.com/v2
      name: Pushbullet API
      type: api
---
# Pushbullet API Integration

Official API docs: https://docs.pushbullet.com/

You are an expert at interacting with the Pushbullet API. Your job is to help the user send push notifications, links, files, and SMS to their devices via Pushbullet, using `curl` and `jq` on the command line or Python scripts with the `requests` library.

## Prerequisites

The `PUSHBULLET_API_KEY` environment variable must contain a valid Pushbullet access token. Check for it before making any API calls. If it is not set, prompt the user:

> Please set your Pushbullet API key in the `PUSHBULLET_API_KEY` environment variable (e.g. in your shell profile or `.env` file). You can generate an access token at https://www.pushbullet.com/#settings

## Trigger

This skill activates when the user wants to interact with Pushbullet or send things to their phone/devices. Example phrases:

- "send a pushbullet notification"
- "push this to my phone"
- "send a link to my devices"
- "list my pushbullet devices"
- "get my recent pushes"
- "send a file to my phone"
- "send an SMS via pushbullet"

If the user asks to "send to my phone" or "notify my phone" without specifying a service, confirm that Pushbullet should be used.

## Instructions

1. **Verify Authentication**
   - Run: `echo $PUSHBULLET_API_KEY` (or equivalent) to check the variable is set.
   - If empty, stop and prompt the user (see Prerequisites).

2. **Consult the API Reference**
   - Full endpoint documentation is in `references/pushbullet-api.md`. Read it for payload formats, query parameters, and the 3-step file upload process.

3. **Execute via curl (default)**
   - For one-off API calls, use `curl` piped to `jq`:
     - Auth header: `--header "Access-Token: ${PUSHBULLET_API_KEY}"`
     - JSON body: `--header 'Content-Type: application/json' --data-binary '{...}'`
   - Always pipe to `jq .` for readable output.

4. **Write Python scripts when appropriate**
   - For complex logic, loops, or when the user requests a script.
   - Load the token: `os.environ["PUSHBULLET_API_KEY"]`
   - Use the `requests` library.
   - Follow patterns from `references/pushbullet-api.md`.
   - Use `uv run` to execute scripts where available — include PEP 723 inline metadata so dependencies are handled automatically:
     ```python
     # /// script
     # dependencies = ["requests"]
     # ///
     ```

5. **Uploading files is a 3-step process**
   1. `POST /v2/upload-request` with `file_name` and `file_type` to get an `upload_url` and `file_url`.
   2. Upload the file to `upload_url` using multipart form data (`curl -F file=@filename`).
   3. `POST /v2/pushes` with `type: "file"`, `file_url`, `file_name`, and `file_type`.

6. **Targeting pushes**
   - Omit target fields to push to all of the user's devices.
   - Use `device_iden` to target a specific device (list devices first with `GET /v2/devices`).
   - Use `email` to push to another Pushbullet user.

7. **Error handling**
   - Check for non-200 status codes in responses. The API returns JSON errors with `type` and `message` fields.
   - Watch for `429 Too Many Requests` — back off and retry if ratelimited. Check `X-Ratelimit-Remaining` headers.
   - Free accounts are limited to 500 pushes per month.

## Examples

### Send a note to all devices
```bash
curl --header "Access-Token: ${PUSHBULLET_API_KEY}" \
     --header 'Content-Type: application/json' \
     --data-binary '{"type": "note", "title": "Notification", "body": "Task completed successfully!"}' \
     --request POST \
     https://api.pushbullet.com/v2/pushes | jq .
```

### Get all pushes
```bash
curl --header "Access-Token: ${PUSHBULLET_API_KEY}" \
     --data-urlencode active="true" \
     --get \
     https://api.pushbullet.com/v2/pushes | jq .
```

### List devices
```bash
curl --header "Access-Token: ${PUSHBULLET_API_KEY}" \
     https://api.pushbullet.com/v2/devices | jq .
```

### Send a link
```bash
curl --header "Access-Token: ${PUSHBULLET_API_KEY}" \
     --header 'Content-Type: application/json' \
     --data-binary '{"type": "link", "title": "Check this out", "url": "https://example.com", "body": "Interesting page"}' \
     --request POST \
     https://api.pushbullet.com/v2/pushes | jq .
```

### Delete a push
Replace `{iden}` with the push identifier from a list-pushes response.
```bash
curl --header "Access-Token: ${PUSHBULLET_API_KEY}" \
     --request DELETE \
     https://api.pushbullet.com/v2/pushes/{iden} | jq .
```
