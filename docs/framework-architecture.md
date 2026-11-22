# Framework Architecture

This document describes the stable high-level architecture of the S7 Unit Test framework.

It is intended as permanent library documentation. It explains how the framework is structured and how the main building blocks relate to each other. Exact PLC/PC interface semantics are defined in `contracts/`. Practical authoring guidance is defined in `docs/authoring/`.

## Supported Execution Scope

The framework supports unit testing standard (non-fail-safe) PLC logic in PLCSIM Advanced. Testing fail-safe (F) blocks is outside the supported scope. The current PC-side execution workflow does not provide an F-software download path; successful execution and CI integration for F-block tests are therefore not guaranteed. The framework does not provide functional-safety validation or certification.

An F-capable CPU or a successful engineering compilation alone does not establish support for testing its F program. Adding F-block support would require a separately designed and validated engineering, download, execution and automation workflow; it is not enabled by including an F station in the reference project.

## Execution Hierarchy

The framework is organized as a PLC-side execution hierarchy:

| Level | Main responsibility |
| --- | --- |
| Run Control | Owns one complete UnitTest run and binds the concrete Test Suites. |
| Test Suite | Groups related Test Cases and produces one Suite result. |
| Test Case | Executes one concrete test scenario and produces one Test Case result. |
| Preparation | Brings a tested resource into a required start condition for a Test Case. |
| Assertion | Evaluates one concrete condition and contributes to the owning Test Case result. |

Each level owns the level below it. Ownership includes start, abort, reset, readiness checks, monitoring where applicable, and result aggregation.

## Generic Execution Helpers

Reusable framework blocks encapsulate common execution behavior:

- `UnitTestRunControlSequencer` handles the generic Run Control lifecycle.
- Suite Orchestrators handle Suite execution below Run Control.
- `UnitTestSuiteSequencer` handles the generic Test Suite lifecycle.
- Test Case Orchestrators handle Test Case execution below a Test Suite.
- Test Case Sequencers handle the generic Test Case lifecycle.

Project-specific blocks should use these helpers when their execution model fits. This is the preferred implementation model because it keeps reusable lifecycle and orchestration behavior out of project-specific binding code. Their use remains optional; a project-specific owner that does not use a provided helper must implement the same lifecycle, signal, result, monitoring, and event behavior directly.

## Capacity-Aware Orchestration

Normal Test Case execution and hierarchical reset can both create event bursts. The generic Orchestrators use producer-side event-buffer capacity to bound subordinate dispatch without coupling PLC execution to consumer polling, drain intervals, or batch sizes.

### Normal Test Case execution

Each Test Case publishes `PreparationStateCount`, `TestStateCount`, and `AssertionCountTotal` in its control status. These values describe the longest finite executable lifecycle path and are valid when the Test Case is `Idle AND Ready`.

The Test Case Orchestrators derive a conservative event budget from these values. Before starting a candidate, an Orchestrator atomically adds the complete candidate budget to the producer-owned global EventBuffer reservation. The increase is accepted only when physical free capacity covers all global reservations, the candidate budget, and `UnitTest.EventBuffer.ExecutionHeadroom`. The repository default headroom is `10` entries.

Every Orchestrator owns one local aggregate contribution to the global reservation count and starts at most one Test Case per PLC cycle. A reservation is created before `Cmd.Start`. On the next Orchestrator call, the child must have left `Idle` or reached `Completed`; otherwise the reservation is released and the missing Start reaction is handled as a Framework error.

An accepted reservation is retained through execution, Abort, and finalization until the child reaches `Completed`. Parent Reset replaces execution reservations with Reset reservations and releases them when children reach `Idle AND Ready`. A successful hierarchical Run Control Reset therefore leaves no reservations. A failed Reset does not silently hide reservations belonging to children that did not return to the executable initial state.

The event-buffer command `BufferCmd.Reset` is the authoritative hard reset of buffered events, EventBuffer status, and global reservation accounting. It is separate from hierarchical Run Control lifecycle Reset. Invoking it during active UnitTest execution is invalid external use because it discards the capacity accounting on which active Orchestrators rely.

`Serial` preserves strict array order. `Parallel` selects the first currently fitting candidate in array order. `ParallelSlots` applies the same selection within the active slot and preserves slot order.

The producer-owned global count combines reservations from Test Case Orchestrators in concurrently active Test Suites. This prevents separate Orchestrators from allocating the same physical capacity even though their PLC calls execute sequentially.

`UnitTest.EventBuffer.ExecutionHeadroom` remains an unreserved shared margin for Run Control, Test Suite, Orchestrator, and exceptional Framework events. It is not a per-owner reservation and does not imply support for an unbounded number of simultaneous non-TestCase events.

