# Structural Validation Handoff

## Purpose

This reference supports source-evidence review of rules `SKILL-048` through `SKILL-056`. Source inspection can establish the needed facts directly; a general SCL analyzer is not a prerequisite.

It is not a parser specification or an analyzer implementation. Optional tooling may assist navigation and evidence collection, but regular expressions, guessed call ownership, or inferred functional intent do not replace semantic review. The diagnostic identifiers below are review vocabulary, not a claim that an implemented analyzer emits them.

## Evidence Model

Retain enough evidence to support a consequential validation finding:

- source artifact and precise source location;
- the applicable Specified, Observed, Proposed characterization, or Unresolved evidence classification from the skill entrypoint;
- the source and dependency closure used to establish the fact;
- explicit assumptions and unresolved blockers for derived conclusions;
- stable identities for blocks, instances, variables, symbols, and call sites.

Keep observed structure separate from accepted intent and ownership. Apply the entrypoint's intent-first review before classifying a scenario: a deliberate invalid stimulus or a protected source-obvious invariant is not a defect by itself. Support a confirmed finding with its actual contradiction and consequence; keep optional optimizations separate. This does not waive the framework or ownership requirements below. Missing evidence remains Unresolved, not a guessed pass or failure. Use proportional prose or a compact table; no fixed artifact schema or numerical confidence score is required.

## Relevant Source Evidence

### Block And Call Structure

- Block kind (`FB` or `FC`), declaration sections, local instances, static data, constants, and field attributes.
- Resolved call targets and instance identities, including calls made through fixed arrays of instances.
- Every call site's lexical and control-flow ancestors, loop bounds, reachability, and execution multiplicity per owner invocation.
- Source order and control-flow order for input assignments, calls, output captures, prior-cycle memorization, and command cleanup.
- Call ownership classified as `test-case`, `external-owner`, or `unknown` from confirmed integration data.
- Stateful behavior classified as `stateful`, `stateless`, or `unknown` from source and resolved dependencies; block kind alone is insufficient to confirm functional statefulness.

### Reset And Ownership Structure

- Reset, Abort, active, and readiness conditions with resolved framework state symbols.
- Assignments applied to owned command inputs and configuration before each owned call.
- Nested lifecycle/status reads used to establish the configured reset baseline.
- Direct and indirect global reads and writes, including resource, reservation, and producer-owned state.
- Confirmed resource owner and release protocol when supplied by project metadata or user input.

### Numeric And Declaration Structure

Use the included general source-authoring and technical-review resources for types/ranges, declarations, source contexts, attributes and native-value evidence. Here retain their connection to accepted stimulus/Expected meanings, framework constants and direct state-offset relationships. A body-only comparison or a permitted framework naming exception does not establish preserved values or supported source context. Do not recreate a general type-checking or attribute policy in these UnitTest diagnostics.

### Orchestration And Timing Structure

- Selected Serial, Parallel, or ParallelSlots Orchestrator and the complete child set.
- Slot assignment expressions, resolved slot values, continuous bounds, and assignment multiplicity.
- Confirmed ordering, independence, and exclusive-resource facts supplied as test intent or ownership metadata.
- Normal, Reset, Abort, and Preparation paths for each child and stateful resource.
- Deterministic cycle bounds, timers, configured durations, nested timeout values, capacity-wait conditions, and unresolved dynamic bounds.
- Parent-child dependency graph and execution aggregation: serial sum, parallel maximum, or sum of the longest child bound in each sequential ParallelSlots slot.

## Detection And Diagnostic Requirements

Apply the diagnostics below to the normal call arrangement. Where a specific testability exception has been explicitly examined and accepted under the Authoring method, assess only that approved intervention against its actual purpose and call/sample trace; do not generalize the approval. Keep its unaffected framework calls and monitoring subject to the normal rules. Distinguish actual multiple execution in one invocation from mutually exclusive call sites distributed across branches; the latter are conditional invocation structure even if every invocation reaches one branch.

