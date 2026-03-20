# Autoresearch: Fix Flaky Tests

## Objective
Reduce flaky test failures in the Gumroad CI suite. Tests run across 15 Fast + 45 Slow shards on Ubicloud runners using Knapsack Pro for distribution. Tests are system/request specs using Capybara + Selenium (Chrome headless).

## Metrics
- **Primary**: failed_jobs (unitless, lower is better)

## How to Run
`autoresearch.sh` — should emit `METRIC name=number` lines for failed_jobs.

## Files in Scope
- `spec/support/product_file_list_helpers.rb` — `wait_for_file_embed_to_finish_uploading` has stale element bug
- `spec/support/checkout_helpers.rb` — checkout flow helpers
- `spec/support/capybara_helpers.rb` — `wait_for_ajax` and other Capybara utilities
- `spec/requests/purchases/product/taxes_spec.rb` — US sales tax test race condition (line ~193)
- `spec/requests/products/edit/rich_text_editor_spec.rb` — audio embed upload test (line ~555)
- `spec/spec_helper.rb` — test configuration, Selenium setup, retry config

## Off Limits
- Application code (app/, lib/, config/) — only test infrastructure
- CI workflow files (.github/workflows/) — no CI config changes
- Other test files not related to identified flaky patterns

## Constraints
- Tests must pass (we're fixing flakiness, not breaking tests)
- No new gem dependencies
- Fixes must be general (not test-specific hacks)
- Each experiment = push to branch → full CI run → observe results
- Use `gh run watch --exit-status` to monitor

## Known Flaky Patterns (from CI analysis)

### Pattern 1: Tax calculation race condition
- `taxes_spec.rb:193` — `set_zip_code_via_js("53703")` → `wait_for_ajax` → `expect(page).to have_text("Total US$105.50")`
- `wait_for_ajax` checks jQuery.active === 0, but React state updates + API calls may not be tracked by jQuery
- Page shows "Total US$100" (no tax) because the tax recalculation hasn't completed
- Fix: Replace `wait_for_ajax` + expect with direct `have_text` assertion (Capybara auto-waits)

### Pattern 2: Stale element in file embed upload
- `rich_text_editor_spec.rb:555` calls `wait_for_file_embed_to_finish_uploading`
- `find_embed` finds element, then `page.scroll_to row` fails with StaleElementReferenceError
- React re-renders the embed component during upload progress updates
- Fix: Re-find element after scroll or wrap in retry

### Pattern 3: Selenium session corruption from Stripe rate limits
- Stripe rate limits kill tests mid-execution, browser session becomes corrupt
- Subsequent tests fail with `NoMethodError: undefined method 'unpack1' for false`
- Then cascade: `NoSuchWindowError`, `undefined method 'slice' for nil`, etc.
- All remaining tests in shard fail (30+ failures from one root cause)
- Fix: Better Selenium session recovery in spec_helper after_each hooks

## What's Been Tried
- #1 discard 3 6d3ddc5 — Remove all wait_for_ajax from taxes_spec.rb + fix stale element in wait_for_file_embed_to_finish_uploading. 3 failed jobs (Slow 17, 26, 36) with 8 test failures: Dropbox uploads (4), Circle integration (2), Canada Tax (1), AI Product Generation (1). The tax fix may have worked (no tax failures) but new flakiness appeared elsewhere — likely pre-existing. Main baseline had 1 failed job.

## What's Been Tried
- No logged experiments yet.

## Plugin Checkpoint
- Last updated: 2026-03-20T01:31:25.527Z
- Runs tracked: 1 current / 1 total
- Baseline: 3
- Best kept: n/a
- Confidence: n/a
- Last logged run: #1 discard 6d3ddc5 — Remove all wait_for_ajax from taxes_spec.rb + fix stale element in wait_for_file_embed_to_finish_uploading. 3 failed jobs (Slow 17, 26, 36) with 8 test failures: Dropbox uploads (4), Circle integration (2), Canada Tax (1), AI Product Generation (1). The tax fix may have worked (no tax failures) but new flakiness appeared elsewhere — likely pre-existing. Main baseline had 1 failed job.

Z
- Runs tracked: 0 current / 0 total
- Baseline: n/a
- Best kept: n/a
- Confidence: n/a
- Pending run awaiting log_experiment: ./autoresearch.sh (3)

Z
- Runs tracked: 0 current / 0 total
- Baseline: n/a
- Best kept: n/a
- Confidence: n/a
