---
description: Stress-test a plan or design by interviewing the user one decision at a time until the decision tree is resolved. Use before planning a non-trivial task, or when the user says "grill me", "stress-test this plan", or "poke holes in my design".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: [what to grill — defaults to the current task/plan]
---

# Grill — `$ARGUMENTS`

Interview the user relentlessly about every aspect of `$ARGUMENTS` (or the current task, if no argument) until you reach a **shared understanding**. The goal: surface and resolve every consequential decision *before* a plan is written, so `plan.md` is built on settled ground instead of the planner's guesses.

> Adapted from Matt Pocock's `grill-me` skill (github.com/mattpocock/skills, MIT).

## How to grill

- **One question at a time.** Ask, wait for the answer, then ask the next. Never batch — batching lets vague answers slide past.
- **Walk the decision tree.** Resolve in dependency order: settle the decision that unblocks the most others next. When an answer opens new branches, follow them before moving on.
- **Recommend an answer to every question.** Don't just ask — state what you'd choose and why. The user should be reacting to a proposal, not starting from a blank page.
- **Explore before asking.** If a question can be answered by reading the codebase, answer it yourself with Read/Grep/Glob and confirm — don't make the user recall what you can look up. Never ask what you can find out.
- **Chase the vague.** When the user uses an overloaded or fuzzy term, stop and pin it down. Ambiguity here becomes scope creep later.
- **Test with concrete scenarios.** Push each decision against a specific edge case ("what happens when X is empty, fails, or runs twice?"). Abstract agreement hides real disagreement.

## Capture decisions as they settle

This is what makes grilling part of the harness rather than a throwaway chat: **decisions are durable state, not conversation.** As each decision crystallizes, record it in `.claude/state/state.md` under a `## Resolved decisions` section (create the section if it's missing):

```
## Resolved decisions
- <decision>: <what was chosen> — <one-line reason>
```

If `.claude/state/` doesn't exist yet (you're grilling before `/mg-harness:start-work`), hold the decisions in the conversation and write them to `state.md` as soon as the state directory is bootstrapped.

## When to stop

Stop when no unresolved branch remains that would change the plan — i.e. a competent engineer could now write `plan.md` without guessing. Don't pad with low-stakes questions; grilling is for decisions that actually matter. For a genuinely trivial, unambiguous task, say so and skip straight to planning.

## Hand off to the plan

Once the tree is resolved, the `## Resolved decisions` in `state.md` are the planner's input. Continue `/mg-harness:start-work`, or run `/mg-harness:plan` — the **planner** subagent reads `state.md` (including `## Resolved decisions`) and bakes them into `plan.md`.
