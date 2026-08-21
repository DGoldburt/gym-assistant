# Agentic-AI Learning Evidence Ledger

This append-only ledger records approved portfolio evidence and first-person reflections. `SKILLS.md` stores current confidence; `AGENTIC_AI_MAP.md` stores the broader ideas and their connections.

## Recording rules

1. At a learning checkpoint, the user answers the teach-back prompt and reviews the concrete artifacts.
2. After a passed checkpoint, Codex drafts a concise first-person reflection in chat.
3. Write an entry only after the user explicitly confirms the reflection and checkpoint.
4. An entry may update confidence in `SKILLS.md`; Demonstrated requires reflection plus observable evidence.
5. Keep entries short, concrete, and safe to reuse as portfolio examples. Do not store secrets or private client data.
6. Do not rewrite an old entry to make later understanding look stronger; add a follow-up instead.

Entries created before 2026-08-19 retain their original `AIC-*` labels as historical evidence. Current skill confidence is recorded in `SKILLS.md`; the broader ideas are organized in `AGENTIC_AI_MAP.md`.

## Entry template

### YYYY-MM-DD — Exercise or lab — Checkpoint

**Skills strengthened**

- `readable-skill-id` — resulting confidence, if changed

**What I did**

One or two sentences on what I inspected, decided, implemented, reviewed, or tested.

**Evidence**

- command and relevant result
- file or artifact path
- commit hash or pull-request link
- screenshot, log, measurement, or reproducible steps

**My reflection**

> I learned...

**Next time / revisit**

None, or a specific point to revisit.

For an optional map check-in, record only the source (title and link, if available), the connection or question it prompted, and any project test or next action. A map check-in does not advance course progress by itself.

## Approved entries

### 2026-08-19 — Optional map check-in — Bootstrap evolution and learning design

**Skills strengthened**

- `review` — Used with guidance

**What I did**

I strengthened the tutorial's learning track, experimented with separate Codex review context, model choice, and reasoning effort, and redesigned the durable learning records into a skills record, learning log, and agentic-AI map.

**Evidence**

- A separate Codex chat in the same project reviewed the repository and its findings were addressed; the shared project context means this was a second perspective rather than fully isolated verification.
- `docs/curriculum/SKILLS.md`, `docs/curriculum/LEARNING_LOG.md`, and `docs/curriculum/AGENTIC_AI_MAP.md` record the resulting separation of skills, portfolio evidence, and broader mental model.
- `docs/curriculum/AGENTIC_AI_MAP.md` contains a future experiment for an external source of truth shared across chats.

**My reflection**

> While updating the Gym Assistant tutorial bootstrap, I realized that the learning experience was initially too weighted toward product development. I asked Codex to strengthen the learning track, which led to `CONCEPTS.md` and `LEARNING_LOG.md`. Those additions clarified the intent, but the catalog’s unique IDs and the detailed ledger specification felt more like an assessment system than a tool I would naturally return to.
>
> That reaction became useful evidence. I began experimenting with different Codex surfaces and settings: I started a separate chat in the project to review the repository and fix findings; I switched from Sol to Terra; and I tried low, medium, and high reasoning effort. The separate review chat gave me a real second perspective, although it was not fully independent because it retained the project’s shared context. I want to learn how much independence comes from a separate chat, a deliberately isolated review brief, a worktree, a different model, or—in higher-risk cases—a different provider.
>
> I also became more comfortable not defaulting to the largest model and highest effort. So far, Terra Medium has felt slightly more than sufficient and is becoming my provisional default. I am not treating that as a permanent rule: I want to capture the configuration deliberately in the repository and compare it against real tasks, rather than choosing settings from anxiety or prestige.
>
> The resulting structure now separates three things that had been entangled. `SKILLS.md` is a human-readable record of practical abilities I am practicing. `LEARNING_LOG.md` is evidence and reflection that can support future retrospectives or portfolio examples. `AGENTIC_AI_MAP.md` is the broader mental model I want to keep developing beyond Gym Assistant.
>
> The map matters to me because I do not want the excitement of early learning to disappear into separate chats. I follow Simon Willison’s newsletter, r/codex, Codex release information, and other developments; I want to connect new ideas to what I have already tried, notice gaps such as Codex CLI or Claude Code CLI, and ask what I could have done differently if I had known a concept earlier.
>
> I am looking forward to proving two things rather than merely documenting them. First, I liked the interview format of Plan mode and want to try the next level: durable plans in `PLANS.md` and durable decision records. Second, I spent roughly a full day making the tutorial’s learning instructions and records more durable. The payoff is still unproven: I need to see whether this structure genuinely improves how I learn, supervise Codex, and build the Notes companion for my strength-coaching work.

