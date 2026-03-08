# SportPass Dynamic Emulator Test Notes
Date: 2026-03-05
Device: Android Emulator `emulator-5554` (`sdk_gphone64_x86_64`, API 36)
App package: `com.sportpass.app`
Build under test: installed from `build/app/outputs/flutter-apk/app-release.apk`

## Scope
- Dynamic stress session with random real-device events (Monkey).
- Guided navigation session with screen recording.
- Crash/ANR/assertion scan via `logcat`.

## Artifacts
- `reports/dynamic-test-2026-03-05/sportpass_dynamic_20260305.mp4`
- `reports/dynamic-test-2026-03-05/sportpass_guided_20260305.mp4`
- `reports/dynamic-test-2026-03-05/logcat.txt`
- `reports/dynamic-test-2026-03-05/logcat_guided.txt`
- `reports/dynamic-test-2026-03-05/monkey.txt`
- `reports/dynamic-test-2026-03-05/before.png`
- `reports/dynamic-test-2026-03-05/after.png`
- `reports/dynamic-test-2026-03-05/guided_after.png`

## Session A: Stress Monkey
- Command profile:
  - package filter: `-p com.sportpass.app`
  - events: `3500`
  - throttle: `40ms`
- Runtime from monkey: `123,506 ms` (~2m03s active event stream)
- Video duration: `03:00.01`
- Result:
  - `Events injected: 3500`
  - `Dropped: keys=0 pointers=0 trackballs=0 flips=0 rotations=0`
  - No app crash, no ANR, no fatal exception for `com.sportpass.app`.

## Session B: Guided navigation recording
- Video duration: `01:50.73`
- App relaunched and interacted with while recording.
- No fatal errors found in guided `logcat`.

## Log findings
### Critical issues
- None detected in this run:
  - No `FATAL EXCEPTION`
  - No `ANR in com.sportpass.app`
  - No `Process com.sportpass.app has died`
  - No Flutter stack overflow/assertion failure in captured logs

### Non-critical warnings (emulator/platform related)
From `logcat.txt`:
- `Unexpected CPU variant for x86: x86_64`
- `avc denied read max_map_count` (SELinux/emulator context)
- `userfaultfd ... unsupported`

These are typical emulator/runtime warnings and did not break app execution.

## UX/Testability note
- Text-driven UI automation via UIAutomator labels was unreliable in this run (many controls not discoverable by expected text labels in hierarchy at runtime state).
- Recommendation: add stable semantics/test tags (`Semantics`, `Key`, `tooltip`, explicit content labels) for important controls (bottom nav, scan button, wallet/topup buttons) to improve deterministic black-box automation.

## Overall status
- Stability under dynamic stress: **PASS**
- Crash/ANR resilience (current run): **PASS**
- Automation discoverability by label: **NEEDS IMPROVEMENT**
