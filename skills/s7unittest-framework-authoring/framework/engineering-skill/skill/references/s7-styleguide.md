# TIA/S7 PLC Styleguide

## Status

Initial project-owner aligned styleguide version for upcoming implementation work.

This document defines general PLC-side style rules for SCL/ST source code in TIA Portal S7 library projects.

Project-specific rules refine this guide. This repository's UnitTest refinement is `docs/s7_unittest_styleguide.md`; apply it to UnitTest work, not as the default for unrelated S7 projects.

## Purpose

The styleguide exists to keep PLC code consistent, readable, debuggable, and maintainable in TIA Portal.

The code style must support:

- predictable cyclic execution,
- clear state-machine behavior,
- explicit resource interaction,
- good online observability in TIA Portal,
- low project-specific boilerplate where practical,
- reliable separation between production/library code and test-only code.

## Intended Audience

This styleguide is written for:

- developers implementing PLC library code,
- developers implementing PLC-side framework code,
- developers writing PLC-side test code,
- maintainers reviewing TIA Portal source exports,
- future code generation or scaffolding tools that emit TIA-compatible PLC source fragments.

## Scope

The styleguide covers general PLC-side source conventions for:

- block names,
- UDT names,
- variable names,
- constants,
- TIA folder naming for framework-owned source areas,
- generated or scaffolded PLC code.

It may be referenced by project-specific styleguides, but does not replace project-specific rules.

## Reading Routes

