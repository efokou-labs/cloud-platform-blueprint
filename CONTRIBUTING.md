# Contributing

Open PRs against `main`. CI must pass `terraform fmt`, `validate`, tflint, and Checkov.

Do not apply staging or production from a laptop. kind (`make kind-up`) is the default cluster.
