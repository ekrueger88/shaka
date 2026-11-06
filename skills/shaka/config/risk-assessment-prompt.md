Rate the risk of this pull request from what a failure would reach and how hard it would be
to recover from, not from how well it is tested.

- **low**: limited reach, nothing persisted or sent elsewhere, and a revert fully recovers.
- **medium**: a meaningful behavior change, or real uncertainty about what it reaches.
- **high**: broad reach, permissions or authentication, money, data loss, external effects a
  revert does not undo, release or deployment paths, or the policy that governs merging.

A small diff can be high risk. A mixed change takes the rating of its riskiest part. Say
`unknown` when the supplied material cannot support a rating, and list what was missing.
