# ADR 006 — App-owned ChatGPT plan connection

Status: accepted provider direction and safeguards, 2026-10-16; live capability
validation and production wiring remain incomplete.

## Context

The coach selected GPT-5.6 Terra with medium reasoning, paid through Sign in with
ChatGPT rather than an API key. PLAN 013 keeps the assistant replaceable and gives
it no Notes or library mutation powers. Authentication must not borrow the coding
agent's credentials or imply access to ChatGPT conversation history.

## Decision

Own the browser authorization, installation identifier and issued registration in
Gym Assistant. Keep credentials in macOS Keychain outside workspace snapshots.
Validate callback state, PKCE and signed identity claims before accepting identity;
check plan-usage permission separately. Serialize registration and token renewal
across processes. First prove authorization/model discovery with an isolated native
helper; leave the scratchpad on its fake provider until the adapter is validated.

Use only the exact approved model when it appears in the account-specific catalog.
The subsequent adapter uses public Responses HTTP streaming with `store: false`,
waits for completed inference and supplies conversation context explicitly. No
automatic inference retries, hidden model substitution, API-key fallback or credit
purchases. Initial trials allow ten synthetic inference attempts and 32,000 input
tokens each, without an output cap: the subscription route rejects
`max_output_tokens`. Short replies are a coaching preference, not a token guarantee.

## Consequences and alternatives

The native authorization helper adds no runtime dependency, but its protocol and
signature validation require dedicated tests. It initially retains one registration;
account switching, native sign-out and production account controls are not complete.
Unsupported identity-signature algorithms fail closed rather than bypassing checks.
The coach must authorize the app in the browser before account-specific behavior
can be verified. API-key billing and reusing Codex authentication were rejected for
this path. The separate Notes-plugin spike does not change this decision.

## Evidence

Seven synthetic security/loopback tests and all five repository verification stages
pass. This is not evidence of actual account eligibility or successful inference.
Official documentation checked on 2026-10-16:

- https://developers.openai.com/siwc/token-sharing-open-source/sign-in
- https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions
- https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations
