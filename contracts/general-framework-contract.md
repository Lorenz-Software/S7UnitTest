# General Framework Contract

## Purpose

This contract defines cross-cutting PLC-side framework rules that are shared by Run Control, Test Suite, Test Case, Preparation, Assertion, and Communication contracts.

## Scope

This contract defines:

- shared execution/result data types,
- shared numeric and time field types relevant to execution/result structures,
- shared constant definitions,
- shared execution and result semantics,
- shared default rules.

This contract does not define owner-specific control/config/status UDTs or event-entry layout.

## Terms

- `Owner`: a framework element with PLC-side execution responsibility.
- `Full Owner`: Run Control, Test Suite, or Test Case.
- `ExecutionStatus`: the derived coarse execution classification of an owner.
- `State`: the actual owner state-machine value.
- `Result`: the current stable evaluation standing of the current run.
- `Lifecycle event`: an event that describes owner lifecycle progress, especially state transitions.
- `Final owner event`: an owner-level Result or Aggregation event emitted as part of controlled owner finalization.

## Version

- Contract version: `1.0.0`

## Requirements

- `GFC-001` The shared execution core UDT MUST be `UDT_UnitTestExecutionStatus`.
- `GFC-002` `UDT_UnitTestExecutionStatus` MUST contain the fields defined in Table A.
- `GFC-003` Numeric field types for execution/result structures MUST follow Table B.
- `GFC-004` `Runtime` type MUST follow Table C.
- `GFC-005` Control/status data fields MUST be set explicitly in code to safe defaults before owner-specific values overwrite them. Datatype defaults alone MUST NOT be treated as the intended functional state.
- `GFC-006` Symbolic execution-status constants MUST follow Table D.
- `GFC-007` Symbolic result constants MUST follow Table E.
- `GFC-008` `ExecutionStatus` MUST be driven by `State` and MUST NOT be treated as an independent second state machine.
- `GFC-009` All transitions that end in `UnitTest.ExecutionStatus.Idle` MUST pass through `UnitTest.ExecutionStatus.Reset`.
- `GFC-010` The default initialization path MUST be `Uninitialized -> Reset -> Idle`, unless the owner is intentionally inactive, in which case `Uninitialized -> Reset -> Inactive` MUST be used.
- `GFC-011` `Result` MUST use `UnitTest.Result.NotEvaluated` as the default and reset value.
- `GFC-012` `Result` MUST represent the current stable evaluation standing of the current run and MUST NOT move back to a less severe value within the same run.
- `GFC-013` `UnitTest.ExecutionStatus.Error` MUST imply `UnitTest.Result.Error` in the same run.
- `GFC-014` `UnitTest.Result.Error` MUST NOT require `UnitTest.ExecutionStatus.Error`.
- `GFC-015` `UnitTest.State.Uninitialized` MUST represent a defined state in which the owner has not yet reached a reset-defined executable base state.
- `GFC-016` `Ready = TRUE` MUST indicate an executable base state with all required owner-local and subordinate startability conditions fulfilled.
- `GFC-017` At the beginning of each execution cycle, `ExecutionStatus` MUST be preset to `UnitTest.ExecutionStatus.Unknown` and MUST then be actively overwritten by the owner logic.
- `GFC-018` Shared framework UDTs and their nested structures MUST define `ExternalAccessible`, `ExternalVisible`, and `ExternalWritable` as restrictively as possible without breaking the intended functionality in their defined usage context.
- `GFC-019` The hierarchical nature of PLC structures MUST be respected for external-access attributes. Higher structural levels MAY further restrict lower-level accessibility, visibility, or writability, but MUST NOT expand permissions beyond what is defined by nested fields or nested structures.
- `GFC-020` The top-level storage instance definition MUST be treated as the highest authority for external-access restriction. It MAY further restrict nested structures and fields, but MUST NOT relax restrictions defined below it.
- `GFC-021` Symbolic full-owner lifecycle state constants MUST follow Table F.
- `GFC-022` `UnitTest.State.Completed` MUST be the only stable final lifecycle state used by new owner logic.
- `GFC-023` Explicit abort completion MUST be communicated by `UnitTest.Result.Abort` while `ExecutionStatus` is `UnitTest.ExecutionStatus.Completed`.
- `GFC-024` Error completion MUST be communicated by `UnitTest.Result.Error` while `ExecutionStatus` may remain `UnitTest.ExecutionStatus.Completed` when the owner reached a controlled final state.
- `GFC-025` `UnitTest.State.AbortingFromError` MUST communicate controlled error termination and MUST NOT be mapped to `UnitTest.Result.Abort`.
- `GFC-026` An owner that starts subordinate owners MUST verify subordinate `Ready` immediately before each concrete subordinate start dispatch.
- `GFC-027` `UnitTest.State.Uninitialized` MUST be passive: it MUST NOT emit lifecycle, result, aggregation, or framework diagnostic events and MUST only be left through explicit reset handling.
- `GFC-028` An unhandled lifecycle state value MUST be treated as a framework error, MUST produce `UnitTest.Result.Error`, and MUST enter the controlled finalization path through `UnitTest.State.Completing` before reaching `UnitTest.State.Completed`.
- `GFC-029` Full-owner finalization MUST use `UnitTest.State.Completing` for final result and aggregation publication before the owner enters `UnitTest.State.Completed`.
- `GFC-030` The state-transition event to `UnitTest.State.Completed` MUST be the final lifecycle event of the affected owner run and MUST NOT be emitted in the same PLC cycle as the owner's final result or aggregation event.
- `GFC-031` A generic Sequencer or Orchestrator `UnitTest.Result.Abort` MUST only confirm an owner abort path that has already been selected by the owning Full Owner; otherwise the owning Full Owner MUST treat it as a framework error and finalize with `UnitTest.Result.Error`.
- `GFC-032` `OwnerScope` in UnitTest events MUST describe the semantic framework level represented by the event, not necessarily the technical block that emitted the event.
- `GFC-033` For each controllable Full Owner lifecycle run from `UnitTest.State.Idle` to `UnitTest.State.Completed`, exactly one final owner Result event MUST be emitted.
- `GFC-034` For each controllable aggregating Full Owner lifecycle run from `UnitTest.State.Idle` to `UnitTest.State.Completed`, exactly one final owner Aggregation event MUST be emitted.
- `GFC-035` Final owner Result and Aggregation events MUST be emitted while the owner is in `UnitTest.State.Completing`.
- `GFC-036` The final `StateTransition` event into `UnitTest.State.Completed` MUST be emitted after the final owner Result and Aggregation events of the same lifecycle run.
- `GFC-037` Diagnostic and framework events MAY explain exceptional conditions, but they MUST NOT replace required final owner Result or Aggregation events.
- `GFC-038` Trigger events MUST describe command or trigger edges and MUST NOT be used as lifecycle completion or result evidence.
- `GFC-039` State-transition events MUST describe lifecycle state changes and MUST NOT carry aggregation or result semantics beyond the state values themselves.
- `GFC-040` PLC-side startup or restart initialization MUST be owned by the PLC-side UnitTest application and MUST NOT depend on an external consumer issuing the initial reset only to establish a valid base state.
- `GFC-041` Within owner finalization, the final owner Result event MUST be emitted before the final owner Aggregation event.
- `GFC-042` Generic Orchestrators MAY emit technical orchestration state-transition diagnostics with dedicated Orchestrator `OwnerScope` values, but these diagnostics MUST NOT be treated as independent Full Owner lifecycle completion, Result, or Aggregation evidence.
- `GFC-043` An Assertion-owned Failed finding MUST NOT suppress a later Assertion-owned Error finding in the same Assertion lifecycle. See Producer-side event semantics.