- Names and interfaces: [naming conventions](#naming-conventions) and [block interfaces](#block-interfaces).
- Metadata and attributes: [block headers](#block-header-metadata), [context matrix](#block-and-variable-attributes) and [storage responsibilities](#variable-attributes).
- Expressions and data: [type usage and conversion matrix](#type-usage-and-conversions), [bounded loops](#loop-bounds-and-termination) and [strings/large data](#strings-text-and-large-data-areas).
- Cyclic behavior: [execution order](#preferred-execution-order), [state machines](#state-machines), [timers](#timers-and-runtime-values) and [retained state](#var-var_temp-and-retained-state).
- Readable source: [regions](#regions), [line readability](#line-readability) and [indentation](#indentation).
- Project integration: [folder structure](#block-and-folder-structure), [Software Units and library copies](#software-units-namespaces-and-library-copies) and [generated code](#generated-and-scaffolded-code).

## Boundaries

This document does not define PLC/PC interface contracts. Contract-like decisions, including final UDT fields, protocol semantics, symbolic paths, and versioning rules, require explicit alignment before they are finalized.

This document does not define product behavior of library blocks. It only defines how PLC source should be written.

This document does not require test-only code inside production or library blocks. Test code must remain separated from production/library block implementations unless a specific exception is explicitly agreed for a higher technical purpose.

## Maintenance Rule

Changes to this styleguide shall be made deliberately and shall preserve concrete implementation and review value. Generic statements should be avoided unless they directly constrain PLC code.

## Naming Conventions

### General Naming Rules

Names shall be descriptive and stable enough to be useful in TIA Portal online views, watch tables, logs, and exported sources.

Use English names for new library/framework code, test code, manually created source folders, and documentation-facing identifiers.

Library projects should use `en-US` as the default TIA project language. TIA Portal creates localized default folders depending on the IDE setup; for manually created library/framework folders, use English names. If a localized TIA-generated default folder already exists, use the existing TIA folder instead of creating parallel German/English variants.

Prefer PascalCase for PLC block names, public interface variables, UDT fields, and local SCL constants.

Avoid abbreviations unless they are common in PLC or domain usage, for example `UDT`, `DB`, `ID`, `IO`, `PLC`, `PC`, `HMI`, `OPC`, `SCL`, `ST`, `FC`, and `FB`.

Names should be specific enough to distinguish behavior, but should not encode every implementation detail. Prefer the primary purpose over a full list of side effects.

Allowed:

- `PrepareAutoMode`
- `PrepareAutoModeUnlocked`
- `AssertEqual_LInt`

Avoid:

- `Prepare`
- `PrepareAutoModeUnlockedNoAlarmWithSimulationAndAck`
- `Test_1`

### Domain Prefixes

Reusable library/framework code shall use a clear domain prefix when names could collide with project-specific code or other libraries.

Domain prefixes are especially important for:

- global TIA user constants,
- shared UDTs,
- globally visible DBs,
- framework entry points,
- reusable utilities,
- generated or scaffolded code.

The prefix shall identify the owning library or framework domain, not the implementation detail.

Examples:

- `UnitTest...` for unit-test framework concepts,
- `Json...` for JSON library concepts,
- `AnalogInput...` for analog-input library concepts,
- `EthernetConnection...` for ethernet connection concepts.

Avoid generic globally visible names:

- `Status`
- `Result`
- `State`
- `Command`
- `Event`
- `Buffer`

Use generic names only for local variables or nested fields where the owner context is already explicit.

If the domain is already clear from the local context and no collision with another domain is expected, prefer the shorter name without a repeated domain prefix.

Examples:

- Inside `UDT_UnitTestRunStatus`, field `State` is preferred over `UnitTestRunState`.
- Inside `UnitTestRunControl`, local variable `RuntimeTimer` is preferred over `UnitTestRunControlRuntimeTimer`.
- For a globally visible constant, `UnitTest.RunState.Idle` is preferred over `RunState.Idle`.

### Block Names

Block names shall identify the responsibility of the block.

Common action prefixes:

| Responsibility | Prefix | Example |
| --- | --- | --- |
| Read access | `Read` | `ReadCycleTime` |
| Write access | `Write` | `WriteAnalogInputData` |
| Reference/value access | `Get` | `GetAnalogInput` |
| Apply condition/configuration | `Set` | `SetValveCondition` |
| Acknowledge operation | `Ack` | `AckValveError` |
| Top-level execution | `Execute` | `ExecuteSimulation` |
| Simulation | `Simulate` or `SIM_` | `SimulateDigitalInput`, `SIM_AnalogInput` |

Use numeric suffixes only when the number is a stable part of the tested configuration, resource identity, or established hardware/domain notation. Do not use numbers only to avoid finding a meaningful name.

Underscores in block names shall be avoided for new code, except when separating a datatype suffix or when preserving a well-established external acronym/domain notation improves readability.

Allowed:

- `AssertEqual_LInt`
- `AssertEqual_WString`
- `Valve_1Q_NO` where the hardware notation is already established.

Avoid:

- `Test_Status_ManualMode`
- `Prepare_EnabledNoCause`

Do not use `FB_` or `FC_` prefixes as the default naming style for function blocks and functions. The block kind is already visible in the SCL declaration, and the name should primarily describe responsibility.

Allowed:

- `UnitTestRunControl`
- `ReadCycleTime`
- `SetValveCondition`

Avoid as default style:

- `FB_UnitTestRunControl`
- `FC_ReadCycleTime`
- `FC_SetValveCondition`

Use `OB_` only when it improves clarity for explicitly named organization blocks. Names such as `Main` or `CyclicInterrupt_100ms` are acceptable without an `OB_` prefix.

### PLC Data Type Names

PLC data types shall use the `UDT_` prefix.

Use the pattern:

```text
UDT_<Domain><Purpose>
```

Examples:

- `UDT_AnalogInputControl`
- `UDT_DigitalOutputSettings`
- `UDT_UnitTestEventEntry`

Shared UDTs shall include the owning domain after the `UDT_` prefix. Do not create globally reusable UDTs with names such as `UDT_Status`, `UDT_Result`, or `UDT_Event`.

Common suffixes:

- `Control` for command/control structures,
- `Status` for read-oriented status structures,
- `Config` for configuration structures,
- `Settings` for runtime-adjustable settings or parameters,
- `Result` for result structures,
- `EventEntry` for event stream entries,
- `Buffer` for buffer structures.

Do not use different UDT prefixes unless explicitly aligned.

### Data Block Names

Global data blocks should use the `DB_` prefix when they expose persistent data areas, framework-owned data, externally visible data, or shared library state.

Examples:

- `DB_UnitTestControl`
- `DB_UnitTestEventBuffer`
- `DB_AnalogInputData`

Use `IDB_` for explicitly named instance DBs when the instance DB must be named and referenced as an artifact.

Examples:

- `IDB_UnitTestRunControl`
- `IDB_UnitTestSuites`

Do not use `DB_` for local FB instances declared inside another FB. Local instance names should describe the instance role without pretending to be global DB artifacts.

### Constants

Use descriptive names for constants.

State machines and other numeric value lists shall always use explicit named constants or, if explicitly chosen, named value types. Do not use magic numbers for states, results, modes, event types, owner scopes, error codes, or comparable classification values.

For local SCL constants inside a block, use PascalCase names with a domain prefix when collisions are possible.

Examples:

- `RunState_Idle`
- `RunState_Reset`
- `TestCaseState_Preparation`
- `Result_Passed`
- `Result_Failed`
- `MaxCnt_EventBufferEntries`
- `MaxLen_MessageText`

For global TIA user constants in tag tables, dot notation may be used to create readable logical groups.

Examples:

- `UnitTest.RunState.Idle`
- `UnitTest.RunState.Reset`
- `UnitTest.TestCaseState.Preparation`
- `UnitTest.Result.Passed`
- `UnitTest.EventType.TestCaseCompleted`
- `AnalogInput.Condition.HighHigh`
- `Json.ElementType.Object`

Do not use overly generic global constant groups such as `State.Idle`, `Result.Passed`, or `EventType.Started` when multiple libraries or frameworks can be integrated into the same project. The group name shall identify the owning domain and concept.

Existing all-uppercase constants may remain in existing code. New code should prefer readable PascalCase or grouped dot notation depending on whether the constant is local SCL or a global TIA user constant.

Reuse an existing constant when its meaning, datatype, units and required value match the purpose and it is accessible from the actual use site. Resolve its definition rather than assuming that a familiar name such as `T_OFF` is globally available. Do not duplicate the same definition merely to change its scope or spelling.

When no suitable accessible definition exists and the value is an implementation-local invariant, declare a descriptive local constant in `VAR CONSTANT` instead of leaving an unresolved global reference or writing a magic number. This is an engineering implementation decision, not a request for the user to select an ordinary constant. A missing contract-owned or externally shared definition is different: resolve that authoritative dependency rather than inventing an independent local replacement.

When introducing a constant, prefer the narrowest useful scope. Local constants near the state machine or logic that uses them are preferred because they keep the code readable and reduce global namespace pressure.

Within one concrete state machine, avoid mixing local and global state constants.

Prefer one of these two forms:

- an entirely global state-constant set,
- or an entirely local state-constant set.

Mixing local and global state constants inside the same state machine is allowed only when no cleaner alternative exists and the reason for the mixed model is explicit in the design.

Use global TIA user constants when at least one of the following applies:

- the value is used by multiple blocks,
- the value is part of a public or project-wide interface,
- the value is consumed by HMI, OPC, PC-side tooling, or generated code,
- the value must stay stable across framework/library boundaries,
- local constant memory or duplication becomes a relevant constraint.

Named value types may be considered as an alternative to global constants, but they are not the default recommendation. Use them only when their TIA Portal behavior is acceptable for the concrete use case.

Do not use named value types for contract-relevant or externally consumed values unless the project owner explicitly approves the decision after checking TIA export, online debugging, and external consumer behavior.

### Public Interface Variables

Public block interface variables shall use PascalCase.

Common signal names:

- `Reset`
- `Enable`
- `Run`
- `Start`
- `Abort`
- `Active`
- `Ready`
- `Running`
- `Completed`
- `Error`
- `Timeout`
- `Result`
- `State`
- `Status`

Use `Completed` as the preferred term for new lifecycle logic. Use `Finished` only for compatibility with existing code or for deliberately simple helper blocks.

Use positive boolean names where practical.

Allowed:

- `Enable`
- `Ready`
- `Running`
- `Completed`

Avoid new negative names:

- `NotReady`
- `NoError`
- `NotCompleted`

Exception: domain names that are already meaningful, such as `NoLimit`, may be used when the negative term is part of the tested feature.

### Internal Variables

Internal variables shall use PascalCase unless a suffix is used to mark a cyclic helper role.

Allowed suffixes:

| Suffix | Meaning |
| --- | --- |
| `_old` | previous-cycle value |
| `_Internal` | internal normalized or intermediate signal |

Examples:

- `Enable_old`
- `Completed_old`
- `Input_Internal`
- `RuntimeTimer`
- `TimeoutTimer`
- `WaitTimer`

Do not create multiple suffix styles for the same purpose.

Avoid:

- `oldEnable`
- `EnableOld`
- `EnablePrev`
- `EnablePrevious`
- `Runtime_Timer`

Do not use datatype prefixes for variables.

Avoid:

- `bEnable`
- `xStart`
- `iState`
- `stStatus`
- `udtData`

Variable names shall describe role and meaning, not the implementation datatype.

New code shall use PascalCase for variables in all declaration sections.

Do not encode scope or datatype through first-letter casing.

Avoid using lowerCamelCase as a convention for local variables.

Existing generated, TIA-provided, or legacy names may remain until an explicit migration is performed.

### Command And Status Fields

Command fields that can be written by an external owner shall be grouped under a clearly named command section.

Use `Cmd` for command sections when following existing PLC library conventions.

Use `Status` for read-oriented status sections where a nested structure is useful.

Use `State` only for an actual state-machine state or for a copy of such a state.

A `State` value represents the current step of a defined state machine. It shall not be used as a generic name for arbitrary communication, diagnostic, progress, or result information.

Use `Status` for externally visible or higher-level communication information that summarizes, derives, aggregates, or exposes the condition of a block or owner.

Status information may contain a copy of an internal state-machine state, but the status structure itself is not the state machine.

When a block needs both internal execution logic and external observability, use this distinction:

- `State`: local static variable owned by the block's state machine.
- `Status.State`: read-only copy of the state-machine value if the state shall be externally visible.
- `Status.*`: derived communication flags, aggregation values, diagnostics, result information, timing information, or other externally useful observations.

Do not name derived lifecycle summaries, result classifications, or diagnostic classifications as `State` if they are not the actual state-machine step.

Command fields shall use action names:

- `Start`
- `Abort`
- `Reset`
- `Acknowledge`

Status fields shall use status, result, and state-copy names:

- `Ready`
- `Running`
- `Completed`
- `Error`
- `Result`
- `State` only when it is a state-machine copy as defined above.

Writable command fields and read-oriented status fields shall not be mixed in the same nested structure.

### Configuration Versus Settings

Use `Config` or `Configuration` for values that are fixed during programming or commissioning and define a stable behavior, block variant, resource assignment, or project-specific mapping.

Configuration values are hard-coded in source code, generated code, or commissioning-time project implementation. They shall not be changed by higher-level runtime applications such as HMI, OPC UA, SCADA, Web API, or PC-side tooling.

Configuration defines how a block works in the application project or which fixed project-specific assignment it uses.

Use `Settings` or `Parameter` for values that may be changed during runtime by higher-level applications such as HMI, OPC UA, SCADA, Web API, or PC-side tooling.

Settings and parameter values shall be stored in retentive PLC memory.

Examples:

- `UDT_AnalogInputConfig` for selected measuring range, channel assignment, or enabled diagnostics.
- `UDT_AnalogInputSettings` for runtime-adjustable thresholds, delays, setpoints, or tolerance values.

If it is unclear whether a value is configuration or setting, align the decision before committing the interface. The decision affects retentivity, external write access, setpoint marking, backup strategy, and expected runtime change behavior.

## Block Interfaces

### General Interface Principles

Block interfaces shall make dependencies and side effects visible without making calls unnecessarily large.

Avoid excessive parameter lists. If a call requires many related parameters, check whether a structured UDT, a smaller block responsibility, or a different access pattern is more appropriate.

Do not use datatype prefixes in interface variable names.

Use names that describe the role of the value at the block boundary.

Allowed:

- `Enable`
- `Reset`
- `CycleTime`
- `Timeout`
- `Status`
- `Result`
- `ResourceData`
- `Control`

Avoid:

- `bEnable`
- `xReset`
- `diCycleTime`
- `stStatus`
- `udtControl`

### Helper Functions And Helper Blocks

Helper functions or helper FBs with a small interface and no ownership of an independent worker object should prefer explicit parameter passing through the block interface.

This applies to:

- stateless calculations,
- conversions,
- small validation helpers,
- small assertion-like checks,
- formatting helpers,
- simple access helpers.

For these blocks, explicit `VAR_INPUT`, `VAR_OUTPUT`, and `VAR_IN_OUT` parameters are usually clearer than hidden DB access.

### Worker Objects

A block that owns an independent worker object shall use at least one structured control/status UDT or equivalent structured data model.

A worker object is a block or component that has its own lifecycle, state, commands, status, diagnostics, resource ownership, or external interaction.

For worker objects, choose the access pattern deliberately:

- pass a control/status UDT through `VAR_IN_OUT` when the caller owns the storage and the worker operates on that object,
- pass input and output UDTs separately when read/write separation is important,
- pass an ID and use getter/setter functions when the worker operates on a global DB-backed object collection,
- use references only when a concrete TIA-specific reason justifies them and performance/usability are acceptable.

Getter/setter access is appropriate when DB access should be encapsulated, validated, or normalized.

Direct interface passing is appropriate when the dependency should remain visible at the call site and the caller intentionally provides the data object.

Do not choose getter/setter access only to hide an overly large interface. First check whether the block responsibility is too broad.

### VAR_INPUT

Use `VAR_INPUT` for command signals, configuration values, IDs, mode flags, caller-provided runtime values, timeouts, and other values that the block reads but does not write.

Under this styleguide's data-area convention, runtime-adjustable settings or parameters belong to a deliberate retentive settings/parameter area, not implicitly inside code-block instance state. This is a design choice, not a Siemens prohibition on SetPoint in FB Static. Setting `S7_SetPoint := 'False'` on an eligible private static field does not introduce a setting.

Inputs should be small and intentional. If many inputs always belong together, use a UDT.

### VAR_OUTPUT

Use `VAR_OUTPUT` for results and status signals produced by the block.

Outputs shall be assigned deterministically.

If a block exposes many related status values, prefer a structured status UDT over many separate outputs.

### VAR_IN_OUT

Use `VAR_IN_OUT` when the block intentionally reads and writes an external structure or resource.

`VAR_IN_OUT` names shall clearly identify the modified object.

Allowed:

- `Control`
- `Status`
- `EventBuffer`
- `ResourceData`
- `AnalogInputData`

Avoid unclear names:

- `Data`
- `Info`
- `Temp`
- `InOut`

Do not use `VAR_IN_OUT` only to avoid defining ownership. The caller and callee responsibilities for the passed object must be clear.

### References

References are not the default access mechanism for library/framework code.

Use references only when the expected benefit is clear and TIA Portal performance, readability, online debugging, and source export behavior are acceptable for the concrete use case.

## SCL/ST Coding Conventions

### General Coding Principles

Prefer readable, explicit, and observable code over compact or overly generic code.

PLC code is cyclic and stateful by default. Every block shall make its cyclic behavior, retained state, and side effects easy to understand in TIA Portal.

Use high-level software engineering principles where they fit PLC constraints:

- one block should have one clear responsibility,
- one region should group one coherent processing step,
- public interfaces should be small and intentional,
- side effects should be explicit,
- error and reset behavior should be visible,
- duplicated logic should be reduced when it improves maintainability without hiding behavior.

Do not optimize for cleverness. PLC code must remain debuggable with the limited online debugging and watch capabilities available in TIA Portal.

### Preferred Execution Order

For cyclic FBs, use a stable execution order unless a block has a clear technical reason to differ.

Cyclic logic should follow this general processing model:

1. Assign required default values and static values; read and normalize inputs.
2. Preprocess commands, configuration checks, timers, and edge-detection helper values.
3. Execute main processing, usually the state machine or main logic.
4. Call subordinate blocks and aggregate subordinate results.
5. Write status data and outputs.
6. Memorize values required for the next cycle.
7. Clean up owned one-shot commands.

The following preferred order is the default concrete implementation of this model for cyclic FBs:

1. Assign required default values and static values; read and normalize inputs.
2. Handle reset and abort conditions.
3. Update timers and edge-detection helper variables.
4. Execute state-machine or main logic.
5. Call subordinate blocks.
6. Aggregate subordinate results.
7. Write outputs and status data.
8. Memorize previous-cycle values.
9. Reset one-shot commands if the block owns them.

The order shall be visible through regions or clearly separated code sections.

### Regions

Use `REGION` blocks to improve navigation in TIA Portal.

Region names shall describe processing intent, not implementation trivia.

Recommended region names:

- `Inputs`
- `Default Values`
- `Reset`
- `Configuration`
- `Timers`
- `State Machine`
- `Sub-Blocks`
- `Aggregation`
- `Outputs`
- `Memorize Old Values`
- `Reset One-Shot Commands`

Do not use regions as a substitute for clear block structure. If a region becomes too large, consider extracting a helper block or reducing responsibility.

### State Machines

State machines shall be implemented with explicit state variables and named constants or approved named value types.

Use `CASE` for state-machine dispatch unless a simpler `IF` structure is clearly more readable.

Each state shall have a clear responsibility. State transitions shall be explicit assignments to the state variable.

Configuration errors shall be detected in explicit local error variables before state-machine dispatch logic.

State-machine states shall react to those local error variables instead of embedding configuration validation expressions directly inside individual state branches.

Do not hide state transitions in deeply nested expressions or subordinate calls.

Outputs that depend on state shall be assigned in one clearly identifiable place where practical.

State-machine logic shall define reset behavior explicitly. PLC startup and restart behavior shall be deterministic and shall lead the state machine into a defined safe state.

Every state machine shall define what happens on PLC startup, warm restart, and explicit reset where these cases are relevant to the block.

Do not rely on accidental retained values after startup unless retained behavior is explicitly required and documented.

If startup behavior depends on first-cycle detection or an external reset command, the dependency shall be visible in the block interface or in a clearly named helper call.

The safe state shall be chosen so that no unintended command, actuator request, resource manipulation, communication acknowledgement, or test execution continues only because the PLC restarted.

One-shot abort commands shall be handled in every active or transitional state in which the block resets the command at the end of the same cycle. Do not defer abort handling only to a later steady state such as `Running` when transient states such as `Starting` or `Preparing` can consume and clear the command first.

Blocks that own cyclic state machines shall be implemented as `FUNCTION_BLOCK`s.

The state variable shall be owned by the FB that owns the state machine. For cyclic FB state machines, the state variable shall be a local static `VAR` of the owning FB.

The recommended local variable name is `State`. If more than one state-like variable appears necessary, treat this as a refactoring signal.

Do not let subordinate blocks or external users write the state variable directly. Any externally visible state information shall be a copied status value derived from the local state variable.

Status structures are not the state machine. A status field such as `Status.Execution.State` shall only expose a copied view of the local state variable.

State values shall use named constants. Error states should use negative values. Normal lifecycle states should use non-negative values.

Use value gaps to allow later insertion of states. For most use cases, steps of 10 are sufficient.

Example:

```scl
VAR CONSTANT
    State_Error : Int := -10;
    State_Idle : Int := 0;
    State_Reset : Int := 10;
    State_Preparing : Int := 20;
    State_Running : Int := 30;
    State_Completing : Int := 40;
    State_Completed : Int := 50;
END_VAR
```

For complex public or framework-wide state models, use domain-prefixed constants according to the constant naming rules.

Render state dispatch under [Expression Contexts](#expression-contexts). Keep framework-defined state relationships visible without duplicating their numeric values or introducing a second state variable merely to obtain a branch label.

Every `CASE`-based state machine shall have an `ELSE` path. The `ELSE` path shall handle invalid or unknown states explicitly, usually by entering an error state or performing a controlled reset.

A `CASE` used only for selection or action dispatch may deliberately omit `ELSE` when unlisted values are intended to cause no action. Reading a state variable does not by itself make that dispatch a state machine. Review which code owns state transitions and invalid-state handling; do not impose the state-machine requirement on every `CASE` statement.

Do not leave a `CASE` branch empty. If a state intentionally has no functional work in the current cycle, insert an explicit empty statement in that branch. When state regions are used, place the empty statement inside the corresponding `REGION`.

Do not leave `IF`, `ELSIF`, or `ELSE` branches empty. If a branch intentionally has no functional work, insert an explicit empty statement in that branch. When regions are used inside the branch, place the empty statement inside the corresponding `REGION`.

State code shall be compact and focused on state-machine behavior and transitions. Move complex calculations, IO mapping, formatting, or subordinate behavior into helper functions, helper FBs, or clearly separated regions.

For larger state machines, use sub-regions for individual states when this improves navigation.

When a transition inside a state means that the remaining logic of the current state shall not be executed, prefer an explicit common state-machine exit point over long or dense nested `IF / ELSIF` structures.

In TIA/SCL, a single `EndOfStateMachine` label with a targeted `GOTO` is acceptable for this narrowly scoped purpose when it improves readability of state-transition logic.

Use this pattern only for explicit early exit from the current state-machine pass. Do not use `GOTO` as a general-purpose control-flow substitute.

Do not add `GOTO EndOfStateMachine` mechanically as a boilerplate end to every state. Use it only when the remaining logic of the current state would otherwise be executed unnecessarily or would require a less readable control-flow structure.

The jump label belongs to the state-machine dispatch itself. Place `EndOfStateMachine` directly after the `END_CASE` of the state machine, either inside the same region or immediately after it.

If no meaningful statement already exists at that exact point, define the label with an empty statement, for example `EndOfStateMachine: ;`.

Recommended pattern:

```scl
REGION State Machine
    CASE #State OF
        #State_Idle:
            REGION State Idle
                // state logic and transitions
            END_REGION

        #State_Running:
            REGION State Running
                // state logic and transitions
            END_REGION

        ELSE
            #State := #State_Error;
    END_CASE;
END_REGION
```

For small state machines, omit per-state sub-regions if they reduce readability.

Multiple state machines inside one FB are a code smell. They are allowed only when the responsibilities are clearly independent and still belong to the same FB. If multiple state machines are needed, explicitly check whether one of them should be moved into a subordinate FB.

Transitions should be kept in the state-machine region. Avoid distributed transition assignments across unrelated regions.

State entry and exit behavior shall be explicit when it matters. Use `State_old`, `StateChanged`, or a clearly named equivalent when entry/exit detection is required.

Terminal states such as `Completed` or `Error` shall remain stable until an explicit reset, acknowledge, or other defined release condition occurs.

Waiting states shall have an observable reason to continue waiting. If the wait can fail or block indefinitely, provide timeout or error handling.

### Boolean Logic

Boolean expressions shall be readable without relying on operator precedence.

Use parentheses when combining `AND` and `OR`.

Do not embed a function call that modifies global, static or caller-owned data in a larger expression. Execute the operation separately and use its returned result in subsequent logic so processing order remains explicit. Pure value-returning calls remain permitted; do not split simple expressions into meaningless aliases. Siemens explicitly warns against global/static side effects in [SCL expressions](https://docs.tia.siemens.cloud/r/en-us/v21/creating-scl-programs/basics-of-scl/expressions).

A Boolean operand is not a proven execution guard for a dependent array access, dereference or division. Establish validity through explicit control flow before evaluating the dependent operation. Do not rely on short-circuit evaluation of `AND` or `OR` without an applicable documented guarantee; no such guarantee is established here. This is not a claim that every Boolean operand is always evaluated.

Prefer positive logic where practical.

Prefer local aggregation variables for branching conditions when the condition has business or control-flow meaning.

Aggregation variables shall have strong semantic cohesion. They shall describe one clear decision or one clear intermediate signal, not an arbitrary bundle of unrelated checks.

Allowed:

```scl
#CanStart := #Enable AND #Ready AND NOT #Error;
#MustAbort := #Abort OR #Timeout;

IF #CanStart THEN
    #State := #State_Running;
END_IF;
```

Avoid:

```scl
IF (#Enable AND #Ready AND NOT #Error AND NOT #Abort AND #Mode = #ModeAuto) OR #Force THEN
    #State := #State_Running;
END_IF;
```

Multiple aggregation variables may be used when they represent distinct concepts.

Allowed:

```scl
#HasValidCommand := #Start OR #Abort OR #Reset;
#CanAcceptStart := #Ready AND NOT #Running AND NOT #Error;
#StartRequested := #Start AND #CanAcceptStart;
```

Do not reuse one signal for unrelated functionality. A signal should have one clear meaning. Reusing a signal for several responsibilities is a code smell because later changes can create unintended side effects.

This is especially important for communication signals between blocks. Command, status, acknowledgement, and event handover signals shall not be overloaded with secondary meanings.

Allowed:

```scl
#CanStart := #Enable AND #Ready AND NOT #Error;
```

Avoid:

```scl
#CanStart := NOT #NotReady AND NOT #NoError = FALSE;
```

### Timers And Runtime Values

Siemens timer instructions, internal elapsed-time accumulation and reusable custom timer blocks are valid solutions; none is the universally preferred choice. Select by required behavior, time base, invocation model, reuse, clarity and cost. Preserve suitable existing accumulation patterns rather than replacing them solely for uniformity. Introduce a custom timer abstraction only for an actual coherent reuse need.

Timer and runtime calculations shall make their time base explicit.

For internal accumulation, define the time source and unit, start/reset/inactive behavior, treatment of call gaps and overflow handling. Repeated calls are not additional elapsed PLC cycles; use the actual time model rather than counting invocations as time unless that is the specified model.

When using a Siemens timer, identify the particular instruction, owning instance, invocation/observation sequence and supported reset mechanism. Skipping its call is not a reset. Do not use one instance as independent timers or overwrite internal fields to simulate a supported reset. Check the instruction-specific rules for preset-time changes and output observations. For example, S7-1500 [TON](https://docs.tia.siemens.cloud/r/en-us/v21/scl-s7-1200-s7-1500-s7-1200-g2/timer-operations-s7-1200-s7-1500-s7-1200-g2/ton-generate-on-delay-s7-1200-s7-1500-s7-1200-g2) documents edge-related PT capture and Q/ET updates on qualifying calls or access to Q/ET. Do not generalize this to every timer, assume only calls update timer data, or treat every timer read as passive.

If a timer is incremented from cycle time, the source of cycle time shall be visible in the block interface, a clearly named helper, or a documented project convention.

`CycleTime` shall be represented as `DInt` in milliseconds by default.

Negative time values may be used intentionally to disable timer behavior. The disabling semantics shall be explicit in the block interface comment or in the owning logic.

Runtime and timer accumulators shall normally use `DInt` in milliseconds so cyclic timer calculations do not require repeated conversions.

Use `LInt` only in rare cases where the expected runtime range requires it.

For expected values larger than the useful `DInt` millisecond range, convert deliberately to a larger time unit when millisecond accuracy is not required.

Timeout values shall use named constants, inputs, or configuration fields. Do not use timeout magic numbers directly in logic.

Runtime and timeout variables shall use descriptive names, for example `RuntimeTimer`, `TimeoutTimer`, or `WaitTimer`.

### Edge Detection

Previous-cycle helper variables shall use the `_old` suffix.

Edge detection shall be easy to review.

Allowed:

```scl
#StartEdge := #Start AND NOT #Start_old;
#Start_old := #Start;
```

Do not update previous-cycle values before all logic that depends on the old value has executed.

### Assignments And Defaults

Outputs and status fields shall be assigned deterministically.

For blocks with conditional outputs, define a clear default assignment or a clear state-based assignment model.

Avoid leaving outputs dependent on old retained values unless retained output behavior is intentional and documented.

Temporary variables shall not be treated as a reliable source of retained or implicit default values.

`VAR_TEMP` values shall be assigned deterministically before they are read in every relevant block call path.

An explicit default assignment near the beginning of the block is required when a temporary value is assigned through conditional, branched, optional-loop, or otherwise partial paths and is read afterwards in shared logic.

An explicit default assignment near the beginning of the block is not required when the temporary value is written unconditionally before every read, or when the value is used only inside a region that unconditionally creates it before local use.

For complex calculations, signal generation, event payloads, and aggregation logic, initialize important temporary variables at the start of the region that owns the value unless that region itself writes the value unconditionally before any read.

Do not rely on a temporary variable keeping a previous value across cycles or calls.

### VAR, VAR_TEMP, And Retained State

Use `VAR_TEMP` for values that are only valid during one block call.

In FBs, use static `VAR` only for instance state that must survive across calls, such as:

- state variables,
- timers or accumulated runtime values,
- previous-cycle values,
- subordinate FB instances,
- one-shot latch state.

Persistence between calls is not power-failure retentivity. A non-retentive FB instance still preserves static state between ordinary calls. An FC has no static instance area; persistent resources accessed by an FC belong to the caller or a global data area. See the [attribute decision matrix](#block-and-variable-attributes).

Do not store intermediate values in `VAR` only because it is convenient for online observation. If observation is needed, expose intentional status fields instead.

### VAR_IN_OUT And Side Effects

Use `VAR_IN_OUT` only when the block intentionally reads and writes an external structure or resource.

Any block that modifies `VAR_IN_OUT` data shall make that side effect obvious through:

- the block name,
- the interface name,
- region structure,
- concise comments where necessary.

Do not pass resources through many layers only to hide where they are modified.

### Function Versus Function Block

Use `FUNCTION` for stateless calculations, conversions, accessors, and helper operations.

Use `FUNCTION_BLOCK` when the block has instance state across calls, cyclic behavior, timers, edge detection, or subordinate FB instances. Power-failure retention remains a separate decision.

Do not implement cyclic state machines as `FUNCTION` blocks without retained context.

For `STRING` and `WSTRING` declarations in block interfaces, do not specify an explicit maximum length when the relevant TIA interface rules only permit the standard interface length. In those interface sections, declare `STRING` or `WSTRING` without `[n]`.

Use explicit string-length declarations only for local variables, DB fields, UDT members, or other declaration contexts where the TIA rules explicitly allow them and where the chosen size is part of the intended design.

In declarations, prefer quoted field names consistently. When declaring block-interface parameters, local declaration fields, DB members, or UDT members, write the field name in double quotes so that identifier collisions with TIA keywords or header attributes do not cause import ambiguities.

Select declaration attributes using [Block And Variable Attributes](#block-and-variable-attributes). Do not infer attribute support merely from the presence of `VAR_INPUT`, `VAR_OUTPUT`, or `VAR_IN_OUT`: the block kind, datatype, access mode, and actual storage owner matter. Project-specific values and source-import restrictions belong in the local project styleguide.

### FC Return Value Versus VAR_OUTPUT

Use the FC return value for exactly one primary stateless result.

If an FC has a non-`VOID` return type, calls to that FC shall assign the return value explicitly to a variable or use it explicitly in an expression.

Do not use bare statement calls for FCs with a meaningful return value.

If no return value is needed, declare the FC with `VOID` instead of inventing a dummy return value.

Good return-value use cases:

- predicates such as `IsValidReal() : Bool`,
- simple calculations such as `ReadCycleTime() : DInt`,
- conversions such as `IntToBcd() : Int`,
- compact text creation such as `CreateSourceText() : String`.

Use `VAR_OUTPUT` when the function produces multiple results, result plus status, error details, diagnostics, or when the call site becomes clearer with named outputs.

Do not hide important status or error information behind a return value.

### ENO

`ENO` shall describe whether the block call itself could execute and produce valid outputs according to its technical preconditions.

`ENO` shall not be used as the primary carrier for business logic, process state, test result, expected validation failure, or normal negative predicate result.

Recommended logic:

- Set or leave `ENO = TRUE` when the block executed normally, even if the functional result is `FALSE`, `Failed`, `Completed`, or another valid negative/terminal result.
- Set `ENO = FALSE` only for exceptional technical conditions where outputs cannot be trusted or the requested operation could not be performed according to the block contract.
- For invalid input ranges, unsupported modes, invalid references, or impossible preconditions, set explicit status/error outputs and set outputs to defined safe/default values before setting `ENO = FALSE`.
- When calling Siemens/system blocks that expose `ENO`, translate relevant `ENO` failures into explicit local status, error, or diagnostic signals before leaving the current block.

Do not chain framework or application control flow only through `ENO`. Use explicit variables such as `Error`, `Status`, `Result`, `ErrorCode`, or `Diag` for readable logic.

When correctness relies on `ENO`, establish how the particular instruction or block generates it and whether automatic ENO calculation is enabled where required. In SCL, [automatic ENO generation](https://docs.tia.siemens.cloud/r/en-us/v21/programming-basics/handling-program-execution-errors/en/eno-mechanism/en/eno-mechanism-in-scl/overview-of-the-en/eno-mechanism-in-scl) is disabled by default and adds execution cost when enabled; this does not describe every system instruction's explicit error output. Do not silently change the setting. Capture the relevant result before subsequent execution makes its attribution ambiguous. Follow the documented [reset/rearm procedure](https://docs.tia.siemens.cloud/r/en-us/v21/programming-basics/handling-program-execution-errors/en/eno-mechanism/en/eno-mechanism-in-scl/using-enable-output-eno-with-scl-instructions) when observing successive operations, without inserting unconditional ENO resets after every statement or discarding an error before handling it.

### UDT Versus Struct

Use UDTs for structures that are reused, externally visible, documented, contract-relevant, status-relevant, command-relevant, or shared between blocks.

Use local or anonymous `Struct` only for private, non-reused structuring where no public interface or reuse is expected.

For reusable library/framework interfaces, prefer UDTs over anonymous structs.

Explicit initial values in UDTs should have a meaningful justification. Prefer defining shared initial values in the UDT rather than repeating them for each instance. Define usage-specific deviations at the respective point of use.

### Declaration Sections

Use a consistent declaration order where TIA export behavior allows it:

1. `VAR_INPUT`
2. `VAR_OUTPUT`
3. `VAR_IN_OUT`
4. `VAR`
5. `VAR_TEMP`
6. `VAR CONSTANT`

If TIA Portal reorders declarations during export, do not fight the tool. Keep the logical separation clear within the exported form.

#### Expression Contexts

Choose syntax for its declaration or executable context before writing it. An expression accepted in an assignment or condition is not automatically accepted in a declaration initializer or a `CASE` branch label.

- Declare local constants in `VAR CONSTANT`, with their datatype and a supported declaration value, without field attributes. Do not assume that TIA folds arithmetic or function calls in that interface section. For a derived invariant, calculate the declaration value beforehand and retain the meaningful derivation as a short comment. Perform actual runtime calculations in executable logic, not in a constant declaration. Siemens documents the interface restriction for [expressions with local constants](https://docs.tia.siemens.cloud/r/en-us/v20/migrating-projects-and-programs/migrating-projects-to-a-tia-portal-project/migrating-step-7-projects-s7-300-s7-400/special-points-to-observe-during-migration-s7-300-s7-400/migrating-scl-programs-s7-300-s7-400).
- In executable assignments, call arguments, conditions and `CASE` selectors, use supported expressions with the required result datatype. A direct state-offset comparison is not a reason to duplicate the framework's state constants.
- Use supported literal or named constant values, lists or ranges for `CASE` branch labels, not arithmetic such as `"Domain.State.Running" + 2:`. Keep arithmetic in the selector, for example `CASE #State - "Domain.State.Running" OF`, with supported offset labels, or use `IF`/`ELSIF` comparisons where clearer. This does not create another state variable or transfer lifecycle ownership. See Siemens [CASE syntax](https://docs.tia.siemens.cloud/r/en-us/v20/scl-s7-1200-s7-1500/program-control-operations-s7-1200-s7-1500/case-create-multiway-branch-s7-1200-s7-1500).

Check the concrete TIA version and source format when a representation is uncertain. Neither plausible IEC syntax nor successful compilation of a different expression context establishes support. Generation and review shall apply the same context distinction.

### Block Header Metadata

Block and type metadata shall be maintained intentionally because it is visible in TIA Portal, exported sources, library handling, and protected blocks.

For FB, FC, OB, and DB blocks, fill at least:

- `Title`: short human-readable purpose.
- `Comment`: concise explanation of responsibility, public behavior, or important usage constraints.
- `Version`: semantic version of the block interface or implementation artifact where applicable.
- `Family`: owning library or domain, for example `UnitTest`, `AnalogInput`, or `Json`.
- `Author`: owning organization or author, for example `Lorenz Software`.
- `User-defined ID`: stable short identifier only when a project or library workflow needs it; otherwise leave it empty rather than inventing meaningless IDs.

For UDTs, fill at least:

- `Title`: short human-readable purpose.
- `Comment`: concise explanation of the data structure, ownership, visibility, and intended use.

Do not duplicate long design documentation in block comments. Use block comments to support TIA Portal navigation and online understanding; keep detailed design rationale in repository documentation.

In SCL source headers, use the corresponding TIA header attributes where the export/import format supports them.

Typical SCL source representation:

```scl
FUNCTION_BLOCK "ExampleBlock"
TITLE = Example block title
{ S7_Optimized_Access := 'TRUE' }
AUTHOR : 'Lorenz Software'
FAMILY : UnitTest
NAME : ''
VERSION : 1.0
// Short block comment.
```

Observed mapping:

- TIA `Title` is represented by `TITLE = ...`.
- TIA `Author` is represented by `AUTHOR : ...`.
- TIA `Family` is represented by `FAMILY : ...`.
- TIA `Version` is represented by `VERSION : ...`.
- TIA `User-defined ID` is represented by `NAME : ...` in SCL source exports.
- TIA `Comment` is represented as the block/type comment in the exported source or XML, depending on export format.

`NAME` shall be treated as user-defined ID metadata, not as the PLC block name. Leave it empty unless a stable library/tooling identifier is intentionally required. Do not use random or generated IDs unless the generation source and purpose are defined.

For new reusable library artifacts, a generated UUID may be used as `NAME` when a stable technical identifier is needed. The UUID shall be generated when the block or type is created and shall not be changed during normal refactoring.

When a block or type is copied, verify that the copied artifact does not keep a duplicate UUID unintentionally. If the copy becomes a new independent artifact, assign a new UUID. If it is only renamed or moved as the same artifact, keep the existing UUID.

`VERSION` shall be changed only explicitly as part of the project or library development process. Do not update versions automatically during formatting, refactoring, moving, or source synchronization.

The block comment shall be written as a short comment after the block header metadata and before the first declaration section. This matches the observed TIA source export pattern and keeps block comments close to the metadata they describe.

Comments before the block or type definition shall not be used as the styleguide default for block comments. The Siemens external-source documentation allows comments in source files but notes that not all comments from a source file are necessarily applied when generating blocks. Therefore, comments before the block definition are not a reliable project rule unless a concrete TIA import/export test proves the behavior for the used TIA version.

### Block And Variable Attributes

#### Scope And General Coding Rules

These rules apply to standard S7-1200/S7-1500 code and data. Siemens capability, the coding requirement and the selected import representation are separate facts. The tables define general coding requirements as well as technical boundaries; project rules refine them for concrete data roles and approved exceptions. An import convenience must not weaken the required effective properties.

- Define instance data in the owning FB declaration. Do not maintain a second attribute policy on its instance DBs. Define global data in the global DB, subject to the restrictions and inherited properties of any referenced datatype.
- Do not share instance data with HMI. Keep instance data externally invisible, inaccessible and non-writable wherever these properties apply. Model required external observations and writes through deliberate global status, diagnostic, command, setting or exchange data areas instead of exposing block internals for debugging.
- Keep FB-owned data non-retentive and without SetPoint markings by default. Retention or SetPoint in an FB requires an explicitly justified and approved exception, and is allowed only in a Siemens-supported declaration context. Inter-call persistence of static data is not power-failure retention.
- An FC has no own instance data. Retention and SetPoint on data used by an FC belong to the actual storage definition, not an invented FC instance area. Access to external storage remains subject to that storage's declared purpose.
- Keep internal global data private by default. An external permission requires an explicitly defined interface purpose; it is not an arbitrary per-field preference. Public status is read-only unless a field is explicitly an approved command, acknowledgement or other write interface.
- Runtime-adjustable settings retain the retentive-data-area requirement in [Configuration Versus Settings](#configuration-versus-settings). The non-retentive implementation default does not override that purpose.
- Preserve attributes during unrelated edits. Changing this styleguide does not authorize automatic rewriting of existing artifacts or communication interfaces.

OB system parameters are outside this policy matrix. Preserve their native definition. Safety, technology-specific objects and unlisted contexts require their own documented treatment; an absent table entry does not prove Siemens rejection.

#### Declaration And Attribute Matrix

The three External columns name independent properties. `FALSE` is a required effective value, not a claim that every format accepts the same syntax. `Not applicable` means there is no corresponding own runtime-storage property in this context; do not invent an attribute for it. `Operand` means the actual storage owner defines the setting. `By role` means private by default, with only explicitly defined external-interface or settings roles permitting different values. `Exception` means the default is non-retentive or SetPoint FALSE, with an approved exception only where Siemens supports it.

The evidence columns describe technical support, not the authority for coding choices. Native results cover optimized S7-1500 (CPU 1517-3 PN V4.0), STEP 7 V21 Update 2, SCL import and default-inclusive XML readback, including save/reopen persistence. They are not S7-1200/standard-access proof, HMI runtime tests or qualification of every datatype. `Partial` identifies tested properties and remaining gaps; `Open` is not a claim of rejection. Retention/SetPoint capabilities do not grant a coding exception. Per-run evidence belongs in the owning issue, not a maintained report here.

| Declaration context | ExternalVisible | ExternalAccessible | ExternalWritable | Retention | SetPoint | Documentation | Native qualification / open scope |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FC Input, elementary | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: no own External properties, with/without supplied flags; BOOL/INT/REAL/LREAL, ARRAY, STRING/WSTRING, UDT/STRUCT |
| FC Input, structured | Operand | Operand | Operand | Operand | Operand | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: no own External properties, with/without supplied flags; BOOL/INT/REAL/LREAL, ARRAY, STRING/WSTRING, UDT/STRUCT |
| FC Output, elementary | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: no own External properties, with/without supplied flags; BOOL/INT/REAL/LREAL, ARRAY, STRING/WSTRING, UDT/STRUCT |
| FC Output, structured | Operand | Operand | Operand | Operand | Operand | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: no own External properties, with/without supplied flags; BOOL/INT/REAL/LREAL, ARRAY, STRING/WSTRING, UDT/STRUCT |
| FC InOut, elementary | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: no own External properties, with/without supplied flags; BOOL/INT/REAL/LREAL, ARRAY, STRING/WSTRING, UDT/STRUCT |
| FC InOut, structured | Operand | Operand | Operand | Operand | Operand | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: no own External properties, with/without supplied flags; BOOL/INT/REAL/LREAL, ARRAY, STRING/WSTRING, UDT/STRUCT |
| FC return value, elementary | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Partial: BOOL return only; other return types open |
| FC return value, structured | Caller storage | Caller storage | Caller storage | Caller storage | Caller storage | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Open: structured returns not tested |
| FC Temp | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Interface sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/overview-of-the-block-interface) | Partial: plain BOOL declaration; no attribute-injection test or other datatype proof |
| FC Constant | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Interface sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/overview-of-the-block-interface) | Partial: plain BOOL declaration; no attribute-injection test or other datatype proof |
| FB Input, elementary | FALSE | FALSE | FALSE | Exception | Not supported here | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: three External FALSE flags and scalar RETAIN; BOOL/INT/REAL/LREAL access, BOOL retention |
| FB Input, structured | FALSE | FALSE | FALSE | Exception | Not supported here | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Partial: three External FALSE flags on ARRAY, STRING/WSTRING, UDT/STRUCT; structured retention not tested |
| FB Output, elementary | FALSE | FALSE | FALSE | Exception | Not supported here | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: three External FALSE flags and scalar RETAIN; BOOL/INT/REAL/LREAL access, BOOL retention |
| FB Output, structured | FALSE | FALSE | FALSE | Exception | Not supported here | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Partial: three External FALSE flags on ARRAY, STRING/WSTRING, UDT/STRUCT; structured retention not tested |
| FB InOut, elementary | FALSE | FALSE | FALSE | Exception | Not supported here | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: three External FALSE flags and scalar RETAIN; BOOL/INT/REAL/LREAL access, BOOL retention |
| FB InOut, structured | Operand/type; no own formal flag in checked contexts | Operand/type; no own formal flag in checked contexts | Operand/type; no own formal flag in checked contexts | Not retentive in this declaration; operand separately | Operand | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: own External flags not retained; ARRAY/STRING/WSTRING/UDT/STRUCT. ARRAY RETAIN removed |
| FB Static, elementary | FALSE | FALSE | FALSE | Exception | Exception | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Checked: External FALSE, SetPoint FALSE/TRUE and BOOL RETAIN |
| FB Static, STRUCT/UDT | FALSE | FALSE | FALSE | Exception, whole structure | FALSE on qualified container declarations; eligible defining members separately; exceptions require approval | [SetPoint rules](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/online-and-diagnostic-functions-for-data-blocks/using-setpoints-during-commissioning/marking-data-as-values-that-can-be-set) and qualified SCL distinction below | Partial: explicit container S7_SetPoint FALSE checked on one static UDT, independently of its member settings, including save/reopen; inline STRUCT container and structured retention remain open |
| FB Static, ARRAY | FALSE | FALSE | FALSE | Exception, whole array | Exception, array/member rules below | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Partial: BOOL-array External/SetPoint FALSE; retention not tested |
| FB multi-instance | Private instance boundary and called FB | Private instance boundary and called FB | Private instance boundary and called FB | Owning/called FB definitions | FALSE on qualified container declarations; called FB members separately; exceptions require approval | [SetPoint rules](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/online-and-diagnostic-functions-for-data-blocks/using-setpoints-during-commissioning/marking-data-as-values-that-can-be-set) and qualified SCL distinction below | Partial: explicit container S7_SetPoint FALSE checked on one user-FB multi-instance, including save/reopen; earlier user-FB/TON_TIME access-boundary checks do not qualify SetPoint on every instruction/instance type |
| FB parameter instance | Private applicable interface properties; referenced instance remains private | Private applicable interface properties; referenced instance remains private | Private applicable interface properties; referenced instance remains private | Referenced instance definition | Referenced FB definition | [Transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) | Open: parameter instances not tested |
| FB Temp | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Interface sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/overview-of-the-block-interface) | Partial: plain BOOL declaration; no attribute-injection test or other datatype proof |
| FB Constant | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Interface sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/overview-of-the-block-interface) | Partial: plain BOOL declaration; no attribute-injection test or other datatype proof |
| OB Temp | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Interface sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/overview-of-the-block-interface) | Documented only; native proof open |
| OB Constant | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | [Interface sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/overview-of-the-block-interface) | Documented only; native proof open |
| Global DB, elementary member | By role | By role | By role | By role | By role | [DB properties](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/editing-the-properties-of-tags-in-data-blocks/properties-of-the-tags-in-data-blocks) | Checked: External FALSE, SetPoint FALSE/TRUE, NonRetain; retained variant open |
| Global DB, STRUCT/UDT member | By role, respecting members | By role, respecting members | By role, respecting members | By role, whole structure | Eligible members/type definition | [DB properties](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/editing-the-properties-of-tags-in-data-blocks/properties-of-the-tags-in-data-blocks) | Partial: External FALSE, nested UDT/member settings; retained variant open |
| Global DB, ARRAY member | By role, respecting elements | By role, respecting elements | By role, respecting elements | By role, whole array | Array/member rules below | [DB properties](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/editing-the-properties-of-tags-in-data-blocks/properties-of-the-tags-in-data-blocks) | Partial: BOOL array and nested UDT array; retained variant open |
| Global DB based on UDT | Datatype restrictions and concrete use | Datatype restrictions and concrete use | Datatype restrictions and concrete use | Concrete DB, by role | UDT definition | [DB properties](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/editing-the-properties-of-tags-in-data-blocks/properties-of-the-tags-in-data-blocks) | Partial: inherited BOOL access and Int SetPoint; retention variants open |
| ARRAY DB | By role | By role | By role | Not supported | Not supported | [DB properties](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/editing-the-properties-of-tags-in-data-blocks/properties-of-the-tags-in-data-blocks) | Documented only; ARRAY DB native proof open |
| UDT, elementary member | By role | By role | By role | Concrete storage, not UDT | By role; effective only in eligible use | [Type/member export](https://docs.tia.siemens.cloud/r/en-us/v21/tia-portal-openness-api-for-automation-of-engineering-workflows/export/import/importing/exporting-data-of-a-plc-device/blocks/xml-structure-of-the-block-interface-section) | Checked: BOOL External TRUE/FALSE and Int SetPoint TRUE; no runtime retention on type |
| UDT, STRUCT/UDT member | By role, respecting members | By role, respecting members | By role, respecting members | Concrete storage, not UDT | Eligible members/type definition | [Type/member export](https://docs.tia.siemens.cloud/r/en-us/v21/tia-portal-openness-api-for-automation-of-engineering-workflows/export/import/importing/exporting-data-of-a-plc-device/blocks/xml-structure-of-the-block-interface-section) | Partial: nested UDT boundary and member exports; arbitrary type overrides open |
| UDT, ARRAY member | By role, respecting elements | By role, respecting elements | By role, respecting elements | Concrete storage, not UDT | Array/member rules below | [Type/member export](https://docs.tia.siemens.cloud/r/en-us/v21/tia-portal-openness-api-for-automation-of-engineering-workflows/export/import/importing/exporting-data-of-a-plc-device/blocks/xml-structure-of-the-block-interface-section) | Partial: BOOL array and UDT array; other element types open |

FC formal parameters do not create an independently HMI-addressable instance data area. The table does not declare all FC field-attribute spellings syntactically forbidden. Actual operands, including those used for elementary FC parameters, retain their own storage permissions and retention/SetPoint policy. A reference parameter does not change those permissions.

In the qualified structured FB InOut contexts, supplied External flags are not retained as own formal properties, even in default-inclusive export. Their absence is not evidence of TRUE; control the actual operand/type at its defining owner. FC formal flags likewise are not retained in the tested contexts. Do not add ineffective flags to simulate protection. Parameter-instance properties remain unqualified and require their own support/evidence rather than extrapolation from a normal multi-instance.

STRING/WSTRING lengths are declaration-context dependent: the tested FB InOut and FC Input/Output/InOut require declarations without an explicit length, unlike the tested FB Input/Output/Static fields. A rejected bounded declaration is not proof that access attributes are invalid. See Siemens [valid interface datatypes](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/rules-for-declaring-the-block-interface/valid-data-types-in-the-block-interface-s7-1200-s7-1500).

The transfer model for ordinary compatible S7-1200/S7-1500 data is documented in the Siemens source below for every row. The metadata probe did not execute runtime copy/reference or asynchronous copy-back tests:

| Block | Datatype category | Input | Output | InOut |
| --- | --- | --- | --- | --- |
| FC | Elementary | Copy | Copy | Copy |
| FB | Elementary | Copy | Copy | Copy |
| FC | Structured | Pointer | Pointer | Pointer |
| FB | Structured | Copy | Copy | Pointer |

Structured includes ARRAY, STRUCT, STRING/WSTRING and UDTs, not just large values. Mixed optimized/standard access can force copying and introduce copy-back hazards; parameter instances and technology objects have separate rules. See Siemens [parameter transfer](https://docs.tia.siemens.cloud/r/en-us/v20/programming-basics/block-calls/parameter-transfer-at-block-call/transfer-parameter-as-copy-or-as-pointer) (V20 reference).

#### Property-Specific Rules And Representation

- `ExternalVisible` controls HMI engineering selection; `ExternalAccessible` and `ExternalWritable` control the documented external runtime access. These are not general PLC security controls against every application. Select them independently; visibility is not write permission.
- A containing level may tighten, but shall not relax, nested external-access restrictions. Do not expose an entire datatype or object to enable one public field. Do not apply this coding restriction as a generic retention or SetPoint inheritance algorithm.
- Optimized FBs/global DBs support differentiated retentivity, with one setting for a complete structured variable. Standard-access instance/global data uses the instance/DB-wide setting. Structured InOut cannot itself be declared retentive; actual-operand retention is a separate decision.
- SetPoint is supported in FB Static, global DBs and UDTs, not FB Input/Output/InOut. In a UDT it becomes effective only in eligible Static/DB use. Typed DB members and multi-instance members derive their settings from the defining UDT/FB. Distinguish those member definitions from the containing variable's own exported SetPoint property; the qualified SCL container declarations below do not redefine child properties or establish an instance-DB policy.
- Siemens documents restrictions on marking STRUCT/UDT parents as setpoints and on changing markings at a multi-instance call point. These restrictions shall not be generalized into a prohibition of the qualified SCL container FALSE declaration below. Selecting eligible lower-level setpoints remains a separate decision. For ARRAY, the documented parent marking is inherited by elements. ARRAY-of-STRUCT has separate eligible-member rules; ARRAY DBs do not support SetPoint or retention.
- Local constants and Temp declarations receive no external-access, retention or SetPoint attribute bundle. Preserve required system/type metadata, including `InstructionName` and `LibVersion`, on the objects that own it.
- A plain FB declaration section without `RETAIN` or `DB_SPECIFIC` expresses non-retentive data. Do not generate `VAR NON_RETAIN` or `VAR_NON_RETAIN`. DB source has its own supported representation.
- Defaults are not project requirements. Siemens documents external visibility/accessibility defaults TRUE, writability FALSE and SetPoint FALSE; authoring defaults may be configurable. Native unannotated control fields in the qualified environment had all three External flags TRUE, including writability. Do not substitute a published default for actual property evidence or omit a required private setting merely because import succeeds.
- SCL, SimaticML and SIMATIC SD have different representations. For example, SCL `S7_SetPoint` corresponds to the relevant XML `SetPoint` attribute. `UserVisible` is not the SCL attribute for HMI engineering visibility; use `ExternalVisible`.
- Verify the required effective properties, not merely compilation or equality with generated text. Review applicable container properties and defining member properties separately; do not exempt a container because its members are FALSE or infer cleared members from a FALSE container. Serializers may omit correctly stored defaults. Use default-inclusive native evidence when omission prevents verification; do not rewrite correct state merely to force explicit export tokens. If a required property cannot be established or verified, report the limitation and align a supported resolution instead of claiming compliance.

Qualified SCL container declarations: in the optimized S7-1500 / V21 Update 2 scope above, `S7_SetPoint := 'False'` on an owning FB's static UDT variable and on its user-FB multi-instance declaration was accepted, retained in source and default-inclusive XML, and persisted after save/reopen. Separate controls established FALSE on either declaration without changing the other; both could also be FALSE together. The defining members remained unchanged and already had FALSE settings while the unannotated containers exported TRUE. The container values therefore shall not be dismissed as a summary of those member values. Explicitly establish FALSE on matching non-setting containers and verify their members independently. This evidence qualifies neither container TRUE as a commissioning mechanism nor arbitrary inline STRUCTs, arrays, instruction instances, parameter instances, other CPUs/access modes or other import formats.

Sources: Siemens [variable attributes](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/declare-block-interface-in-the-textual-view/attributes-for-variables), [declaration sections](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/declare-block-interface-in-the-textual-view/declaration-sections), [local retentivity](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/rules-for-declaring-the-block-interface/setting-the-retentivity-of-local-tags), [global DB retentivity](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/setting-retentivity/setting-retentivity-in-a-global-data-block), [SetPoint rules](https://docs.tia.siemens.cloud/r/en-us/v21/programming-data-blocks/online-and-diagnostic-functions-for-data-blocks/using-setpoints-during-commissioning/marking-data-as-values-that-can-be-set), [external-access limitations](https://docs.tia.siemens.cloud/r/en-us/v21/declaring-the-block-interface/editing-the-properties-of-local-tags-and-constants/properties-of-local-tags-and-constants) and [Openness interface export](https://docs.tia.siemens.cloud/r/en-us/v21/tia-portal-openness-api-for-automation-of-engineering-workflows/export/import/importing/exporting-data-of-a-plc-device/blocks/xml-structure-of-the-block-interface-section).

#### Object Attributes And Metadata

| Object | Applicable decisions | Boundary | Evidence / remaining native scope |
| --- | --- | --- | --- |
| FC | Identity, title/comment, version, family/author, supported access mode/protection/publication | No own instance storage | Documented; native SCL header/optimized access preserved in probe; protection/publication variants open |
| FB | Identity, title/comment, version, family/author, supported access mode/protection/publication; instance-data declaration | Define instance properties here, not as an independent instance-DB policy | Documented; native SCL header/optimized access and instance properties checked within the declared field scope; protection/publication variants open |
| OB | Supported identity/header metadata, access mode and protection; event-specific block definition | No invented FB interface; system parameters remain native | Documented only; event/protection/header variants not natively qualified by the field probe |
| Global DB | Supported header metadata, access mode, publication and field properties | UDT-based and ARRAY DB restrictions remain applicable | Documented; native plain/UDT-based optimized forms checked for stated fields; ARRAY DB, standard access and other metadata variants open |
| UDT | Type identity, supported metadata, member properties and publication | No own runtime storage or invented code-block optimization/protection/header pragmas | Documented; native type/member declarations and inherited settings checked for stated members; publication variants open |
| PLC tag/constant table | Identity/publication and supported member properties | Tag-memory/CPU settings govern retention; publication is not runtime permission | Documented only; no native tag/table attribute qualification in this probe |

Maintain identity/version metadata under [Block Header Metadata](#block-header-metadata). Publication for software-unit use is separate from HMI access. See Siemens [block access](https://docs.tia.siemens.cloud/r/en-us/v21/programming-basics/blocks-in-the-user-program/blocks-with-optimized-access/setting-up-block-access) and [software units](https://docs.tia.siemens.cloud/r/en-us/v20/using-software-units-s7-1500/introduction-to-software-units-s7-1500) (V20 reference). Call-display attributes remain governed by the following section; they do not hide required dependencies or define storage permissions.

### Block Call Interface Attributes

TIA Portal supports interface settings that affect LAD/FBD block-call display and predefined actual parameters.

Observed SCL export attributes include:

- `S7_PredefinedAssignment`: predefined actual parameter for a formal parameter.
- `S7_HiddenAssignment`: visibility behavior of a parameter at LAD/FBD block calls.
- `S7_ShowAssignmentIfParamsNotIdentical`: show the parameter when the assigned actual parameter differs from the predefined one.

Use these attributes only for non-essential interface parameters with a meaningful predefined assignment, or when a reusable library block intentionally provides a default actual parameter and improves LAD/FBD call readability without hiding important dependencies.

Do not use hidden/predefined assignment attributes to hide required dependencies, project-specific wiring, side effects, or values that must be reviewed at the call site.

### External Visibility Attributes

External-access requirements, private instance data and deliberate global interfaces are defined in [Block And Variable Attributes](#block-and-variable-attributes). Do not maintain a second permission policy here.

### Optimized Blocks

Optimized access rules are defined in [Block And Variable Attributes](#block-and-variable-attributes).

As a coding rule, do not disable optimized access for a standard code block only for convenience or manual online access.

Non-optimized exchange data areas shall be clearly separated from normal library/framework code and shall be documented as interface/exchange areas.

### Standard Block Data Access

Reusable standard/library blocks should not directly access global DBs except in well-justified cases.

Prefer explicit external accessor blocks, getter/setter functions, or caller-provided data objects to separate reusable block logic from project-specific data access.

This separation keeps dependencies visible and makes the block easier to reuse, test, and review.

For performance-sensitive code, prefer grouped read/write operations and local variables over repeated dynamic address resolution. TIA Portal is better than classic STEP 7 in this area, but references and dynamic access can still be less predictable and less performant than local working values.

### Memory Area M (Merker / Siemens Bit Memory)

Memory area M is the IEC 61131-3 direct-addressed internal memory area `%M`. Siemens documentation commonly calls it bit memory `(M)`, and German TIA/STEP 7 terminology calls it `Merker`.

Memory area M shall not be used as regular data storage, regular interface data, or hidden communication between blocks.

Temporary use of memory area M for debugging is allowed, but it shall not become part of committed production/library logic.

System memory in memory area M may be used when technically appropriate, but only through a clearly encapsulated access layer or helper block.

Do not spread direct system memory reads from memory area M across reusable library/framework code.

### Return And Error Handling

Early `RETURN;` is allowed in stateless functions for simple guard clauses when it improves readability.

Avoid early `RETURN;` in cyclic FB logic if it skips required output assignment, command reset, or previous-cycle memorization.

Error handling shall be explicit. Do not silently ignore invalid input ranges or unsupported states unless the behavior is intentionally documented.

### Loop Bounds And Termination

Before using a loop, establish its iteration domain, direction and finite termination. For `FOR`, select compatible control/bound/step types. Do not mix signed and unsigned forms, use an unsigned control variable for a descending loop, or modify the control variable, end value or increment in the body. Reject or explicitly handle a zero step and account for an empty iteration domain. Ensure every executed control update, including the update needed to leave the loop, remains representable. Valid array accesses in the body alone do not establish safe termination.

Siemens documents these constraints for [FOR on S7-1200/S7-1500/S7-1200 G2](https://docs.tia.siemens.cloud/r/en-us/v21/scl-s7-1200-s7-1500-s7-1200-g2/program-control-operations-s7-1200-s7-1500-s7-1200-g2/for-run-in-counting-loop-s7-1200-s7-1500-s7-1200-g2). The online boundary formula is rendered incompletely; do not reconstruct it as an exact manufacturer guarantee. Derive safety from the actual typed bounds and updates. Do not introduce a multi-cycle controller unless the required work actually needs one.

### Type Usage And Conversions

Author type transitions according to the conversion rules with IEC check enabled, even when the target block has IEC check disabled. Newly authored or changed conversions shall produce no compiler warnings. Do not use an IEC-off-only implicit transition merely because it compiles without warnings in that mode. This coding rule does not authorize changing existing block or IDE settings.

Use IEC-conforming implicit conversions when they are warning-free and preserve the required numerical meaning. Different source and destination types alone do not require an explicit conversion. Use an explicit conversion where the IEC-conforming binding/operator requires it or a deliberate, range-checked value transformation is needed; a cast is not proof that truncation, sign change or rounding is acceptable. IEC acceptance alone establishes neither warning freedom nor value safety.

Resolve external symbol and constant declarations before using them. A name, literal value or catalog summary does not establish the declared type. An expression with unresolved consequential operand types is not technically reviewed. Check arithmetic intermediates and comparisons separately from the eventual assignment or parameter type.

Reduce avoidable conversions through suitable, consistent local types for related values. Preserve public interfaces and independently owned declarations. Reuse a converted working value only when its name and lifetime express a real shared meaning; do not add meaningless aliases, persistent state or extra cyclic work merely to reduce cast counts. Do not widen everything mechanically or convert a result after the intermediate has already overflowed.

#### Select Rounding By Required Meaning

Choose rounding from the required numerical relationship, including negative inputs and exact ties, not from a familiar conversion mnemonic:

| Operation | Meaning | Result for +2.5 | Result for -2.5 |
| --- | --- | --- | --- |
| [ROUND](https://docs.tia.siemens.cloud/r/en-us/v21/scl-s7-1200-s7-1500-s7-1200-g2/conversion-operations-s7-1200-s7-1500-s7-1200-g2/round-round-numerical-value-s7-1200-s7-1500-s7-1200-g2) | Nearest integer; exact ties select the even integer | 2 | -2 |
| [TRUNC](https://docs.tia.siemens.cloud/r/en-us/v21/scl-s7-1200-s7-1500-s7-1200-g2/conversion-operations-s7-1200-s7-1500-s7-1200-g2/trunc-truncate-numerical-value-s7-1200-s7-1500-s7-1200-g2) | Discard fractional part toward zero | 2 | -2 |
| [CEIL](https://docs.tia.siemens.cloud/r/en-us/v21/scl-s7-1200-s7-1500-s7-1200-g2/conversion-operations-s7-1200-s7-1500-s7-1200-g2/ceil-generate-next-higher-integer-from-floating-point-number-s7-1200-s7-1500-s7-1200-g2) | Toward positive infinity | 3 | -2 |
| [FLOOR](https://docs.tia.siemens.cloud/r/en-us/v21/scl-s7-1200-s7-1500-s7-1200-g2/conversion-operations-s7-1200-s7-1500-s7-1200-g2/floor-generate-next-lower-integer-from-floating-point-number-s7-1200-s7-1500-s7-1200-g2) | Toward negative infinity | 2 | -3 |

Resolve the actual instruction result type and validate finite input and destination range where the required domain does not guarantee them. Do not equate every `X_TO_Y` conversion with `TRUNC`. A mnemonic, explicit conversion or warning-free compilation does not prove that the intended rounding is implemented. The examples describe mathematical results for exactly representable half-values, not a new native qualification claim.

#### Directed Conversion Matrix

The following documentary matrix covers STEP 7 V21's S7-1500/S7-1200 G2 conversion chapter. It is not a qualification of classic S7-1200, S7-300/400, Safety, every V21 update or all instruction/call contexts. Rows are source types and columns destination types. Same-type cells mean identity only; sized strings and structured/reference bindings have additional constraints.

Each cell is `implicit/explicit`. Implicit codes: `B` = available with IEC check both on and off; `O` = available only with IEC check off; `N` = unavailable in both modes; `?` = unresolved documentary claim. Explicit codes: `Y` = the type table lists a direct conversion; `N` = it does not. `=` denotes same-type identity, not a conversion. Availability is not a warning-free or value-preserving guarantee. A missing direct conversion does not forbid a separately justified multi-step algorithm.

The matrix is read together with the context and native-evidence sections below. Its IEC-off distinctions document compiler capability and help analyze existing sources; they are not an alternative authoring strategy. For new or changed transitions, use the IEC-on availability and the actual expression/binding context. Unknown cells remain unresolved, not implicitly allowed or forbidden. In particular, do not use assignment availability as an arithmetic-promotion or reference-compatibility table.

| Source / Destination | BOOL | BYTE | WORD | DWORD | LWORD | SINT | USINT | INT | UINT | DINT | UDINT | LINT | ULINT | REAL |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BOOL | = | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/N |
| BYTE | N/Y | = | B/Y | B/Y | B/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | N/N |
| WORD | N/Y | O/Y | = | B/Y | B/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | N/N |
| DWORD | N/Y | O/Y | O/Y | = | B/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y |
| LWORD | N/Y | O/Y | O/Y | O/Y | = | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | N/N |
| SINT | N/Y | O/Y | O/Y | O/Y | O/Y | = | O/Y | B/Y | O/Y | B/Y | O/Y | B/Y | O/Y | B/Y |
| USINT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | B/Y | B/Y | B/Y | B/Y | B/Y | B/Y | B/Y |
| INT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | O/Y | B/Y | O/Y | B/Y | O/Y | B/Y |
| UINT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | B/Y | B/Y | B/Y | B/Y | B/Y |
| DINT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | O/Y | B/Y | O/Y | O/Y |
| UDINT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | B/Y | B/Y | O/Y |
| LINT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | O/Y | O/Y |
| ULINT | N/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = | O/Y |
| REAL | N/N | N/N | N/N | O/Y | N/N | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | = |
| LREAL | N/N | N/N | N/N | N/N | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y |
| S5TIME | N/N | N/N | O/Y | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N |
| TIME | N/N | N/Y | N/Y | O/Y | N/Y | N/Y | N/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y | N/N |
| LTIME | N/N | N/Y | N/Y | N/Y | O/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | O/Y | O/Y | N/N |
| DT | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N |
| LDT | N/N | N/Y | N/Y | N/Y | O/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | O/Y | O/Y | N/N |
| DTL | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N | ?/N |
| DATE | N/N | N/Y | O/Y | N/Y | N/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y | N/Y | N/Y | N/N |
| TOD | N/N | N/Y | N/Y | O/Y | N/Y | N/Y | N/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y | N/N |
| LTOD | N/N | N/Y | N/Y | N/Y | O/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | O/Y | O/Y | N/N |
| CHAR | N/N | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | N/N |
| WCHAR | N/N | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | O/Y | N/N |
| STRING | N/N | N/N | N/N | N/N | N/N | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y |
| WSTRING | N/N | N/N | N/N | N/N | N/N | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y | N/Y |

| Source / Destination | LREAL | S5TIME | TIME | LTIME | DT | LDT | DTL | DATE | TOD | LTOD | CHAR | WCHAR | STRING | WSTRING |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BOOL | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N |
| BYTE | N/N | N/N | N/Y | N/Y | N/N | N/Y | N/N | N/Y | N/Y | N/Y | O/Y | O/Y | N/N | N/N |
| WORD | N/N | O/Y | N/Y | N/Y | N/N | N/Y | N/N | O/Y | N/Y | N/Y | O/Y | O/Y | N/N | N/N |
| DWORD | N/N | N/N | O/Y | N/Y | N/N | N/Y | N/N | N/Y | O/Y | N/Y | O/Y | O/Y | N/N | N/N |
| LWORD | O/Y | N/N | N/Y | O/Y | N/N | O/Y | N/N | N/Y | N/Y | O/Y | O/Y | O/Y | N/N | N/N |
| SINT | B/Y | N/N | N/Y | N/Y | N/N | N/Y | N/N | N/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y |
| USINT | B/Y | N/N | N/Y | N/Y | N/N | N/Y | N/N | N/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y |
| INT | B/Y | N/N | N/Y | N/Y | N/N | N/Y | N/N | O/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y |
| UINT | B/Y | N/N | N/Y | N/Y | N/N | N/Y | N/N | O/Y | N/Y | N/Y | O/Y | O/Y | N/Y | N/Y |
| DINT | B/Y | N/N | O/Y | N/Y | N/N | N/Y | N/N | N/Y | O/Y | N/Y | O/Y | O/Y | N/Y | N/Y |
| UDINT | B/Y | N/N | O/Y | N/Y | N/N | N/Y | N/N | N/Y | O/Y | N/Y | O/Y | O/Y | N/Y | N/Y |
| LINT | O/Y | N/N | N/Y | O/Y | N/N | O/Y | N/N | N/Y | N/Y | O/Y | O/Y | O/Y | N/Y | N/Y |
| ULINT | O/Y | N/N | N/Y | O/Y | N/N | O/Y | N/N | N/Y | N/Y | O/Y | O/Y | O/Y | N/Y | N/Y |
| REAL | B/Y | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/Y | N/Y |
| LREAL | = | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/Y | N/Y |
| S5TIME | N/N | = | N/Y | N/Y | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N |
| TIME | N/N | N/Y | = | B/Y | N/N | N/N | N/N | N/N | O/Y | N/N | N/N | N/N | N/N | N/N |
| LTIME | N/N | N/Y | O/Y | = | N/N | O/Y | N/N | N/N | N/N | O/Y | N/N | N/N | N/N | N/N |
| DT | N/N | N/N | N/N | N/N | = | B/Y | B/Y | N/Y | N/Y | N/Y | N/N | N/N | N/N | N/N |
| LDT | N/N | N/N | N/N | O/Y | O/Y | = | B/Y | N/Y | N/Y | N/Y | N/N | N/N | N/N | N/N |
| DTL | ?/N | ?/N | ?/N | ?/N | ?/Y | ?/Y | = | ?/Y | ?/Y | ?/Y | ?/N | ?/N | ?/N | ?/N |
| DATE | N/N | N/N | N/N | N/N | N/Y | N/Y | N/Y | = | N/N | N/N | N/N | N/N | N/N | N/N |
| TOD | N/N | N/N | O/Y | N/N | N/Y | N/Y | N/Y | N/N | = | B/Y | N/N | N/N | N/N | N/N |
| LTOD | N/N | N/N | N/N | O/Y | N/Y | N/Y | N/Y | N/N | O/Y | = | N/N | N/N | N/N | N/N |
| CHAR | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | = | N/Y | B/Y | N/N |
| WCHAR | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/Y | = | N/N | B/Y |
| STRING | N/Y | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | O/Y | N/N | = | N/Y |
| WSTRING | N/Y | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | N/N | O/Y | N/Y | = |

#### Conversion Context And Meaning

| Context | Interpretation |
| --- | --- |
| Assignment and value parameters | Check conversion direction and the actual formal/destination type. Do not apply input conversion rules to output or InOut bindings without checking their direction and storage semantics. |
| Arithmetic | Determine the intermediate type from the actual operands and operator before considering the assignment. Same-signedness widening, mixed signedness, floating operands and duration/date operations have distinct rules and IEC restrictions. A wider destination does not retroactively widen a product. |
| Comparison | A Bool result does not remove operand-compatibility requirements. Do not copy arithmetic restrictions or casts into comparisons merely because the operand types differ. |
| Instruction result | Read the instruction's actual signature and any selected result type; an instruction name or a compatible outer parameter is insufficient. |
| REF() and InOut | REF() requires the exact referenced type. For InOut, distinguish elementary FC value/copy conversion from structured/reference storage binding; the simple FC fixture below does not establish a universal InOut rule. A cast does not make arbitrary reference storage compatible. |
| Bit strings | SCL expressions can interpret bit strings as corresponding unsigned integers. An explicit DWORD/REAL or LWORD/LREAL conversion can instead transfer the bit representation. These are not interchangeable numeric operations. |
| Duration/date/time | Preserve units and epoch/calendar meaning. Widening milliseconds to nanoseconds is not the same operation as reinterpreting raw integer storage. Use the particular conversion's documented validity and overflow behavior. |
| Character and string | Distinguish character conversion, sized-string assignment and text parsing/formatting. Same STRING/WSTRING spelling does not guarantee that the destination capacity is sufficient. FC formals and owned FB/DB/local string storage have different declaration contexts. |

IEC check can be selected per block and as a default for newly created blocks. Establish the actual block setting instead of assuming the editor default or an imported source preserves it. Do not change another project's or the IDE's defaults to make generated code compile.

#### Scoped Native Compiler Evidence

The following representative compiler observations were obtained for CPU 1517-3 PN, order number 6ES7 517-3AQ10-0AB0, firmware V4.0, Portal/Openness file version 2100.0.121.1 (API assembly 21.0.0.0). They qualify the stated variable-based fixtures/settings only. The reproducible compiler harness is maintained separately from the distributed guide; run reports are not permanent guide content.

| Actual fixture context | IEC on | IEC off | Boundary |
| --- | --- | --- | --- |
| Int to DInt; UInt to UDInt; UInt to DInt assignment | Clean | Clean | No cast needed for these full-domain-preserving transitions. |
| Int to Real; Real to LReal; Byte to DWord assignment | Clean | Clean | Do not introduce conversion boilerplate into these controls. |
| Time to LTime; DT to DTL; DTL to LDT assignment | Clean | Clean | DTL to LDT is one native pair, not documentary resolution of the entire DTL row. |
| DInt to Int; UInt to Int; LReal to Real implicit assignment | Error | Sign/accuracy warning | Explicit counterparts compile cleanly but do not prove range or precision safety. |
| DInt to Real implicit assignment | Error | Clean | Many DInt values are not exactly representable as Real. No warning is not proof of exactness; an explicit cast cannot make an unrepresentable value exact. |
| Bool to Int implicit assignment | Error | Error | The explicit BOOL_TO_INT counterpart is clean. |
| Int + DInt into DInt | Clean | Clean | Same-signedness arithmetic widening needs no added casts here. |
| Int + UInt into DInt | Error | Accuracy warning | Mixed arithmetic requires deliberate type handling; the wider destination alone is not a repair. |
| Int > UInt comparison | Clean | Clean | Do not infer a universal cast requirement from the mixed-arithmetic result. |
| Byte + UInt into DInt | Error | Clean | Bit-string expression treatment and IEC restrictions are context-specific. |
| Time to DInt assignment | Error | Clean | Availability alone does not define the intended physical unit transformation. |
| Time to Date assignment | Error | Error | No implicit transition in this fixture. |
| Elementary FC value input Int to DInt and output Int into DInt | Clean | Clean | Binding direction matters; no casts required for these controls. |
| Elementary FC InOut DInt formal bound to Int working storage | Error | Sign/accuracy warning | Not REF(), FB structured InOut or proof of compatible arbitrary reference storage. |
| Char to String[8]; WChar to WString[8] with FB-owned storage | Clean | Clean | Not length-qualified FC formals. |
| FB String[20] to String[4] assignment | Clean | Clean | Does not prove that actual text fits or that no truncation occurs. |
| LREAL_TO_REAL; REAL_TO_DWORD; STRING_TO_DINT | Clean | Clean | Correct spelling/acceptance only; preserve numeric versus bit/text semantics and valid input domains. |

The documentary DTL implicit row remains unresolved because its source page was unavailable; do not replace its unknown cells with forbidden conversions. The LREAL explicit table's apparent LREAL_TO_LREAL mnemonic for a Real destination is not an executable prescription: the tested instruction spelling is LREAL_TO_REAL. Overview summaries and individual tables can differ; do not reconstruct the entire matrix from widths or an abbreviated type list. Integer-to-floating exactness must be derived from the target representation and required values, not generalized from a prose example's threshold.

Use applicable Siemens instruction documentation for specific rounding, parsing, ENO, validity and representation behavior. Compiler acceptance cannot establish runtime rounding, string contents, overflow results or the type/range of every unobserved intermediate. Do not add a cast just to hide a warning, or remove one needed for the required behavior because another fixture compiled without it.

#### Conversion Sources

See Siemens V21 [conversion overview](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/overview-of-data-type-conversion-s7-1500-s7-1200-g2), [arithmetic expressions](https://docs.tia.siemens.cloud/r/en-us/v21/creating-scl-programs/basics-of-scl/arithmetic-expressions), [relational expressions](https://docs.tia.siemens.cloud/r/en-us/v21/creating-scl-programs/basics-of-scl/relational-expressions), [value assignments](https://docs.tia.siemens.cloud/r/en-us/v21/creating-scl-programs/basics-of-scl/value-assignments) and [general editor settings](https://docs.tia.siemens.cloud/r/en-us/v21/program-editor/general-settings-for-the-plc-programming/overview-of-the-general-settings).

Each row's manufacturer type tables are listed below. The matrix records their availability facts, not copied explanatory examples or an independently invented conversion policy.

| Source type | Implicit table | Explicit table |
| --- | --- | --- |
| BOOL | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/implicit-conversion-of-bool-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/explicit-conversion-of-bool-s7-1500-s7-1200-g2) |
| BYTE | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/implicit-conversion-of-byte-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/explicit-conversion-of-byte-s7-1500-s7-1200-g2) |
| WORD | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/implicit-conversion-of-word-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/explicit-conversion-of-word-s7-1500-s7-1200-g2) |
| DWORD | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/implicit-conversion-of-dword-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/explicit-conversion-of-dword-s7-1500-s7-1200-g2) |
| LWORD | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/implicit-conversion-of-lword-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/binary-numbers-s7-1500-s7-1200-g2/bit-strings-s7-1500-s7-1200-g2/explicit-conversion-of-lword-s7-1500-s7-1200-g2) |
| SINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-sint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-sint-s7-1500-s7-1200-g2) |
| USINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-usint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-usint-s7-1500-s7-1200-g2) |
| INT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-int-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-int-s7-1500-s7-1200-g2) |
| UINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-uint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-uint-s7-1500-s7-1200-g2) |
| DINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-dint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-dint-s7-1500-s7-1200-g2) |
| UDINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-udint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-udint-s7-1500-s7-1200-g2) |
| LINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-lint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-lint-s7-1500-s7-1200-g2) |
| ULINT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/implicit-conversion-of-ulint-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/integers-s7-1500-s7-1200-g2/explicit-conversion-of-ulint-s7-1500-s7-1200-g2) |
| REAL | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/floating-point-numbers-s7-1500-s7-1200-g2/implicit-conversion-of-real-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/floating-point-numbers-s7-1500-s7-1200-g2/explicit-conversion-of-real-s7-1500-s7-1200-g2) |
| LREAL | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/floating-point-numbers-s7-1500-s7-1200-g2/implicit-conversion-of-lreal-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/floating-point-numbers-s7-1500-s7-1200-g2/explicit-conversion-of-lreal-s7-1500-s7-1200-g2) |
| S5TIME | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/timers-s7-1500-s7-1200-g2/implicit-conversion-of-s5time-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/timers-s7-1500-s7-1200-g2/explicit-conversion-of-s5time-s7-1500-s7-1200-g2) |
| TIME | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/timers-s7-1500-s7-1200-g2/implicit-conversion-of-time-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/timers-s7-1500-s7-1200-g2/explicit-conversion-of-time-s7-1500-s7-1200-g2) |
| LTIME | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/timers-s7-1500-s7-1200-g2/implicit-conversion-of-ltime-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/timers-s7-1500-s7-1200-g2/explicit-conversion-of-ltime-s7-1500-s7-1200-g2) |
| DT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/implicit-conversion-of-dt-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/explicit-conversion-of-dt-s7-1500-s7-1200-g2) |
| LDT | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/implicit-conversion-of-ldt-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/explicit-conversion-of-ldt-s7-1500-s7-1200-g2) |
| DTL | Unresolved page | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/explicit-conversion-of-dtl-s7-1500-s7-1200-g2) |
| DATE | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/implicit-conversion-of-date-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/explicit-conversion-of-date-s7-1500-s7-1200-g2) |
| TOD | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/implicit-conversion-of-tod-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/explicit-conversion-of-tod-s7-1500-s7-1200-g2) |
| LTOD | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/implicit-conversion-of-ltod-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/date-and-time-of-day-s7-1500-s7-1200-g2/explicit-conversion-of-ltod-s7-1500-s7-1200-g2) |
| CHAR | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/implicit-conversion-of-char-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/explicit-conversion-of-char-s7-1500-s7-1200-g2) |
| WCHAR | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/implicit-conversion-of-wchar-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/explicit-conversion-of-wchar-s7-1500-s7-1200-g2) |
| STRING | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/implicit-conversion-of-string-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/explicit-conversion-of-string-s7-1500-s7-1200-g2) |
| WSTRING | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/implicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/implicit-conversion-of-wstring-s7-1500-s7-1200-g2) | [Siemens](https://docs.tia.siemens.cloud/r/en-us/v21/data-types/data-type-conversion-for-s7-1200-g2-s7-1500-s7-1500-s7-1200-g2/explicit-conversions-s7-1500-s7-1200-g2/string-s7-1500-s7-1200-g2/explicit-conversion-of-wstring-s7-1500-s7-1200-g2) |

#### Numeric Representations

Choose numeric representations for the required value, range and precision before writing literals or conversions. Mathematical representability in a datatype does not establish that a particular decimal entry, declaration, import or export preserves that value. An explicit type qualifier alone is not a precision guarantee. Distinguish numerical conversion from transfer of a bit representation; use the documented instruction semantics for the selected source and destination types.

Ordinary decimal literals remain appropriate when they preserve the required meaning. When exact floating-point identity, a representable neighbour, a range boundary or a special value matters, use a representation that preserves that distinction in the target. A named integer bit pattern with documented representation transfer is one supported option, not a requirement for every floating value. Keep conversion calls in a supported executable context rather than putting them into an unsupported constant initializer. Siemens describes the [LREAL representation and rounding](https://docs.tia.siemens.cloud/r/en-us/v20/data-types/floating-point-numbers/lreal-s7-1200-s7-1500) and [LWORD-to-LREAL bit transfer](https://docs.tia.siemens.cloud/r/en-us/v20/data-types/data-type-conversion-for-s7-1500-s7-1500/explicit-conversions-s7-1500/binary-numbers-s7-1500/bit-strings-s7-1500/explicit-conversion-of-lword-s7-1500).

For tests, establish stimulus and expected representations independently of the DUT algorithm and classifiers. Exact versus tolerant comparison follows the required numerical relationship and its justified rounding allowance, not a general ban on floating-point equality. Do not compensate for a changed fixture value by widening tolerance or changing Expected. Keep the intended value distinction through generation, native storage and readback; a rounded diagnostic string or a host-language conversion is not sufficient evidence of the target value.

Choose integer sizes intentionally. Do not use a larger datatype only because it avoids thinking about the actual value range.

For externally consumed values, prefer stable fixed-size numeric types and document their meaning through constants or contract definitions.

### Strings, Text, And Large Data Areas

Use strings and text sparingly in production code.

Prefer coded values, numeric identifiers, enums/constants, compact status fields, or externally resolved message text when this is sufficient.

String operations can affect performance and cycle time, especially when executed cyclically, copied repeatedly, concatenated, or stored in arrays.

Do not build large diagnostic or message strings in a production-cycle path unless the benefit is explicit and the performance impact is acceptable.

Large data areas such as arrays, buffers, and large UDT instances shall be kept as compact as practical.

Avoid repeated copying of large structures. Prefer passing only the required data, using compact summaries, or performing grouped read/write operations where possible.

When large buffers are necessary, define ownership, maximum size, and copy behavior explicitly.

### Comments

Use comments differently in definitions and executable logic.

Definitions shall be commented when they are part of a public or reusable interface.

Short comments are explicitly useful for:

- `VAR_INPUT`,
- `VAR_OUTPUT`,
- `VAR_IN_OUT`,
- UDT fields,
- DB fields,
- global constants,
- public status and command structures.

Definition comments shall provide short textual descriptions or readable identifiers that improve understanding in TIA Portal, exported sources, and external tooling.

Executable logic in FBs, FCs, and OBs shall use comments sparingly.

If executable logic needs comments to be understandable, first check whether naming, structure, aggregation variables, regions, helper functions, or refactoring would make the code clearer.

Comments in executable logic are acceptable for:

- non-obvious technical constraints,
- intentional workarounds,
- safety/startup/timing assumptions,
- external interface constraints,
- exceptional cases that cannot be expressed clearly through code structure.

Good comments describe why code exists, not what the assignment syntax does.

### Line Readability

Line formatting shall primarily serve code readability, not mechanical compactness.

The readability expectation is context-sensitive:

- In executable logic, line readability is important because the source is read directly during review, debugging, and maintenance.
- In declarations, attribute-heavy definitions, and header metadata, greater line width is more acceptable because TIA Portal often presents those structures in a tabular or otherwise structured form.

For executable logic, a soft line-width orientation of about `120` characters should be used where this improves readability. This is not a hard limit. Readability takes precedence over a formal width target.

#### Calls

Function and block calls should preferably remain on one line when they are immediately readable.

If a call becomes difficult to read, parameters should be split across multiple lines.

When a call is broken across lines, prefer listing one block parameter per line.

Formatting should make the call structure and the mapping between parameter names and values easy to understand at a glance.

Complex logical expressions or similarly dense expressions directly inside parameter assignments are a code smell and should be used only in a very limited way. In such cases, check whether local helper variables or a small refactoring would make the call clearer.

Single long call lines remain acceptable when a line break would not improve readability.

#### Logical Expressions

Logical expressions should preferably remain on one line when they are immediately readable.

If a logical expression becomes difficult to understand in one line, split it across multiple lines.

Line breaks should make the logical and domain structure of the condition visible, especially by grouping related subconditions.

Very long or hard-to-read logical expressions are a code smell. In such cases, check whether parts of the condition should be refactored into cohesive, domain-meaningful helper variables or clearly separated subchecks.

Short and clear conditions may remain on one line.

### Indentation

Indentation shall make structural ownership, block nesting, and logical grouping immediately visible.

PLC source files shall use tabs for indentation. This follows the default indentation behavior of TIA Portal.

One indentation level shall always correspond to exactly one tab.

Do not mix indentation styles within one artifact.

#### Declaration Blocks

Declaration block keywords such as `VAR`, `VAR_INPUT`, `VAR_OUTPUT`, `VAR_IN_OUT`, `VAR_TEMP`, `VAR_CONSTANT`, and comparable declarations shall be placed on the declaration block indentation level used by the TIA export.

Declaration fields shall be indented by exactly one additional level relative to the declaration block keyword.

The closing keyword of a declaration block shall be aligned with the corresponding declaration block keyword.

#### Executable Logic

`BEGIN` and the corresponding block ending such as `END_FUNCTION`, `END_FUNCTION_BLOCK`, or comparable endings shall be placed on the block base indentation level.

Executable logic directly inside `BEGIN ... END_*` shall start one indentation level below `BEGIN`.

Nested control structures such as `IF`, `CASE`, `FOR`, `WHILE`, and comparable constructs shall increase indentation by exactly one level per structural layer.

Closing keywords such as `END_IF`, `END_CASE`, `END_FOR`, `END_WHILE`, and comparable endings shall return to the indentation level of the corresponding opening construct.

Do not add an artificial indentation level to the executable logic beyond the actual structural nesting.

#### CASE Structures

`CASE` shall remain on the current logic indentation level.

Each branch label of a `CASE` statement shall be indented by one additional level relative to `CASE`.

The statements inside a branch shall be indented by one additional level relative to the branch label.

`ELSE` shall be aligned with the other branch labels.

`END_CASE` shall be aligned with `CASE`.

Avoid long `IF / ELSIF` chains inside `CASE` branches when they hide the actual decision flow of the branch.

In such cases, check whether a state-machine-style early-exit pattern, a local helper variable, or a smaller extracted decision step would make the branch clearer.

#### REGION Blocks

`REGION` shall be placed on the current structural indentation level of the contained code.

The content of a region shall be indented by exactly one level relative to the `REGION` line.

`END_REGION` shall be aligned with its opening `REGION`.

Regions shall not be used to hide inconsistent indentation.

#### Wrapped Calls

Function and block calls should preferably remain on one line when they are immediately readable.

When a call is wrapped across multiple lines, each named block parameter should preferably be placed on its own line.

Wrapped parameter lines shall use one consistent continuation indentation for the whole call. The continuation indentation shall make the parameter list clearly subordinate to the call statement, but shall not add an additional logical indentation level to the surrounding executable code.

The closing `);` of a wrapped call shall be placed at the end of the final parameter line.

Follow-up indentation inside a wrapped call shall remain consistent throughout the whole call.

Complex logical expressions or similarly dense expressions directly inside parameter assignments are a code smell and should be used only in a very limited way. In such cases, check whether local helper variables or a small refactoring would make the call clearer.

#### Wrapped Logical Expressions

Logical expressions shall remain on one line when the expression is short and immediately understandable.

Do not wrap an `IF`, `ELSIF`, `WHILE`, or comparable condition only because it contains more than one operand. Wrapping is justified only when the one-line condition becomes hard to read or hides the logical structure.

The `THEN` keyword shall stay on the same line as the condition unless the condition is intentionally wrapped for readability.

When a logical expression is wrapped across multiple lines, each logically cohesive subcondition should preferably be placed on its own line.

Wrapped subconditions shall be indented by one additional level relative to the line that introduces the expression.

Avoid line breaks that split a simple expression without improving readability.

For wrapped Boolean expressions, the logical operators should remain at the beginning of the continued line so that the connection type is directly visible.

Follow-up indentation inside a wrapped logical expression shall remain consistent throughout the whole expression.

Very long or hard-to-read logical expressions are a code smell. In such cases, check whether parts of the condition should be refactored into cohesive, domain-meaningful helper variables or clearly separated subchecks.

#### TIA-Structured Artifacts

In declarations, attribute-heavy definitions, and header metadata, greater line width is more acceptable because TIA Portal often presents those structures in a tabular or otherwise structured form.

This wider tolerance does not remove the requirement for consistent indentation between header, declaration blocks, nested structures, and executable logic.

#### Change Rule

When editing an existing artifact, indentation in the touched area shall be normalized to the currently agreed style.

New artifacts shall apply the indentation rules consistently from the beginning.

### Block Size And Refactoring Thresholds

Reusable library/framework blocks with their own logic should stay small enough to review and debug in TIA Portal.

Recommended targets:

| Block kind | Target size | Refactoring review threshold |
| --- | ---: | ---: |
| FC with own logic | <= 80 executable lines | > 120 executable lines |
| Simple FB with own logic | <= 150 executable lines | > 220 executable lines |
| Stateful reusable worker FB | <= 250 executable lines | > 350 executable lines |

These thresholds are review triggers, not hard compile rules.

Count executable logic approximately. Do not count declarations, UDT field lists, comments, or empty lines.

Pure project/caller/orchestration code is not subject to fixed size thresholds. Large orchestration code is acceptable when it is mostly structured calls, wiring, and aggregation with little own decision logic.

Large orchestration becomes a refactoring candidate when it contains hidden state machines, complex decisions, broad data manipulation, or mixed responsibilities.

## Block And Folder Structure

### General Structure Principles

Source structure shall make ownership and intended use visible.

Separate reusable library/framework code from project-specific orchestration, project-specific data access, simulation, test code, and exchange data areas.

Do not mix production/library block implementation, test-only code, generated helper metadata, and temporary debugging artifacts in the same source area.

### Software Units, Namespaces And Library Copies

Establish the consuming project's actual object placement before resolving cross-block symbols: outside Software Units, within one Software Unit, or across different Software Units. Folder names, a namespace prefix and the original library source location do not independently establish that placement. Preserve the existing project organization; using a library does not require introducing or removing Software Units.

| Caller and referenced object in the consuming project | Publication and access treatment |
| --- | --- |
| Both outside Software Units | Do not impose Software Unit publication or relation requirements. Resolve actual project symbols and declarations; `Published` in the original source is not a consumer access barrier. |
| Both within the same Software Unit | Internal access does not require publication to another unit or a cross-unit relation. Resolve the actual namespace and symbol; do not publish internal objects just to make a local call. |
| In different Software Units | Resolve the providing unit, required published objects and the consuming unit's relation. Include referenced types/data/constants as applicable, not only the called FB/FC. A namespace qualifier or public API classification does not grant access. |
| Mixed unit/project-level placement | Check the Siemens-supported access path for the actual object kind and direction. Do not extrapolate a unit-to-unit relation or ordinary outside-unit call to every mixed placement. |

For S7-1500, Siemens documents [publication](https://docs.tia.siemens.cloud/r/en-us/v21/using-software-units-s7-1500/creating-relations-s7-1500/publishing-program-elements-s7-1500?contentId=33j~j3dZl8eUiXcReP0hKg) and [relations](https://docs.tia.siemens.cloud/r/en-us/v21/using-software-units-s7-1500/creating-relations-s7-1500/setting-up-relations-s7-1500?contentId=zgxGMEAAIJwL5bGxTjWQYw) as technical access mechanisms. Public library/API eligibility, TIA `Published`, namespace resolution and HMI External permissions are separate concepts; none substitutes for the others. This table is documented context guidance, not a claim of native qualification for every object/import combination.

Individual blocks and PLC data types can be [reused from a library independently of their original Software Unit](https://docs.tia.siemens.cloud/r/en-us/v21/using-software-units-s7-1500/creating-and-managing-software-units-s7-1500/managing-software-units-in-libraries-s7-1500). For Mastercopies, apply the table to the resulting project copy and its actual dependencies, not to an assumed continuing connection to the source unit or a publication setting inferred from the original header. Siemens preserves a library object's namespace when inserted into a Software Unit and drops it when used outside Software Units; render references for the destination, not by blindly copying source qualifiers. Do not assume that Mastercopy insertion automatically establishes cross-unit relations or publishes required objects.

Preserve attributes and structure outside the approved change. Missing access does not authorize publishing an implementation, moving a dependency, duplicating a contract constant or replacing an object with a same-named copy. Resolve the technical facts first; align any consequential structural/interface change under the project's authority rules.

### TIA Folder Language

Library projects should use `en-US` as the TIA project language for new work.

Manually created folders shall use English names.

If TIA Portal already created localized default folders, use the existing default folders instead of creating parallel language variants.

Do not create duplicate folder trees only to normalize language after the fact.

Multiple PLCs, software units, and their containing folders are project organization concerns. They are not defined by this general styleguide.

Do not introduce typo variants for manually created framework/library folders.

### Recommended Library Areas

Use numbered top-level areas when a project contains several logical source areas and the numbering improves navigation.

Recommended high-level concepts:

- public API blocks,
- implementation blocks,
- DB access or data access helpers,
- simulation blocks,
- unit test blocks,
- utilities,
- PLC data types,
- PLC tags or constants.

Numbering should express stable structure, not temporary priority.

### Data Access Blocks

DB access, getter, setter, and ID-based object access helpers shall be grouped separately from reusable logic blocks.

This makes project-specific data access visible and prevents hidden coupling between standard block logic and global DB layout.

### Exchange Data Areas

Exchange data areas for external PLCs, OPC servers, PC applications, or non-optimized layout requirements shall be separated from normal optimized implementation code.

Exchange data areas shall be named and documented as exchange/interface areas.

Do not place unrelated internal state or implementation details into exchange DBs only because they are easy to observe.

### Instance Blocks

Explicitly named instance DBs shall be grouped in a predictable area when they are part of the exported source structure.

Local multi-instances inside FBs do not need folder-level representation and shall be treated as implementation details of the owning FB.

### Temporary And Debug Artifacts

Temporary debugging artifacts shall not be committed as part of library/framework source structure.

If a temporary TIA object is needed for local debugging, keep it outside the reusable source area or remove it before committing.

## Test-Only Code Boundaries

Test-only code shall be separated from production/library block implementations.

Production/library blocks shall not contain test-only branches, test-only variables, test-only commands, or test-only instrumentation unless a specific exception is explicitly approved for a higher technical purpose.

Unit tests, simulations, scaffolds, mocks, and framework self-tests shall live in dedicated test, simulation, sample, or framework-test source areas.

If test code needs to interact with production/library blocks, use public interfaces, explicit test resources, simulation blocks, or dedicated wrapper/access blocks instead of modifying the production/library block for the test.

Temporary test hooks shall not be committed as reusable production/library behavior.

## Observability And Debuggability

### General Principles

PLC code shall be observable enough to debug in TIA Portal without adding temporary logic to the block.

Observability shall be designed intentionally through:

- clear public status fields,
- explicit state values,
- explicit error/status codes,
- readable region structure,
- deterministic outputs,
- diagnostic fields where needed.

Do not expose internal implementation variables only because they are convenient to watch online.

### Status Data

Reusable worker objects shall expose intentional status data instead of requiring online inspection of internals.

Status data should be compact and structured.

Status fields shall use named constants or documented coded values when they represent classifications.

Avoid large text fields in production status data unless there is a deliberate diagnostic reason.

### Diagnostic Data

Diagnostic data shall describe exceptional or support-relevant conditions.

Do not use diagnostics as a substitute for clear block interfaces or explicit status values.

Diagnostic values shall be stable enough to support troubleshooting across online sessions and source exports.

### Debug Visibility

Internal state, timers, latches, and aggregation variables shall remain internal unless they are part of an intentional status or diagnostic interface.

If an internal value is regularly needed during commissioning or debugging, consider exposing a read-only status/diagnostic copy instead of making the internal variable externally visible or writable.

### Debug Code

Temporary debug code shall not be committed as production/library behavior.

Temporary watch tags, memory-area-M-based debug logic, forced helper branches, and temporary instrumentation shall be removed or converted into intentional diagnostics before commit.

### Failure Visibility

Unexpected states, invalid configuration, timeout conditions, unsupported modes, and failed technical preconditions shall be visible through explicit status, error, or diagnostic data.

Do not silently ignore exceptional conditions.

## Variable Attributes

### General Rule

Variable attributes are part of a TIA artifact's engineering definition. Use the general coding requirements and explicit [decision matrix](#block-and-variable-attributes), then the project-specific refinement and qualified import representation. The project does not silently weaken the general defaults. Do not maintain a second, less specific attribute matrix in this checklist.

### Function Blocks

Check FC versus FB, declaration section, datatype category, access mode and storage owner before selecting attributes. Verify the effective FB/IDB settings without interpreting ordinary inter-call persistence as power-failure retention. Do not override those settings during unrelated refactoring.

### Global Data Blocks

Review external access, retention and SetPoint as separate decisions. Check inherited settings of typed DBs, aggregate restrictions and the actual storage instance. Configuration does not automatically imply Retain or SetPoint; use the project's approved data-area design and the Siemens property-specific rules.

## Generated And Scaffolded Code

### General Rules

Generated or scaffolded SCL shall follow the same styleguide rules as manually written code.

Generated code shall be readable in TIA Portal after generation.

Do not generate unreadable generic indirection only to reduce generated source size.

Generated code may be repetitive when repetition improves online debugging, watch-table usage, and reviewability.

### Naming

Generated names shall be deterministic, stable, and human-readable.

Generated names shall not contain random GUID-like text unless the name is required by TIA Portal metadata and is not used as a human-facing PLC identifier.

Generated names shall not depend only on unstable list indexes when inserting a new object could change the meaning of existing names.

### Structure

Generated or scaffolded code shall be placed in the same conceptual structure as manually written code.

Do not create a separate generated-code folder hierarchy if it makes TIA Portal navigation harder.

Generated code shall clearly indicate ownership and intended use through folder location, block names, and comments on public definitions.

Do not manually convert the encoding of TIA-exported source files. Use the encoding produced by TIA Portal export/synchronization as the reference unless a concrete toolchain problem requires an explicit project decision.

### Regeneration

If code is generated and expected to be regenerated, the generator input shall be the source of truth.

Manual edits to generated code shall be avoided unless the code is explicitly converted into maintained manual code.

Generated files or blocks shall be recognizable as generated/scaffolded through naming, header metadata, or surrounding documentation where practical.

### Scaffolding

Scaffolded code is starter code meant to be copied, activated, or completed by a developer.

Scaffolded code may contain intentionally commented-out calls when this makes later project integration easier.

Scaffolded code shall not contain hidden behavior that runs by default before the developer intentionally adapts it.

When a variable is updated from its own current value and the used TIA/SCL language level supports compound assignment operators such as `+=` or `-=`, prefer those operators over equivalent self-referential assignments such as `Value := Value + 1`.