**Next time / revisit**

Test review independence by separating the reviewer from the implementer's rationale and comparing findings. Decide whether to establish Terra Medium in repository configuration only after a representative-task comparison. Test the external mental-map source-of-truth workflow, durable plans, and decision records before treating their payoff as proven.

### 2026-08-18 — Exercise 01 — Task A: Repository, Git, and product orientation

**Concepts and resulting status**

- `AIC-02` — Demonstrated
- `AIC-03` — Introduced
- `AIC-04` — Introduced
- `AIC-05` — Practiced
- `AIC-06` — Demonstrated
- `AIC-07` — Introduced
- `AIC-08` — Introduced

**Activity**

Inspected the bootstrap as an ordinary local folder; distinguished a local folder, Git repository, and future GitHub remote; identified the Apple Notes interaction as the highest-risk product assumption; and selected medium reasoning with a read-only planning boundary for the bounded spike-plan task.

**Evidence**

- Repository inspection confirmed that `.git` is absent, Git is available, no Git author is configured, GitHub CLI is absent, and `.gitignore` excludes `.DS_Store`.
- Toolchain inspection confirmed that Command Line Tools are active and full Xcode is not selected; Exercise 02 owns the tooling/architecture decision.
- The approved teach-back distinguishes `git init`, `git clone`, `git switch`/`git checkout`, commits, branches, pull requests, merge outcomes, and explicit branch deletion.
- `docs/curriculum/01-repository-and-specification.md` defines the next Git/GitHub steps and their stopping conditions.

**Approved first-person reflection**

> I understand that `git init` adds Git tracking to an existing local folder, whereas `git clone` creates a local copy of an existing remote repository and its history. A commit is an immutable point in the history, while a branch is a movable name pointing to a commit. Switching or checking out changes which branch or revision my working tree reflects; it does not clone, merge, push, or delete anything.
>
> A pull request compares a pushed source branch with a base branch so its changes can be reviewed before merging. The merge may create a merge commit, squash the changes into one commit, or rebase the commits, and the source branch remains until it is explicitly deleted.
>
> The product’s highest-risk assumption is whether invoking a companion service from Apple Notes can be fast, reliable, and frictionless enough for repeated use. For the bounded initial spike, medium reasoning in read-only Plan mode is proportionate. I would escalate reasoning only if the investigation leaves important architectural uncertainty unresolved, and I would require explicit approval before local Git setup or external GitHub writes.

**Remaining gap or revisit trigger**

Apply the model by creating the repository, commit, branch, remote, and pull request in Tasks B–D. Revisit if the user cannot distinguish a local branch, its remote counterpart, and a pull request after using them.

### 2026-08-19 — Exercise 01 — Task B: First commit and remote

**Skills strengthened**

- `collaborate` — Used with guidance

**What I did**

Created a clean, versioned tutorial root while preserving learner-specific Task A state on a local exercise branch; authenticated with GitHub over SSH; and published only the approved `main` branch and starter tag to a private remote.

**Evidence**

- Local and remote `main` resolve to root commit `4161f6fc564d52cc15eadc32842e9b899bac14e1`, `docs: establish reusable tutorial starter`.
- Remote tag `tutorial-start-v1` resolves to the same clean commit.
- The clean starter contains 31 tracked files, excludes `.DS_Store`, and contains no approved learning entries or learner-specific markers found by the verification scan.
- `tutorial/exercise-01` contains the restored learner-state diff locally; the temporary backup branch was deleted and obsolete commit `68ecdb2` was pruned without being pushed.
- GitHub SSH authentication succeeded as `DGoldburt`; `origin` uses `git@github.com:DGoldburt/gym-assistant.git`.

