# Working in ~/Projects

This directory is **shared by Claude Code and Codex**. Its layout is deliberate — keep it clean.

## Layout

- **Top-level folders are code repos / real projects** (e.g. `my-web-app`, `some-service`, `a-cli-tool`). Leave these as they are. Only a genuine new project earns a new top-level folder — and ask before creating one.
- **`conversations/`** holds everything else: ad-hoc reports, data dumps, generated scripts, images, PDFs, scratch analysis — anything produced during a chat that isn't part of an existing repo.
  - `conversations/claude/` — your output
  - `conversations/codex/` — Codex's output
  - `conversations/_inbox/` — unsorted legacy files (ignore unless asked)

## Rule: where new files go

**Never write loose files to the `~/Projects` root.**

When you create any file that is **not** part of an existing repo, put it under:

```
conversations/claude/<YYYY-MM-DD>_<short_topic_slug>/
```

- Use **today's actual date** (run `date +%F` if unsure). Example: `conversations/claude/2026-06-05_projects_directory_organization/`.
- One folder per task/topic. If you're continuing work you already started in this session, reuse its folder instead of making a new one.
- Keep the slug short, lowercase, underscore-separated.

If a file clearly belongs inside an existing repo (it's code for that project), put it there instead — this rule is only for standalone/scratch output.

## Routine tasks (recurring work)

A **one-off** gets a dated folder (above). A **routine** — the same task run repeatedly (a weekly report, a daily data pull) — uses a different shape: the task is the folder, and dates live on the output *inside* it.

The moment you run something a second time, promote it to a routine:

```
conversations/claude/routines/<task-name>/
  run.py          # the script — kept stable and reused, edited not regenerated
  README.md       # what it does and how to run it
  out/<YYYY-MM-DD>/   # dated output for each run
```

- The **task name** is the folder (no date on it); only the `out/` subfolders are dated.
- Reuse `run.py` across runs instead of writing a fresh script each time.
- Raw data dumps in `out/` are disposable — regenerate from `run.py`, don't treat them as precious.
- Use a fixed, predictable path so scheduled/automated runs can write to it without guessing.
