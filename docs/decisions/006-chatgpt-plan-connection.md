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
purchases. Initial trials allow ten synthetic inference attempts and 100,000 UTF-8
bytes of total request text each, without an output cap: the subscription route rejects
`max_output_tokens`. Short replies are a coaching preference, not a token guarantee.

## Consequences and alternatives

On 2026-10-17 the coach approved regular use after the native synthetic pass:
user-submitted requests only, the same 100,000-byte text limit, no lifetime request
count cap, no automatic retries/background inference, and unchanged account billing
settings. `ChatGPTUsagePolicy.regularUse` explicitly selects this policy; synthetic
tools retain the default ten-attempt policy. Existing trial history is preserved,
not reset or repurposed. This approval does not authorize agent-driven unbounded
testing, credit purchases, or model/billing fallbacks. Production wiring remains
separate implementation work.

The native authorization helper adds no runtime dependency, but its protocol and
signature validation require dedicated tests. It initially retains one registration;
account switching and production account controls are not complete. Native trial
sign-out is implemented but not yet verified in live use.
Unsupported identity-signature algorithms fail closed rather than bypassing checks.
The coach must authorize the app in the browser before account-specific behavior
can be verified. API-key billing and reusing Codex authentication were rejected for
this path. The separate Notes-plugin spike does not change this decision.

## Evidence

Seven synthetic security/loopback tests and all five initial repository verification
stages passed. Subsequent browser authorization and model discovery succeeded.
Exact token-count preflight returned HTTP 401; the coach approved replacing the
32,000-input-token proposal with the stated local byte limit. Six additional contract
tests pass. Three synthetic submissions yielded no completed reply; the latest reached
the event stream and reported subscription usage unavailable/limited. Successful
inference remains unverified. A fourth attempt after the coach confirmed enabled
app access and remaining allowance returned HTTP 200, then a different generic
failure; its exact cause was not retained. Diagnostics now distinguish usage-limit,
usage-check unavailability, allowlisted provider codes and local format rejection.
No further request or settings change was made at this checkpoint.
A subsequent separately authorized fifth attempt returned HTTP 200 and failed local
response-stream format validation before completed-reply decoding. It does not
establish successful generation; no further request or account change followed.
Opt-in native trial wiring and sign-out exist, but
production composition remains offline.
Subsequent evidence: attempt 6 isolated empty terminal text. Retaining completed
streamed output items, while still requiring successful response completion, enabled
usable replies on attempts 7–9. The second turn recognized the updated B1 but asked
redundantly for that same context; conversation-quality acceptance remains open.
Nine of ten attempts are used. No billing settings or real Notes were changed.
The coach subsequently marked the native synthetic live test passed. This accepts
the bounded edit-and-question interaction; production profile/composition and a
post-trial usage policy remain pending. The ten-request ledger is not reset.
Official documentation checked on 2026-10-16:

- https://developers.openai.com/siwc/token-sharing-open-source/sign-in
- https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions
- https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations
- https://developers.openai.com/siwc/token-sharing-open-source/errors-and-recovery