A project-specific Test Suite implementation that does not use the generic Test Case Orchestrators remains responsible for equivalent capacity behavior when it claims this guarantee.

### Reset orchestration

Hierarchical reset can produce a short burst of lifecycle, result, aggregation, and diagnostic events. The generic Orchestrators therefore gate subordinate reset dispatch using the currently available event-buffer capacity.

`GetEventBufferFreeEntries` exposes the available producer capacity without coupling Orchestrators to FIFO implementation details. `UnitTest.EventBuffer.ResetHeadroom` defines the capacity that remains unallocated while new subordinate resets are admitted. The repository default is `20` entries.

Suite Orchestrators reset subordinate Suites sequentially and reserve `4` entries for the reset being started. Test Case Orchestrators admit capacity-bounded reset batches and reserve `3` fixed entries plus `3` entries for each active or newly started Test Case reset. Subordinate owners already in `Idle` and `Ready` are treated as reset-complete.

These values bound reset-generated event bursts; they do not define consumer timing or batch behavior. A project-specific owner that does not use the generic Orchestrators must implement equivalent capacity-aware reset scheduling.

## Project-Specific Binding

TIA/SCL does not provide dynamic FB dispatch or runtime creation of arbitrary multi-instances. Therefore, concrete project binding remains explicit:

- Run Control explicitly binds and calls the concrete Test Suites; their instance storage need not be embedded in Run Control.
- Test Suites declare and call the concrete Test Cases.
- Test Cases declare and call Preparations and Assertions.

The generic helpers encapsulate reusable lifecycle and orchestration behavior. The project-specific Full Owner remains the semantic owner and provides the static TIA binding, result composition, status publication, and owner-specific finalization around the helpers.

## Repository Implementation

The logical architecture is independent from concrete TIA software-unit names. In the provided TIA project, the framework and Self-Test roles are:

- `03_Handling`: reusable UnitTest framework and handling implementation.
- `90_UnitTest`: dedicated PLC-side UnitTest usage and framework self-test area.

The `90_UnitTest` area is intentionally separate from reusable framework implementation. It represents the project-local UnitTest execution area rather than an application production implementation area.

## Library Dependency Boundary

The reusable implementation in `03_Handling` owns its required datatypes, global framework DBs, helpers and the `UnitTestConstants` and `LoggingConstants` tables. Conversion and token-search/count helpers needed by framework blocks are included under its Utilities area. Consumers must not need the development project's `01_MainUnit`, `02_CommonUnit`, `90_UnitTest` or `CommonConstants` implementation data.

Internal timer sentinels/ceilings and numeric limits are block-local implementation definitions, not additional consumer configuration. Contract-bound constants remain shared definitions. Cycle time and startup information are explicit integration inputs; application-specific global access must not be hidden inside framework internals.

Library contents and an authoring application's selected dependency closure are different scopes. A minimal authoring base consumes only its core and required dependencies; Assertions are added for actual test intent. A compiling selected base does not establish independent compilation or runtime acceptance of the entire delivered catalog. See the [framework authoring model](authoring/framework-model.md).

## Lifecycle And Result Model

Run Control, Test Suite, and Test Case are Full Owners. They use the shared lifecycle states and publish their status through their control/status data.

`UnitTest.State.Completed` is the stable final lifecycle state for new owner logic. Normal completion, explicit abort, and controlled error termination all end in `Completed`; the final outcome is communicated through `Result`.

Finalization follows one consistent order:

1. Final owner Result event.
2. Final owner Aggregation event.
3. State-transition event into `UnitTest.State.Completed`.

The state-transition event into `Completed` is the final lifecycle event for that owner run. Result and Aggregation events describe the final outcome and the subordinate aggregation data, but they are not lifecycle-completion events.

## Events And Diagnostics

The PLC-side framework emits structured UnitTest events. The event stream is the normative source for automated result evaluation.

Run Control owns event-buffer request processing. Consumers request release or reset through the Run Control buffer-command interface; they never manipulate FIFO control, buffer status, or event entries directly. An event-buffer reset starts a new event-buffer epoch and is independent of the Run Control lifecycle reset.

The Logging subsystem encapsulates the producer-side EventBuffer storage, FIFO handling, initialization, reservation accounting, request processing, and status access. Only Logging blocks address `DB_UnitTestEventBuffer` directly. Run Control remains responsible for invoking request processing at the defined point in its cyclic execution, but it and all other UnitTest lifecycle, sequencing, orchestration, assertion, example, and entry-point blocks interact with the EventBuffer exclusively through semantic Logging utilities.