## Requirement Details

### Table A: `UDT_UnitTestExecutionStatus`

| Field | Type | Default |
| --- | --- | --- |
| `State` | `INT` | `UnitTest.State.Uninitialized` |
| `ExecutionStatus` | `INT` | `UnitTest.ExecutionStatus.Unknown` |
| `Result` | `INT` | `UnitTest.Result.NotEvaluated` |
| `Uninitialized` | `BOOL` | `FALSE` |
| `ConfigError` | `BOOL` | `FALSE` |
| `Ready` | `BOOL` | `FALSE` |
| `Running` | `BOOL` | `FALSE` |
| `Completed` | `BOOL` | `FALSE` |
| `Aborted` | `BOOL` | `FALSE` |
| `Inactive` | `BOOL` | `FALSE` |
| `Error` | `BOOL` | `FALSE` |

### Table B: Numeric field types for execution/result structures

| Field | Type |
| --- | --- |
| `State` | `INT` |
| `ExecutionStatus` | `INT` |
| `Result` | `INT` |

### Table C: Time field types

| Field | Type | Semantics |
| --- | --- | --- |
| `Runtime` | `DINT` | Relative owner runtime in `ms`; timeout helpers compare this value directly with the configured timeout and MUST NOT add hidden execution-status-bit gating |

