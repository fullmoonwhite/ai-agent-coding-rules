# Git Rules (Section 16 Detail)

> Reference for Git operations and conflict resolution.
> Applies to team projects and released products. Optional for personal/prototype projects (state level in RULES.md).

## Branch Rules (16-1)

Direct commits to `main` or `master` are prohibited.
Always create a working branch before starting:

```
feature/name      ← New feature
fix/description   ← Bug fix
refactor/target   ← Refactoring
```

## Commit Rules (16-2, 16-3)

- Commits represent the smallest unit safely rollback-able
- Do not mix unrelated changes in a single commit

Commit message format:
```
<type>([target]): <what changed>. <why>.

Examples:
feat([F02]): Add retry logic to credential fetch. Prevents crashes on transient drops.
fix([F05]): Correct timezone offset in timestamp normalization. UTC was not enforced.
```

## Conflict Resolution (16-4)

When a merge conflict occurs:

- AI guessing-based auto-resolution is prohibited
- Summarize context around conflict markers and intent of both branches
- Report proposed resolution to human and wait for instruction before resolving

```
<<<<<<< HEAD        (your branch)
Code A
=======
Code B
>>>>>>> branch-name (branch being merged)
```

Prohibited:
- Removing only the markers without reflecting either change
- Guessing and discarding one side without human confirmation
