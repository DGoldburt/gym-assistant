# Optional Lab 05 — Documentation Integrity and Gardening

## Skills practiced

- `verify` — Build an evidence-producing delivery loop
- `review` — Challenge work from more than one perspective
- `scale-capabilities` — Apply advanced capabilities deliberately

## Learning objective

Learn to separate mechanically enforceable documentation invariants from semantic
code-versus-doc drift. Run one bounded doc-gardening workflow that produces a reviewed
pull request, then decide whether the procedure is mature enough to repeat or schedule.

## Starting state and scope

Begin only after Exercise 12 has established one-command verification. Exercise 13's
independent-review practice is helpful but not required. Choose a small documentation
surface whose authoritative evidence is available locally, such as the durable context
map, architecture boundaries, command references, or curriculum cross-links.

Do not use this lab to change product success criteria, architecture decisions, learner
progress, reflections, or skill confidence. A gardening agent may propose corrections,
but it may not merge its own pull request. Do not add a new CI system or recurring task
merely to complete the lab; reuse existing verification and scheduling infrastructure
when it exists and is appropriate.

## Task — Add invariants and run one gardening pull request

1. Inventory the selected documentation, its source of truth, and important incoming
   and outgoing links. State which relationships are mechanical and which require
   judgment about meaning.
2. Add two to four high-value deterministic checks to the existing verification path.
   Examples include broken internal links, missing required sections, duplicate stable
   identifiers, an out-of-date generated index, or a declared file that no longer
   exists. If CI already runs that path, confirm the checks run there; otherwise keep
   the trial local and record CI integration as a separate decision.
3. Observe one controlled failure, repair it, and rerun the complete verification path.
   Do not retain a fake failure or weaken a useful check merely to make the run pass.
4. Give a separate agent a read-only gardening prompt. Bound its files and evidence
   sources; require every finding to cite the conflicting documentation and the code,
   test, configuration, or runtime evidence that challenges it. Require it to distinguish
   certain mechanical violations from semantic findings that need human judgment.
5. Review the findings, select at most one supported correction, and have the agent
   prepare it on a separate branch. Inspect the complete diff and verification evidence,
   then open a pull request for human review. Do not merge it as part of the lab.
6. Record false positives, missed issues, elapsed review effort, unchanged-run behavior,
   and whether the prompt and checks were stable enough to repeat. Consider recurrence
   only after another successful manual run; use Optional Lab 04 before scheduling it.

### STOP / REVIEW — Documentation-gardening evidence

Inspect the documentation contract, deterministic checks, controlled failure, passing
rerun, agent findings with cited evidence, and the unmerged fix-up pull request. Decide
which claims were mechanically established, which still required judgment, and whether
the gardening procedure reduced stale knowledge without granting the agent authority
over product truth.

Teach back: Why can CI prove that repository knowledge is structured and cross-linked
while still needing human review of an agent's claim that the documentation is stale?
