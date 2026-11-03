# What to expect from Shaka

<a id="pilot-status-and-limitations"></a>
<a id="what-the-pilot-has-established"></a>

Use Shaka with your repository's checks and review rules. This guide explains
setup choices, what happens when verification is incomplete, and how to resume
work or recover from access problems. For installation and everyday prompts,
see [Start here](getting-started.md) and [Working with Shaka](working-with-shaka.md).

## Choose how to start

Give Shaka a task. If setup is missing, it asks whether you want individual
or team settings. Individual setup avoids a team setup PR; shared
[repository setup](configure-repository.md) gives the team one configuration.
Setup alone does not authorize merging.

<a id="private-trials-available-tools-incomplete-guided-experience"></a>
<a id="individual-trials-available-tools-incomplete-guided-experience"></a>

### Individual setup

```text
$shaka <task or issue link>
Set up Shaka just for me. Go.
```

Individual settings remain outside commits in a repository without team setup.
They cover the same choices as shared settings: reviewers, custom code-review
instructions, checkpoint choices, writing limits, opening instructions, and WIP preferences.
When a later task starts in a new worktree, the agent copies your individual
settings into it. Edits you made after setup come along while the earlier
checkout still exists. The agent should find your existing commands and go on
with your task.

To try repository settings for one task before adopting them, use a
[settings preview](settings.md#preview-settings-before-adopting-them). Trying an
unmerged change to Shaka itself is different: see [try a Shaka PR](trying-pr-versions.md).

## Run an ordinary task

If a project has no usable checks, decide with the agent whether to add them or
report limited verification. Routine tasks should not require editing configuration
or PATH by hand.

## Multiple reviewers per commit

Start with one reviewer. For broader coverage, configure
[multiple reviewers](settings.md#reviewlocal_review_count), such as Claude, Codex,
or DeepSeek. Additional reviews cost more. The agent combines reviews before
deciding how to respond, so overlapping findings are handled once.

## Understand the PR's settings and evidence

Expand the settings block to see whether the validation and review results match
the candidate commit. One row per result shows the settings it used and what it
ran with, such as the validation command or the reviewer.
[Which settings apply](settings.md#which-settings-apply) explains where settings
come from. When the settings are not the default branch's, as in an individual
setup or a settings PR tried on one task, the block also lists every setting.
A settings block describes the run; it does not prove tests or review happened.

| What changes or fails | What you should see |
| --- | --- |
| Validation fails | The agent fixes the problem and reruns the affected checks. The PR stays unverified until they complete. |
| The commit changes after tests or review | The agent reruns whatever the earlier results no longer cover. |
| Validation or review settings change | Earlier results may no longer count. Editing your validate script, for example, reruns both validation and review. |
| Shaka updates during a task | Earlier validation and review still count unless the update changes the Shaka code that runs them or checks their results. A new Shaka version, or a change to how review comments are displayed, also means a rerun. |
| The description is reworded for the same commit | Verified results stay, marked as not rechecked, except in a pull request from a fork, whose author can edit the description. |
| A result is missing, a reviewer is unavailable, or CI is still running | The PR shows the gap. Missing or stale evidence cannot satisfy a required gate. |
| An optional reviewer is pending | The PR says so and follows your [waiting choice](settings.md#reviewci_review_wait); required gates still apply. |

Public PRs must contain no private task content, operational settings, or
private-content fingerprints. Expandable details are still public. WIP Details
shows the checkout path and a link back to the chat by default; the
[WIP setting](settings.md#wipinclude_checkout_path) hides the checkout path.
Shaka redacts some settings values, but nothing scans the rest of a publication
for private content; the agent has to inspect it.

## Decide whether to merge

See [merge choices](working-with-shaka.md#choose-a-merge-policy) for Ask, Auto,
and required approvals. An Auto choice lasts for its task in the chat where you
made it. A fresh chat treats it as a record, not permission, and holds at Ask.
To keep Auto, say so again in the new chat.

## Resume or change your checkout

| Scenario | What to do and what can be recovered |
| --- | --- |
| Resume the same task with a PR | Open WIP Details and return to the chat that owns the PR, or give a new chat the PR URL after that chat stops. The agent refreshes the PR's state and evidence before continuing. |
| Resume before a PR exists | Give a new chat the task and checkout, plus the branch, head, and paths of saved validation and review results if you have them. Without a PR there is no record to recover missing choices from, and the agent reruns any check whose result is missing before it publishes. |
| Use a linked worktree with individual settings | Each worktree keeps its own copy, backed up in the repository's shared Git directory, so your coding agent must be allowed to write there. |
| An outside pull adds team settings | The default branch's team settings govern. Compare them with your saved individual settings; do not overwrite them with the local copy. |
| Clean or delete a worktree with individual settings | Settings captured earlier can be restored outside a checkout for comparison. Edits made since the last capture, or a deleted shared Git directory, cannot be recovered. |

Use the [resume guide](working-with-shaka.md#resume-unfinished-work).
Recovery copies protect captured settings, not feature changes or the agent
conversation. To go back to an earlier point in a task, use a
[return point](pr-verification.md#return-points); it can restore only the work
state the agent recorded.

## When the coding agent denies access

Expect the failed operation and path to be reported, with no claim of completion.
Use the host's supported permission mechanism for the necessary operation, then
retry and verify it. Shaka does not create a sandbox or grant filesystem access.

Host permissions can allow project edits while denying the protected Git writes
individual setup needs, so a sandbox that allows ordinary edits can still block
individual setup.
