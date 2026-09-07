#!/usr/bin/env python3
"""Claude Code status line: session id · model · context% · rate-limit usage."""
import json
import subprocess
import sys
import time


def git_branch(cwd):
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=cwd, capture_output=True, text=True, timeout=1,
        )
        if out.returncode == 0:
            return out.stdout.strip()
    except Exception:
        pass
    return None


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return

    parts = []

    session_id = data.get("session_id")
    if session_id:
        parts.append(session_id[:8])

    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd")
    branch = git_branch(cwd) if cwd else None
    if branch:
        parts.append(f"⎇ {branch}")

    model = (data.get("model") or {}).get("display_name")
    if model:
        effort = (data.get("effort") or {}).get("level")
        parts.append(f"{model} ({effort})" if effort else model)

    ctx = data.get("context_window") or {}
    used_tokens = ctx.get("total_input_tokens")
    limit = ctx.get("context_window_size")
    pct = ctx.get("used_percentage")
    if used_tokens is not None and limit:
        pct_str = f" ({round(pct)}%)" if pct is not None else ""
        parts.append(f"ctx:{used_tokens // 1000}k/{limit // 1000}k{pct_str}")

    rate_limits = data.get("rate_limits") or {}
    five_hour = rate_limits.get("five_hour") or {}
    seven_day = rate_limits.get("seven_day") or {}
    usage_bits = []
    if five_hour.get("used_percentage") is not None:
        bit = f"5h/{round(five_hour['used_percentage'])}%"
        resets_at = five_hour.get("resets_at")
        if resets_at:
            remaining = int(resets_at) - int(time.time())
            if remaining > 0:
                hrs, rem = divmod(remaining, 3600)
                mins = rem // 60
                bit += f" ({hrs}h{mins:02d}m left)"
        usage_bits.append(bit)
    if seven_day.get("used_percentage") is not None:
        usage_bits.append(f"7d/{round(seven_day['used_percentage'])}%")
    if usage_bits:
        parts.append("usage: " + " ".join(usage_bits))

    print("  ".join(parts))


if __name__ == "__main__":
    main()
