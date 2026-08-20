# Apple Notes interaction spike evidence

This file records the disposable macOS 26.6 experiment. Use only the scratch note named `Gym Assistant Spike — disposable`; never select or record client content.

## Artifact

The preserved first-mechanism artifact is `spikes/notes-interaction/Gym Assistant Exercise Chooser.workflow`. Automator 2.10 created and installed its active copy at `~/Library/Services/Gym Assistant Exercise Chooser.workflow`.

The Quick Action receives plain text only in Apple Notes and requests that its output replace the selected text. Its final preserved version uses a `Run AppleScript` action to present Front Squat, Single-Leg Romanian Deadlift, and Aussie Pull-up with Replace and Cancel controls. It remains installed as failed-mechanism evidence, not as the active candidate.

The approved fallback source is `spikes/notes-interaction/appkit-service/`. Its build script produces an ignored, ad-hoc-signed local app at `/private/tmp/gym-assistant-notes-spike/Gym Assistant Service.app`. The app advertises `Gym Assistant Exercise Chooser (AppKit)` only in Notes and exchanges selected text through the Service pasteboard.

Artifact hashes at creation:

    document.wflow  114a18743b9efd69f9a69e9932853dc2c50f05694b3b4e2cbb042d115adcbf5f
    Info.plist      ff6a53fc6f8b219a49c6c52719001425ff21f63b6211faef8a33cce7f24103ef
    main.swift      3c85f40b8b342515184a04cd05b7230f3c43bb3b0bf59ec5ae66931540cf2ec5
    AppKit plist    86d10707e5bbe06dcb6d96303dfe08bfbdfc116570467b0ef657d076ee623fbb
    trial driver    5db71c5552286a66ba4dab605566d78e567bc65f54d4c8787ee56f9465814449
    trial results   24d07b23d40903e86c33efca4c1ad44300039cc0531f06efeee5ca35419d7fa9

## Verified environment

    macOS: 26.6 (25G72)
    Xcode: 26.6 (17F113)
    Developer directory: /Applications/Xcode.app/Contents/Developer
    Swift: Apple Swift 6.3.3
    macOS SDK: 26.5
    Automator: 2.10
    Notes: 4.13

The Automator mechanism does not require Xcode. The fallback was compiled with the verified Swift/AppKit toolchain; its property list passed `plutil`, and its temporary bundle passed strict code-signature verification.

## Mechanism attempts

1. The initial Automator `Get Specified Text` plus `Choose from List` workflow displayed all three newline-separated names as one item. The chooser also exposed only OK, with no Cancel control; Escape and Command-period did not dismiss it in the Automator validation run.
2. Replacing the text source with three distinct strings fixed the list rows but did not add cancellation.
3. A `Run AppleScript` chooser supplied three choices plus Replace and Cancel inside Automator, but repeated Notes Services-menu invocations did not present its dialog. Selected Notes text stayed unchanged.
4. The preserved Quick Action therefore failed the complete interaction contract, and the approved AppKit fallback was built. Its first real Notes invocation displayed all three choices plus Cancel. Escape left `SL RDL` unchanged and returned keyboard focus to the scratch note. The first alert implementation did not provide arrow-key selection, so it was replaced by a focused `NSTableView` with Up/Down, Return, and Escape behavior.
5. The rebuilt table implementation passed both smoke paths in the disposable note. Down moved the highlight from Front Squat to Single-Leg Romanian Deadlift; Return replaced only `SL RDL` with `Single-Leg Romanian Deadlift` and returned focus to the Notes body. In a separate invocation, Escape left `SL RDL` unchanged and returned focus to the Notes body.

## Setup and invocation

1. Run `spikes/notes-interaction/appkit-service/build.sh` from the repository root.
2. Register `/private/tmp/gym-assistant-notes-spike/Gym Assistant Service.app` with Launch Services and launch it once.
3. Confirm in System Settings > Keyboard > Keyboard Shortcuts > Services > Text that `Gym Assistant Exercise Chooser (AppKit)` is enabled and assigned Control-Option-Command-G.
4. In Notes, use only the scratch note `Gym Assistant Spike — disposable`, which contains no private content.
5. Restore the trial's exact input, select only that input, and invoke Control-Option-Command-G.
6. For a replacement trial, wait for the list to receive keyboard focus, highlight the required exercise with the arrow keys, and press Return.
7. For a cancellation trial, press Escape without choosing an exercise.
8. Confirm the exact note text, target range, and returned focus before recording the result.

