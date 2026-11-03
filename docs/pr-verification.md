# PR verification

![Two independently supported inspection lenses examine the same component on a workbench.](img/independent-review.webp)

A Shaka PR tells you what changed, how it was checked, and what is left for you to
decide. The top of the description is usually enough to decide; everything below it
is evidence to open when something looks off.

You decide one of three things: merge the commit the agent handed you, ask for a
revision, or answer a question the agent could not settle. Tell the agent in its chat;
it also reads review comments on the PR from accounts your repository trusts.

Your repository chooses who merges. Under **Ask**, the default, the agent stops with a
handoff: a chat message naming the verified commit, which waits for your decision.
Under **Auto**, it merges eligible work itself. The task owner, the person or
coordinating agent running the task, makes the PR's recommendation.

<a id="read-a-pr-for-your-decision"></a>
<a id="answers-for-your-merge-decision"></a>

## Answers for your next decision

While the agent is waiting on you, the description opens with **Decisions to make**.
Otherwise it opens with the task owner's recommendation, such as
**Recommendation: Merge**, beside links to the code walkthrough, the code review, and
the checkpoint.

![PR description opening with Recommendation: Merge, a short Next action, and links to Code Walkthrough, Code Review, and Checkpoint.](img/pr-recommendation.webp)

This capture of [PR #527](https://github.com/shakacode/shaka/pull/527) is from
October 14, 2026. It shows the layout; it does not approve any other commit.

| Your question | Where to look |
| --- | --- |
| What is it for, and what does it leave out? | **Intent**: the problem, the task it came from, the scope, anything deliberately left out, and why the change is safe. A bug fix names its **Root cause**, or says it was not found. |
| What should I read myself? | **Human review** under Intent, from 1 (the description is enough) to 5 (read the riskiest files closely). The agent picks the rating, and **Closer reading** lists files that need more care than the rest. Shaka refuses a rating below the minimum the changed files set; each repository chooses those minimums with [`pr_description.human_review_floors`](settings.md#pr_descriptionhuman_review_floors). |
| How was it checked? | **Verification**. Its first line, written by Shaka from the recorded results, says whether validation passed and who reviewed this commit. It stays unfolded when something is missing, and a **Setup gaps** line names each configured reviewer that did not finish. Up to three checks follow, then **Not verified** for any claim left unproven. |
| Why this approach? | The [code walkthrough](#read-the-walkthrough). |
| What did people say? | [**Human comments**](#see-what-people-said). |
| What do I need to do? | Open decisions, and **Steps besides merging** with who does each and when. |

Further down, **Skills used** is the agent's account of the skills it applied. Shaka
checks its format, not that it is complete or that a listed skill was followed. Usage
and timing sections follow. Validation timing names the kind of machine it ran on;
only the CPU model, core and memory counts, load, and your machine alias are published.

<a id="when-a-diagram-helps"></a>

## Read the walkthrough

The walkthrough is a GitHub review comment that explains the change in reading order,
with each step linked to its lines. It covers the alternatives the agent rejected,
who a failure would reach, and what a revert would not undo, such as emails already
sent or data already rewritten. It may add a few notes on the diff, like "Start here"
or "Skim: this file moves code unchanged," and one small diagram when the change
crosses several components.

Shaka does not check any of this against the code. A walkthrough that says nothing
about stored data is not evidence that a revert is enough.

<a id="show-what-a-person-will-see"></a>

## Check the latest changes

Evidence counts only for the commit it ran on, so check that tests, reviews, and
captures name the commit in the agent's handoff. Earlier evidence carries over only
where Shaka can show nothing relevant changed, such as a clean merge of the base or a
prose-only edit.

Good checks show they can catch the problem: a test should fail without the fix and
pass with it. For a visible change, expect desktop and mobile screenshots of the tested
commit, annotated where something changed, and a short recording when timing matters.
For a change that could make pages faster or slower, expect a comparison of the base
and the change with a verdict: improvement, wash, regression, or ambiguous. When
something could not be captured or measured, the PR says so.

A check that also fails on the base branch can leave the PR a blocked draft until the
repair lands or you tell the agent you accept that failure for this task. Accepting it
does not waive security or trust failures, required checks, or branch protection.

Spend your own review time on decisions that need your knowledge. An agent can check a
billing calculation; someone who knows the contract has to decide whether it is the
right billing rule.

## See what people said

Agent posts can far outnumber people's comments: on one Shaka PR, 5 of 52 comments
came from a person. **Human comments** lists each of those, with its reply and whether
it is still open.

| From | Said | Response | Status |
| --- | --- | --- | --- |
| **Reviewer** maria | Finds the tester terms unclear; suggests template notation | — | **Open** |
| sam | “you mean chat, not owner.” | “Changed the guide to use chat throughout…” | Resolved |

**Said** quotes a short comment in the person's own words; text without quotation marks
is the agent's one-line summary. **Status** is GitHub's resolved state for an inline
thread and the verdict for a review. Any other comment stays open until an agent reply
links to it.

A comment without the agent's 🤖 line counts as a person's. On a public repository, a
comment from an account the repository does not trust is listed as **Unverified**,
because the agent does not read it. Instructions you give in chat are not listed. To
hide the list or change its length, see
[`pr_description.show_human_comments`](settings.md#pr_descriptionshow_human_comments).

<a id="reconsider-the-finished-result"></a>
<a id="decision-checkpoint"></a>
<a id="evaluation-checkpoint"></a>

## Checkpoint

Before the agent calls a PR ready, a reviewer model checks whether the finished result
solves the original problem and earns its maintenance cost, and whether the
verification proves what the intent claims. The task owner then recommends what to do.
Open **Checkpoint** before acting on a recommendation.

![Checkpoint for commit 1198b62 showing Recommendation: Merge, the next action, Reviewer verdict: Proceed, no unresolved concerns, and a copyable squash commit title.](img/pr-checkpoint.webp)

The reviewer concludes **Proceed**, **Simplify/reframe**, or **Do not merge**, and
rates the verification **Adequate**, **Adequate, with gaps the reviewer judged
acceptable**, **Inadequate**, or **Cannot judge**. Under Ask, the last two are
information for your decision. Under Auto, they stop the agent's merge until you
approve that commit.

The owner then recommends **Merge**, **Merge after maintainer decision**, **Revise
before merge**, **Reconsider approach**, or **Do not merge**. When the agent disputes a
concern or a new question comes up, it recommends **Merge after maintainer decision**
and asks you under **Decisions to make**. A recommendation becomes a **Recorded
decision** once you accept it or the agent acts under authority you already gave.

Unresolved concerns hold the agent's merge even when checks pass. To accept one after a
**Proceed**, tell the agent, for example: "I accept the unknown-frequency concern;
merge as is." It lists your decision under **Concerns recorded as accepted by the
maintainer**. Shaka checks that each concern has a decision, not who made it, so read
that list before you merge.

A ready checkpoint follows the walkthrough and screenshots for the same commit and
carries the squash commit message. Each new commit needs a new checkpoint. To skip it
for a small fix after review, tell your agent "Skip the checkpoint for this correction;
the outcome is unchanged," and the PR shows that no checkpoint ran for that commit.
Repositories tune it with the [checkpoint settings](settings.md#checkpoint).

## Return points

A return point saves guidance you gave during a task, such as your first request or a
later change of direction, with the code revision it applies to. The description lists
them as C1, C2, and so on. When a direction does not work out, you can restart from
one; see
[revise earlier guidance and try again](working-with-shaka.md#revise-earlier-guidance-and-try-again).

## Approval and attention labels

To find PRs waiting on you, use the
[attention-label searches](working-with-shaka.md#find-prs-waiting-on-you). The agent
manages the labels as it works.

![While the agent works, a PR has no attention label. The agent sets awaiting-answer for a decision, awaiting-merge-approval when the PR is ready to merge, and awaiting-resume when it paused and nothing will wake it.](img/attention-labels.svg)

Under **Ask**, the agent hands you a verified commit and waits. Tell it in chat to
merge that commit, for example "Merge the commit in your handoff," or merge it yourself
on GitHub. Saying "Go" at the start does not grant this. An **Approve** review also
counts when it comes from a login you named to the agent as a merge approver for this
task. When the repository requires a GitHub approval, an eligible reviewer still has to
approve there; a chat instruction does not count for it. The agent cannot set
`awaiting-merge-approval` while the local review has open findings. It also needs a
published review of the commit, unless it skipped review on purpose with a stated
reason or the repository sets `review.required: none`.

Under **Auto**, the agent merges eligible work itself. Every check on the commit has to
pass, not only the required ones, and the agent hands the PR back to you when one fails.
A check that has not started when the agent merges is not seen, so make a check required
if it must always gate the merge. PRs it merged carry the `auto-merged` label, except
one added to a merge queue or one GitHub refused to label; the agent's report says so.

If GitHub needs the branch updated, the agent rebases and checks the new commit; your
approval carries forward only when the behavior is unchanged. Both modes keep
repository protection and required approvals.

## Squash merge details

When you merge on GitHub, first check that its current commit matches the agent's
handoff; if it differs, go back to the agent. For a squash merge, copy the title and
body from the ready **Checkpoint**, or from the agent's squash-message comment when the
checkpoint was skipped. GitHub prefills the boxes with every commit title unless
**Settings → General → Pull Requests → Allow squash merging** is set to **Pull request
title**.

### Merge queues

A merge queue takes no message, so the checkpoint tells you to add the PR to the queue
and says what the queue will write. A queue set to **Pull request title and
description** would copy Shaka's whole description into Git history; `shaka doctor`
flags it and the agent will not merge through it. Choose **Default message** or **Pull
request title** instead.

## Revisit a merged change

The same record helps after merging: was the approach reasonable given what was known
then, and which commit was tested and reviewed, with what gaps reported? Missing
evidence leaves a question open; it does not show that a step passed or failed. Shaka
does not prove that every instruction was followed. See
[what is enforced](workflow.md#what-is-enforced).