**My reflection**

> I understand that my local repository can contain branches, configuration, ignored files, and uncommitted work that GitHub has never received. GitHub currently contains only the clean root commit on `main` and the fixed `tutorial-start-v1` tag. My restored Task A progress and reflections remain uncommitted on the local `tutorial/exercise-01` branch.
>
> We created a temporary post–Task-A commit, used a local backup branch to preserve it, applied the cleanup, and amended the root so the temporary history was never pushed. After publishing the clean root, we restored my learner-state changes on the exercise branch, deleted the backup reference, and pruned the obsolete commit.
>
> Continuing on a branch keeps my personal tutorial work separate and reviewable while the starter tag remains a stable clean entry point. I may later push the exercise branch to the private repository without changing the tagged starter.

**Next time / revisit**

Revisit the distinction between a local branch, its remote counterpart, and a pull request while preparing and reviewing the first pull request in Tasks D–E.

### 2026-08-19 — Exercise 01 — Task C: Initial architecture-spike plan

**Skills strengthened**

- `plan` — Demonstrated
- `frame-work` — Used with guidance
- `set-boundaries` — Used with guidance

**What I did**

Compared a regular-prompt plan, a Plan-mode plan, and an isolated regular-prompt control without `PLANS.md`. I selected a deliberate hybrid that preserves cold/warm performance gates, requires a disposable keyboard interaction, separates system latency from human decision time, and stops before product implementation.

**Evidence**

| Candidate | Strongest result | Important weakness |
| --- | --- | --- |
| Regular prompt + `PLANS.md` | Independently supplied concrete cold/warm thresholds and strong execution/recovery structure | Omitted the lightweight interaction, so it did not test an important MVP feasibility risk |
| Plan mode + `PLANS.md` | Surfaced the missing performance decision and required a lightweight keyboard interaction | Needed learner input before completing; its proposed timing included human reaction time, which would make measurements noisy |
| Regular prompt without `PLANS.md` | Still produced a plausible bounded investigation | Omitted the living-plan machinery, chose weaker reliability criteria, gave cold starts a less precise gate, and omitted the interaction |

- Plan mode exposed a consequential missing assumption.
- Regular prompting made useful independent performance decisions.
- `PLANS.md` improved durability and reproducibility but did not guarantee sound judgment.
- Regular-prompt task: `01a01cec-e1d0-77c0-82e0-c514d8b5f8b5`.
- Plan-mode task: `01a01cec-e3c3-7b73-82f7-09a931ba1f4b`.
- Isolated no-`PLANS.md` Codex CLI session: `01a01d1b-b65b-7003-a1c7-30f2570aa772`; it ran without `.git` or `PLANS.md`, after which the original `PLANS.md` checksum was verified as restored.
- Approved thresholds: 5/5 cold starts at no more than 3 seconds each; 20/20 warm successes with median no more than 1 second and p95 no more than 2 seconds; zero text-integrity, wrong-note, wrong-range, or cancellation failures.

**My reflection**

> I am willing to write disposable spike code because cheaply testing the riskiest interaction can prevent much more costly development around an infeasible workflow. This spike asks whether selected Apple Notes text can pass through a macOS service, support a lightweight keyboard interaction, return transformed text and focus safely to Notes, and remain fast enough in cold and repeated use. Performance measurements, screenshots, logs, exact replacement checks, cancellation checks, and focus behavior will provide the evidence, although I should remain alert to whether the verification burden becomes disproportionate.
>
> The planning comparison did not establish that Plan mode or regular prompting is categorically better. Regular prompting independently proposed useful cold/warm thresholds, while Plan mode surfaced the consequential question of whether the prototype must include an interaction. `PLANS.md` improved the plans’ durable execution structure, but no convention guarantees that a plan is testing the right thing. I should choose planning tools based on uncertainty and risk, critically inspect their assumptions, and consider whether a more capable interviewing workflow would improve future planning.

**Next time / revisit**

