# ADR 001 — Retain Apple Notes through an AppKit Service adapter

Status: accepted for the initial product direction on 2026-08-20.

## Context

Apple Notes is the primary workout-writing workspace. The companion should make program writing faster without replacing Notes or coupling exercise identity, matching, persistence, blocks, or future history to a Notes-specific interface.

The main architecture risk was whether selected Notes text could pass through a lightweight keyboard interaction and return safely enough for repeated use. Exercise 02 tested this risk with a disposable three-choice interaction. It evaluated two bounded native mechanisms rather than building the exercise resolver or production application early.

## Decision

Retain Apple Notes as the initial writing workspace and use an AppKit macOS Service provider as its adapter boundary.

The adapter may receive selected plain text, invoke application workflows, present a lightweight keyboard-operated chooser, return replacement or insertion text to the selected range, and restore Notes focus. Cancellation must leave the note unchanged. Exercise identity, alias knowledge, matching, persistence, blocks, programming tendencies, and future client history remain outside the adapter behind reusable application/domain boundaries.

After acceptance of the selected-text interaction, the same adapter boundary may
also be invoked with an empty Notes insertion point. In that mode it may present
keyboard-operated search over existing confirmed exercise names and insert the
selected exercise's preferred display name at the original cursor. Selecting a
search result expresses intent to insert an exercise; it must not by itself create
an alias, create an exercise, or otherwise write exercise-identity knowledge.

The Exercise 02 AppKit code is disposable evidence, not the production implementation. Production work may reuse the proven Service/pasteboard interaction shape, but it must make fresh decisions about lifecycle, packaging, signing, shortcut configuration, user feedback, and integration with the resolver.

Do not use the tested Automator Quick Action as the initial product mechanism.

## Evidence

- The Automator Quick Action failed the complete interaction contract. Its built-in chooser did not provide usable cancellation, and the corrected AppleScript chooser did not appear reliably from the Notes Services menu.
- The AppKit Service received selected Notes text, automatically focused a three-row chooser, supported Up/Down, Return, and Escape, replaced only the selected range, left text unchanged on cancellation, and returned focus to Notes.
- All five fresh-launch trials passed. Maximum system-controlled latency was 480.0 ms against the 3,000 ms limit.
- All twenty resident replacement trials passed. Median system-controlled latency was 130.5 ms and nearest-rank p95 was 192.9 ms against limits of 1,000 ms and 2,000 ms.
- Both cancellation trials left the selected text unchanged. The 27 accepted rows had zero wrong-note, wrong-range, text-loss, cancellation, or focus-restoration failures.
- The learner tested the real shortcut workflow repeatedly and judged it quick, painless, reliable, and suitable for repeated program writing.
- The complete procedure, failures, raw results, and measurement qualification are preserved in [PLAN-001](../exec-plans/PLAN-001-notes-interaction-spike.md) and the [spike evidence](../../spikes/notes-interaction/EVIDENCE.md).

## Alternatives considered

### Automator Quick Action

Rejected for the initial product mechanism. It was smaller than an AppKit provider and had a documented selected-text replacement route, but the real Notes experiment could not satisfy reliable chooser presentation and cancellation together.

### Replace Notes with a companion editor

Rejected for the initial product. It conflicts with the product principle that Notes remains the workout-writing workspace and was unnecessary because the AppKit adapter passed the interaction gate.

### Investigate another integration mechanism

Not pursued. The spike deliberately allowed no more than two native mechanisms, and the second passed every approved gate. A third mechanism would have expanded the investigation without resolving a remaining acceptance failure.

## Consequences

- The product needs a macOS/AppKit integration surface even if the domain and resolver are implemented independently of AppKit.
- Notes-specific pasteboard, focus, selection, and chooser behavior belongs in an adapter layer and must not leak into exercise identity or matching logic.
- Production verification must continue to include real Notes behavior; unit tests of domain logic cannot prove focus, selected-range integrity, cancellation, or interaction friction.
- Packaging, signing, distribution, lifecycle, and shortcut configuration become explicit future implementation work.
- The failed Automator artifact and disposable AppKit spike remain evidence, but no product code should depend on either artifact.
- Exercise 03 records this decision only. Resolver, persistence, aliases, fuzzy matching, blocks, history, and load recommendations remain out of scope until their curriculum exercises.

## Known limitations

- Testing covered one machine running macOS 26.6 and Notes 4.13; it did not establish compatibility across macOS versions or hardware.
- The chooser contained only three hard-coded exercises. The spike did not test search, resolution, aliases, persistence, blocks, or realistic library size.
- The local provider was ad-hoc signed and manually registered. Distribution, updates, sandboxing, notarization, and permission onboarding were not tested.
- Control–Option–Command–G was awkward in repeated human use and is not an accepted production shortcut.
- Replacing text with identical text gives no visible confirmation, which could make successful completion ambiguous.
- Automated latency used a documented one-frame settled proxy after service return, followed by independent UI assertions of exact text and focus; it was not direct video-frame measurement.
- The sample demonstrated the bounded interaction, not long-term reliability during full programming sessions.

## Revisit triggers

Reopen this decision when any of the following is observed:

- A wrong-note or wrong-range replacement, text loss, changed text after cancellation, or failure to restore Notes focus occurs in production-like testing.
- Five fresh-launch trials no longer all complete within 3,000 ms, or twenty resident trials no longer all succeed with median system latency at most 1,000 ms and nearest-rank p95 at most 2,000 ms.
- The workflow requires repeated permission prompts, a mouse, or manual application switching.
- A Notes or macOS update breaks selected-text transfer, Service invocation, pasteboard replacement, cancellation, or focus restoration.
- No comfortable, conflict-free shortcut can be configured, or ambiguous identical-text completion causes repeated user errors.
- Signing, sandboxing, notarization, or distribution constraints make the Service provider impractical for the intended users.
- Real resolver or block workflows require context or interaction that cannot remain lightweight through selected text in Notes.
- Repeated program-writing use changes the learner's judgment from “quick and painless” to an interaction they would avoid.

If one of these triggers cannot be corrected inside the adapter without weakening the product principles or acceptance gates, abandon the Notes companion approach and evaluate a different writing interface or integration boundary.