Owner runtime is the active execution time published by the owner status view. Additional helper-local runtime values may exist for narrower phases, for example `StateRuntime`, `PreparationRuntime`, or `TestStateRuntime`. Such helper-local values are diagnostics or internal monitoring inputs unless an owner-specific contract explicitly publishes them.

### Table D: Execution-status constants

| Symbolic constant | Value |
| --- | ---: |
| `UnitTest.ExecutionStatus.Error` | `-10` |
| `UnitTest.ExecutionStatus.Unknown` | `0` |
| `UnitTest.ExecutionStatus.Inactive` | `1` |
| `UnitTest.ExecutionStatus.NotReady` | `9` |
| `UnitTest.ExecutionStatus.Idle` | `10` |
| `UnitTest.ExecutionStatus.Starting` | `20` |
| `UnitTest.ExecutionStatus.Running` | `30` |
| `UnitTest.ExecutionStatus.Completing` | `40` |
| `UnitTest.ExecutionStatus.Completed` | `50` |
| `UnitTest.ExecutionStatus.Aborting` | `60` |
| `UnitTest.ExecutionStatus.Aborted` | `70` |
| `UnitTest.ExecutionStatus.Reset` | `80` |

`UnitTest.ExecutionStatus.Aborted` is retained as a legacy constant. New owner logic MUST NOT use it as a stable final execution status.

### Table E: Result constants

| Symbolic constant | Value |
| --- | ---: |
| `UnitTest.Result.Error` | `-10` |
| `UnitTest.Result.NotEvaluated` | `0` |
| `UnitTest.Result.Passed` | `10` |
| `UnitTest.Result.Failed` | `20` |
| `UnitTest.Result.Abort` | `30` |

### Table F: Full-owner lifecycle state constants

| Symbolic constant | Value |
| --- | ---: |
| `UnitTest.State.Error` | `-10` |
| `UnitTest.State.Uninitialized` | `0` |
| `UnitTest.State.Reset` | `1` |
| `UnitTest.State.Idle` | `10` |
| `UnitTest.State.Starting` | `11` |
| `UnitTest.State.Preparing` | `20` |
| `UnitTest.State.Running` | `50` |
| `UnitTest.State.Completing` | `80` |
| `UnitTest.State.Completed` | `89` |
| `UnitTest.State.Aborting` | `90` |
| `UnitTest.State.AbortingFromError` | `91` |
| `UnitTest.State.Aborted` | `99` |

`UnitTest.State.Error` and `UnitTest.State.Aborted` are retained as legacy constants. New owner logic MUST NOT use either value as a stable final lifecycle state.

### Execution-status semantics

