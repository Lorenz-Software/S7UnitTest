# Run Control Contract

## Purpose

This contract defines the PLC-side producer contract for Run Control.

## Scope

This contract defines:

- `UDT_UnitTestRunControl`,
- `UDT_UnitTestRunConfig`,
- `UDT_UnitTestContractInfo`,
- Run-Control-specific timeout defaults and naming rules.

This contract references:

- `general-framework-contract.md` for shared execution/result semantics and shared type rules,
- `event-stream-model-contract.md` for event-entry structure, event classifications, and event-stream rules.

## Version

- Contract version: `1.0.0`

## Requirements

- `RCC-001` `UDT_UnitTestRunControl` MUST use the top-level structure `Name`, `Cmd`, and `Status`.
- `RCC-002` `Name` MUST be a stable instance property and MUST NOT be modeled inside `Status`.
- `RCC-003` Run Control top-level field references MUST follow Table A.
- `RCC-004` Shared framework command fields MUST follow Table B.
- `RCC-005` Run-status fields MUST follow Table C.
- `RCC-006` Run Control configuration fields MUST follow Table D.
- `RCC-007` Contract info fields MUST follow Table E.
- `RCC-008` Command triggers MUST be interpreted by positive edge.
- `RCC-009` Command triggers SHOULD normally be reset again at the end of the same internal cycle.
- `RCC-010` Timeout deactivation MUST NOT be allowed. Zero and negative timeout values MUST be treated as invalid.
- `RCC-011` Run Control MUST own the project-specific suite binding and SHOULD delegate generic run lifecycle handling to the framework-provided Run Control Sequencer.
- `RCC-012` Run Control Suite orchestration MUST be implemented through the framework-provided Suite Orchestrators when serial, parallel, or slot-based parallel Suite execution matches the required project behavior.
- `RCC-013` Run Control finalization MUST keep `UnitTest.State.Completing` active for at least the configured `CompletionDelay` before entering `UnitTest.State.Completed`.
- `RCC-014` Run Control MUST emit exactly one final Run Control Result event for each controllable run lifecycle from `Idle` to `Completed`.
- `RCC-015` Run Control MUST emit exactly one final Run Control Aggregation event for each controllable run lifecycle from `Idle` to `Completed`.
- `RCC-016` Run Control MUST emit its final Result and Aggregation events while in `UnitTest.State.Completing` and before the final state-transition event into `UnitTest.State.Completed`.
- `RCC-017` Project-specific suite binding MUST belong to the concrete Run Control implementation, and generic suite execution MUST belong to Suite Orchestrators.
- `RCC-018` Run Control reset handling MUST bound subordinate Suite reset dispatch against the available event-buffer capacity so that the expected reset events fit while the required producer headroom remains available.
- `RCC-019` Framework-provided Suite Orchestrators MUST dispatch subordinate Suite resets sequentially and MUST wait for sufficient event-buffer capacity before starting each required Suite reset.
- `RCC-020` A subordinate Suite in `UnitTest.State.Idle` with `Status.Execution.Ready = TRUE` MAY be treated as reset-complete without receiving another reset command.
- `RCC-021` Run Control `ResetTimeout` monitoring MUST cover the complete reset operation, including time spent waiting for event-buffer capacity and subordinate Suite completion.
- `RCC-022` A project-specific Run Control implementation that does not use a framework Suite Orchestrator MUST provide equivalent capacity-bounded reset dispatch and completion behavior.
- `RCC-023` Regular Run Control transition from `Running` to `Completing` MUST require completed subordinate execution and a completed Suite Orchestrator when one is used. When the generic Sequencer and Orchestrator are composed, the Sequencer MUST consume `OrchestratorState` and `OrchestratorResult` retained from the same preceding Orchestrator call; `OrchestratorState` MUST equal `UnitTest.State.Completed` for regular completion. Raw subordinate lifecycle signals supplied to the Orchestrator MUST remain independent of its own completion.
- `RCC-024` A Suite Orchestrator's final result MUST describe technical execution. Functional `Failed` results of subordinate Suites MUST be aggregated by Run Control, not converted into a technical Orchestrator `Failed` result. Genuine technical errors MUST retain controlled error handling.
- `RCC-025` Run Control MUST settle its final result before emitting final Result and Aggregation events and MUST retain that result throughout `Completing` and `Completed` until Reset. Subsequent helper/status observations MUST NOT rewrite the published result. `CompletionDelay` remains effective.
- `RCC-026` Reset, explicit Abort, controlled error termination and timeout exits MUST retain their respective completion conditions; the regular child-and-Orchestrator completion gate MUST NOT be imposed on these paths. Untouched Idle/Ready Suites MUST NOT have to execute merely to complete controlled error termination.

