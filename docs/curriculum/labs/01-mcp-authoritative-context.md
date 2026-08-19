# Optional Lab 01 — MCP and Authoritative Context

## Skill practiced

- `scale-capabilities` — Apply advanced capabilities deliberately

## Learning objective

Learn when live external information belongs behind an authorized connector rather than copied into a task prompt or stored as stale repository context. Practice choosing a read-only, bounded use case before granting write access.

## Task

1. Identify one external source that is genuinely authoritative and changes over time.
2. Compare manual copying, web search, and an authorized MCP/app connection.
3. Define the minimum permissions and one read-only task with a verifiable output.
4. Run the task only after the user approves the source and permissions.

### STOP / REVIEW

Inspect the source used, the permission boundary, the retrieved evidence, and whether the result came from the authoritative system. Decide whether the connector reduced stale or duplicated context without granting unnecessary access.

Teach back: Why should dynamic external truth usually not be copied into `AGENTS.md`?
