# Branch Guard for Agents

## What

Add a pre-flight check to the plan, build, and hack agent prompts: if the current branch is `main`, ask the human whether they should be on a feature branch before proceeding.

## Why

It's easy to start a session and forget to branch. Agents shouldn't silently commit to main when the human probably intended to work on a branch. A quick check at the start prevents messy resets later.

## Status

TODO — not yet planned in detail.
