# 0007: Show companion skill results on the PR

Status: proposed; awaiting maintainer approval.
Date: 2026-11-09. Tracks [issue #1075](https://github.com/shakacode/shaka/issues/1075).

## Context

Some companion skills produce evidence a maintainer could check before merging:

- pstack's `/statechart` checks a TLA+ model and draws the flow.
- Formal verification skills report each property, its bounds, and any counterexample.
- A harness from `create-verification-skill` captures screenshots and logs.
- `interrogate` keeps findings that a run proves, each with the command that reproduces it.

A Shaka PR description has two places for that evidence today, and neither checks it:

- **Verification** holds one to three `checks`. Each one-line check needs a link or a code
  span (`IntentVerification::EVIDENCE`). Nothing compares the commit a line names with
  the head.
- **Skills used** gives each skill a one-line `contribution` (`SkillsUsed`). It records
  that a skill was applied, not what a run found.

[Companion skills](../../skills/shaka/references/companion-skills.md) already tells the
agent where such output goes: carry the command, commit, result, artifacts, and gaps
into Verification, put a diagram in a `sections` item, and put before and after evidence
in a `details` item. Those items are free-form, so Ruby checks none of the fields.

**Demand is unproven.** The issue says to build this once a real PR uses `/statechart`
or a verification harness, so the format follows real output. On 2026-11-09:

- No shakacode PR mentions `/statechart`.
- In a private shakacode repository, seven recent PRs mention `create-verification-skill`.
  Three of them report pstack skills in Skills used. None reports a harness run or
  another skill that produces results files.

**Overlap with #1071.** [Issue #1071](https://github.com/shakacode/shaka/issues/1071)
adds a doctor check for duplicate and broken skill installs. That check reads skill
folder names and links only. It resolves no pack or revision, so it offers nothing this
design could reuse. The two changes touch different files.

## Decisions

1. **Wait for real output before building.** Approving this ADR settles the design, not
   the timing. Build it after a PR in a Shaka-managed repository reports `/statechart`,
   a formal verification skill, or a harness run in Skills used, and its results do not
   fit three Verification lines and a `details` item. Until then, the existing
   companion-skills guidance stands, and no code changes.
2. **A separate list, joined to Skills used by skill.** Description content gains
   optional `companion_results`. Each entry describes one run with the fields
   companion-skills already asks the agent to carry:
   - `skill`: the `name` of a `skills_used` record.
   - `revision`: optional; required when Skills used lists that name at more than one
     revision.
   - `command`: the command the run used, written as a code span.
   - `checked`: one line on what the run checked.
   - `result`: one line on what it found.
   - `not_covered`: one line on what the run did not check, or `Nothing.`
   - `commit`: the full SHA the run used.
   - `artifacts`: a list of http or https links, possibly empty.

   An entry joins a skill, meaning a name at one revision, not a single Skills used row.
   Skills used keeps separate rows for the same skill in different phases, and all of
   them name the same skill. An entry normally omits `revision`, and the helper takes it
   from the matching rows. When Skills used lists the name at two revisions, the entry
   names its revision. The helper renders
   the list as one collapsed `Companion skill results` section, one entry per run. Each
   text field goes through the same `PublicationText` escaping that Skills used cells
   use, so text an agent copied from a skill's output cannot break the PR body.
3. **Ruby checks the shape and the commit, not the truth.** Publication refuses an entry
   in these cases:
   - its `skill`, with its `revision` when given, matches no Skills used record, or
     matches records at more than one revision;
   - `command` is not a code span;
   - `checked`, `result`, or `not_covered` is empty or more than one line;
   - `commit` is not a full SHA.

   Because `command` is a code span, every entry meets the test
   `IntentVerification::EVIDENCE` applies to each Verification check.

   An entry whose commit is not the head renders with a visible `stale` label. Ruby does
   not refuse it. Rerunning a model check or harness can be expensive, and a reviewer can
   judge whether a later commit touched what the run checked.
4. **The run's record has one home.** Once the field ships, a companion run's full
   record goes in `companion_results`, in place of the before and after `details` item
   companion-skills prescribes today. A result that bears on the merge also gets one
   Verification line that summarizes it, as today. That line stays agent-written and
   unchecked: it carries no commit field, so no `stale` label reaches it. The entry it
   summarizes sits one click below and shows the label, which is where a reviewer
   checks currency. The helper does not copy entries into Verification, because the
   limit of three checks is what keeps that section readable. A Mermaid diagram stays in
   a `sections` item, and the entry links it.
5. **No new uploader.** `artifacts` accepts links only. A screenshot or diagram goes up
   through the existing [UI evidence publication](../../skills/shaka/references/ui-verification.md#publish-ui-evidence)
   path, and the entry links the uploaded file.
6. **One instruction change.** When the code ships, the "Consume verification evidence"
   paragraph of companion-skills gains one sentence pointing the agent to
   `companion_results`. The before and after sentence in its PR-body advice then points
   there too, so the guidance names one place. `workflow.yml` is unchanged, because
   the paragraph loads only when a task uses a companion skill.

## Alternatives considered

- **No new field (keep `details` and Verification).** This costs nothing. Ruby can
  check neither the commit nor the link, so a stale or unsupported result can pass as
  current. It stays the answer until decision 1's
  trigger arrives.
- **Add results to Skills used records.** This uses one list, but a record describes a
  skill and a result describes one run. Two runs at different commits would need two rows
  for the same skill, and the Skills used table would grow columns most rows leave empty.
- **Refuse a name Skills used lists at two revisions.** This is simpler than an
  optional `revision`, but it would forbid reporting the same skill at two revisions, which
  Skills used allows today.
- **Refuse stale entries.** This is stricter, but it forces a rerun after every
  unrelated commit, or pushes agents back to free-form `details`, where nothing is
  checked.
- **Wait for [#1026](https://github.com/shakacode/shaka/issues/1026).** #1026 would bind a
  separately run harness to its commit through `evidence run`. That is stronger
  evidence, but only for a harness the repository runs through a fixed entry point
  beside `validate`. A TLA+ check or an `interrogate` run is a one-off command outside
  that entry point, so the `stale` label serves cases #1026 does not cover. The two can ship in either order.

## Consequences

- One optional content key, one renderer beside `SkillsUsed`, and behavioral tests for
  each refusal and the `stale` label. No setting, so no `defaults.yml` entry or settings
  migration.
- Older content files publish unchanged. Description content has no unknown-key refusal
  at the top level today, so an older installation that receives `companion_results`
  drops it.
- Revision stays agent-reported. [#1027](https://github.com/shakacode/shaka/issues/1027)
  remains the place to make pack and revision countable.
- The commit check compares text with the head. It does not prove the run happened on
  that commit.

## Delivery

This ADR merges first as the design record. Once decision 1's trigger arrives, one
implementation PR delivers decisions 2 to 6, and its description links the triggering PR.
