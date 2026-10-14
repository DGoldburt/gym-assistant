# Session scratchpad — independent CLI review

Reviewed 2026-10-12 local date (2026-10-13 UTC). This records the Exercise 13
fresh-CLI review method, not completion of a tutorial task or implementation approval.

## Review boundary

The reviewer ran a fresh `codex exec --sandbox read-only --ephemeral` conversation
in the existing contextual-program-assistance design worktree, on branch
`codex/contextual-program-assistance`, HEAD
`ed7653a3a4b9a9b86c424e523a4e6e38dc238a02`. The installed CLI was 0.160.1;
the user's configured model was `gpt-5.6-terra`, medium reasoning, OpenAI provider,
approval mode never. No model override was supplied. The host launch was approved
to permit CLI runtime/authentication; the reviewer's own tool sandbox stayed read-only.

The prompt supplied the approved product boundaries, requested the complete tracked
and untracked candidate package, and supplied verification results. It did not supply
implementer self-review conclusions or a defense. The candidate included architecture,
opportunity tree, design documents and frozen mockups, ADR 004, capability PLAN 011,
and synthetic probes. The reviewer also inspected the newer learner checkout's
application source/manifest read-only (and Service packaging references).

Separation came from a new CLI conversation/process, not another checkout or another
explicitly selected model. The reviewer inherited repository instructions, PLANS,
configured CLI context, and the rationale/evidence inside the design documents.
It did not inherit this conversation's transcript. This is not total informational
isolation. No Notes access, private export access, native runs, production tests,
file mutations, delegation, or curriculum advancement occurred. The CLI exited 0
and saved its final report. Runtime reported 111,526 tokens used; this is a CLI
reported usage figure, not a measured billing total.

## Findings and disposition

The reviewer reported no contradiction with the supplied acceptance boundaries,
but judged the package not yet production-implementation-ready.

1. **Session-boundary/confirmation contract missing.** Named anchor types and
   general intent did not define testable recognition/range/confirmation rules.
   Accepted as a useful design gap. Added a clearly proposed executable fixture
   contract in [Notes monitoring](NOTES_MONITORING_CONTRACT.md#proposed-executable-association-contract),
   including observation-bound ranges, identity evidence, stale-confirmation
   checks and one-to-one collisions. It is still untested; no production recognizer
   or assumption that all real notes match this grammar follows.
2. **Verification overclaim.** A revision note said unchanged-large-note tests were
   measured, although they are future acceptance work. Accepted and corrected to
   proposed validation. Also clarified that prompt context may use the observation
   validated by the shared cache policy, not necessarily a new body fetch.
3. **Finder metadata in the directory.** The reviewer found an ignored `.DS_Store`.
   Not accepted as a product defect or reason to delete local user metadata. It is
   not a candidate tracked/untracked Git artifact and must not be force-added.

The verification overclaim and lack of executable association detail were useful
independent additions. Several remaining gates were already explicit in the plan.
Review completion does not turn planned experiments into passes. The corrections
above were made after review; they have document checks, not a second CLI review.

## Readiness and next checkpoint

Approve the proposed implementation contracts and choose the execution stream
before production work. The next bounded work is the synthetic association and
rich-paste checkpoint in Milestone 1: prove session/weekly ranges and workspace
identity across renumbering, and native Heading/Subheading/bold/continuing bullets.
Also measure equal-timestamp edits, shared-cache reads and whole-copy keyboard
timing before adopting those policies. Preserve failures; do not weaken formatting
or association promises to get a pass.

The reviewer listed production permission, storage/recovery and monitoring validation
as prerequisites to implementation. Narrow that conclusion: production permission
onboarding and persistence/recovery tests necessarily happen **during the offline
implementation milestone**, using a fake provider, not before any code can be
written. Choose the proposed storage/recovery contract when approving that milestone.
Do not require API configuration to begin native fixture or offline work.

Before live API calls, separately choose the exact model, request/output limits,
trial budget, key handling and retention defaults. Preferences learning/editing,
historical-chat import, library mutation, client/load history, automatic proposal
application, merge and Notes write-back remain outside this slice.

## Verification and handoff

`git diff --check` passed before review and after corrections. Link/whitespace/basic
private-material checks passed for all 11 Markdown documents checked afterward.
No new capability or production tests passed in this review cycle.

The reusable package remains uncommitted in its existing main-based design
worktree. Approval/sequence and synthetic evidence are still outstanding; it must
not be mistaken for a finished implementation or advanced learner checkpoint.

Reconciliation update, 2026-10-13: the design package and synthetic probes were
copied into a learner-based integration branch, where this review's statement about
the earlier worktree is historical. The original worktree was preserved. This move
does not resolve the review's implementation gates or grant production approval.
