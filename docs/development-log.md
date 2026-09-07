# Development log

## September 7, 2026 — Repository setup

- Vihaan chose iOS as the proposed platform because all three participants have MacBooks and iPhones.
- Repository already contained an initial README commit when cloned.
- Codex checked the installed tools: Xcode 26.6 (17F113).
- The default Git command failed because the Xcode license has not yet been accepted. The separate Command Line Tools Git executable worked (2.50.1).
- GitHub CLI is installed but not logged in. Public repository cloning succeeded.
- Codex prepared Swift/Xcode ignore rules, documentation, and task/PR templates.
- Verified ignore rules against build artifacts, user-specific Xcode files, and local secrets; Git whitespace checks passed.
- Setup commit `641c752` was successfully pushed to GitHub using existing Git credentials, even though GitHub CLI is not signed in.
- Pending: open Xcode and complete first-run setup; invite partners once usernames arrive; select and run an existing sample.
- No app/device/backend testing has happened yet.

## Entry template — copy for each session

- Date and participant:
- Goal:
- Actions and references used:
- Result:
- Problem, error, and attempted fixes:
- Testing performed and device:
- What I learned (write in your own words):
- Evidence: screenshot captions, commit/PR/issue links:
- AI assistance used and how I checked it:
- Next step:

## September 7, 2026 — Xcode setup and original sample import

- User completed Xcode setup; first-launch check now passes and iOS 26.5 SDK is available.
- Codex downloaded Apple's completed Passing Data with Bindings sample (Scrumdinger), preserving its source and licenses under `ios/Scrumdinger`.
- This is an existing interactive sample, not student-authored app code. Root README remains minimal as requested.
- Attempted unsigned iOS build: package cache writes initially failed. Granted cache access and redirected module cache into the workspace. Package resolution then failed with `sandbox-exec: sandbox_apply: Operation not permitted`.
- Sandbox access to simulator/device services failed, and Xcode UI inspection timed out. No successful build or physical-device run has been verified.
- Added `docs/ios-setup.md` with signing/run instructions and a before/after input demonstration to record.
- Pending: user selects Apple signing team and iPhone, runs the sample in Xcode, and captures actual device evidence.
