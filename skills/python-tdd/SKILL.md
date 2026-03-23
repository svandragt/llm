---
name: python-tdd
description: "Run a red-green TDD cycle for Python projects using pytest: confirm baseline green, write a failing test, implement minimum code, confirm green, then lint with ruff."
---

Run a red-green TDD cycle for the current task:

1. Run `uv run pytest` — confirm baseline is green
2. Write a failing test in the relevant `apps/*/tests/` directory
   - Use existing factories from `apps/*/tests/factories.py` — do not hand-craft model instances
   - Override only the fields your test cares about
3. Implement the minimum code change to make the test pass
4. Run `uv run pytest` — confirm full suite is green
5. Run `uv run ruff check . && uv run ruff format .` — lint and format
