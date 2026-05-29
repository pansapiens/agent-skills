# Pushbullet API Reference

Official docs: https://docs.pushbullet.com/

Base URL: `https://api.pushbullet.com/v2`

## Authentication

All requests require the `Access-Token` header:
```
Access-Token: <your_access_token_here>
```

For POST/PUT requests sending JSON, also include:
```
Content-Type: application/json
```

### HTTP Status Codes
- `200` OK
- `400` Bad Request (missing required parameter)
- `401` Unauthorized (invalid access token)
- `403` Forbidden (token not valid for that request)
- `404` Not Found
- `429` Too Many Requests (ratelimited)
- `5XX` Server Error

### Ratelimiting
Response headers include:
- `X-Ratelimit-Limit` — total allowed per interval
- `X-Ratelimit-Remaining` — remaining in current interval
- `X-Ratelimit-Reset` — unix timestamp when the limit resets

Free accounts are limited to 500 pushes per month.

### Error Response Format
```json
{
  "error": {
    "type": "invalid_request",
    "message": "The resource could not be found.",
    "cat": "~(=^‥^)"
  }
}
```

### Pagination
List endpoints return a `cursor` field when more results are available. Pass it as a query parameter to get the next page.

### Deleted Objects
When `active` is `false`, the object has been deleted. Use `modified_after` to sync changes efficiently.

---

## 1. User

**Get Current User**
- `GET /v2/users/me`
- Returns: `iden`, `email`, `name`, `image_url`, `max_upload_size`, `created`, `modified`

---

## 2. Devices

**List Devices**
- `GET /v2/devices`
- Returns: `{"devices": [...]}`

**Create Device**
- `POST /v2/devices`
- Payload: `{"nickname": "My Server", "model": "Linux", "manufacturer": "Custom"}`
- Optional fields: `push_token`, `app_version`, `icon` (`desktop`, `browser`, `website`, `laptop`, `tablet`, `phone`, `watch`, `system`)

**Update Device**
- `POST /v2/devices/{iden}`
- Payload: `{"nickname": "New Name"}`

**Delete Device**
- `DELETE /v2/devices/{iden}`

---

## 3. Pushes

**List Pushes**
- `GET /v2/pushes`
- Query parameters:
  - `modified_after` — unix timestamp, return only pushes modified after this time
  - `active` — `true` to return only non-deleted pushes
  - `cursor` — pagination cursor from a previous response
  - `limit` — max number of pushes to return
- Returns: `{"pushes": [...]}`

**Create Push**
- `POST /v2/pushes`
- Push types:

  **Note:**
  ```json
  {"type": "note", "title": "Hello", "body": "Message body"}
  ```

  **Link:**
  ```json
  {"type": "link", "title": "Cool Site", "body": "Check this out", "url": "https://example.com"}
  ```

  **File** (requires upload first, see section 7):
  ```json
  {"type": "file", "file_name": "cat.jpg", "file_type": "image/jpeg", "file_url": "https://...", "body": "A cat"}
  ```

- Target parameters (optional, pick at most one):
  - `device_iden` — send to a specific device (use `/v2/devices` to find the iden)
  - `email` — send to a Pushbullet user by email (falls back to email delivery)
  - `channel_tag` — send to all subscribers of a channel
  - `client_iden` — send to all users of an OAuth client
  - _(omit all targets to send to all of the user's own devices)_

- Returns: a Push object with `iden`, `active`, `type`, `title`, `body`, `url`, `created`, `modified`, `dismissed`, `direction`, `sender_*`, `receiver_*` fields.

**Update Push** (dismiss only)
- `POST /v2/pushes/{iden}`
- Payload: `{"dismissed": true}`

**Delete Push**
- `DELETE /v2/pushes/{iden}`

**Delete All Pushes**
- `DELETE /v2/pushes`

---

## 4. Chats

**List Chats**
- `GET /v2/chats`
- Returns: `{"chats": [...]}`

**Create Chat**
- `POST /v2/chats`
- Payload: `{"email": "[email protected]"}`

**Update Chat**
- `POST /v2/chats/{iden}`
- Payload: `{"muted": true}`

**Delete Chat**
- `DELETE /v2/chats/{iden}`

---

## 5. Subscriptions (Channels)

**List Subscriptions**
- `GET /v2/subscriptions`
- Returns: `{"subscriptions": [...]}`

**Create Subscription**
- `POST /v2/subscriptions`
- Payload: `{"channel_tag": "elonmusknews"}`

**Update Subscription**
- `POST /v2/subscriptions/{iden}`
- Payload: `{"muted": true}`

**Delete Subscription**
- `DELETE /v2/subscriptions/{iden}`

**Channel Info** (no auth required)
- `GET /v2/channel-info?tag={tag}`
- Optional: `no_recent_pushes=true`

---

## 6. Texts (SMS)

Sends an SMS via the user's Android device. The device must have SMS permissions granted to Pushbullet.

**Create Text**
- `POST /v2/texts`
- Payload:
```json
{
  "data": {
    "target_device_iden": "ujpah72o0sjAoRtnM0jc",
    "addresses": ["+13035551212"],
    "message": "Hello from Pushbullet"
  }
}
```
- Optional: `file_url` and `data.file_type` for MMS attachments (upload the file first).
- Optional: `data.guid` to prevent duplicate sends.

**Update Text**
- `POST /v2/texts/{iden}`

**Delete Text**
- `POST /v2/texts/{iden}` with delete payload

---

## 7. Uploading Files

File uploads are a 3-step process:

**Step 1: Request an upload URL**
- `POST /v2/upload-request`
- Payload: `{"file_name": "cat.jpg", "file_type": "image/jpeg"}`
- Response includes: `file_name`, `file_type`, `file_url`, `upload_url`

**Step 2: Upload the file**
- `POST {upload_url}` (from step 1)
- Use multipart form data:
```bash
curl -i -X POST "{upload_url}" -F file=@cat.jpg
```
- Returns `204 No Content` on success.

**Step 3: Create the push**
- Use `file_url` from step 1 in a file-type push (see Create Push).

---

## 8. Ephemerals

Used for notification mirroring, clipboard sync, and SMS. These are not stored — they are delivered in real time via the websocket stream.

**Send Ephemeral**
- `POST /v2/ephemerals`
- Payload: `{"type": "push", "push": { ... }}`

### SMS via Ephemeral (legacy, prefer /v2/texts)
```json
{
  "type": "push",
  "push": {
    "type": "messaging_extension_reply",
    "package_name": "com.pushbullet.android",
    "source_user_iden": "ujpah72o0",
    "target_device_iden": "ujpah72o0sjAoRtnM0jc",
    "conversation_iden": "+1 303 555 1212",
    "message": "Hello!"
  }
}
```

### Universal Copy/Paste via Ephemeral
```json
{
  "type": "push",
  "push": {
    "type": "clip",
    "body": "Text to copy to clipboard",
    "source_user_iden": "ujpah72o0",
    "source_device_iden": "ujpah72o0sjAoRtnM0jc"
  }
}
```

---

## 9. Realtime Event Stream

Connect via WebSocket to receive live events:
```
wss://stream.pushbullet.com/websocket/<access_token>
```

Message types:
- `type: "nop"` — keepalive, sent every ~30 seconds
- `type: "tickle"` — something changed server-side; `subtype` indicates what (`push`, `device`)
- `type: "push"` — ephemeral push (mirrored notifications, clipboard, etc.)