When executing the spike, check whether the planned evidence is proportionate and measure system-controlled latency separately from human decision time. Revisit whether a more capable interviewing workflow improves consequential plans after defining a bounded comparison.

### 2026-08-19 — Exercise 01 — Task D: First pull request

**Skills strengthened**

- `collaborate` — Demonstrated

**What I did**

Opened and inspected the first learner-progress pull request, using `learner/main` as the personal integration base while keeping reusable `main` free of learner state.

**Evidence**

- Pull request: <https://github.com/DGoldburt/gym-assistant/pull/1>
- GitHub PR ref `refs/pull/1/head` resolved to exercise commit `bd900ec`; its synthetic merge commit `542a969` had base parent `2b4dbe1` (`learner/main`) and source parent `bd900ec` (`tutorial/exercise-01`).
- The inspected comparison contained exactly four learner-state files plus `docs/exec-plans/PLAN-001-notes-interaction-spike.md`, with no application code or later-exercise implementation.
- The learner inspected the commit history and available GitHub checks before approving this reflection.

**My reflection**

> I inspected PR #1 and confirmed that `learner/main` is the base, `tutorial/exercise-01` is the source, and the comparison contains only my learning records and approved `PLAN-001`. I reviewed the commit history, five-file diff, and available checks, and confirmed that no product code or later-exercise implementation is included.
>
> The commits already existed on the exercise branch before the pull request was opened. The pull request makes their combined changes, history, discussion, target branch, and automated checks explicit before they are merged into my persistent learner branch. A direct push to `learner/main` would not provide the same deliberate review boundary.
>
> My personal progress remains outside reusable `main` because `main` is the clean tutorial that a new learner can start from. `learner/main` accumulates my approved progress, while reusable curriculum improvements are prepared and reviewed separately on `main`.

**Next time / revisit**

Verify the merged remote result and synchronize local `learner/main` before beginning Exercise 02; recheck that reusable `main` remains learner-free.

### 2026-08-19 — Exercise 01 — Task E: Merged and synchronized

**Skills strengthened**

- `collaborate` — Demonstrated
- `set-boundaries` — Demonstrated

**What I did**

Merged pull request #1 into the personal integration branch, fast-forwarded local `learner/main` to the reviewed GitHub result, and separately verified that reusable `main` remained learner-free.

**Evidence**

- GitHub merge commit `feb2e0c400f5229c5b00e067d4c8c69c5c12dd3f` has parents `2b4dbe1` (`learner/main` before merge) and `bff0558` (the final reviewed exercise head).
- Local and remote `learner/main` both resolved to `feb2e0c` after `git pull --ff-only`; the working tree was clean.
- Local and remote reusable `main` both remained at `2b4dbe1`.
- The `main...learner/main` comparison contained exactly four learner-state files plus `docs/exec-plans/PLAN-001-notes-interaction-spike.md`; reusable `main` contained only the shared `docs/exec-plans/README.md` in that folder.

**My reflection**

> I synchronized local `learner/main` with the pull request’s merged GitHub result so Exercise 02 will begin from the exact reviewed state with a clean working tree. If Exercise 01 changed the repository but those changes were not pulled into my integration branch, the next exercise would operate with incomplete or incorrect durable context.
>
> I also verified reusable `main` separately because synchronization alone does not prove that personal progress stayed isolated. `learner/main` now contains my approved plan, evidence, reflections, skills, and progress, while `main` remains a learner-free tutorial starting point.
>
> For Exercise 02, I can create `tutorial/exercise-02` from the synchronized `learner/main`. This preserves the same workflow: perform bounded exercise work on a reviewable branch, merge personal progress into `learner/main`, and keep reusable curriculum updates separate on `main`.

**Next time / revisit**

Create `tutorial/exercise-02` from synchronized `learner/main` before starting the read-only mechanism and toolchain investigation.

### 2026-08-19 — Exercise 02 — Task A: Mechanism and tooling gate

**Skills strengthened**

- `orient` — Demonstrated
- `frame-work` — Used with guidance
- `set-boundaries` — Demonstrated

**What I did**

Inspected the active macOS and Xcode environment, compared the two mechanisms bounded by `PLAN-001`, and approved an Automator Quick Action as the smallest mechanism worth testing before any implementation.

