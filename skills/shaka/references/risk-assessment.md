# Risk assessment

Run this only when the user asks to rate a PR's risk.

1. Resolve the trusted default-branch commit as for any task and run `seam check --root ROOT --ref SHA`.
   Pass that full SHA as `--ref`. Never pass the PR head or a candidate branch: `--ref` selects the
   settings and prompt that run.
2. Run `shaka risk assess --root ROOT --base BASE_SHA --head HEAD_SHA --ref SHA`, adding
   `--description-file PATH` for the PR description. The checkout must be clean at `HEAD_SHA`.
3. Report `status`. For `completed`, give `evidence.rating`, its reasons and unknowns, and
   `decision`. Say that the decision is a shadow preview and changes no merge. For `disabled`,
   say `risk_assessment.enabled` is false. For `not_completed`, give the reason; there is no rating.
