# Test Suite Authoring

A Test Suite groups related Test Cases and produces one Suite-level result. It is the project-specific Full Owner of the Suite lifecycle and Test Case execution.

The preferred implementation uses `UnitTestSuiteSequencer` for the generic Suite lifecycle and one framework-provided Test Case Orchestrator for subordinate execution. Both helpers are optional. A Suite that does not use them must implement the same lifecycle, signal, monitoring, result, status, and event behavior itself.

## Navigation

- [Suite Composition](#suite-composition)
- [Sequencer And Orchestrator Integration](#sequencer-and-orchestrator-integration)
- [Configuration](#configuration)
- [Test Case Calls](#test-case-calls)
- [Normal Execution Capacity](#normal-execution-capacity)
- [Reset Scheduling](#reset-scheduling)

## Test Suite Responsibility

The Test Suite translates one Suite-level execution request into execution of the registered Test Cases.

It is responsible for the Test Case group that belongs together from a test intent perspective. This includes Test Case configuration, concrete Test Case calls, and suite-local diagnostic views that help understand which Test Cases are active during execution.

The Test Suite is not responsible for implementing the internal behavior of individual Test Cases, Preparation logic, or Assertion logic. Those belong to the Test Case level and below.

## Suite Composition

A Test Suite using the preferred helper model should make the separation visible in its cyclic structure:

```scl
REGION Configuration
    // Configure the registered Test Cases and optional execution slots.
END_REGION

REGION Lifecycle signals
    // Derive Ready, Completed, AbortFinished, and ResetFinished.
END_REGION

REGION Sequencer
    // Execute the Suite lifecycle and generate subordinate commands.
END_REGION

REGION Test Case Orchestrator
    // Execute the selected Test Case orchestration model.
END_REGION

REGION Test case calls
    // Call each registered Test Case exactly once per cycle.
END_REGION

REGION Result
    // Combine Sequencer, Orchestrator, and Test Case results.
END_REGION

REGION Status
    // Publish the Suite status after subordinate calls.
END_REGION

REGION Finalization events
    // Emit final Suite Result and Aggregation evidence.
END_REGION
```

The declaration part contains the Suite control and configuration inputs, concrete Test Case instances, local Test Case Config and Control arrays, one Suite Sequencer, one Test Case Orchestrator, the subordinate command data between them, optional execution-model data such as parallel execution slots, and suite-local diagnostics.

The separation should remain stable: the Sequencer handles the generic Suite lifecycle, the Orchestrator handles generic Test Case execution, and the Suite owns project-specific binding, result composition, status publication, and finalization evidence.

`UnitTestSuite_Example_Serial`, `UnitTestSuite_Example_Parallel`, and `UnitTestSuite_Example_ParallelSlots` show this preferred structure. `UnitTestSuite_Example` shows the allowed direct implementation, but it should not be the first choice for normal project code.

## Test Case Registration

Registered Test Cases must be consistent across the local Test Case count, Test Case configuration data, Test Case control data, and concrete Test Case calls.

Test Case data is suite-local. A Test Suite owns arrays such as `TestCaseConfigData` and `TestCaseControlData`; Test Cases are not registered through global Test Case DBs.

For every registered Test Case index, the Suite implementation needs a matching configured Test Case, a matching control-data entry, and a concrete Test Case call. If these elements are not aligned, the Orchestrator cannot reliably start, monitor, or aggregate the Test Case.

The relevant mapping should be visible in the Suite. Test Case names are full hierarchical names generated from the Suite name and one local Test Case segment:

```scl
// Test Case index 1
#TestCaseConfigData[1].Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'TestCase_1');
#TestCaseConfigData[1].Timeout := 5000;
#TestCaseConfigData[1].PreparationTimeout := 2000;

#TestCase_1(
    ConfigData := #TestCaseConfigData[1],
    ControlData := #TestCaseControlData[1]
);
```

For a real project, each registered Test Case index follows the same pattern: one configuration entry, one control entry, and one concrete Test Case call.

## Suite Sequencer

`UnitTestSuiteSequencer` is the recommended implementation helper for the Suite lifecycle. It processes Suite commands, maintains Suite state and runtime, monitors reset and abort completion, produces subordinate command requests, and emits Suite trigger and state-transition events under `UnitTest.OwnerScope.TestSuite`.

The Sequencer consumes the aggregated Test Case lifecycle signals and the technical Orchestrator result. It publishes Suite state, previous state, runtime, its technical sequencing result, configuration status, and the one-cycle command requests for the selected Test Case Orchestrator.

The Sequencer does not bind or call Test Cases and does not create the final Suite Result or Aggregation events. Those responsibilities remain in the project-specific Suite around the Sequencer.

A direct Suite state machine remains valid when the generic lifecycle cannot be used. In that case, the Suite implementation must provide the same command priority, lifecycle states, runtime, timeout monitoring, lifecycle signals, result stability, and event sequence itself.

## Test Case Orchestrators

The Test Suite should use the Orchestrator that matches the intended Test Case execution model. This is the recommended implementation path for normal Suite authoring.

An Orchestrator starts Test Cases, propagates subordinate abort and reset commands, checks readiness before starts, observes completion, monitors Test Case runtime, reacts to subordinate errors, and reports a technical Orchestrator result. Its own state-transition events are technical diagnostics under `UnitTest.OwnerScope.TestCaseOrchestrator`; they are not Suite lifecycle evidence.

The Suite still owns the concrete binding around the Orchestrator: it assigns Test Case configuration, declares and calls Test Case instances, provides the Test Case control data, publishes the Suite status view, and creates the final Suite result and aggregation evidence.

The framework currently provides three Test Case Orchestrators for Test Suite implementations. Select among them from execution order, concurrency, and resource ownership. EventBuffer size and expected event volume are not selection criteria: all three manage producer-owned global EventBuffer reservations internally. There is no separate Adaptive Orchestrator variant.

Custom Suite state-machine logic should be avoided unless the available Orchestrators cannot model the required execution behavior.

### `UnitTestCaseOrchestrator_Serial`

`UnitTestCaseOrchestrator_Serial` starts one Test Case at a time. It waits until the active Test Case has completed before it starts the next registered Test Case.

Use this Orchestrator when Test Case execution must be deterministic and exclusive, or when Test Cases may share resources that must not be used in parallel.

The Suite must provide:

- the Suite control data,
- the Test Case configuration array,
- the Test Case control array,
- one concrete Test Case call for each registered Test Case index.

No additional execution-model configuration is required.

### `UnitTestCaseOrchestrator_Parallel`

`UnitTestCaseOrchestrator_Parallel` provides maximum safe parallel execution of registered Test Cases. It starts at most one new Test Case per Orchestrator call and may delay a candidate until sufficient globally unreserved EventBuffer capacity exists. Its orchestration completes when all registered Test Cases have completed or when an abort or error condition ends subordinate execution.

Use this Orchestrator only when all registered Test Cases can safely run at the same time. This requires that their Preparations and active test phases do not compete for the same external resources.

The Suite must provide the same binding as for serial execution:

- the Suite control data,
- the Test Case configuration array,
- the Test Case control array,
- one concrete Test Case call for each registered Test Case index.

No additional execution-model configuration is required.

### `UnitTestCaseOrchestrator_ParallelSlots`

`UnitTestCaseOrchestrator_ParallelSlots` runs Test Cases in configured execution slots. Test Cases assigned to the same slot can run in parallel subject to global EventBuffer capacity. The next slot starts only after the current slot has completed.

Use this Orchestrator when parts of the Test Case set can run in parallel, but other Test Cases must be separated because of resource ownership or execution order.

The Suite must provide:

- the Suite control data,
- the Test Case configuration array,
- the Test Case control array,
- one concrete Test Case call for each registered Test Case index,
- a slot assignment for each registered Test Case index.

The slot assignment is suite-local execution configuration:

```scl
#TestCaseExecutionSlot[1] := 1;
#TestCaseExecutionSlot[2] := 1;
#TestCaseExecutionSlot[3] := 2;
```

All registered Test Cases must have a valid slot assignment. A missing or invalid assignment is a Suite configuration error.

### Normal Execution Capacity

All three Test Case Orchestrators derive a conservative event budget from each candidate's published `PreparationStateCount`, `TestStateCount`, and `AssertionCountTotal`. Before issuing Start, the Orchestrator atomically adds that budget to its contribution to the producer-owned global EventBuffer reservation count. Reservations from concurrently active Test Suites therefore share one capacity boundary and cannot allocate the same entries twice.

The Orchestrator owns pending-Start confirmation, active reservation retention, completion release, Abort retention, and execution-to-Reset handover. The project-specific Suite must not reproduce or manipulate this accounting around a framework Orchestrator.

A direct Suite implementation without a framework Test Case Orchestrator must provide the equivalent behavior required by `test-suite-contract.md`. It must use the framework's semantic reservation service rather than addressing `DB_UnitTestEventBuffer` directly.

### Reset Scheduling

All three Test Case Orchestrators use capacity-bounded reset batches, independent of their normal serial, parallel, or slot-based execution model. Before starting another Test Case reset, the Orchestrator checks the available event-buffer capacity through `GetEventBufferFreeEntries`.

The admission threshold is the configured `UnitTest.EventBuffer.ResetHeadroom` of `20` entries, a fixed Orchestrator reserve of `3` entries, and `3` additional entries for every active or newly started Test Case reset. Test Cases already in `UnitTest.State.Idle` with `Status.Execution.Ready = TRUE` are skipped.

The Orchestrator may start several resets in one cycle when the available capacity permits it. It waits before starting further resets when the reserve would be violated. This wait remains part of Suite reset handling and counts toward `ResetTimeout`. A custom Suite without a Test Case Orchestrator must provide equivalent bounded reset dispatch itself.

## Sequencer And Orchestrator Integration

The Suite connects two independent generic responsibilities: the Sequencer controls the Suite lifecycle, while the Orchestrator controls execution of the registered Test Cases. The Sequencer writes one-cycle subordinate commands; the Orchestrator consumes those commands and updates the Test Case command data.

The normal cyclic order is:

- prepare Suite configuration and derive lifecycle signals,
- call `UnitTestSuiteSequencer`,
- call the selected Test Case Orchestrator with the Sequencer's subordinate commands,
- combine Sequencer and Orchestrator configuration status,
- call the concrete Test Case instances,
- create the Suite result,
- publish the Suite status view,
- emit finalization events and update diagnostics,
- reset one-shot Suite commands.

```scl
#Sequencer(
    CmdData := #ControlData.Cmd,
    LifecycleSignals := #LifecycleSignals,
    OrchestratorState := #OrchestratorState,
    OrchestratorResult := #OrchestratorResult,
    State => #State,
    PreviousState => #PreviousState,
    Result => #SequencerResult,
    CmdSubordinate => #OrchestrationCmd
);

#Orchestrator(
    CmdData := #OrchestrationCmd,
    LifecycleSignals := #LifecycleSignals,
    State => #OrchestratorState,
    Result => #OrchestratorResult,
    TestCaseConfigData := #TestCaseConfigData,
    TestCaseControlData := #TestCaseControlData
);
```

The Orchestrator call must happen before the concrete Test Case calls because it writes subordinate Test Case commands. The Suite status view must be updated after the concrete Test Case calls because it reads the status published during those calls. Lifecycle signals should remain static, debug-visible Suite variables that are refreshed every cycle.

Retain `OrchestratorState` and `OrchestratorResult` in initialized persistent fields, starting with `UnitTest.State.Uninitialized` and `UnitTest.Result.NotEvaluated`. The Sequencer consumes the paired outputs from the preceding Orchestrator call; the later call refreshes those same fields. Do not use `VAR_TEMP`, shadow copies or a reordered call sequence for this handover. Regular completion requires both raw child completion and helper `Completed`. Keep the shared `LifecycleSignals.Completed` as the raw child snapshot to avoid a circular dependency. Reset, explicit Abort, error termination and timeout exits retain their own completion conditions.

Do not duplicate Sequencer or Orchestrator logic around these calls. A direct implementation is an alternative to the helpers, not an additional competing state machine.

## Suite Lifecycle

The Suite lifecycle is represented by framework state constants. When `UnitTestSuiteSequencer` is used, it implements this lifecycle on behalf of the Test Suite. The Test Case Orchestrator has a separate technical state machine and does not own Suite lifecycle state.

The relevant Suite lifecycle states are:

- `UnitTest.State.Reset`: reset Suite-level state and propagate reset to registered Test Cases.
- `UnitTest.State.Idle`: stable ready state; the Suite can accept a start command when subordinate readiness allows it.
- `UnitTest.State.Preparing`: reserved lifecycle phase before active Test Case execution. Current Test Case Orchestrators normally do not require project-specific handling for this state.
- `UnitTest.State.Running`: execute the selected Test Case orchestration model and monitor registered Test Cases.
- `UnitTest.State.Completing`: finalize after all required Test Cases and the selected Orchestrator have completed during regular execution, or after the applicable controlled termination path, and prepare final aggregation/result handling.
- `UnitTest.State.Aborting`: abort execution after an external abort command and wait until subordinate Test Cases are no longer active.
- `UnitTest.State.AbortingFromError`: abort execution after a detected error condition and wait until subordinate Test Cases are no longer active.
- `UnitTest.State.Completed`: stable final state for the Suite-level execution.

The Suite-level result is produced by the Suite owner from lifecycle state, optional Sequencer and Orchestrator results, and registered Test Case results. Normal completion leads to passed or failed depending on the aggregated Test Case results. External abort leads to abort. Internal errors, configuration errors, readiness violations, subordinate errors, or timeouts lead to error handling and normally pass through `AbortingFromError` before the Suite reaches `Completed`.

Unhandled Suite lifecycle state values are framework errors. They are not an uninitialized state and should be completed through the controlled error finalization path.

With `UnitTestSuiteSequencer`, project-specific Suite code should not set Suite states directly. It supplies raw child lifecycle signals and the retained Orchestrator state and technical result, then consumes the Sequencer outputs.

Only a direct Suite lifecycle implementation should own Suite states itself. In that case, the implementation also owns the responsibility to keep lifecycle state, execution status, result, runtime, monitoring, aggregation, and events consistent.

## Incoming Suite Commands

The Suite reacts to commands from the owning Run Control path through its Suite control data. The relevant commands are reset, start, and abort.

Reset has the highest priority. A reset returns the Suite to a defined base state. After reset handling has settled, the Suite returns to `Idle`.

Start is only valid while the Suite is ready. Readiness depends on the Suite lifecycle and on subordinate Test Case readiness.

Abort can be requested while the Suite is idle or active. If start and abort are present in the same cycle, abort must win over starting Test Case execution.

Configuration errors, Test Case readiness violations at the point of Test Case start, Test Case timeout, and subordinate Test Case errors are not normal aborts. They are error conditions and should drive the Suite into error handling, normally through `AbortingFromError`.

When `UnitTestSuiteSequencer` is used, Suite command priority, trigger events, and conversion into subordinate command requests belong to the Sequencer. The Test Case Orchestrator consumes only those subordinate requests. The Suite should not implement competing command handling around either helper.

## Test Case Trigger Propagation

The Suite level owns Test Case execution. Therefore the Suite level is responsible for triggering start, abort, and reset on registered Test Cases.

When the preferred helper model is used, the Sequencer selects the lifecycle command and the Test Case Orchestrator propagates the resulting subordinate request. Without these helpers, a direct Suite implementation must perform both steps explicitly.

Start triggers should be issued only for Test Cases that are intended to start in the current execution step and only after their readiness has been checked.

Example for a custom serial Suite:

```scl
IF "IsTestCaseReady"(ControlData := #TestCaseControlData[#CurrentTestCaseIndex]) THEN
    "StartTestCase"(ControlData := #TestCaseControlData[#CurrentTestCaseIndex]);
ELSE
    #Result := "UnitTest.Result.Error";
    #State := "UnitTest.State.AbortingFromError";
END_IF;
```

Abort propagation must cover all registered Test Cases that are still in `Starting`, a Preparation state, or a Running state. Test Cases in stable, finalizing, or existing abort states need no new abort command. Use the collection helper instead of aborting only the currently selected Test Case; the helper filters the registered array to the lifecycle states that still require cancellation.

```scl
"AbortAllTestCases"(TestCaseControlData := #TestCaseControlData);
```

Reset propagation must establish a defined base state for all registered Test Cases. Test Cases already in `Idle` with `Ready = TRUE` need no additional reset. Required resets must be dispatched in a capacity-bounded manner so their expected events do not exhaust the event buffer.

After abort or reset propagation, the Suite must observe subordinate Test Case status until the affected Test Cases have reached stable states. `UnitTestSuiteSequencer` performs this monitoring against `AbortTimeout` and `ResetTimeout`; a timeout emits a diagnostic event and completes the Suite with an error result. A direct Suite implementation must provide equivalent handling.

When a provided Orchestrator is used, the Suite should not call `StartTestCase`, `AbortTestCase`, `AbortAllTestCases`, `ResetTestCase`, or `ResetAllTestCases` around the Orchestrator for the same execution path. Doing so would create competing trigger logic.

## Configuration

Suite and Test Case configuration should be explicit. The Suite Config contains the hierarchical Suite name, the execution timeout monitored by the owning Run Control path, and the positive `ResetTimeout` and `AbortTimeout` used by the Suite lifecycle. Test Case names, timeouts, preparation timeouts, and execution-model settings should be assigned in a clear configuration region before the configured Test Cases are executed.

After assigning child configuration, compute a temporary `LocalConfigError` from the current Suite configuration/name and every configured Test Case using the existing validation helpers. For slot-based orchestration, also validate positive slot assignments and a gap-free range starting at 1. Prepare `LifecycleSignals.Ready` from this current local status and child readiness before calling the Sequencer and Orchestrator; do not use their previous-invocation error outputs as the only local configuration check. Afterwards, combine the local error with the current technical configuration-error outputs for the published status and final readiness guard. Keep the generic blocks' own validation, lifecycle and command ownership intact; the owner check does not duplicate their runtime-capacity or reservation handling.

Test Case names must include the owning Suite name. Generate each Test Case name from the full Suite name plus one local Test Case segment:

```scl
#TestCaseConfigData[1].Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'TestCase_1');
```

Use local Test Case segments without spaces or dots. The full Test Case name is used by the event stream to place Test Case events below the owning Suite.

Configuration should describe the registered Test Cases that actually exist in the Suite. Generic loops are only useful when the configuration itself is truly generic. For project-specific Test Case names and Test Case-specific settings, explicit assignments are easier to review and less error-prone.

For slot-based parallel execution, the Suite also defines the execution slot for each registered Test Case. Slot configuration belongs to the Suite because the Suite owns how Test Cases are arranged relative to each other.

## Test Case Calls

Concrete Test Cases are called cyclically by the Test Suite. Each registered Test Case index must map to exactly one concrete Test Case call.

The Test Case receives its own Config and Control data. The Test Case owns its published status and result. The Suite and Orchestrator consume that status for monitoring and aggregation, but they do not implement the Test Case's internal behavior.

Keep the Test Case call region explicit:

```scl
REGION Test case calls
    #TestCase_1(
        ConfigData := #TestCaseConfigData[1],
        ControlData := #TestCaseControlData[1]
    );

    #TestCase_2(
        ConfigData := #TestCaseConfigData[2],
        ControlData := #TestCaseControlData[2]
    );
END_REGION
```

Do not hide project-specific Test Case binding behind a generic loop unless the Test Case instances and their configuration are actually generic.

## Monitoring Responsibility

The Suite level monitors the registered Test Cases through the selected Test Case Orchestrator. The Orchestrator checks readiness before start, observes completion, monitors Test Case runtime against the configured timeout, reacts to subordinate errors, and reports its technical result to the Suite Sequencer and final result composition.

The Suite Sequencer separately monitors whether subordinate reset and abort handling reaches the aggregated lifecycle signals within the Suite-level `ResetTimeout` and `AbortTimeout`. Timeout helper utilities evaluate the relevant runtime and do not hide timeout decisions behind execution-status bits.

The Test Case itself publishes its status. The Suite level decides how that status affects the Suite lifecycle and the aggregated Suite result.

Project-specific Suite code should not reimplement the monitoring logic that already exists in the selected Orchestrator. If custom monitoring is required, that is a custom execution model and should be treated deliberately.

The Test Case timeout is configured per registered Test Case. The Suite level evaluates this timeout because it owns the execution of Test Cases. A Test Case does not monitor its own timeout for the purpose of Suite-level execution control.

The Suite implementation must make subordinate Test Case status available to the Orchestrator. Otherwise the Orchestrator cannot detect readiness, running state, completion, result, timeout, or subordinate errors reliably.

If a Test Case is not ready when the Orchestrator is about to start it, the Suite-level execution must not silently wait until the global timeout expires. The Orchestrator treats this as a deterministic error condition.

## Result Aggregation

The Test Suite aggregates the results of the registered Test Cases into the Suite-level result consumed by the owning Run Control path.

With the preferred helper model, the Suite owner creates the final Suite result from the Sequencer result, the technical Orchestrator result, and the registered Test Case results. Successful orchestration reports technical `Passed` even when a Test Case has a functional `Failed` result; the Suite owner aggregates that functional failure. Use `CreateTestSuiteResult` on first entry to `Completing`, before status publication and final events. During subsequent `Completing` calls and in `Completed`, retain the published owner result until Reset rather than re-aggregating later helper observations. The templates use the existing `State`, `PreviousState` and status result for this decision; no additional publication flag or result copy is needed.

A helper-reported `Error` escalates to the Suite result. A helper-reported `Abort` is only valid as confirmation of a Suite abort path that was already selected from an explicit abort command; otherwise it is a framework error.

The Suite should provide the concrete Test Case calls and status publication needed for aggregation, but should not independently calculate a second Suite result.

Suite-level aggregation is emitted through `CreateUnitTestSuiteAggregationEvent`. This event describes how Test Case results contributed to the Suite result.

## Events

The Test Suite is the semantic owner of Suite lifecycle, Result, and Aggregation evidence. The selected implementation pattern determines which block performs the reusable mechanics:

- `UnitTestSuiteSequencer` emits Suite trigger and Suite state-transition events under `UnitTest.OwnerScope.TestSuite`.
- `UnitTestCaseOrchestrator_*` emits only technical orchestration diagnostics under `UnitTest.OwnerScope.TestCaseOrchestrator` and `<suiteName>.Orchestrator`.
- The project-specific Suite emits the final Suite Result and Aggregation events after it has composed and published the final Suite data.
- A direct Suite implementation without helpers must provide all of these owner-level events itself.

### State Transition Events

Suite state-transition events document every Suite lifecycle state change. When `UnitTestSuiteSequencer` is used, it emits these events automatically with the Suite name and `UnitTest.OwnerScope.TestSuite`. The Suite must not emit duplicate transitions around the Sequencer.

The Test Case Orchestrator has its own technical state transitions. These are useful for online diagnosis of subordinate execution, but they are not Suite lifecycle evidence and cannot complete the Suite lifecycle in the event stream.

A direct Suite state machine must emit its own Suite state-transition events. Its final lifecycle event is the transition into `UnitTest.State.Completed`.

### Result And Aggregation Events

The project-specific Suite creates its final result from the Sequencer result, Orchestrator result, and registered Test Case results. On entry into `UnitTest.State.Completing`, it emits exactly one Suite Result event followed by exactly one Suite Aggregation event.

Use the framework finalization helper after result composition and status publication:

```scl
"EmitTestSuiteFinalizationEvents"(
    PreviousState := #PreviousState,
    State := #State,
    ResourceName := '',
    ControlData := #ControlData
);
```

The Suite must remain in `Completing` for the finalization cycle. The state-transition event into `Completed` follows no earlier than the next PLC cycle and remains the final lifecycle event. External abort produces an Abort result; error-driven termination and reset or abort timeouts produce an Error result.

### Diagnostic Framework Events

Diagnostic framework events are emitted for exceptional Suite-level conditions that explain why execution cannot continue normally.

Typical situations are:

- invalid Suite or Test Case execution configuration,
- invalid Test Case index or execution slot,
- a Test Case that is not ready when the Orchestrator is about to start it,
- a Test Case timeout,
- an invalid Suite lifecycle state.

Example:

```scl
#RetVal_Event := "CreateUnitTestFrameworkEvent"(
    Name := #ControlData.Name,
    State := #State_local,
    Severity := "Logging.Severity.Error",
    Message := 'Test Case is not ready for start.'
);
```

Diagnostic framework events primarily explain the PLC-side execution flow. They can be essential context for a Suite-level error result, but they do not replace the final result event.

## Status Publication

The Suite publishes its status view after the relevant subordinate Test Case calls have updated their own status. This allows the Suite status to reflect the current subordinate state.

The status view includes the Suite lifecycle state, execution status, result, runtime, Test Case counters, and readiness. Readiness must reflect both the Suite's own state and the subordinate readiness required for a safe start.

`UpdateTestSuiteStatusView` is the framework utility that maps Suite control data and subordinate Test Case status into the published Suite status view. The Suite should use this utility instead of writing the status view field-by-field.

The status region should therefore stay compact:

```scl
REGION Status
    "UpdateTestSuiteStatusView"(
        State := #State,
        Result := #Result,
        Runtime := #Runtime,
        ConfigError := #ConfigError,
        Ready := #LifecycleSignals.Ready,
        TestCaseControlData := #TestCaseControlData,
        ControlData := #ControlData
    );
END_REGION
```

Suite-local diagnostics should be derived separately.

## Diagnostics

Suite-local diagnostic views such as active-Test-Case indicators are useful for engineering and online debugging. They are not part of the PLC/PC communication contract unless explicitly documented as such.

Diagnostics should be derived from status data. They should not duplicate execution decisions that are already owned by the Orchestrator.

Typical Suite diagnostics are:

- active Test Case indicators,
- current execution slot for slot-based parallel execution,
- local configuration checks,
- local readiness summaries.

Example:

```scl
REGION Diagnostics
    FOR #LoopIndex := 1 TO #TestCaseCount DO
        #TestCaseActive[#LoopIndex] := "IsTestCaseRunning"(ControlData := #TestCaseControlData[#LoopIndex]);
    END_FOR;
END_REGION
```

## Example Implementations

The framework contains example Test Suite implementations for both supported authoring patterns:

- `UnitTestSuite_Example`: shows direct Suite lifecycle and Test Case execution without generic helpers.
- `UnitTestSuite_Example_Serial`: combines `UnitTestSuiteSequencer` with serial Test Case orchestration.
- `UnitTestSuite_Example_Parallel`: combines `UnitTestSuiteSequencer` with parallel Test Case orchestration.
- `UnitTestSuite_Example_ParallelSlots`: combines `UnitTestSuiteSequencer` with slot-based parallel Test Case orchestration and shows slot assignment.

These examples are intended as authoring references for project-specific Test Suite implementations.

## Validation

Before using a Test Suite in a project, check that:

- The local Test Case count matches the number of registered Test Case instances.
- Each registered Test Case has explicit configuration.
- Each registered Test Case index has exactly one concrete Test Case call.
- The preferred implementation uses `UnitTestSuiteSequencer` and the Orchestrator matching the intended execution model.
- Slot configuration is complete when slot-based parallel execution is used.
- Suite code does not duplicate Sequencer lifecycle or Orchestrator execution logic.
- A direct implementation provides equivalent commands, lifecycle signals, monitoring, result, status, and event behavior.
- Orchestrator selection is based on execution and resource requirements, not EventBuffer sizing; no Adaptive variant is referenced.
- A framework Test Case Orchestrator owns global EventBuffer reservation behavior without competing Suite logic.
- A direct implementation provides equivalent normal-execution reservation and capacity behavior as well as capacity-aware Reset propagation.
- Suite status is published after subordinate Test Case calls.
- Suite Result and Aggregation events are emitted in `Completing` before the final transition into `Completed`.
- Suite-local diagnostics are not treated as PLC/PC contract data.