**Evidence**

- Created `tutorial/exercise-02` from clean, synchronized `learner/main`; no Xcode project, Swift package, or Swift source existed.
- Verified macOS 26.6 (`25G72`), Xcode 26.6 (`17F113`), Swift 6.3.3, the selected full-Xcode developer directory, and the macOS SDK.
- Verified that Automator 2.10, Shortcuts 7.0, and Notes 4.13 are installed.
- Apple's Automator documentation explicitly supports Text or Rich Text input with “Output replaces selected text”; current macOS documentation supports Services-menu keyboard shortcuts.
- The installed `Choose from List` Automator action accepts strings, displays a choice dialog, and returns the selected string.
- The fallback AppKit Service-provider mechanism has a documented pasteboard round trip, but requires a macOS app target and has more activation, signing, and distribution surface.
- Approved scope: test an Automator Quick Action on macOS 26.6 with the three hard-coded exercise choices, keyboard invocation, replacement on choice, and unchanged text on cancellation. Fall back to one minimal AppKit Service provider only if the Quick Action fails.
- Preserved as experiment uncertainties: Apple Notes selection transfer, chooser focus, Return/Escape behavior, exact cancellation, focus restoration, permissions, and cold/warm latency.

**My reflection**

> I approved an Automator Quick Action as the smallest mechanism worth testing because Apple’s documented selected-text replacement, macOS Services keyboard invocation, and the installed Choose from List action provide a credible route to the required workflow. The actual spike still needs to prove Notes-specific selection transfer, replacement, cancellation, focus restoration, permissions, and latency.
>
> Xcode was deferred because tool installation should follow from an architecture requirement, not be treated as generic Codex setup. The investigation showed that the selected Automator mechanism does not require Xcode; the already-installed Xcode environment is relevant only if we must fall back to an AppKit Service provider.

**Next time / revisit**

Record the approved mechanism and verified prerequisites in `PLAN-001`, while preserving the Notes-specific behavior as unresolved until the actual experiment.

### 2026-08-19 — Exercise 02 — Task B: Implementation readiness

**Skills strengthened**

- `verify` — Used with guidance
- `set-boundaries` — Demonstrated

**What I did**

Reverified the already-installed developer environment, reconciled `PLAN-001` with the approved three-choice Automator mechanism, and approved the environment for implementation without adding unrelated tools.

**Evidence**

- Verified macOS 26.6 (`25G72`), Xcode 26.6 (`17F113`), `/Applications/Xcode.app/Contents/Developer`, Apple Swift 6.3.3, the default Swift compiler, and the macOS 26.5 SDK.
- Verified Automator 2.10, Shortcuts 7.0, and Notes 4.13.
- Confirmed that the selected Automator Quick Action requires no Xcode capability; the installed macOS app toolchain is ready only if the approved AppKit Service-provider fallback becomes necessary.
- Updated `PLAN-001` with the approved mechanism, three-choice behavioral contract, verified prerequisites, fallback boundary, trial expectations, and revision history.
- `git diff --check` passed, and no workflow, Xcode project, dependency, or product implementation existed at the checkpoint.

**My reflection**

> Codex verified that the installed environment is ready for both the selected Automator Quick Action and the fallback AppKit Service-provider mechanism. The available tools establish implementation readiness, but they cannot prove that the real Apple Notes interaction meets its acceptance criteria. Only the experiment can establish its performance and other runtime behavior, including selection replacement, cancellation, focus restoration, and reliability.

**Next time / revisit**

Build only the disposable Quick Action and judge it through the actual Apple Notes workflow rather than treating tool availability as proof of interaction quality.

### 2026-08-20 — Exercise 02 — Task C: Apple Notes interaction architecture gate

**Skills strengthened**

- `verify` — Demonstrated
- `set-boundaries` — Demonstrated

**What I did**

Tested the bounded Apple Notes interaction through two approved native mechanisms, preserved the failed Automator evidence, implemented the AppKit Service-provider fallback, and judged the real keyboard workflow after functional, performance, integrity, cancellation, and focus verification.

