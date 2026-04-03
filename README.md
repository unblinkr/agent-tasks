# Polypal Tasks — Claude × OpenClaw Agent Bridge

This repo is the bridge between Claude (strategist) and OpenClaw (executor).

## How it works
1. Claude pushes task files to `tasks/pending/`
2. A watcher on Hostinger VPS polls this repo every 60 seconds
3. Watcher reads new task files and posts instructions to Discord channels
4. OpenClaw agents in Discord execute the tasks
5. Completed tasks move to `tasks/done/`

## Task format
Each task is a JSON file in `tasks/pending/`:
```json
{
  "channel": "scout",
  "message": "Research Chrome extensions for payment splitting...",
  "project": "polypal",
  "priority": "high",
  "created_at": "2026-04-03T21:00:00Z"
}
```

## Channels
- `scout` — Research & validation
- `builder` — Code & build
- `marketing` — Content & social
- `ship-log` — Activity log
- `general` — General comms
