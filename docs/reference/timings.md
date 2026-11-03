# Understanding PR timings

Expand **Shaka metrics → Timings** to see elapsed time, waits for a person, and
measured validation and review runs. Ask the agent to explain a number there;
this reference covers the labels and their limits.

## Time to ready and merge

**Ready in** measures from the recorded task start until the current commit's
required checks and configured CI reviews are green. After merge, **merged in**
measures through the merge instead.

| Interval | Meaning |
| --- | --- |
| Prompt to CI | Task start to the current commit's earliest check. |
| CI to ready | That check to the recorded ready time. |
| Ready to merged | Ready time to merge. |
| Before first recorded validation | Task start to the earliest recorded validation, including focused checks. This overlaps the timeline; it is not added again. |

After a new push, the ready intervals describe the new commit. `pending` means
not known yet. `UNKNOWN` or unavailable means no suitable record, not zero.

## What each stretch means

| Stretch | Starts | Ends |
| --- | --- | --- |
| Before the pull request | Recorded task start, or first commit | PR opens |
| Between checkpoints | PR opens or a wait ends | Next wait, merge, closure, or description update |
| Waiting on a person | Agent records a request for an answer, merge approval, or manual resume | Agent resumes, or PR merges or closes |

Time between checkpoints includes work, checks, and any unmarked wait. Waiting
on a person follows the PR's attention labels, so a wait can end slightly after
you reply. These are wall-clock intervals, including nights and weekends; they
do not measure active human effort.

## Read the bars

The chart puts the PR and measured steps on one time axis. Each reviewer has a
lane. Marks in the same column overlap.

| Mark | Meaning |
| --- | --- |
| `-` | Before the PR opens |
| `=` | PR is open |
| `.` | Waiting on a person |
| `#` | A measured step ran |
| `x` | Validation failed, or review/checkpoint did not complete |
| `//19h//` | Nineteen hours of idle wait removed from the axis |

The number beside a step lane adds its runs. The PR lane measures its full
span. A long idle wait is shortened so the other runs remain visible; clock
times jump across the cut. Brief or overlapping runs can share a column, so use
the table to inspect individual results rather than measuring pixels.

## Measured steps

Steps include validation, local review, and checkpoints. Models and machine
aliases appear when known. A completed review can still report defects; read
its report for findings. **Not completed** describes execution, not a favorable
or unfavorable verdict.

Failed or incomplete steps have table rows with exit codes. If the chart cannot
render, the table lists all retained steps. A step overlaps its timeline
stretch; adding both would count the same time twice.

Each description update keeps steps published by earlier sessions or machines.
Unpublished steps on another machine are missing. The log stays local; see
[manual installation](../manual-installation.md#what-the-installer-changes)
for its location and the switch to stop recording.

## Read the limits

- The agent reports the task start. Shaka checks its timestamp, not when work
  actually began. Without it, the timeline starts at the first commit and omits
  earlier work. Moving to a new chat before publication can lose the earlier start.
- Ready time needs an update or watch that observes the gates passing. It can be
  missing when CI review was skipped or no update recorded readiness.
- Times use the [configured time zone](../settings.md#pr_descriptiontime_zone), UTC by default.
- The latest 30 stretches appear in the table; totals still cover all stretches.
  Timings reflect the last description update, so a later manual merge wait may
  not appear until another update.
- Step matching covers the latest 100 commits. Rebased commits' steps survive
  only when an earlier update published them. Uncommitted failing trees are omitted.
- The latest 50 steps contribute to bars and totals; the table shows up to 30 rows.
  The section reports these cuts. The earliest validation time survives once
  published, but stays unavailable if its record was dropped before being saved.
- Fork PRs do not retain earlier descriptions' steps, because their authors can
  edit them. Only steps available to the updating machine appear.

If GitHub cannot supply the timeline, the PR says so. The next description
update tries again. Treat the numbers as recorded coverage, not a complete
account of the task. See [usage and cost](usage-and-cost.md) beside them.