**Evidence**

- The Automator Quick Action failed the complete interaction contract: its built-in list lacked usable cancellation, and the corrected AppleScript chooser did not appear reliably when invoked from Notes.
- The AppKit fallback received selected Notes text, automatically focused a three-row chooser, supported arrow keys, Return, and Escape, replaced only the intended range, and returned focus to Notes.
- The configured Control–Option–Command–G shortcut successfully invoked the service from Notes.
- Five fresh-launch trials passed with a maximum 480.0 ms system-controlled latency, below the approved 3,000 ms limit.
- Twenty resident trials passed with a 130.5 ms median and 192.9 ms nearest-rank p95, below the approved 1,000 ms and 2,000 ms limits.
- Two cancellation checks left the selected text unchanged. All 27 accepted rows preserved the expected scratch-note range and returned Notes focus, with zero integrity or focus failures.
- The automated timing endpoint used a documented one-frame settled proxy followed by independent UI assertions. Failed automation calibration attempts remained preserved separately rather than being relabeled or silently discarded.
- The learner performed the real shortcut workflow repeatedly and judged it quick, painless, fast, and reliable enough to pass. The learner identified visually ambiguous identical-text replacement and the Control–Option–Command–G chord as UX limitations.
- Durable evidence is in `spikes/notes-interaction/EVIDENCE.md`, `AUTOMATED_TRIALS.jsonl`, `AUTOMATION_CALIBRATION.jsonl`, and `PLAN-001`.

**My reflection**

> I would use this Notes interaction repeatedly because it is quick and painless. It felt fast and reliable enough to pass the acceptance gate. Replacing Front Squat with the identical text gives no visible confirmation, but the other replacement cases and recorded evidence demonstrate that the round trip works. The Control–Option–Command–G shortcut was the main source of friction and should be reconsidered. I want Exercise 03 to retain the Notes-adapter hypothesis. Working code alone is insufficient evidence because frictionless operation—not merely technical execution—is a central acceptance criterion for this workflow.

**Next time / revisit**

In Exercise 03, record the decision to retain the Notes adapter, the failed Automator alternative, the successful AppKit evidence, the timing-proxy limitation, the awkward shortcut, the identical-text ambiguity, and falsifiable revisit triggers in an ADR without turning the spike into product architecture.

### 2026-08-20 — Exercise 03 — Notes integration architecture decision

**Skills strengthened**

- `record-decisions` — Demonstrated
- `verify` — Demonstrated
- `collaborate` — Demonstrated

**What I did**

Converted the approved Exercise 02 result into ADR 001, synchronized the architecture overview, and kept the durable decision separate from the experimental procedure and full-fidelity evidence.

**Evidence**

- Pushed `tutorial/exercise-02`, merged it into `learner/main` as `968f6c7`, pushed and fast-forward verified the integration branch, and created `tutorial/exercise-03` from that exact commit.
- Created `docs/decisions/001-notes-integration.md` with Context, Decision, Evidence, Alternatives considered, Consequences, Known limitations, and Revisit triggers.
- Recorded the decision to retain Apple Notes through an AppKit Service adapter while keeping resolver and domain logic independent and treating the spike as disposable evidence rather than production code.
- Recorded the failed Automator alternative, the rejected companion-editor alternative, and why a third integration mechanism was not investigated.
- Preserved the macOS-version, fixed-list, distribution, shortcut, identical-text feedback, timing-proxy, and sample-duration limitations.
- Added quantitative, integrity, compatibility, usability, and distribution revisit triggers, plus an explicit rule to abandon the Notes companion when a triggered problem cannot be corrected inside the adapter without weakening product principles or acceptance gates.
- Updated `docs/ARCHITECTURE.md` to distinguish the validated Notes adapter direction from downstream domain boundaries that remain hypotheses.
- `git diff --check` passed and the ADR's evidence links resolve to the completed plan and spike evidence.

**My reflection**

