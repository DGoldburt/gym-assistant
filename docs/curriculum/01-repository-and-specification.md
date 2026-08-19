# Exercise 01 — Repository, Git/GitHub, and Specification

## Why we're doing this

The first Codex skill is establishing a reviewable engineering environment before generating application code. This exercise separates product truth, agent behavior, architecture assumptions, task instructions, local version history, and remote collaboration.

## Skills practiced

- `orient` — Orient before changing
- `frame-work` — Frame a bounded task
- `plan` — Plan in proportion to risk
- `set-boundaries` — Control autonomy safely
- `collaborate` — Work through reviewable Git collaboration

## Starting state

Expected for this bootstrap:

- the tutorial files already exist in a local Finder folder
- the folder is not yet a Git repository
- Apple Git is available
- Git author name/email are not configured for this repository
- GitHub CLI is not installed; GitHub's web interface will be used
- the future GitHub repository will be private, named `gym-assistant`, and use `main`
- `.gitignore` excludes `.DS_Store`
- no application or Xcode project exists

Do not initialize Git, create a GitHub repository, or create application code during Task A.

## Mental model

- **Local folder** — files on this Mac; it has no version history by itself.
- **Git repository** — a local folder whose `.git` data records commits, branches, and history.
- **GitHub repository** — a remote copy and collaboration surface for pushes, pull requests, reviews, and merges.
- **`git init`** — add Git history to an existing local folder, which is the path used here.
- **`git clone`** — copy an existing remote repository and its history into a new local folder.
- **`git switch` / `git checkout`** — move among branches or revisions inside a repository that already exists. They do not create the first local copy of a remote project.

Codex normally uses the Git root as the project root and reads `AGENTS.md` before work. See the official documentation: <https://learn.chatgpt.com/docs/agent-configuration/agents-md>.

## Task A — Repository, Git, and product orientation

Ask Codex to:

1. inspect the repository without editing it
2. describe the files and the purpose of each durable context surface
3. verify whether `.git`, Git, Git author configuration, GitHub CLI, `.gitignore`, and Xcode are present
4. explain `init`, `clone`, and `switch`/`checkout` using this folder as the concrete example
5. summarize the product in its own words
6. identify missing project/tooling decisions
7. identify the highest-risk architecture assumption
8. recommend an appropriate reasoning depth and permission boundary for the next steps

### STOP / REVIEW — Orientation

Inspect the command evidence and repository map. Confirm that Codex correctly distinguished the local folder, local Git repository, and future private GitHub remote without changing any of them.

Explain in your own words:

1. Why does this existing folder need `git init` rather than `git clone`?
2. What does `git switch` or `git checkout` change, and what does it not do?
3. Why are a commit and a pull request different review boundaries?
4. What is the product's highest-risk architecture assumption?

The correct architecture risk is:

> Can a macOS Service/Quick Action interaction with Apple Notes be fast and reliable enough to form the core workflow?

Also decide whether the proposed reasoning depth and permission boundary match the risk. Codex must draft a first-person reflection, but it must not write the reflection, initialize Git, or update progress until the user approves this checkpoint.

## Task B — Create the local and remote repository

Only after the orientation checkpoint is approved:

1. Review the current folder with the user and decide what the first commit should represent and how a clean reusable tutorial starting point should be preserved. Here, a clean reusable tutorial starting point means a pristine curriculum state from which a new learner can begin before Task A; it is not a snapshot of this learner's post-Task-A progress or approved learning evidence. There should also be a strategy for incorporating future exercise updates into the fresh tutorial, even if the user has completed some exercises already.
2. Ask the user for the Git author name and GitHub-verified email or GitHub private noreply email to store in this repository's local Git configuration.
3. Confirm `.gitignore` excludes `.DS_Store` and that no secrets or generated files are about to be committed.
4. Initialize the existing folder with `main` as the initial branch.
5. Show the working-tree and staged-file evidence before committing.
6. Create the first commit with a message that accurately describes the baseline the user approved.
7. Show the commit hash, log, and clean working-tree evidence.
8. Have the user create an empty private `gym-assistant` repository in GitHub's web interface without adding a README, license, or `.gitignore`.
9. Add the GitHub-provided HTTPS URL as `origin`, verify it, and push `main`.
10. Create and switch to `tutorial/exercise-01` for the remaining exercise artifacts.

Do not install GitHub CLI. Do not store credentials in repository files.

### Curriculum TODO — Generic learning-harness release

After the repository and release workflow exists, evaluate publishing a versioned learning-harness release that omits the gym-assistant product and architecture assumptions. A new learner using that release should begin by having Codex help elicit and record the product and architecture truths for something they want to build. This is future curriculum-design work, not a Task B deliverable, and must not advance or block the current exercise.

### STOP / REVIEW — First commit and remote

Inspect the local commit hash, `main` branch, `origin` URL, clean status before branching, and the private GitHub repository page. Decide whether the remote contains exactly the bootstrap commit and no accidental files or secrets.

Teach back: What information exists only locally, what was sent to GitHub by the push, and why will the next work happen on a branch?

Do not merge or advance the exercise yet.

## Task C — Initial architecture-spike plan