```text
default initialization:
UnitTest.ExecutionStatus.NotReady
 -> UnitTest.ExecutionStatus.Reset
 -> UnitTest.ExecutionStatus.Idle

inactive initialization:
UnitTest.ExecutionStatus.NotReady
 -> UnitTest.ExecutionStatus.Reset
 -> UnitTest.ExecutionStatus.Inactive

normal forward execution:
UnitTest.ExecutionStatus.Idle
 -> UnitTest.ExecutionStatus.Starting
 -> UnitTest.ExecutionStatus.Running
 -> UnitTest.ExecutionStatus.Completing
 -> UnitTest.ExecutionStatus.Completed

abort path:
... -> UnitTest.ExecutionStatus.Aborting -> UnitTest.ExecutionStatus.Completed

return to idle:
Completed/Error/Inactive
 -> UnitTest.ExecutionStatus.Reset
 -> UnitTest.ExecutionStatus.Idle
```

Owner-specific state machines MAY have additional internal state steps, but they MUST map their current execution situation to this shared `ExecutionStatus` model.

`UnitTest.State.Uninitialized` maps to `UnitTest.ExecutionStatus.NotReady`, sets `Uninitialized = TRUE`, and keeps `Ready = FALSE`, `Running = FALSE`, `Completed = FALSE`, and `Error = FALSE`. It is a defined non-executable state, not an error state. It is used when an owner has not yet been brought into a reset-defined base state.

PLC-side startup or restart initialization must bring the relevant Full Owner path from `UnitTest.State.Uninitialized` through explicit reset handling into the defined executable base state before normal start processing is expected. An external consumer may request reset as an operational command, but the PLC-side UnitTest application must not require that external request only to make the startup state valid.

An unhandled state value is not `Uninitialized`. It represents a framework or programming error such as an incomplete state-machine branch, invalid state assignment, or manual overwrite of lifecycle state. The owner must report this as an error and complete through the controlled finalization path so higher levels can aggregate the error deterministically.

### Result semantics

```text
default/reset:
UnitTest.Result.NotEvaluated

stable progression within one run:
UnitTest.Result.NotEvaluated
 -> UnitTest.Result.Passed
 -> UnitTest.Result.Failed
 -> UnitTest.Result.Error

allowed direct jumps:
UnitTest.Result.NotEvaluated -> UnitTest.Result.Failed
UnitTest.Result.NotEvaluated -> UnitTest.Result.Error
UnitTest.Result.NotEvaluated -> UnitTest.Result.Abort
UnitTest.Result.Passed -> UnitTest.Result.Abort
UnitTest.Result.Failed -> UnitTest.Result.Abort
UnitTest.Result.Passed -> UnitTest.Result.Error

forbidden:
UnitTest.Result.Failed -> UnitTest.Result.Passed
UnitTest.Result.Error -> UnitTest.Result.Failed
UnitTest.Result.Error -> UnitTest.Result.Passed
UnitTest.Result.Abort -> UnitTest.Result.Passed
UnitTest.Result.Abort -> UnitTest.Result.Failed
UnitTest.Result.* -> UnitTest.Result.NotEvaluated (except by reset)
```

`UnitTest.Result.Abort` is a separate terminal outcome for explicitly aborted runs. It is not part of the passed/failed/error evaluation-severity order. `UnitTest.Result.Error` remains the highest-priority outcome if abort handling itself fails.

`UnitTest.ExecutionStatus.Completing` and `UnitTest.ExecutionStatus.Aborting` are not result-evaluation phases. During these phases no new `Passed` or `Failed` result may be created. `Result` MAY still escalate to `UnitTest.Result.Error` or be set to `UnitTest.Result.Abort` for an explicit abort path.

`UnitTest.State.Aborting` represents explicit abort handling and normally leads to `UnitTest.Result.Abort`.

`UnitTest.State.AbortingFromError` represents controlled termination after an internal, subordinate, timeout, or framework error and leads to `UnitTest.Result.Error`. It is not an explicit user abort outcome.

Generic Sequencer and Orchestrator results are interpreted in the context of the owning Full Owner. `UnitTest.Result.Error` from a generic helper always escalates to the owner result. `UnitTest.Result.Abort` from a generic helper is only valid when the owner has already selected its explicit abort path. If no owner abort path exists, a generic helper abort result represents an inconsistent lifecycle situation and must be treated as `UnitTest.Result.Error`. Subordinate owner results are not blindly combined as abort outcomes; an unexpected subordinate abort must be routed into the owner's error finalization path before the owner completes.

