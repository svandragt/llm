---
name: smoke-test
description: Build a Showboat smoke-test document proving a new feature works end-to-end by seeding the database, running the dev server, exercising the endpoint, and verifying reproducibility.
---

Build a Showboat smoke-test document proving a new feature works:

1. `uvx showboat init demo.md "<feature name>"`
2. Seed the database:
   ```
   uvx showboat exec demo.md bash "uv run python manage.py migrate --no-input"
   uvx showboat exec demo.md bash "uv run python manage.py init_domains"
   ```
3. Start the dev server:
   ```
   uvx showboat exec demo.md bash "uv run python manage.py runserver 8765 --noreload &"
   uvx showboat exec demo.md bash "sleep 2"
   ```
4. Exercise the endpoint or management command and capture output with `uvx showboat exec demo.md bash "..."`
5. Kill the dev server: `uvx showboat exec demo.md bash "kill %1"`
6. Run `uvx showboat verify demo.md` — re-run all blocks and diff outputs