The shortcut assignment was verified in the Services preferences as `@~^g` (`Command` + `Option` + `Control` + `G`).

## Reset and cleanup

For a cold-start reset, run `spikes/notes-interaction/appkit-service/cold-reset.sh`. It sends `TERM` only to the exact disposable process name `GymAssistantService`, confirms that process is no longer resident, and leaves Notes open. Do not launch the temporary app manually: the configured Services shortcut must launch it. Record any failure to launch as a genuine cold-trial failure.

After the architecture gate, cleanup may move `~/Library/Services/Gym Assistant Exercise Chooser.workflow` to Trash, unregister the temporary AppKit bundle, terminate its background process, and remove its keyboard shortcut. Keep the repository artifacts and this evidence unless the gate explicitly decides otherwise.

## Measurement method

The learner declined twenty manual recordings, so the final batch used `appkit-service/automated-trials.mjs` through the already-authorized desktop-control process. The driver prepared and selected only the disposable note text, sent the configured Notes shortcut and chooser keys, and asserted the eventual exact scratch-note value and focused Notes body. The provider recorded wall-clock timestamps for `chooser_ready`, `confirm` or `cancel`, and `visible_proxy`; the driver recorded shortcut invocation on the same clock.

`visible_proxy` is emitted 17 ms—one 60 Hz display frame—after the service returns its output. It is not direct frame analysis. Exact replacement or unchanged cancellation and returned Notes focus were independently observed afterward through the UI. Because the observed warm values are more than 800 ms below the approved median limit and more than 1,800 ms below the p95 limit, this proxy limitation does not approach either boundary, but it remains a limitation of the evidence.

The four timestamps are:

- shortcut invocation
- chooser ready for keyboard input
- learner confirmation
- replacement visible with focus returned to Notes

Compute system-controlled latency as `(chooser ready - shortcut invocation) + (replacement visible - learner confirmation)`. Record the full shortcut-to-visible duration as supplementary evidence. Human decision time is excluded from acceptance latency.

Use `pass`, `fail`, or `invalid`. An unrelated notification or operator mistake may make a trial invalid when its reason is preserved. Invocation, focus, replacement, cancellation, latency, wrong-note, wrong-range, or text-integrity failures are genuine failures, not invalid trials.

`AUTOMATED_TRIALS.jsonl` contains the 27 accepted batch rows. `AUTOMATION_CALIBRATION.jsonl` preserves the pre-batch automation failures: the standalone helper lacked Accessibility access, a stale pre-instrumentation process produced no events, and an app-targeted Command-Q did not prove a cold reset. None was relabeled as a product pass or included in the accepted distribution. The final cold build instead logged a fresh application-launch event for every cold row and self-terminated only after its settled event.

## Smoke checks

| Check | Input | Action | Expected output | Result | Notes |
| --- | --- | --- | --- | --- | --- |
| Replacement | `SL RDL` | Choose Single-Leg Romanian Deadlift and press Return | `Single-Leg Romanian Deadlift` in the same range; Notes focused | pass | Rebuilt focused-table implementation; Down changed the highlighted row, Return performed exact same-range replacement, and the Notes body regained focus. |
| Cancellation | `SL RDL` | Press Escape | `SL RDL` unchanged; Notes focused | pass | Verified against both the alert prototype and the rebuilt focused-table implementation; no note mutation and the Notes body regained focus. |

## Cold replacement trials

Every trial uses input `SL RDL` and chooses Single-Leg Romanian Deadlift. Every successful trial must have system-controlled latency no greater than 3,000 ms.

| Trial | Shortcut→ready ms | Decision ms | Confirm→visible ms | System ms | Full ms | Exact output | Same note/range | Focus | Permissions/anomalies | Result |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- | --- |
| C1 | 323.1 | 318.4 | 32.1 | 355.3 | 673.6 | yes | yes | yes | Fresh provider launch observed | pass |
| C2 | 363.3 | 265.7 | 34.9 | 398.1 | 663.8 | yes | yes | yes | Fresh provider launch observed | pass |
| C3 | 344.2 | 274.0 | 30.2 | 374.4 | 648.4 | yes | yes | yes | Fresh provider launch observed | pass |
| C4 | 447.3 | 284.0 | 32.8 | 480.0 | 764.0 | yes | yes | yes | Fresh provider launch observed | pass |
| C5 | 377.0 | 277.9 | 32.3 | 409.3 | 687.2 | yes | yes | yes | Fresh provider launch observed | pass |