| Diagnostic | Rule | Detection | Severity | Actionable message requirement |
|---|---|---|---|---|
| `S7UT-AUTH-048-MISSING` | `SKILL-048` | A confirmed Test Case-owned stateful FB instance has no reachable call on an owner invocation. | error | Identify the instance and missing invocation path; require one unconditional cyclic call. |
| `S7UT-AUTH-048-CONDITIONAL` | `SKILL-048` | Calls for the same owned stateful FB are controlled by lifecycle/scenario branches or spread across mutually exclusive IF/CASE paths instead of one central unconditional site. | error | Identify the branches; consolidate normal invocation while retaining conditional stimulus, or identify the specific accepted testability exception. |
| `S7UT-AUTH-048-MULTIPLE` | `SKILL-048` | More than one call can execute for the same owned instance in one owner invocation. | error | List competing call sites and consolidate them into one call. |
| `S7UT-AUTH-049-ORDER` | `SKILL-049` | Confirmed command neutralization, current stimulus, call, and output capture are not ordered in that sequence. | error | Report the first invalid ordering edge and the required order. |
| `S7UT-AUTH-050-BASELINE` | `SKILL-050` | Reset can be released or readiness asserted before every confirmed nested baseline is reached. | error | Name the missing baseline and the readiness/reset expression that bypasses it. |
| `S7UT-AUTH-050-CONFIG` | `SKILL-050` | A confirmed invalid reset configuration can reach the owned stateful call before its reset baseline. | error | Identify the invalid assignment and require valid reset configuration until baseline completion. |
| `S7UT-AUTH-051-OWNER` | `SKILL-051` | A Test Case directly writes confirmed shared or producer-owned state without the owner release protocol. | error | Identify the write, confirmed owner, and required protocol or Preparation boundary. |
| `S7UT-AUTH-052-SPLIT` | `SKILL-052` | A mode or scenario-step controller appears to multiplex potentially independent stateful scenarios. | review | Show the controller and reset boundaries; request confirmation of one cohesive temporal scenario or split Test Cases. |
| `S7UT-AUTH-053-NUMBER` | `SKILL-053` | A semantically relevant number lacks a justified name or a representation preserving its required value distinction. | warning | Identify the intended value/precision, source context and missing evidence; do not silently change Expected or widen tolerance. |
| `S7UT-AUTH-054-TIMEOUT` | `SKILL-054` | A timeout is non-positive, unsupported by child-path evidence, or can preempt a valid child timeout path. | error | Report the path, available bounds, aggregation method, overhead, and violated hierarchy. |
| `S7UT-AUTH-054-UNKNOWN` | `SKILL-054` | Required external source, dynamic duration, analyzer dependency, or PLC-cycle bound is unresolved. | clarification | List the missing evidence and ask the user for the maximum duration or configured timeout; do not propose an invented value. |
| `S7UT-AUTH-055-PATTERN` | `SKILL-055` | The selected Orchestrator conflicts with confirmed ordering, independence, slot, or resource-ownership facts. | error | State the conflicting fact and the compatible execution pattern. |
| `S7UT-AUTH-055-SLOT` | `SKILL-055` | A child has no slot, multiple slots, a non-positive slot, a gap exists, or exclusive-resource users share a slot. | error | Identify children, slots, bounds, and the conflicting resource. |
| `S7UT-AUTH-056-CONSTANT` | `SKILL-056` | A constant uses an unsupported declaration context/value, or a CASE label is an unsupported expression. | error | Identify the exact context and use the styleguide's supported representation; preserve valid executable expressions and framework relationships. |

When call ownership, statefulness, command semantics, reset validity, baseline meaning, scenario cohesion, resource ownership, or timing bounds are unknown, diagnostics dependent on those facts shall be `clarification` or `review`, not an error.

## Positive And Negative Test Vectors

