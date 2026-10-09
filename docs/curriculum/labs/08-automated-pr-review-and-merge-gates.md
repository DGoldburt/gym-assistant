# Optional Lab 08 — Automated PR Review and Merge Gates

Status: Approved; not started. Approval publishes this reusable teaching material,
not permission to configure GitHub or execute its tasks. Start it only when the
learner explicitly chooses it; Optional Lab 07 Task B is independent.

## Learning objective and skills

Learn to distinguish an author's verification, independent code-review findings,
deterministic CI checks, repository-enforced merge requirements and the human's
authorization to integrate a change. Practice a bounded response to automated
findings and verify that evidence applies to the exact revision being merged.
Skills: `review`, `verify`, `collaborate`, `set-boundaries`, `operate-cli-agents`.

## Starting state and scope

Use one already-approved implementation PR with acceptance criteria, a known base
branch, verification evidence and an explicit manual-test checklist. Library Edit
is a suitable live example after its product-only diff is prepared. Do not manufacture
a defect in that feature merely to obtain a bot comment. If no live findings occur,
practice disposition with a labeled synthetic example and report that limitation.

Keep product integration distinct from installation and migration of live data.
Do not implement deferred features, advance tutorial progress, install providers,
grant an integration access, add secrets, alter review settings/protection, post
comments, or merge without the corresponding explicit approval. Raw private Notes,
library files, client material and learner reflections must not enter a product PR
or remote-review payload. Inspect current repository visibility before publishing.

Publish this reusable lab from a clean main-based worktree,
separately from feature and learner changes. Never copy personal learning records
to reusable main. No changes to PROGRESS.md are part of this optional lab.

## Task A — Identify who supplies evidence and who can merge

Before the checkpoint, Codex may inspect source, local Git ancestry, existing PRs,
workflow files, branch protections/rulesets, available review integrations and official
documentation without changing settings. Record the PR base/head revision and complete
candidate diff, reviewers' access and reporting thresholds, CI runner requirements,
permissions, possible cost/data flow, and how newer pushes affect earlier evidence.

Compare three surfaces: local `/review`; Desktop's Code Review PR workspace and
review instructions; and repository-triggered Codex reviews. A shared review model
or a different chat is not automatically an independent authorization boundary.
Make a compact evidence/authority diagram and propose the smallest policy for this
repository: deterministic checks, independent review, explicit finding dispositions,
and a human merge decision. For a solo-maintainer repository, do not invent a second
human approver or pretend the same account creates organizational separation.

### STOP / REVIEW — Integration and authority plan

Inspect the base/diff, repository visibility, current enforcement and proposed policy.
Decide the integration target and what to configure. Any requested setup approval
must name exact repositories/settings, permissions, provider/data flow and costs;
no vague blanket approval. Merely accepting this lab does not approve those changes.
Teach back: which evidence is independent of the author, and what actually prevents
an authoring agent from merging a bad PR?

## Task B — Observe CI and a PR reviewer separately

After the required setup approvals, prepare a product-only PR without merging. Use
existing CI if sufficient; otherwise propose a minimal workflow running the project's
deterministic verification on a compatible macOS runner. Do not install the app or
claim Notes usability from a hosted build. Record job permissions and ensure private
data/secrets are not supplied to untrusted PR code. Configuring a required check is
a distinct operation from creating a workflow that happens to run.

Start with one manual Codex PR review and inspect its report in GitHub and Desktop.
Use `@codex review` only after approval to post it and after confirming repository
connection/access. If that setup is unavailable, stop with a precise setup plan;
do not simulate a completed review. Automatic triggers can be enabled later only
after this first observed run. Copilot or a custom Actions reviewer are optional
alternatives to discuss, not additional required providers to install.

Record the reviewed commit, configured instructions, actual review type and findings,
check names/conclusions, completion/failure behavior and usage where exposed. Learn
the distinction between an AI comment, an approving review and a required status
check. Absence of findings or a completed job is not itself merge approval.

### STOP / REVIEW — Evidence and enforcement

Inspect the CI logs and review on the same head revision. Explain which outcomes
are advisory and which GitHub currently enforces. Decide whether automatic triggers
or required checks are justified, and approve exact settings separately if desired.
Teach back: why can a green test job and a zero-finding bot review still be insufficient?

## Task C — Respond to findings without an unbounded fix loop

Before this checkpoint, Codex may analyze findings and prepare proposed dispositions.
For each, record severity, file/line, triggering input, evidence and fix/defer/reject
recommendation. No product fix is authorized solely by an agent's review comment.
If no supported findings exist, retain that result; use a synthetic example only for
the learner's disposition exercise, outside the feature diff and finding counts.

For each human-approved correction, the implementer changes only the approved scope,
runs relevant verification, and pushes only with authorization. Rerun relevant review
and CI on the new head; record which earlier findings are resolved or remain. Use
at most one correction/re-review cycle before unresolved judgments return to the
learner. Do not loop until all agents agree or automatically accept every suggestion.

### STOP / REVIEW — Disposition and revision coverage

Inspect findings, dispositions, any approved correction diff and latest-head evidence.
Decide whether another narrowly justified cycle is necessary; otherwise stop.
Teach back: why should a new commit invalidate some earlier review evidence, and
why is resolving a comment not the same as fixing the underlying issue?

## Task D — Make a revision-bound merge decision

Before the checkpoint, Codex may inspect merge readiness read-only. Present the exact
PR base/head, latest required checks, outstanding findings, merge method, manual-test
gates and recovery plan. Inspect the final full diff for private material and unrelated
changes. Integration may be approved while installation remains separately gated.
Do not override protections, enable auto-merge or send the merge command yet.

### STOP / REVIEW — Human merge authorization

The learner explicitly decides to merge this exact PR revision, defer, or require
more evidence. After that approval, Codex may issue a revision-guarded merge command,
confirm the resulting target commit, synchronize the intended checkout and rerun
relevant verification. Retain recovery work until target synchronization succeeds;
close obsolete source refs only when no active worktree needs them. Installation,
live-database migration and automatic merging of future PRs remain unapproved.
Teach back: if an agent sends the merge command, what makes that delegated execution
rather than the agent being the sole judge of its own work?

## Evidence and completion

Retain configuration decisions, candidate diff, base/head IDs, CI/review reports,
findings and human dispositions, actual permission boundaries, final merge outcome,
and remaining manual checks. After each checkpoint, draft a first-person reflection;
append only approved reflections/evidence to LEARNING_LOG.md and update only justified
skill confidence. Never advance PROGRESS.md for this lab.

## Official references checked 2026-10-08

- [Desktop/local Code Review](https://learn.chatgpt.com/docs/code-review): review
  instructions and PR investigation do not automatically post feedback or merge.
- [Codex in GitHub](https://learn.chatgpt.com/docs/third-party/github): manual and
  automatic repository reviews, repository guidance, and separate fix requests.
- [Codex GitHub Action](https://learn.chatgpt.com/docs/github-action): a custom
  workflow option with explicit permissions and API-key setup, not required here.
- [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches): required checks/reviews, stale review handling and admin bypass.
- [Copilot review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-code-review): comment reviews by default; optional approval behavior requires configuration and is not assumed.
- [Actions security](https://docs.github.com/en/actions/reference/security/secure-use): least-privilege workflows and untrusted-code/secret boundaries.

Recheck these controls and account availability before setup; this lab is not proof
that any review provider is already connected to this repository.