## Warm replacement trials

Run five trials for each input and required choice: `Front Squat` → Front Squat; `SL RDL` → Single-Leg Romanian Deadlift; `A1 Front Squat — 3 × 5` → Aussie Pull-up; and the approved three-line block → Front Squat. All 20 must succeed; median system latency must be at most 1,000 ms and nearest-rank p95 at most 2,000 ms.

| Trial | Input category | Shortcut→ready ms | Decision ms | Confirm→visible ms | System ms | Full ms | Exact output | Same note/range | Focus | Permissions/anomalies | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- | --- |
| W01 | Front Squat | 79.5 | 576.4 | 28.0 | 107.5 | 683.9 | yes | yes | yes | none | pass |
| W02 | Front Squat | 95.8 | 585.0 | 32.0 | 127.8 | 712.8 | yes | yes | yes | none | pass |
| W03 | Front Squat | 93.8 | 573.8 | 27.8 | 121.7 | 695.5 | yes | yes | yes | none | pass |
| W04 | Front Squat | 120.2 | 550.0 | 28.3 | 148.5 | 698.5 | yes | yes | yes | none | pass |
| W05 | Front Squat | 155.0 | 609.7 | 37.9 | 192.9 | 802.6 | yes | yes | yes | none | pass |
| W06 | SL RDL | 80.9 | 531.3 | 30.8 | 111.7 | 643.1 | yes | yes | yes | none | pass |
| W07 | SL RDL | 153.5 | 606.3 | 28.9 | 182.4 | 788.7 | yes | yes | yes | none | pass |
| W08 | SL RDL | 115.6 | 644.4 | 34.4 | 150.0 | 794.4 | yes | yes | yes | none | pass |
| W09 | SL RDL | 117.4 | 598.2 | 28.5 | 145.9 | 744.1 | yes | yes | yes | none | pass |
| W10 | SL RDL | 81.2 | 597.1 | 35.2 | 116.5 | 713.6 | yes | yes | yes | none | pass |
| W11 | A1 line | 65.3 | 561.9 | 26.4 | 91.7 | 653.6 | yes | yes | yes | none | pass |
| W12 | A1 line | 118.0 | 667.9 | 28.6 | 146.6 | 814.5 | yes | yes | yes | none | pass |
| W13 | A1 line | 164.3 | 584.3 | 29.3 | 193.5 | 777.9 | yes | yes | yes | none | pass |
| W14 | A1 line | 138.2 | 614.0 | 28.7 | 166.9 | 780.9 | yes | yes | yes | none | pass |
| W15 | A1 line | 103.5 | 719.7 | 29.8 | 133.2 | 852.9 | yes | yes | yes | none | pass |
| W16 | Three-line block | 96.3 | 576.9 | 27.0 | 123.3 | 700.1 | yes | yes | yes | none | pass |
| W17 | Three-line block | 74.0 | 602.4 | 29.8 | 103.8 | 706.1 | yes | yes | yes | none | pass |
| W18 | Three-line block | 74.0 | 576.9 | 27.6 | 101.6 | 678.5 | yes | yes | yes | none | pass |
| W19 | Three-line block | 80.5 | 553.5 | 27.2 | 107.7 | 661.1 | yes | yes | yes | none | pass |
| W20 | Three-line block | 110.6 | 578.1 | 27.4 | 138.0 | 716.0 | yes | yes | yes | none | pass |

## Warm cancellation checks

| Trial | Input | Shortcut→ready ms | Decision ms | Confirm→unchanged ms | System ms | Full ms | Byte-for-byte unchanged | Focus | Permissions/anomalies | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| X1 | `SL RDL` | 88.3 | 569.0 | 28.7 | 117.0 | 686.0 | yes | yes | none | pass |
| X2 | `SL RDL` | 107.9 | 576.7 | 30.4 | 138.2 | 715.0 | yes | yes | none | pass |

## Summary

    Mechanism: AppKit Service provider fallback (Automator Quick Action failed)
    Cold trials: 5 / 5 successful
    Cold maximum system latency: 480.0 ms
    Warm trials: 20 / 20 successful
    Warm system latency median / p95: 130.5 ms / 192.9 ms
    Cancel checks: 2 / 2 unchanged
    Integrity and focus failures: 0
    Recommendation: pass; retain the Notes-adapter hypothesis for Exercise 03

## Artifacts

Record only scratch-note screenshots or recordings. Do not commit client text, credentials, signing identities, or unrelated desktop content.