| Vector | Input structure | Expected result |
|---|---|---|
| `SV-P01` | One confirmed owned stateful FB call outside conditional branches; neutral inputs, stimulus, call, then capture. | No `048` or `049` finding. |
| `SV-N01` | The owned stateful FB is called only in Running, or separate calls are distributed across mutually exclusive Reset/Running branches. | `S7UT-AUTH-048-CONDITIONAL`; mutually exclusive branches alone do not establish `048-MULTIPLE`. |
| `SV-N02` | The same owned stateful FB instance has an unconditional call and an additional conditional call reachable in the same Test Case invocation. | `S7UT-AUTH-048-MULTIPLE`. |
| `SV-P02` | A fixed loop unconditionally calls every member of a fixed owned instance array exactly once. | No `048` finding. |
| `SV-P03` | A cyclic stateful DUT is confirmed as externally owned and the Test Case only drives stimulus and reads feedback. | No `048` finding and no generated second DUT call. |
| `SV-P04` | A stateless FC is called conditionally according to supplied test intent. | No `048` finding. |
| `SV-N03` | A confirmed Start input is not neutralized before current stimulus, or capture precedes the owned call. | `S7UT-AUTH-049-ORDER`. |
| `SV-N04` | Readiness depends only on the enclosing Reset state while a nested framework fixture whose required baseline is Idle and Ready has not reached that baseline. | `S7UT-AUTH-050-BASELINE`; do not impose this framework baseline on a DUT whose defined Reset target is Idle without Ready. |
| `SV-N05` | A non-owner Test Case clears a confirmed producer-owned reservation directly. | `S7UT-AUTH-051-OWNER`. |
| `SV-N06` | A numeric scenario-step controller contains unrelated stimulus and reset branches. | `S7UT-AUTH-052-SPLIT` review, pending intent confirmation. |
| `SV-P05` | An executable condition compares a Multi-State value with `UnitTest.State.Running + 1`; CASE labels and declarations use their separately supported forms. | No `053` warning. |
| `SV-N07` | A raw numeric timeout is assigned where a named configuration value is available. | `S7UT-AUTH-053-NUMBER`. |
| `SV-P06` | Serial parent timeout uses the sum of bounded child paths plus explicit overhead. | No `054` finding. |
| `SV-P07` | ParallelSlots parent timeout sums the longest bounded child path in every sequential slot plus overhead. | No `054` finding. |
| `SV-N08` | An external resource has no source, analyzer evidence, configured bound, or supplied maximum duration. | `S7UT-AUTH-054-UNKNOWN`; user clarification required. |
| `SV-N09` | Parallel is selected although two children have a confirmed exclusive shared resource. | `S7UT-AUTH-055-PATTERN`. |
| `SV-N10` | ParallelSlots assigns one child twice or places exclusive-resource users in one slot. | `S7UT-AUTH-055-SLOT`. |
| `SV-N11` | A scenario constant uses the wrong section, field attributes or an unsupported computed initializer; alternatively arithmetic is used as a CASE label. | `S7UT-AUTH-056-CONSTANT`. |

The repository's internal authoring scenarios retain decisions and reference-presence checks outside the installable skill. They are consistency checks, not proof of semantic source analysis or independent skill effectiveness. Use the vectors above only where their assumptions apply; parser-backed fixtures are not a prerequisite.

## Dynamic Validation Boundary

Static analysis cannot prove recovery across executions. For a generated stateful Test Case, the authoring result shall still prescribe dynamic validation with:

1. two consecutive executions without PLC restart;
2. Abort during an applicable active path;
3. exactly one Reset;
4. an immediate same-session follow-up execution;
5. active and error reset paths where applicable.

The analyzer may identify target paths and instrumentation points, but it shall not report this runtime behavior as passed without execution evidence.

## Handoff Acceptance

Review is sufficient for its stated boundary when the consequential findings have source support, unknowns are explicit, and no unexecuted behavior is reported as passed. Independent authoring evaluation uses separate reference projects and preserved first candidates; it is not replaced by this checklist or a successful text-presence check.