## Requirement Details

### Table A: Run Control top-level fields

| Field | Type | Default |
| --- | --- | --- |
| `Name` | `STRING[UnitTest.TextLength.Name]` | `''` |
| `Cmd` | `STRUCT` | fields defaulted explicitly in code |
| `Status` | `STRUCT` | fields defaulted explicitly in code |

### Table B: Shared framework command fields

| Field | Type | Default |
| --- | --- | --- |
| `Start` | `BOOL` | `FALSE` |
| `Abort` | `BOOL` | `FALSE` |
| `Reset` | `BOOL` | `FALSE` |

### Table C: Run-status fields

| Field | Type | Default |
| --- | --- | --- |
| `Execution` | `UDT_UnitTestExecutionStatus` | field defaults of nested UDT |
| `SuiteCountTotal` | `UINT` | `0` |
| `SuiteCountInactive` | `UINT` | `0` |
| `SuiteCountIdle` | `UINT` | `0` |
| `SuiteCountRunning` | `UINT` | `0` |
| `SuiteCountCompleted` | `UINT` | `0` |
| `SuiteCountPassed` | `UINT` | `0` |
| `SuiteCountFailed` | `UINT` | `0` |
| `SuiteCountError` | `UINT` | `0` |
| `Runtime` | `DINT` | `0` |

### Table D: Run Control configuration fields

| Field | Type | Default |
| --- | --- | --- |
| `Timeout` | `DINT` | `30000` |
| `ResetTimeout` | `DINT` | `1000` |
| `AbortTimeout` | `DINT` | `1000` |
| `CompletionDelay` | `DINT` | `100` |
| `SuiteCount` | `UINT` | No explicit UDT initial value; application-defined |

The application MUST set `SuiteCount` to its configured number of Suite instances. The implicit datatype initial value is not an application configuration default.

The configured Suite array uses one-based indices and MUST remain within `1..32767`. `SuiteCount` MUST not exceed the configured `UnitTest.SuiteArray.Length`. This is a project configuration limit; it does not require an additional cyclic upper-limit check in the Suite Orchestrators and does not restrict Assertion input arrays.

### Table E: Contract info fields

| Field | Type | Default |
| --- | --- | --- |
| `ContractVersion` | `STRING[10]` | `''` |
| `FrameworkVersion` | `STRING[10]` | `''` |

### Owner interactions

- Run Control is the single intended PLC-side entry point of the framework slice.
- Run Control owns top-level run orchestration and the concrete Test Suite binding below it.
- The Run Control Sequencer owns the generic Run Control lifecycle when it is used.
- Suite Orchestrators own the generic Suite execution model below Run Control when they are used.
- Run Control aggregates suite-level execution and result information into its own status structure.
- Run Control does not own suite-internal test logic.
- Run Control uses the event structures and classifications defined in `event-stream-model-contract.md` when emitting run-level events.
- Run Control emits run-level lifecycle, Result, and Aggregation evidence with `UnitTest.OwnerScope.RunControl`, even when a generic helper technically emits the event on behalf of the Run Control lifecycle.
- Suite Orchestrators are technical helpers below Run Control, not independent reportable UnitTest owner levels.
- Suite Orchestrators may emit technical orchestration state-transition diagnostics with `UnitTest.OwnerScope.TestSuiteOrchestrator`. These diagnostics describe the Suite Orchestrator state machine and must not be interpreted as Run Control lifecycle completion, Run Control Result, or Run Control Aggregation evidence.

### Reset capacity responsibility

Reset can produce lifecycle, result, aggregation, and diagnostic events at several hierarchy levels in a short period. Run Control therefore owns capacity-safe dispatch of subordinate Suite resets. Capacity waiting is part of the active reset operation; it does not suspend or restart reset timeout monitoring.

The framework Suite Orchestrators satisfy this responsibility by resetting at most one Suite at a time and by checking available event-buffer capacity before dispatch. Direct implementations may use another scheduling algorithm, but they must preserve the same capacity and completion guarantees.

## Compatibility

This contract defines the producer-side Run Control data structures only.

## Non-Requirements

This contract does not define:

- normal Suite execution scheduling details and concrete reset-capacity reservation formulas,
- event transport,
- event structure or communication classifications,
- PC-side contract consumption.
