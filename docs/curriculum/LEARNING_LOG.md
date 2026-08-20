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