Before planning, fork the current Codex chat into two temporary planning conversations. Do this only after Task B is complete: the fork is a planning experiment, not an additional product branch or a Git operation.

Run a fair, read-only A/B comparison:

1. In one fork, use a regular prompt and explicitly request a plan using the `PLANS.md` convention.
2. In the other fork, select Plan mode and make the same request, again explicitly requiring the `PLANS.md` convention.
3. Use medium reasoning in both conversations. Give both the same outcome, constraints, non-goals, and required sections so the mode is the variable being compared.
4. In both conversations, prohibit file writes, Git commands that change state, Xcode installation, and product implementation. Neither draft becomes `PLAN-001` yet.

Use this shared request in both conversations, changing only the mode:

> Draft a read-only candidate for `PLAN-001` using the `PLANS.md` convention. It must test only whether a macOS interaction with Apple Notes can be fast and reliable enough for repeated use. Include outcome, context, constraints and non-goals, investigation steps, verification evidence, stopping conditions, and an Exercise 02 tooling gate. Do not write files, initialize projects, install Xcode, or implement application code.

Compare the two drafts for scope control, missing assumptions, evidence and stopping gates, useful questions, and unnecessary ceremony. Response length or elapsed time may be noted, but they are not the success metric. Choose one draft or a deliberate hybrid only after the comparison.

Have Codex propose the smallest plan that tests only the Apple Notes interaction. The proposed plan must state:

- outcome
- relevant context
- constraints and non-goals
- investigation steps
- verification evidence
- stopping and architecture-gate conditions

It must explicitly exclude:

- database or persistence
- fuzzy matching or aliases
- client or performance history
- load recommendations
- exercise blocks
- production polish

Full Xcode installation is not generic Exercise 01 setup. The plan should place toolchain inspection, mechanism selection, and any resulting Xcode installation inside Exercise 02.

### STOP / REVIEW — Spike plan

Inspect both read-only drafts and the comparison. Decide whether regular prompting, Plan mode, or a hybrid produced the most proportionate plan for this architecture question; explain why. Inspect whether the selected plan answers only the Notes-interaction risk and stops before implementation. Reject any proposed product architecture, persistence, resolver, history, or polish work that does not reduce that uncertainty.

Teach back:

1. Why are we intentionally willing to write disposable code?
2. What single architectural question will the spike answer?
3. What observable evidence will determine whether the interaction is acceptable?
4. Why did this task justify Plan mode and a durable `PLANS.md` entry, while a tiny mechanical edit might not?
5. What did the A/B comparison show about when you would choose Plan mode versus a regular prompt, given that both followed the same `PLANS.md` convention?

Codex drafts a concise first-person reflection covering the relevant skills and the A/B conclusion. Preserve links or reproducible summaries of both drafts as learning evidence. Do not write either draft into `PLANS.md`, write the reflection, or update progress until the user explicitly confirms the reflection and checkpoint.

## Task D — Prepare the first pull request

Only after the spike-plan reflection and checkpoint are explicitly approved:

1. Record the approved spike as `PLAN-001` in `PLANS.md`.
2. Append the approved Exercise 01 evidence and first-person reflection to `LEARNING_LOG.md`.
3. Update only the skill-confidence states justified by that evidence in `SKILLS.md`.
4. Review the complete diff, confirm the relevant skills are named clearly, and confirm every checkpoint states what the user must inspect, explain, decide, or test.
5. Commit the branch with message `docs: complete tutorial exercise 01`.
6. Push `tutorial/exercise-01`.
7. Have the user open a GitHub pull request titled `docs: complete tutorial exercise 01`.

The pull request must contain the approved plan, learning evidence, justified skill-confidence changes, and progress transition.

### STOP / REVIEW — First pull request

In GitHub's web interface, inspect every changed file, the commit history, target branch, source branch, and available checks. Confirm that the PR contains documentation and learning evidence only, with no application code or later-exercise work.

Teach back: What did the pull request make reviewable that a direct push to `main` would not have made as explicit?

Codex drafts a final PR-review reflection. Do not write it yet. Passing this checkpoint completes Task D.

## Task E — Merge and synchronize

Only after the first-pull-request checkpoint is passed:

1. Update `PROGRESS.md` to identify Task E as current; this is allowed only because the preceding checkpoint was passed.
2. Append the approved final PR-review reflection to `LEARNING_LOG.md` and update `collaborate` only if its evidence justifies the change.
3. Commit that small documentation delta and push it to the same pull request.
4. Reinspect the final pull-request diff and checks.
5. Have the user merge the approved pull request in GitHub's web interface.
6. Switch the local repository back to `main`, synchronize it, and verify that local `main` contains the merged progress transition and learning evidence.

### STOP / REVIEW — Merged and synchronized

Inspect the merged pull request, local `main`, and synchronization evidence. Confirm that Exercise 01's approved plan, learning evidence, and progress transition are present on `main`, and that no product code or later-exercise work was merged.

Teach back: Why does this final synchronization check matter before starting Exercise 02?

Codex drafts a final Exercise 01 reflection. After the user passes this checkpoint and confirms the reflection, append the evidence, update only justified skill-confidence states, and update `PROGRESS.md` to mark Exercise 01 complete and point to Exercise 02 Task A.
