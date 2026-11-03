# PR verification

Read the PR's summary, evidence, and recommendation. Ask the agent to explain
anything unclear; this page is optional reference.

<a id="read-a-pr-for-your-decision"></a>
<a id="answers-for-your-merge-decision"></a>

## Answers for your next decision

| Question | Where to look on the PR |
| --- | --- |
| What changes, and why? | **Summary** and **Intent**, including scope and any deliberate exclusions. |
| What needs my attention? | **Human review** names the files to read closely. **Decisions to make** lists open choices. |
| Does it work? | **Verification** names the checks, results, and anything unproved. |
| Why this approach? | **Code Walkthrough** links the implementation and explains alternatives. |
| What did reviewers find? | **Code Review** records findings, fixes, and unresolved concerns. |
| Can I merge? | **Checkpoint** recommends the next action. Required checks and approvals still apply. |
| What else must happen? | **Steps besides merging** names each action, timing, and owner, or says none. |

<a id="see-a-current-pr"></a>
<a id="start-with-the-recommendation"></a>
<a id="follow-the-review-history"></a>

[PR #667](https://github.com/shakacode/shaka/pull/667) is a public example.

<a id="check-the-latest-changes"></a>
<a id="change-one-behavior-at-a-time"></a>
<a id="documentation-changes"></a>
<a id="show-what-a-person-will-see"></a>
<a id="show-what-changed-between-captures"></a>
<a id="show-whether-it-is-faster-or-slower"></a>

## Check the evidence

Tests and review should cover the change you are deciding on. Check their
reported commit and coverage, not just a green job. A test that fails before a
fix and passes afterward demonstrates that it can catch the problem.

For visible changes, look for inspected before-and-after captures on desktop
and mobile. Callouts explain what changed; original captures let you inspect
beyond those callouts. Interaction or timing may also need a recording.
Speed-affecting changes need a measured comparison or an explicit gap.
For rewritten guides, link checks alone do not establish usability.

When code or material check settings change, affected evidence needs refreshing.
A Shaka update can also require a rerun when its verification code or version
or review rendering changes. Rewording the same-commit description can retain results marked
**not rechecked**. Fork PRs need results supplied again because their authors
can edit descriptions.

Missing evidence leaves a question open. Ask:

```text
What does this PR's verification prove, and what remains untested?
```

<a id="keep-the-pr-easy-to-read"></a>
<a id="expect-a-readable-delivery-record"></a>
<a id="notes-on-the-diff"></a>

## Read the walkthrough when you need more detail

The walkthrough explains choices, alternatives, risks, and rollback. Reverting
code cannot recall emails, reverse charges, or restore deleted data by itself.
Inline notes suggest where to start or skim; they are not findings to fix.

### When a diagram helps

A small diagram can show how several callers reach a check:

```text
RefundsController#create ──┐
RefundRetryJob#perform ────┴── Refunds.issue
                               ├── RefundPolicy.check
                               └── PaymentGateway.refund
```

A change confined to one condition usually needs only a sentence. A diagram
explains the change; tests and observed results establish whether it works.

<a id="what-a-rollback-undoes"></a>
<a id="reconsider-the-finished-result"></a>
<a id="decision-checkpoint"></a>
<a id="evaluation-checkpoint"></a>

## Checkpoint

The checkpoint asks whether the finished result solves the problem and is worth
maintaining. Open it for the reasons, verification gaps, and any unresolved
concerns. A **Merge** recommendation is advice, not permission to merge.
Substantive concerns need a fix, evidence disproving them, or your explicit
acceptance. Green tests alone do not settle them.

The checkpoint also supplies the squash commit message and its verification gaps.

## Approval and attention labels

By default, you merge on GitHub or approve the agent's merge. An initial "Go"
does not grant that approval. Auto authorizes eligible merges; large or risky
changes still need your decision. Required GitHub approvals apply in both modes.
See [merge choices](working-with-shaka.md#choose-a-merge-policy).

[Attention labels](working-with-shaka.md#find-prs-waiting-on-you) identify PRs
that need an answer, merge approval, or a resumed chat. The handoff names who
checks later feedback and how to continue.

<a id="corrections-after-review"></a>
<a id="publish-work-while-a-base-repair-is-pending"></a>

## Return points

To [revise earlier guidance](working-with-shaka.md#revise-earlier-guidance-and-try-again),
ask for a return point. Recovery covers only preserved work.
After corrections, look for evidence covering the new commit. A draft blocked
by a base failure should name the failed check, comparison, and next action.

## Squash merge details

Compare GitHub's current commit with the agent's handoff. If they differ, return
to the agent. For a squash merge, copy the title and body from the ready
**Checkpoint**, or the separate squash-message comment when the checkpoint was
explicitly skipped.

### Merge queues

A queue takes no custom message. The checkpoint names the queue's message
setting. Shaka refuses a queue configured to copy the whole PR description into
history; choose **Default message** or **Pull request title** instead.

<a id="see-which-skills-contributed"></a>
<a id="see-what-people-said"></a>
<a id="revisit-a-merged-change"></a>

## Look up supporting detail

Expand **Shaka metrics** for [usage and cost](reference/usage-and-cost.md),
[timings](reference/timings.md), settings, and reported skills. **Human comments**
collects people's feedback and its status. Later comments appear after the next
refresh; public comments from untrusted accounts are linked without being read.

After merge, compare the recorded goal and evidence with what you learned in use.
Shaka does not prove every instruction was followed; see
[what is enforced](workflow.md#what-is-enforced).