`Ready = TRUE` indicates an executable base state. For full owners, `Ready = TRUE` requires that the owner itself is in its idle base state, all required owner-local ready releases are true, and all subordinate owners required for the next start are ready as well. For Preparation, this additionally implies that no action is currently performed on the tested resource.

If a subordinate owner is no longer ready immediately before a concrete start dispatch, the starting owner MUST treat this as a framework error, avoid starting that subordinate, and enter its controlled error termination path instead of waiting for a regular timeout.

### Producer-side event semantics

UnitTest events are producer-side semantic records. They document the framework lifecycle, final outcomes, aggregation, trigger edges, and diagnostic context. They are not a replacement for owner state machines and do not define transport or consumer polling behavior.

`OwnerScope` describes the semantic context represented by an event. Full Owner lifecycle, Result, and Aggregation evidence uses the Full Owner scope (`RunControl`, `TestSuite`, or `TestCase`) even when a generic helper technically emits the event on behalf of that owner.

Generic Orchestrators may additionally emit technical orchestration state-transition diagnostics with dedicated Orchestrator scopes. These events describe the helper state machine that coordinates subordinate owners. They do not introduce additional reportable Full Owner levels and must not be interpreted as owner finalization, final Result, or Aggregation evidence.

`StateTransition` events document lifecycle state changes. The state-transition event into `UnitTest.State.Completed` is the deterministic lifecycle-completion event of a Full Owner run. It must be emitted only after that owner's final Result and Aggregation events have already been produced.

`Result` values are escalated by the owning PLC-side result logic before a final owner Result event is emitted. Result events do not perform escalation themselves.

Final Full Owner Result events document the final owner outcome after owner-side result escalation has completed. They are emitted during `UnitTest.State.Completing`.

Assertion failed/error Result events are assertion-owned finding events. They can contribute to Test Case result aggregation and escalation, but they are not final Test Case Result events.

GFC-043: Assertion-owned failed findings and assertion-owned error findings are distinct finding types. If one assertion lifecycle can produce both types, their one-shot event-emission control MUST be independent so that a previously emitted functional failed finding cannot suppress a later assertion error finding. An assertion error has priority over functional failure: once the assertion result is `UnitTest.Result.Error`, it MUST NOT transition to `UnitTest.Result.Failed`, and the assertion MUST NOT emit a subsequent functional failed finding during the same assertion lifecycle.

`Aggregation` events document how subordinate outcomes contributed to an owner outcome. Run Control, Test Suite, and Test Case are aggregating Full Owners. Preparation, Assertion, and generic lifecycle helpers are not independent aggregating Full Owners.

Within a Full Owner finalization cycle, the final owner Result event is emitted first and the final owner Aggregation event is emitted afterwards. The subsequent state-transition event into `UnitTest.State.Completed` remains the final lifecycle-completion event for that owner run.

Diagnostic and framework events provide technical context such as invalid configuration, timeout, unhandled state, resource readiness violation, or event-buffer capacity problems. They do not complete an owner lifecycle and do not replace final owner Result or Aggregation events.

Explicit abort paths finalize controllably through the owner abort path and produce `UnitTest.Result.Abort`. Error, timeout, subordinate-error, and framework-error paths should finalize controllably through the owner error path and produce `UnitTest.Result.Error`. If controlled finalization cannot be reached, the required final event set may be incomplete; detecting missing events is outside this local producer lifecycle contract.

`OwnerScope` classifies the represented framework level or technical diagnostic context. The concrete parent/child identity of UnitTest owner events is defined by the hierarchical event `Name` rules in `event-stream-model-contract.md`.

## Compatibility

This contract intentionally uses PLC-owned structures and symbolic constants that can be implemented on different PLC platforms.

## Non-Requirements

This contract does not define:

- event-buffer transport semantics,
- event-entry layout, transport semantics, or communication classifications such as `OwnerScope`, `EventType`, `Severity`, or `Timestamp`,
- owner-specific orchestration rules,
- PC-side classes,
- dynamic runtime FB dispatch.
