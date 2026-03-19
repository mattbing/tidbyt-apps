# Claude Says - Tidbyt/Tronbyt App

A Tidbyt app that calls the Claude API to generate a short creative sentence and scrolls it across your display.

## What it does

- Calls Claude (Haiku 4.5) every 15 minutes for a new witty sentence
- Shows "Claude says:" header in amber with the generated text scrolling below in purple
- Caches responses to avoid excessive API calls

## Local Deployment on Tronbyt

### Prerequisites

1. **Pixlet** (Tronbyt fork recommended):
   ```bash
   # macOS
   brew install tronbyt/tronbyt/pixlet

   # Linux - download from https://github.com/tronbyt/pixlet/releases
   ```

2. **Tronbyt server** running locally (default: `http://localhost:8000`)

3. **Anthropic API key** from https://console.anthropic.com/

### Development & Preview

```bash
# Preview in browser at http://localhost:8080
pixlet serve claude_says.star

# Pass your API key for a live preview
pixlet serve claude_says.star -- api_key=sk-ant-...

# Render to a static file
pixlet render claude_says.star api_key=sk-ant-...
# Output: claude_says.webp
```

### Deploy to Tronbyt

**Option A: Tronbyt Web UI (easiest)**
1. Open your Tronbyt web interface at `http://<tronbyt-server>:8000`
2. Go to your device and add a new app
3. Upload or paste `claude_says.star`
4. Set the `api_key` config field to your Anthropic API key
5. Save — the app will appear in your device rotation

**Option B: Push via pixlet CLI**
```bash
# Render and push in one step
pixlet render claude_says.star api_key=sk-ant-...
pixlet push --api-token <TRONBYT_API_TOKEN> <DEVICE_ID> claude_says.webp

# Or with installation ID to add to rotation
pixlet push --api-token <TRONBYT_API_TOKEN> \
  --installation-id claude-says \
  <DEVICE_ID> claude_says.webp
```

**Option C: Cron job for regular updates**
```bash
# Add to crontab to refresh every 15 minutes
*/15 * * * * cd /path/to/tidbyt-claude-says && pixlet render claude_says.star api_key=sk-ant-... && pixlet push --api-token <TOKEN> --installation-id claude-says <DEVICE_ID> claude_says.webp
```

### Notes

- The app uses `claude-haiku-4-5-20251001` for fast, cheap responses
- Sentences are cached for 15 minutes to minimize API costs
- Cost is negligible — Haiku is extremely cheap and responses are tiny