The EventBuffer FIFO is a framework-owned specialization in `PLC_1/03_Handling`, not a modification of the generic FIFO in `02_CommonUnit`. Its control type is `UDT_UnitTestEventBufferFifoControl`; the low-level helpers are `InitializeUnitTestEventBufferFifo`, `UpdateUnitTestEventBufferFifoStatus`, `PushUnitTestEventEntry`, and `PopUnitTestEventEntry`. They use explicitly passed control data and typed `UDT_UnitTestEventEntry` storage, so production storage and local Selftest fixtures can use the same FIFO implementation without generic `VARIANT` transfers. The generic FIFO remains independently usable alongside it.

The specialization retains the index-based ring algorithm. An array of `N` entries provides `N - 1` usable positions; occupied count is derived from the input/output indexes. Free-capacity, admission, budget, and headroom calculations use that usable capacity, not the physical array length. Reservations remain separate from occupancy. Published DB paths, field names, primitive types, and access restrictions remain unchanged; the event-stream contract defines the readable range and wrap boundary. Direct-access reads remain non-atomic as described by the PLCSIM Advanced communication contract.

Full Owner lifecycle, Result, and Aggregation evidence uses the Full Owner scopes:

- `UnitTest.OwnerScope.RunControl`
- `UnitTest.OwnerScope.TestSuite`
- `UnitTest.OwnerScope.TestCase`

Generic Sequencers emit lifecycle events for their Full Owner scope when they provide that owner's lifecycle state machine. Generic Orchestrators may emit technical state-transition diagnostics with dedicated Orchestrator scopes. These diagnostics help debug orchestration state machines and are not additional Full Owner completion evidence.

Assertion failed/error events are Assertion-owned findings. They contribute to Test Case result aggregation, but they are not final Test Case Result events.

### Optional PLC Diagnostic Consumer

`UnitTestEventBufferDiagConsumer` is a separate optional Logging FB for PLC-only execution without a PC application draining events. Its implementation is present in the PLC sources.

The normal framework execution path contains no production instance, instance DB, or call of this consumer. A project explicitly opts in by declaring an instance and calling it after Run Control in the same cyclic task, including during startup Reset and after run completion.

The consumer reads bounded batches in FIFO order and submits the last consumed `SequenceId` through `BufferCmd.DeleteSequenceId`. Run Control remains the sole caller of `ProcessUnitTestEventBufferRequests` and performs deletion on its next cyclic invocation. The consumer does not invoke that producer service or low-level FIFO helpers. Its counters describe consumed entries, not confirmed deletions; no additional deletion-confirmation workflow is introduced.

Diagnostic consumption intentionally discards event evidence. It does not evaluate test results, archive events, reset the EventBuffer, or change reservation accounting. Exactly one logical consumer owns an event-buffer epoch: diagnostic consumption and PC consumption are not used concurrently, and there is no automatic takeover on PC disconnection. Returning to PC evaluation requires a fresh event-buffer context and a new observed run; it cannot recover events already discarded by the diagnostic consumer.

See [Run Control Authoring](authoring/run-control.md#optional-plc-only-diagnostic-consumption) for the opt-in integration and handover procedure. The existing [event-stream contract](../contracts/event-stream-model-contract.md) remains authoritative for FIFO ranges, watermark requests, epochs, and evidence completeness; no PC-facing field or version changes are introduced.

## Status Views

Status views make the current PLC-side execution observable in TIA Portal and can be used by higher PLC levels for monitoring.

Status views are not a replacement for the event stream when a PC-side runner evaluates a completed UnitTest run. The PC-facing event-stream and direct-access semantics are defined in the contracts.

## Assertions

Assertions are reusable checks called by Test Cases. They keep their own result stable until reset and report findings through assertion-owned events when applicable.

The implemented assertion set covers scalar, bitfield, sequence, array, and text-array checks in the delivered catalog. Future assertion families should be added only when they provide clear repeated value for PLC-side library testing.

## Documentation Boundaries

Use the documentation set as follows:

- `docs/authoring/`: practical guidance for framework users.
- `docs/framework-architecture.md`: stable high-level architecture.
- `contracts/`: normative PLC/PC and cross-block contract semantics.
- [General TIA/S7 styleguide](../skills/s7unittest-framework-authoring/framework/engineering-skill/skill/references/s7-styleguide.md): general SCL guidance included in the standalone Authoring distribution.
- [UnitTest styleguide](../skills/s7unittest-framework-authoring/framework/docs/s7_unittest_styleguide.md): UnitTest-specific style and structure rules included in the same distribution.
- [Library usage](library-usage.md) and [project use](project-use.md): integration and validation of the delivered product.
