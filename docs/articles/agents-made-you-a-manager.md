# Shaka and "Your coding agents made you a manager"

*An AI agent wrote this article: Claude Code running Claude Opus 5.5, on 2026-11-08.
Justin Gordon asked it to compare Addy Osmani's
[post](https://x.com/addyosmani/status/2119332146485891501) of 2026-11-07 with Shaka.
The agent read the post and Shaka's docs, workflow, and enforcement map at
[`6dda80b`](https://github.com/shakacode/shaka/tree/6dda80b82188). No experiment was run.
Codex and a fresh Claude session reviewed it before publication.*

Addy Osmani argues that an engineer working with coding agents is already managing.
The habits that help are a good manager's habits: give work a check it can run, brief
it well, plan first, and keep the decisions yourself. His post names twelve habits, ordered
roughly by impact.

Shaka is a skill that takes one task to a reviewed pull request (PR). This article checks
each habit against what Shaka does, and says what backs it: a command that refuses, or
an instruction the agent follows.

## Main results

- Shaka covers ten of the twelve habits for each task. The two it skips are about
  where the analogy breaks and not needing a manager title.
- The habits that protect the merge decision have code behind them. The merge helper
  refuses a PR over the size limits until the agent passes a flag recording your
  confirmation of that commit. The description helper refuses a review rating below a
  file's floor.
- Most other habits are instructions only. Shaka's own audit lists 100 workflow rules: 8
  refused by a command, 2 reported by one, 1 refused by GitHub, and 89 backed by nothing
  but the agent.
- The post argues against heavy process. The workflow `shaka workflow` prints is about 11,800 words, with 42
  reference procedures the agent loads when a task needs them.
- Three ideas in the post have no Shaka counterpart: splitting one change into many PRs
  automatically, counting reverts beside throughput, and dropping rules once newer models
  no longer need them.

## The habits, one by one

*Backed by* uses the categories from `shaka enforcement`: a command refuses, a command
reports, GitHub refuses, or only the agent follows it.

| Habit in the post | What Shaka does | Backed by |
| --- | --- | --- |
| Give it a way to check its work | Runs the repository's checks, reviews the final commit, and links the results on the PR | Command, for a review line covering the merged commit |
| Set clear context | Restates outcome, scope, and success criteria before coding | Agent |
| Make every correction compound | Points to retrospectives and `AGENTS.md` | Agent |
| Enforce only what can't bend | Lists each rule and what enforces it | Command, for 8 of 100 rules |
| Plan before it builds | Plans, then offers to agree on a design when choices are open | Agent |
| Steer early, reset fast | Return points record guidance to go back to | Agent |
| Delegate the task, never the judgment | Ask merge by default; large or risky PRs return under Auto | Command, until the agent records your confirmation |
| Design the run that doesn't need you | Trusted settings, base-branch rules, and an approval step | Command for merge; agent for using the settings and comment checks, and for the base branch |
| Scale verification, not attention | Labels PRs that wait on you; one chat can follow many tasks | Agent, with labels set by a command |
| Decide what not to build | States the value before work and reconsiders the finished result | Agent |

### Give it a way to check its work

- **Idea:** an agent stops when the work looks done. A test, build, or screenshot lets
  it find its own failure. A reviewer with fresh context catches what the author missed.
- **In Shaka:** the Verify step runs the repository's validation, then one or more
  reviewers with no access to the implementing chat. The PR links each result and names
  what went unverified. See [PR verification](../pr-verification.md).
- **Backed by:** the merge helper refuses when the merging account has posted no review
  line for the commit it merges. The line shows that someone posted it, not that a
  reviewer ran or findings were fixed. Test quality and review depth are the agent's
  judgment.
- **Limit:** a merge clicked on GitHub skips that check. The agent can also pass a
  waiver reason, which the merge result reports.

### Set clear context

- **Idea:** brief the agent on what it cannot learn from the code: why, constraints,
  what is out of scope, and what done means.
- **In Shaka:** [give it an outcome](../working-with-shaka.md#give-it-an-outcome) asks
  for only what the agent can't infer. Before coding, the agent restates the outcome,
  scope, success criteria, and risky assumptions.
- **Backed by:** the agent. The audit says Ruby cannot verify understanding.
- **Limit:** nothing checks that the restatement matches what you meant.

### Make every correction compound

- **Idea:** when you correct the same thing twice, write it into the team's
  instructions or a shared skill.
- **In Shaka:** projects keep constraints in `AGENTS.md`. On request, a retrospective
  reads named sessions and proposes changes.
  [Improve the process over time](../pr-verification.md#improve-the-process-over-time)
  suggests a regular review of merged PRs.
- **Backed by:** the agent.
- **Limit:** a retrospective runs only when someone asks.

### Enforce only what can't bend

- **Idea:** let the agent decide by default. Use hard enforcement only for what must
  always or never happen. Remove enforcement that only expresses a preference.
- **In Shaka:** [what is enforced](../workflow.md#what-is-enforced) lists the rules code
  checks. `shaka enforcement` prints every audited rule and what, if anything, backs it.
  Commands check settings, which public comments the agent reads, and merge conditions
  when the agent runs them.
- **Backed by:** a loader. It fails when a quoted rule leaves the workflow, or when a
  "never" or "must" rule in a new passage has no classification. Review, not the
  loader, catches a rule added inside a passage already quoted.
- **Limit:** see [where the post argues against Shaka](#where-the-post-argues-against-shaka).

### Plan before it builds

- **Idea:** agree on a plan first and look for hidden assumptions. Split work into parts
  that don't overlap.
- **In Shaka:** the Plan step assesses value, scope, and risk. When a task leaves
  design choices open, the agent offers to agree on the design before coding.
  [Get a plan before implementing](../working-with-shaka.md#get-a-plan-before-implementing)
  stops at the plan.
- **Backed by:** the agent. The `checkpoint` command records the decision to start.
- **Limit:** the agent splits a task into PRs while planning, by judgment. Shaka has no
  tool that divides a change into many parallel PRs.

### Steer early, reset fast

- **Idea:** correct the agent early. After two failed corrections, start fresh with a
  better prompt.
- **In Shaka:** [revise earlier guidance and try again](../working-with-shaka.md#revise-earlier-guidance-and-try-again)
  uses return points. Each one records your guidance and the code it applied to.
- **Backed by:** the agent. Ruby saves no snapshot and restores no files.
- **Limit:** Shaka does not count failed corrections or suggest a fresh chat.

### Delegate the task, never the judgment

- **Idea:** the agent does the work, and you decide what ships. Approving a large diff
  because the tests pass ratifies code without reviewing it.
- **In Shaka:** Ask is the default [merge policy](../working-with-shaka.md#choose-a-merge-policy).
  Under Auto, the agent hands back PRs over the
  [size limits](../settings.md#mergelimits) and PRs touching files above
  [`merge.auto_max_review_floor`](../settings.md#mergeauto_max_review_floor).
  This repository sets 999 changed lines and floor 2.
- **Backed by:** the merge helper refuses both, unless the agent passes a flag naming the
  commit you confirmed. Nothing checks that you did confirm it. The description helper
  refuses a review rating below the floor that the changed files set.
- **Limit:** under Ask, the depth of your own review stays with you.

### Design the run that doesn't need you

- **Idea:** before an unattended run, answer five questions. What is done? How does it
  check itself? What are its boundaries and guardrails? Who approves the output?
- **In Shaka:** done is the success criteria from intake. Self-checking is the Verify
  step. Boundaries come from the [trust model](../workflow.md#trust-model): settings come
  from the default branch, and the target branch never comes from an issue or comment.
  Approval is Ask or Auto.
- **Backed by:** the merge helper, for merge conditions. `seam check --ref` reads settings
  from the default branch, and `comments` withholds untrusted comments. Nothing forces
  the agent to use either one. Choosing the target branch is the agent's alone.
- **Limit:** Shaka sets no turn or spend limit. Its PRs report usage after the fact.

### Scale verification, not attention

- **Idea:** add agents only as fast as checks and fresh reviewers can watch them.
  Measure quality beside throughput.
- **In Shaka:** labels such as `awaiting-merge-approval` show
  [PRs waiting on you](../working-with-shaka.md#find-prs-waiting-on-you).
  [Control towers](../control-towers.md) follow many tasks from one chat.
- **Backed by:** the `attention` command sets the labels. Acting on them is yours.
- **Limit:** see gap 2.

### Decide what not to build

- **Idea:** cheap code still costs review and maintenance. Ask who needs it and how you
  will know it worked.
- **In Shaka:** before work, the agent names the user problem and a cheaper
  alternative. Agent-proposed work waits for your acceptance. Before merge, a checkpoint
  can recommend Revise, Reconsider approach, or Do not merge.
- **Backed by:** the agent. The helper prints the value line but does not judge it.
- **Limit:** the checkpoint judges a finished PR, after the cost of building it.

The post's last two sections, on where the analogy breaks and on not needing a manager
title, are about people and careers. Shaka has nothing to add there.

## Where the post argues against Shaka

The post separates requests from requirements. Prompts and skills are requests the model
weighs. Hooks and deny rules are requirements. It warns that over-process is the agent
version of micromanagement, and suggests dropping rules newer models no longer need.

- Shaka is mostly requests. 89 of its 100 audited rules rely on the agent alone.
- Shaka limits what the agent reads instead. The workflow loads its 42 reference
  procedures only when a task needs them. `bin/report-instruction-growth` measures added
  instruction text in each PR, and this repository's `AGENTS.md` asks reviewers to name
  the failure each new instruction prevents.
- Nothing in Shaka retires rules. No step asks whether a newer model still needs one.

## What Shaka lacks

### 1. Automatic decomposition

- **Today:** Shaka defaults to one PR per task. The agent may split a task while
  planning, and each PR repeats the full workflow.
- **In the post:** Claude Code's `/batch` divides a large mechanical change into 5 to 30
  tasks, each in its own worktree with its own PR.
- **Possible change:** none planned, and no issue asks for one. A `/batch` run can
  produce the PRs, and a Shaka task can review each one.

### 2. A quality counterweight to throughput

- **Today:** PRs report token usage. Retrospectives read named sessions.
  Nothing counts reverts or follow-up fixes after merge.
- **In the post:** measure reverts and rework beside PRs merged, after Andy Grove's rule
  of pairing each measure with a countermeasure.
- **Possible change:** let a requested retrospective count reverts and fix-up PRs for
  merged Shaka PRs. [#1077](https://github.com/shakacode/shaka/issues/1077) already
  proposes reading findings across merged PRs.

### 3. Retiring rules after a model upgrade

- **Today:** the enforcement audit and instruction-growth report measure rules as they
  are added. Nothing reviews old ones.
- **In the post:** each model release changes which instructions still help.
- **Possible change:** a requested retrospective step that lists agent-only rules no
  recent session needed. No issue tracks this. Whether one run finds rules worth
  removing is unknown.

## Sources

- Addy Osmani, ["Your coding agents made you a manager"](https://x.com/addyosmani/status/2119332146485891501),
  2026-11-07.
- Shaka at [`6dda80b`](https://github.com/shakacode/shaka/tree/6dda80b82188):
  [workflow and enforcement](../workflow.md), the
  [enforcement map](../../skills/shaka/config/enforcement.yml), and the output of
  `shaka enforcement`.