> The ADR persists the architecture decision and summarizes the evidence supporting it. The experiment plan records the intended procedure, acceptance gates, and recovery rules, while the evidence log preserves the observations and measurements in full fidelity so the decision can be inspected later.
>
> The Notes decision is falsifiable, but its revisit triggers use different kinds of evidence. Performance, integrity, and focus can be tested mechanically. A change from “quick and painless” to actively avoiding the interaction is subjective and cannot be fully automated, but it is still meaningful product evidence that requires deliberate human reassessment. I reviewed the alternatives, consequences, limitations, and revisit triggers and believe ADR 001 accurately records the decision.

**Next time / revisit**

Begin Exercise 04 with design only: settle stable exercise identity, display text, aliases, ownership constraints, indexes, migration strategy, examples, and tradeoffs before generating persistence code.

### 2026-08-21 — Exercise 04 — Task A: Exercise library model design

**Skills strengthened**

- `frame-work` — Demonstrated
- `orient` — Demonstrated
- `plan` — Demonstrated

**What I did**

Reviewed and materially simplified the proposed exercise-library model before persistence, used read-only evidence from the existing Apple Notes library to separate present identity needs from future program and client concepts, and approved database-enforced ownership constraints.

**Evidence**

- Reviewed the proposed entities, keys, constraints, indexes, examples, migration path, and tradeoffs before generating persistence code.
- Reduced `Exercise` to an opaque stable UUID, a required owned `preferredNameID`, and timestamps; all human-readable vocabulary is stored as durable `ExerciseName` records.
- Rejected a separate canonical-name role because the current workflow needs stable identity, one preferred display name, and confirmed aliases, with no demonstrated consumer for a formal taxonomy name.
- Chose preferred-name-plus-short-UUID diagnostics such as `Front Squat · 8E22A4D3` instead of name-derived identifiers or bare UUIDs in ordinary human interaction.
- Preserved normalized display text separately from its deterministic lookup key so cosmetic differences can be deduplicated without treating fuzzy or semantic similarity as authoritative ownership.
- Approved global normalized-name uniqueness, idempotent same-owner additions, explicit cross-owner conflicts, workflow-supplied provenance, and no initial hard-delete API.
- Identified that an application-only invariant could permit an orphan `Exercise`; corrected the design with a required deferred composite foreign key that verifies the preferred name exists and belongs to the same exercise at transaction commit.
- Opened and inspected all 57 Apple Notes in the Strength Training folder read-only. Program context, progressions, movement patterns, equipment/loading distinctions, source attribution, and client constraints were recorded only as evidence-backed future directions marked `do not implement now`.
- Added an approved optional Agentic-AI Map check-in about visible coordination between an agent and a sub-thread, with the supplied screenshot preserved as evidence.
- Approved reusable guidance requiring agents to question potentially under- or over-scoped success criteria, especially opportunities to make them narrower or more specific, without changing criteria absent explicit approval.
- Prepared and inspected that reusable guidance separately against clean `main`; after an accidental push was retracted, committed it locally only and synchronized local `learner/main` and the current exercise branch without pushing.
- `git diff --check` passed for the approved design, learning artifacts, and reusable guidance candidate.

**My reflection**

> Before generating the migration, I settled the model’s identity, naming, normalization, uniqueness, conflict, provenance, and lifecycle decisions. I chose an opaque UUID as canonical exercise identity, with exactly one preferred `ExerciseName` for display and other confirmed names as aliases. I deliberately omitted a separate canonical-name role because no current product behavior needs it.
>
> I was surprised that this review cycle materially simplified the model. In the past, discussion sometimes expanded durable instructions and made them more confusing. A review or planning cycle can move in either direction, which makes it worth proceeding slowly at consequential design points. The new `AGENTS.md` guidance should encourage future reviews to inspect whether success criteria should expand or can become narrower or more specific, with particular attention to simplification, although whether it consistently produces simplification remains to be seen.
>
> Reviewing these decisions before persistence is cheaper because mistakes are still document changes. After seeding data, the same changes could require collision handling, backfills, ownership repair, and migrations. I also learned to preserve evidence-backed future directions without expanding the current model or changing its success criteria.

**Next time / revisit**

Implement only the approved persistence surface and verify the no-orphan, exact-lookup, idempotency, and conflict constraints against the actual schema before adding resolver or history behavior.
