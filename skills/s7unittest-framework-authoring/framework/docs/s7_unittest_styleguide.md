# S7 Unit Test Framework Styleguide

## Status

Project-owner aligned styleguide for the UnitTest framework implementation.

This document defines project-specific style rules for the S7 unit test framework and for PLC-side test code written against it.

General TIA/S7 PLC rules are documented in [TIA/S7 PLC Styleguide](../engineering-skill/skill/references/s7-styleguide.md).

## Scope

This document covers naming and structure rules for:

- framework blocks,
- framework UDTs and constants,
- run control,
- test suites,
- test cases,
- preparation blocks,
- assertion blocks,
- event-stream and diagnostic components,
- generated or scaffolded unit-test PLC code.

## Reading Routes

- Naming and declarations: [domain prefix](#domain-prefix), [block names](#framework-block-names), [interfaces](#block-interfaces) and [header metadata](#unit-test-header-metadata).
- Attributes and native import: [UnitTest attribute policy and qualified profiles](#unit-test-artifact-attributes).
- Source placement: [framework structure](#unit-test-framework-structure), [application/Self-Test structure](#unit-test-application-and-self-test-structure) and [test-only boundaries](#test-only-boundaries).
- Cyclic behavior: [execution order](#runsuitetest-execution-order), [state machines](#state-machines), [Assertions](#assertions) and [Preparations](#preparation-blocks).
- Review and generation: [test component conventions](#test-component-style-conventions), [observability](#observability-and-debuggability) and [generated code](#generated-and-scaffolded-unit-test-code).

## Naming Conventions

### Domain Prefix

The S7 unit test framework shall use `UnitTest` as the primary domain prefix for globally visible framework concepts.

Use the domain prefix for:

- framework UDTs,
- global TIA user constants,
- global DBs,
- public framework entry points,
- event-stream structures,
- generated or scaffolded framework code.

The prefix is required to avoid collisions when the framework is integrated into PLC projects that already contain logging, diagnostics, status, result, or event concepts.

Do not use generic global names such as:

- `EventBuffer`
- `LogEntry`
- `RunState`
- `Result`
- `Status`

Use names such as:

- `UnitTestEventBuffer`
- `UnitTestEventEntry`
- `UnitTestRunState`
- `UnitTestResult`
- `UnitTestStatus`

Do not use the `UnitTest` prefix for project- or library-specific concrete test names when the block is not framework infrastructure and the surrounding test context is already clear.

Prefer:

- `TestValveOpenInManualMode`
- `PrepareValveAutoMode`
- `TestSuiteValveManualMode`

Avoid:

- `UnitTestValveOpenInManualMode`
- `UnitTestPrepareValveAutoMode`
- `UnitTestTestSuiteValveManualMode`

Inside framework-owned UDTs, FBs, and FCs, do not repeat the `UnitTest` prefix for every nested field or local variable if the owner context is already explicit.

Examples:

- `UDT_UnitTestRunStatus.State`, not `UDT_UnitTestRunStatus.UnitTestRunState`.
- `UDT_UnitTestEventEntry.Result`, not `UDT_UnitTestEventEntry.UnitTestResult`.
- `UnitTestRunControl.RuntimeTimer`, not `UnitTestRunControl.UnitTestRunControlRuntimeTimer`.

### Canonical Framework Terms

Do not introduce typo variants or plural variants for framework concepts.

Canonical spellings:

- `TestSuite`, not `TestsSuite`.
- `TestSuites`, not `TestsSuites`.
- `Preparation`, not `Prepararion`.
- `Assertions`, with assertion-family subfolders such as `BasicTypes` and `Arrays`.

### Framework Block Names

Framework block names shall identify whether the block is framework infrastructure or concrete test code.

| Role | Prefix | Example |
| --- | --- | --- |
| Run Control infrastructure | `RunControl` | `RunControl` |
| Generic Test Suite infrastructure | `TestSuite` | `TestSuiteOrchestrator` |
| Generic Test Case infrastructure | `TestCase` | `TestCaseSequencer` |
| Concrete Test Suite | `TestSuite` plus scenario/domain | `TestSuiteAnalogInputBipolar` |
| Concrete Test Case | `Test` plus tested behavior | `TestStatusUnderRange` |
| Preparation | `Prepare` | `PrepareUnderRangeNoError` |
| Assertion | `Assert` | `AssertEqual_LInt` |
| PC-facing unit-test event API | `UnitTestEvent` | `UnitTestEventBufferWrite`, `UnitTestEventCreateTestCaseResult` |
| PLC-local unit-test diagnostics | `UnitTestDiag` | `UnitTestDiagBufferWrite`, `UnitTestDiagDebugMessage` |
| Utility | descriptive verb phrase | `CreateSourceText`, `ReadCycleTime` |

Concrete test code may use `Test...`. Generic framework lifecycle blocks shall use `TestCase...` to avoid confusing infrastructure with actual tests.

Example:

- `TestCaseSequencer` is a reusable framework mechanism.
- `TestStatusUnderRange` is a concrete test scenario.

Do not prefix framework FBs and FCs with `FB_` or `FC_`.

Preferred:

- `UnitTestRunControl`
- `UnitTestEventBufferWrite`
- `UnitTestEventCreateTestCaseResult`

Avoid:

- `FB_UnitTestRunControl`
- `FC_UnitTestEventBufferWrite`
- `FC_UnitTestEventCreateTestCaseResult`

### Event Versus Log Naming

Use `UnitTestEvent...` for PC-facing structured unit-test event stream data.

Use `UnitTestDiag...` for PLC-local unit-test diagnostic/debug information that is not part of the PC-facing test result stream.

Example:

- `UnitTestEventBufferWrite` writes a structured result event that the PC runner can consume for CI artifacts.
- `UnitTestDiagBufferWrite` stores a PLC-local diagnostic message such as `UploadBufferFull`.

Do not use generic `Log...` for PC-facing unit-test result events in new framework code, because unit-test event reporting is independent from other real logging functionality in an integrated PLC project.

### Test Naming Specificity

Test, preparation, and assertion names shall be specific enough to distinguish their purpose during TIA Portal debugging and PC-side reporting.

Names should focus on the primary behavior or condition. They should not encode every setup detail.

Allowed:

- `TestStatusUnderRange`
- `TestOutputOpenInManualMode`
- `PrepareAutoModeUnlocked`
- `PrepareUnderRangeNoError`

Avoid:

- `TestStatus`
- `PrepareAutoModeUnlockedNoAlarmWithSimulationAndAck`
- `Test_1`

If a block has important side effects that are not obvious from its name, the side effects shall be visible through its interface, regions, or concise comments.

### Unit Test UDT Names

Framework UDTs shall use `UDT_UnitTest...`.

Examples:

- `UDT_UnitTestEventEntry`
- `UDT_UnitTestExecutionStatus`
- `UDT_UnitTestRunControl`
- `UDT_UnitTestSuiteControl`
- `UDT_UnitTestCaseControl`
- `UDT_UnitTestRunConfig`
- `UDT_UnitTestEventBuffer`

### Unit Test DB Names

Framework-owned global data blocks shall use the `DB_UnitTest...` prefix.

Examples:

- `DB_UnitTestControl`
- `DB_UnitTestEventBuffer`
- `DB_UnitTestStatus`

Explicitly named framework instance DBs shall use `IDB_UnitTest...`.

Examples:

- `IDB_UnitTestRunControl`
- `IDB_UnitTestUploadControl`

Local multi-instances inside framework FBs shall not use `DB_` or `IDB_` prefixes. Their names should describe their role in the owning block.

### Unit Test Constants

For global TIA user constants, prefer grouped dot notation with the `UnitTest` domain prefix.

Examples:

- `UnitTest.RunState.Idle`
- `UnitTest.RunState.Reset`
- `UnitTest.RunState.Completed`
- `UnitTest.TestSuiteState.Running`
- `UnitTest.TestCaseState.Preparation`
- `UnitTest.PreparationState.Completed`
- `UnitTest.Result.Passed`
- `UnitTest.Result.Failed`
- `UnitTest.Result.Error`
- `UnitTest.EventType.TestCaseResult`
- `UnitTest.OwnerScope.TestCase`

For local SCL constants inside a block, use identifier-safe names with an owner prefix.

Examples:

- `UnitTestRunState_Idle`
- `UnitTestRunState_Completed`
- `UnitTestTestCaseState_Preparation`
- `UnitTestResult_Error`

Do not use `State.Idle`, `RunState.Idle`, `State_Idle`, or `RunState_Idle` for global/shared framework constants because the owning framework is unclear when several libraries are integrated into the same project.

Unit-test framework state machines, result classifications, owner scopes, and event types shall never use magic numbers.

Prefer local SCL constants for block-internal state machines, for example inside a concrete test case or preparation block.

Use global `UnitTest...` constants when values are shared between framework blocks, written to PC-facing data areas, used in status/event structures, or consumed by generated/scaffolded code.

Named value types are only an optional alternative to global constants. They are not the default for framework v1 and shall not be used for PC-facing contract values without explicit approval.

### Lifecycle Terms

Use `Completed` as the preferred lifecycle term for new framework code.

Use `Finished` only for compatibility wrappers or deliberately simple helper blocks.

For new framework status data, prefer:

- `Ready`
- `Running`
- `Completed`
- `Error`
- `Timeout`

### Generated Or Scaffolded Unit Test Names

Generated or scaffolded unit test names shall be deterministic, stable, and human-readable.

Generated names shall preserve behavior meaning when tests are inserted or reordered. Do not generate names whose meaning depends only on sequence numbers.

Allowed:

- `TestStatusUnderRange`
- `TestSuiteAnalogInputBipolar`

Avoid:

- `Test_001`
- `TestSuite_003`
- `GeneratedTest_42`

## Block Interfaces

### Unit Test Block Interfaces

Small unit-test helper functions and helper FBs without ownership of an independent worker object shall prefer explicit parameter passing through the interface.

This applies to:

- simple assertion helpers,
- source/message formatting helpers,
- small conversion helpers,
- compact validation helpers.

Framework blocks that own a lifecycle or worker object shall use structured control/status data.

This applies to:

- Run Control,
- Upload Control,
- Test Suite orchestration,
- Test Case lifecycle,
- event buffer handling,
- reusable multi-cycle Preparation blocks.

For these owner blocks, avoid large unstructured parameter lists. Prefer UDT-based control/status/resource structures or an explicit ID/getter/setter access pattern when working with global object collections.

References are not the default mechanism for unit-test framework data access.

Concrete test cases may pass project-specific resources through `VAR_IN_OUT` when the test intentionally works on that resource. The variable name shall identify the resource role, not only its datatype.

### Unit Test ENO Usage

Unit-test framework blocks shall not use `ENO` for test results.

`ENO = TRUE` is valid even when a test result is failed, an assertion finding exists, or a test run completed with failed tests.

Use explicit `UnitTestResult...`, status structures, event entries, and diagnostic fields for unit-test outcomes.

Use `ENO = FALSE` only for exceptional technical execution problems where the block cannot produce trustworthy outputs according to its interface contract.

### Unit Test UDT Versus Struct

Use UDTs for framework status, result, event, buffer, configuration, and other contract-facing shared structures.

Do not use anonymous structs for PC-facing event stream data or framework status areas.

Private structs may be used only for local implementation details that are not shared across framework blocks.

For UnitTest producer-side control structures, inline `STRUCT`s are allowed for `Cmd` and `Status` when this layout is explicitly defined by the local contracts.

Apply the general UDT initial-value rule. `UDT_UnitTestRunConfig.SuiteCount` has no explicit UDT initial value: the concrete application sets its configured Suite count. This does not remove shared timeout defaults, status/result initial values or technically required start values such as one-based FIFO indices.

### Unit Test External Visibility

Apply the general [attribute rules](../engineering-skill/skill/references/s7-styleguide.md#block-and-variable-attributes) and the project refinement below. Framework implementation and Test Case/Preparation internals are not public HMI or runner interfaces. All external interaction uses deliberately defined global command/control, status, event-stream, diagnostic or exchange data.

Only a field defined as writable by its contract, approved data-area design or concrete interface definition may be externally writable. For producer-side public UnitTest data, that definition is authoritative. Do not broaden an entire UDT or worker-object array to expose one field; containing levels may restrict but shall not relax nested permissions.

Runtime-adjustable Settings/Parameter data, if introduced, belongs to a deliberate retentive global data area, not hidden instance settings. UnitTest configuration DBs remain PLC/framework-owned commissioning configuration, not PC-runner runtime-control data. Their concrete commissioning access, retention and existing SetPoint choices require an approved data-area definition. The runner shall not depend on configuration DBs to evaluate lifecycle completion, logs or results.

### Unit Test Artifact Attributes

This section refines the general coding matrix; it does not replace it with a permissive import shortcut. The required effective setting and the source representation are separate. No blanket InOut omission rule applies. Existing valid attributes remain unchanged outside an approved artifact change.

`FALSE` in an External column is the required effective setting. `No formal field attribute` means this project generates no such property on the call-local FC/Temp/constant declaration; it is not a Siemens-wide syntax prohibition and says nothing about actual-operand permissions. `Contract` or `Design` requires a concrete approved definition, not an arbitrary choice.

| Project context | ExternalVisible | ExternalAccessible | ExternalWritable | Retention | SetPoint | Import profile | Qualification / required additional evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FC Input, elementary | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | P1 | Checked: supplied External flags not retained; actual storage separately |
| FC Input, structured | Actual operand by role | Actual operand by role | Actual operand by role | Actual operand | Actual operand | P1 | Checked: supplied External flags not retained; actual storage separately |
| FC Output, elementary | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | P1 | Checked: supplied External flags not retained; actual storage separately |
| FC Output, structured | Actual operand by role | Actual operand by role | Actual operand by role | Actual operand | Actual operand | P1 | Checked: supplied External flags not retained; actual storage separately |
| FC InOut, elementary | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | P1 | Checked: supplied External flags not retained; actual storage separately |
| FC InOut, structured | Actual operand by role | Actual operand by role | Actual operand by role | Actual operand | Actual operand | P1 | Checked: supplied External flags not retained; actual storage separately |
| FC return value | No own external-access declaration | No own external-access declaration | No own external-access declaration | Actual destination, if any | Actual destination, if any | P1 | Partial: BOOL return only; structured return open |
| FC Temp / Constant | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | P9 | Partial: plain BOOL Temp/Constant; attribute injection not tested |
| FB Input, elementary | FALSE | FALSE | FALSE | Non-retentive | No attribute | P2 | Checked for tested elementary/structured fields; no SetPoint declaration |
| FB Input, structured | FALSE | FALSE | FALSE | Non-retentive | No attribute | P2 | Checked for tested elementary/structured fields; no SetPoint declaration |
| FB Output, elementary | FALSE | FALSE | FALSE | Non-retentive | No attribute | P2 | Checked for tested elementary/structured fields; no SetPoint declaration |
| FB Output, structured | FALSE | FALSE | FALSE | Non-retentive | No attribute | P2 | Checked for tested elementary/structured fields; no SetPoint declaration |
| FB InOut, elementary | FALSE | FALSE | FALSE | Non-retentive | No attribute | P3 | Checked: BOOL/INT/REAL/LREAL flags; plain non-retentive and BOOL RETAIN control |
| FB InOut, structured | Operand/type by role; no own formal flag in P4 | Operand/type by role; no own formal flag in P4 | Operand/type by role; no own formal flag in P4 | No retentive formal declaration; operand separately | No formal attribute | P4 | Checked: ARRAY, STRING/WSTRING, UDT/STRUCT; no own External flags retained |
| FB Static, elementary | FALSE | FALSE | FALSE | Non-retentive | FALSE | P5 | Checked for tested elementary fields; explicit SetPoint FALSE/TRUE control |
| FB Static, STRUCT/UDT | FALSE | FALSE | FALSE | Non-retentive | FALSE on qualified container declarations and eligible defining members | P6 | Partial: static UDT container FALSE checked separately from members, including save/reopen; inline STRUCT container and arbitrary datatype overrides remain open |
| FB Static, ARRAY | FALSE | FALSE | FALSE | Non-retentive | FALSE under array/member rules | P6 | Partial: tested aggregates; no arbitrary datatype or inherited override proof |
| FB multi-instance | Private boundary/called FB | Private boundary/called FB | Private boundary/called FB | Owning/called FB definitions | FALSE on qualified container declarations; called FB members separately | P7 | Partial: user-FB container FALSE checked, including save/reopen; TON_TIME access-boundary evidence is not instruction SetPoint qualification |
| FB parameter instance | Private applicable formal properties/referenced instance | Private applicable formal properties/referenced instance | Private applicable formal properties/referenced instance | Referenced instance definition | Referenced FB definition | P8 | Open; do not infer support from multi-instance |
| FB Temp / Constant | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | P9 | Partial: plain BOOL Temp/Constant; attribute injection not tested |
| OB Temp / Constant | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | No formal field attribute | P9 | Documented; native OB proof open |
| Internal global DB, elementary fields | FALSE | FALSE | FALSE | Non-retentive | FALSE | P10 | Checked: External FALSE, NonRetain, SetPoint FALSE/TRUE |
| Internal global DB, STRUCT/UDT/ARRAY fields | FALSE | FALSE | FALSE | Non-retentive | FALSE on eligible fields; preserve type rules | P10/P14 | Partial: tested aggregates and UDT members; other layouts open |
| Global DB based on UDT | Internal FALSE or Contract, within type restrictions | Internal FALSE or Contract, within type restrictions | Internal FALSE or approved write field | Concrete DB, by role | UDT definition | P11/P14 | Partial: inherited tested members; retention variants open |
| ARRAY DB | Internal FALSE or Contract | Internal FALSE or Contract | Internal FALSE or approved write field | Unsupported | Unsupported | P12 | Documented only; native proof open |
| Public command / acknowledgement DB field | Contract | Contract | TRUE only for an approved writable interaction field | Non-retentive | FALSE | P10-P14, as storage permits | Role/contract attestation required; probe does not qualify a public interface or approve an exception |
| Public status / event / contract-info DB field | Contract | Contract | FALSE | Non-retentive | FALSE | P10-P14, as storage permits | Role/contract attestation required; probe does not qualify a public interface or approve an exception |
| Public worker-object / diagnostic DB field | Approved observable fields only | Approved observable fields only | FALSE except specifically approved interaction fields | Data-area design; no implicit persistence | FALSE unless an approved setting | P10-P14, as storage permits | Role/contract attestation required; probe does not qualify a public interface or approve an exception |
| Framework configuration DB field | Approved commissioning design | Approved commissioning design | Approved commissioning design; not runner runtime configuration | Approved design | Approved design; existing markings preserved | P10-P14, as storage permits | Role/contract attestation required; probe does not qualify a public interface or approve an exception |
| Deliberate global Settings/Parameter field | Approved interface | Approved interface | Approved setting fields only | Retentive | Approved design, not implied by Retain | P10-P14, as storage permits | Role/contract attestation required; probe does not qualify a public interface or approve an exception |
| Internal UDT elementary members | FALSE | FALSE | FALSE | Concrete storage | FALSE | P13 | Checked: tested flags and SetPoint; explicit per-member verification required |
| Internal UDT STRUCT/UDT/ARRAY members | FALSE, respecting nested properties | FALSE, respecting nested properties | FALSE, respecting nested properties | Concrete storage | FALSE under member/array rules | P14 | Partial: tested nested UDT/BOOL-array/UDT-array; remaining types open |
| Public contract/exchange UDT members | Contract | Contract | Approved interaction/setting members only; producer-owned members FALSE | Concrete storage | FALSE except approved settings or preserved configuration markings | P10-P14, as storage permits | Role/contract attestation required; probe does not qualify a public interface or approve an exception |

The FC profile also generates no external-access/retention/SetPoint field attributes on structured formals. The table names their actual-operand properties to prevent accidentally treating omission as protection of the passed storage. No new framework-internal absolute PLC tags are introduced by default. If explicitly approved, their address/memory area and supported external access must be defined; retention follows the memory/CPU configuration, not table publication.

#### Qualified Import Profiles

The following mapping records bounded technical evidence, not per-artifact approval. Checked cases use optimized S7-1500 / STEP 7 V21 Update 2, SCL imports and WithDefaults XML. Save/reopen evidence applies where explicitly recorded; later extensions retain their own evidence boundaries below. Apply the general matrix's documentation/open-scope limits. A contract/design entry still needs its exact role and values checked; successful private probe imports are not qualification of a public interface.

| Profile | Representation for the required project settings | Evidence boundary |
| --- | --- | --- |
| P1 - FC formals/return | No External, Retain or SetPoint field bundle. Apply data permissions at the actual operand/destination. STRING/WSTRING formals without explicit length in the tested sections | Explicit External flags were accepted but not retained for tested Input/Output/InOut. BOOL return only; no structured-return qualification |
| P2 - FB Input/Output | Explicit ExternalAccessible/ExternalVisible/ExternalWritable FALSE; no SetPoint; plain non-retentive declaration section. Tested STRING/WSTRING lengths supported here | BOOL, INT, REAL, LREAL, BOOL-array, STRING/WSTRING, UDT and inline STRUCT |
| P3 - FB elementary InOut | Explicit three External FALSE flags; no SetPoint; plain VAR_IN_OUT | BOOL, INT, REAL and LREAL. The BOOL RETAIN control proves capability, not a framework exception |
| P4 - FB structured InOut | No ineffective External/SetPoint/retention bundle on the reference formal; enforce the passed storage/type role. STRING/WSTRING without explicit length | Flags were not retained for tested ARRAY, STRING/WSTRING, UDT/STRUCT; structured RETAIN was removed by generation |
| P5 - FB elementary Static | Explicit three External FALSE flags and eligible S7_SetPoint FALSE; plain VAR section | Tested elementary fields; TRUE SetPoint and BOOL RETAIN controls distinguish supported exceptions |
| P6 - FB aggregate Static | Three External FALSE flags at supported boundaries. Explicit S7_SetPoint FALSE on matching qualified static UDT container declarations; independently establish eligible defining member/array settings. Other containers require their own qualification | Static UDT container FALSE retained independently of member settings, including save/reopen. Static binding/result arrays have the bounded evidence recorded below. Earlier inline STRUCT/BOOL-array/member evidence remains bounded; do not infer arbitrary container support. Preserve approved existing configuration markings |
| P7 - Multi-instance | Preserve required instruction/type attributes and use three External FALSE boundary flags. Explicit S7_SetPoint FALSE on matching qualified user-FB multi-instance declarations in the owning FB; review called FB members separately | User-FB container FALSE retained in source/WithDefaults and after save/reopen without changing defining members. Static Assertion FB arrays have the bounded evidence recorded below. Earlier TON_TIME access-boundary evidence does not qualify its SetPoint declaration; other instruction/instance types remain open |
| P8 - Parameter instance | Use documented representation only after context-specific qualification | Open; no native parameter-instance proof |
| P9 - Temp/Constant | Plain declarations, no runtime attribute bundle; initialize Temp before use | Plain BOOL FB/FC declarations checked; other applicable contexts remain documented or open as in general matrix |
| P10 - Plain global DB | Explicit three External FALSE flags for private storage, supported DB non-retentive form and eligible SetPoint FALSE; substitute only exact approved public-role values | Tested elementary/aggregate fields. Public TRUE/FALSE roles must be verified separately against their definition |
| P11 - UDT-based global DB | Retain datatype definition/constraints and use concrete DB retention by approved role; verify inherited member properties | Tested UDT member access/SetPoint inheritance; no retained-DB variant |
| P12 - ARRAY DB | Follow documented ARRAY-DB restrictions; no Retain/SetPoint; qualify concrete access/import representation before use | Native ARRAY-DB proof open |
| P13 - Elementary UDT member | Explicit External flags for its defined role; effective SetPoint FALSE unless an approved marking | Tested BOOL access and Int SetPoint; no own runtime retention |
| P14 - Nested UDT/STRUCT/ARRAY member | Preserve defining member restrictions; apply flags at supported boundaries and SetPoint only at eligible members/arrays | Tested nested UDT, BOOL array and UDT array; arbitrary overrides/other element types open |

An omitted formal attribute in P1/P4 does not establish a permissive runtime property: the tested formals have no such own exported setting. Conversely, omitted flags on an applicable FB/DB/UDT field do not establish private defaults. Native unannotated controls had all three External flags TRUE. These cases must not share a blanket omission rule.

##### Static Assertion Instance Arrays: P6/P7 Extension

The qualified source-import representation applies to optimized S7-1500 / STEP 7 V21 Update 2 outside Software Units, in a Test Case FB: four private Static arrays declared as `Array[1..#SampleCount] of "AssertEqual_LReal"`, `"AssertEqual_Bool"` (two arrays) and `"AssertEqual_Int"`, with local `SampleCount : UInt := UINT#11`, using dynamically indexed calls in bounded same-invocation loops. This qualifies the concrete representation, not a preference for arrays or a performance improvement.

WithDefaults inspection confirmed the three External flags FALSE and SetPoint FALSE on the owning array containers, separately checked defining Assertion FB members, and non-retentive materialized Suite instance data. Associated private Static arrays of LReal, Bool, String[12], configuration UDT and result UDT retained the intended container properties; the defining subject UDT member properties were checked separately. Source readback also preserved the binding data, index expressions and intended body indentation. The project was saved, but this extension does not claim a separate close/reopen attribute roundtrip or injected-failure coverage.

Do not extrapolate this evidence to other FB/instruction types, arbitrary array bounds, CPU families, TIA versions, Software Unit contexts or import representations. Verify those contexts and their effective container/defining-member properties separately. Arrays remain an authoring representation chosen under the existing execution, instance-ownership and diagnostic criteria, not a new lifecycle or logging contract.

#### Import Representation And Existing Artifacts

For private FB fields whose declaration context supports these properties, explicitly generate `ExternalAccessible := 'False'`, `ExternalVisible := 'False'` and `ExternalWritable := 'False'`. Select SetPoint separately under P5/P6/P7; do not append it, retention modifiers or other static-field attributes indiscriminately to all declaration sections. Elementary FB InOut must not be treated as a pointer-only context or left to permissive defaults.

Use P4 for the tested structured InOut contexts, P8 for still-open parameter-instance qualification and P14 for the tested nested datatype boundaries. Do not extrapolate beyond their explicit limits or copy an elementary bundle onto all formals. Preserve required instruction/type metadata. A failed import is not evidence that all attributes in that declaration section are prohibited.

For new eligible private Static/DB/UDT fields, explicitly establish SetPoint FALSE at the defining owner and permissible aggregate/member level. This includes the qualified static UDT and user-FB multi-instance container declarations in P6/P7; their FALSE property is not a redefinition of the referenced type's members. Do not add SetPoint to Input/Output/InOut. Correct exports may omit the FALSE default; absence alone is not a defect.

Check applicable container markings and eligible defining members independently, including nested storage/type relationships. Neither a container TRUE with FALSE members nor a container FALSE with unchecked members satisfies the complete non-setting-data review. The general matrix distinguishes Siemens' documented marking restrictions from the qualified owning-FB SCL FALSE declarations. Do not treat an unqualified container context as a blanket omission exception: qualify it or report the unresolved property before accepting the artifact.

Use plain FB declaration sections for non-retentive data; no `VAR NON_RETAIN`, `VAR_NON_RETAIN` or invented retention member attribute. Keep supported DB source syntax distinct. Retain, SetPoint and inter-call state persistence remain independent.

Existing configuration datatype SetPoint markings are preserved. They are an existing concrete data-area choice, not an exception for all future configuration fields. Changes require their own approved artifact scope. Other existing attributes likewise remain unchanged unless their update is explicitly authorized.

An import representation is qualified only when accepted syntax and effective properties have been verified for its block kind, section, datatype category, access mode, TIA version and format. Compilation and source equality alone do not establish qualification. An unsupported operation or insufficient readback must be reported as unresolved; agree any fallback under the consuming project's development workflow rather than using a weaker default. Source preparation and helper paths must use the same policy.

#### Unit Test Object Attributes

| Object | Project choice | Boundary |
| --- | --- | --- |
| FC | Optimized access where supported; no know-how protection by default; publication only for required cross-unit use | Preserve supported header metadata; no instance-storage attributes |
| FB | Optimized access; no know-how protection by default; publication only for required cross-unit use | Define and verify instance-data properties in the FB |
| OB | Supported optimized access; no know-how protection by default | Preserve event-specific definition; no generated system-parameter policy |
| Global DB | Optimized access; publication only for required unit consumers | Concrete field roles and typed/ARRAY restrictions remain applicable |
| UDT | Publication only for required cross-unit use; supported type metadata and member roles | No invented code-block optimization/protection/header pragmas |
| Tag / constant table | Publication only when another software unit requires the definitions | Publication is not per-member HMI/runtime permission |

Retain names, namespace, title/comment and supported identity/version metadata under the existing [header rules](#unit-test-header-metadata). Protection remains a separate release decision; neither this matrix nor a library build introduces protection automatically. Concrete instance DBs are application integration objects, not generic library deliverables.

Preserve `InstructionName`, `LibVersion` and other native/type-specific metadata. LAD/FBD display/default-assignment attributes are governed by the general styleguide and must not hide required dependencies.

Unit-test framework blocks shall use S7 optimized access by default.

If a PC-facing, OPC-facing, or cross-PLC exchange area requires non-optimized layout, it shall be isolated from internal framework logic and documented as an exchange data area.

Unit-test framework logic shall not depend on memory area M (Merker / Siemens bit memory) for state, result, event, or control behavior.

Temporary memory-area-M-based debugging shall not be committed as framework behavior.

## Block And Folder Structure

### Unit Test Source Area

In this repository, reusable UnitTest framework and handling code shall be grouped under the `03_Handling` software unit.

Do not place unit-test code inside production/library block implementation folders.

Production/library blocks shall not contain test-only code.

PLC-side UnitTest usage, integration tests, and framework self-tests shall be grouped under the dedicated `90_UnitTest` software unit.

### TIA Export Structure

The TIA Portal export and synchronization structure defines the upper folder levels.

Use the following conceptual structure:

```text
<plc>/<software-unit>/<tia-base-folder>/<project-internal-folder>
```

`<plc>` is only used when a library project contains multiple PLCs.

`<software-unit>` is only used when TIA software units are used. In this repository, `03_Handling` contains reusable framework/handling code and `90_UnitTest` contains UnitTest usage and self-test code.

`<tia-base-folder>` is defined by TIA Portal export/synchronization, for example:

- `Program blocks`
- `PLC data types`
- `PLC tags`

Project-internal UnitTest folders shall be created below the TIA base folders, not above them.

### Unit Test Framework Structure

Below the TIA base folders of `03_Handling`, reusable UnitTest framework blocks shall be grouped by framework concept.

Current project-internal framework folders include:

- `Assertions`
- `Examples`
- `Logging`
- `Preparation`
- `RunControl`
- `TestCases`
- `TestSuites`
- `Utilities`

`Examples` contains framework examples and scaffold-like reference blocks that may be distributed with the library. These blocks are not required for framework core execution.

Reusable framework blocks and data types intended to become part of the TIA library belong in the concept folders below `03_Handling`.

Local experiments and temporary integration code shall not be committed into reusable framework folders.

Do not use typo variants such as `TestsSuites` or `Prepararion`.

Current reusable framework structure:

```text
<plc>/
  03_Handling/
    Program blocks/
      Assertions/
      Examples/
      Logging/
      Preparation/
      RunControl/
      TestCases/
      TestSuites/
      Utilities/
    PLC data types/
      Common/
      Logging/
      Preparation/
      RunControl/
      TestCases/
      TestSuites/
    PLC tags/
      <framework tag tables>
```

The `<plc>` level is only used when the library project contains multiple PLCs.

Prefer framework-owned data type and tag definitions whenever the structure is reusable or part of the intended library interface.

### Unit Test Application And Self-Test Structure

The `90_UnitTest` software unit contains PLC-side UnitTest usage, integration wiring, and framework self-test content. It is separate from the reusable framework implementation in `03_Handling`.

Current UnitTest software-unit structure:

```text
<plc>/
  90_UnitTest/
    Program blocks/
      ConfigureUnitTests
      ExecuteUnitTests
      RunControl/
      TestSuites/
      TestCases/
```

The current content can be small or focused on one vertical self-test slice. The software unit still represents the project-local UnitTest execution area.

### Framework Versus Project-Specific Tests

Reusable UnitTest framework blocks shall be separated from project-specific test suites and concrete tests.

Framework blocks include:

- Run Control,
- Upload Control,
- event buffer handling,
- shared status/result/event UDTs,
- generic assertion helpers,
- generic lifecycle helpers,
- reusable utilities.

Project-specific test code includes:

- concrete Test Suites,
- concrete Test Cases,
- project-specific Preparation blocks,
- resource-specific test fixtures,
- example wiring for a concrete library block.

### Run Control And Upload Control

Run Control and Upload Control shall be separate framework responsibilities.

The folder structure shall not force test execution and PC-facing upload/consumer logic into the same block or source area.

### Event And Exchange Data

PC-facing UnitTest event stream, command, status, and exchange data areas shall be grouped separately from internal framework logic.

Exchange DBs or non-optimized data areas, if required, shall be explicitly named as UnitTest exchange/interface artifacts.

Direct access to `DB_UnitTestEventBuffer` is restricted to blocks in the `Logging` area that implement producer-side EventBuffer ownership. Run Control, Sequencers, Orchestrators, Test Suites, Test Cases, Assertions, examples, and entry-point blocks shall use semantic Logging utilities instead of addressing the EventBuffer DB directly.

EventBuffer DB fields and FIFO implementation structures shall not be passed through UnitTest block interfaces to bypass this boundary. Logging utilities shall expose the required operation or semantic value without exposing the underlying storage implementation.

### Test Suite And Test Case Structure

Concrete Test Suites shall be placed below `TestSuites`.

Concrete Test Cases shall be placed below `TestCases`.

Preparation helpers shall be placed below `Preparation` unless they are private local implementation details of a specific Test Case.

Assertion evaluation helpers shall be placed below `Assertions`. Assertion-owned event creation helpers belong to the Logging area because they create UnitTest log/event entries.

Reusable assertion blocks shall be grouped by assertion family below `Assertions`.

Current assertion family folders:

- `Assertions/BasicTypes/<Type>` for scalar datatype assertions.
- `Assertions/Arrays/<Type>` for array assertions.

Do not use a generic `Assertions/Handling/<Type>` folder for assertion exports. The first folder level shall describe the assertion family; the datatype folder is the second level.

### Test Suite Orchestrators

Run Control blocks shall prefer the generic Suite Orchestrators when the intended execution pattern matches one of the provided variants defined by the framework design.

Current orchestrator variants:

- `UnitTestSuiteOrchestrator_Serial` for sequential suite execution.
- `UnitTestSuiteOrchestrator_Parallel` for running all registered suites in parallel.
- `UnitTestSuiteOrchestrator_ParallelSlots` for slot-based parallel suite execution.

Run Control blocks shall keep project-specific Suite binding explicit: suite configuration, optional slot configuration, and concrete suite calls remain in the Run Control implementation. Logical ownership does not require Suite storage to be a Run-Control-local multi-instance; follow the project's integration rules for concrete instance DBs.

Do not duplicate generic Suite orchestration behavior in project-specific Run Control implementations unless the existing orchestrators cannot model the required execution pattern. The concrete ownership of lifecycle, result escalation, timeout handling, reset/abort propagation, and suite-level orchestration events is defined by the framework design and contracts.

Run-Control-local debug views such as `SuiteActive` shall be derived in the Run Control implementation after subordinate suite calls and status-view updates. They shall not be passed into orchestrators unless the framework design explicitly introduces such an interface.

### Test Suite Sequencer

Test Suite blocks shall prefer `UnitTestSuiteSequencer` for the generic Suite lifecycle. The Sequencer encapsulates Suite command priority, lifecycle state transitions, runtime handling, reset and abort monitoring, subordinate command generation, and Suite owner state-transition events.

The project-specific Test Suite remains responsible for Test Case binding, lifecycle-signal derivation, final result composition, status publication, and final Result and Aggregation events. A direct Suite-owned state machine remains allowed, but it must implement the same lifecycle and event behavior without duplicating a simultaneously used Sequencer.

### Test Case Orchestrators

Test Suite blocks shall prefer the generic test-case orchestrators when the intended execution pattern matches one of the provided variants defined by the framework design.

Current orchestrator variants:

- `UnitTestCaseOrchestrator_Serial` for sequential test-case execution.
- `UnitTestCaseOrchestrator_Parallel` for running all registered test cases in parallel.
- `UnitTestCaseOrchestrator_ParallelSlots` for slot-based parallel test-case execution.

Test Suite blocks shall keep suite-specific binding explicit: test-case instance declarations, test-case configuration, optional slot configuration, and concrete test-case calls remain in the suite.

Do not duplicate generic test-case orchestration behavior in concrete suites unless the existing orchestrators cannot model the required execution pattern. Test Case Orchestrators own subordinate start/reset/abort propagation, readiness and completion evaluation, Test Case timeout monitoring, orchestration result reporting, and technical Orchestrator diagnostics. They do not own the Test Suite lifecycle or emit Test Suite lifecycle-completion evidence.

Suite-local debug views such as `TestCaseActive` shall be derived in the suite after subordinate test-case calls and suite status-view updates. They shall not be passed into orchestrators unless the framework design explicitly introduces such an interface.

Direct Test Suite lifecycle handling and direct Test Case orchestration remain allowed for special cases, but they are not the default pattern for standard serial, parallel, or slot-based execution. A direct implementation owns all corresponding command, lifecycle-signal, monitoring, result, and event responsibilities itself.

### Test-Only Boundaries

UnitTest code shall not be placed inside production/library block implementation folders.

Production/library blocks shall not be changed to contain UnitTest-only logic.

Use framework blocks, local test code, samples, simulation blocks, mocks, or wrapper/access blocks to test production/library behavior without embedding test code in the production/library block.

Framework self-tests belong to the framework test software unit, not to production/library block implementation areas.

## SCL/ST Coding Conventions

### Framework Coding Principles

Unit-test framework code shall prefer traceability and debuggability over maximum abstraction.

Reusable framework mechanics are encouraged when they reduce project-specific boilerplate without hiding the active state, result, tested resource, or event ownership.

Concrete tests shall remain understandable in TIA Portal without requiring a separate generator or PC-side tool to explain the active behavior.

### Unit Test Header Metadata

UnitTest framework blocks and UDTs shall use header metadata consistently, within the metadata supported by their object kind and source format. Do not require FC/FB author/family/UUID header syntax on a UDT or tag table merely because the same fields exist on a block.

Recommended framework defaults:

- `Author`: `Lorenz Software`
- `Family`: `UnitTest` for this project.
- `Title`: same as the block or type name.
- `Comment`: concise short description of responsibility, expected owner, and important usage constraints.
- `Version`: `1.0` for initial framework v1 artifacts. Version changes are explicit project/library development decisions.
- `User-defined ID` / SCL `NAME`: generated UUID created once when the block or type is first created. The UUID remains stable after rename, move, or refactoring.

UnitTest framework source headers shall set `S7_Optimized_Access := 'TRUE'` and `Published := 'FALSE'` explicitly unless software-unit usage requires access from another software unit.

Typical UnitTest framework SCL header:

```scl
FUNCTION_BLOCK "UnitTestRunControl"
TITLE = UnitTestRunControl
{ S7_Optimized_Access := 'TRUE' ; Published := 'FALSE' }
AUTHOR : 'Lorenz Software'
FAMILY : UnitTest
NAME : 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
VERSION : 1.0
//Orchestrates UnitTest test suites and aggregates run status.
```

Concrete project-specific test blocks may use the project or tested-library family instead of `UnitTest` when they are not reusable framework artifacts.

### Run/Suite/Test Execution Order

Framework orchestration blocks shall follow a predictable cyclic order:

1. Read command/status inputs.
2. Handle reset and abort.
3. Update timing information.
4. Execute lifecycle/state-machine logic.
5. Call subordinate suites, test cases, preparations, or assertions.
6. Aggregate subordinate status and result data.
7. Emit one-shot unit-test events where the owner is responsible.
8. Write public status data.
9. Memorize previous-cycle values.

Run Control, Test Suite, and Test Case blocks may specialize this order, but deviations shall be intentional and easy to review.

### State Machines

Run Control, Test Suite, Test Case, and multi-cycle Preparation blocks shall use explicit state-machine logic according to the lifecycle model defined by the relevant contract or framework design.

Use named constants for all states. Do not compare or assign numeric state literals directly.

For framework-owned lifecycle FBs, keep the active state in a local static variable named `State` unless the relevant design explicitly defines another pattern.

When state is externally visible, publish it as a status copy instead of exposing the local state variable as an externally writable value.

Error states should use negative values. Normal unit-test lifecycle states should use non-negative values with gaps, usually in steps of 10 unless a concrete reason requires a different spacing.

Every unit-test state machine shall have an explicit `ELSE` path that handles invalid states. The invalid-state behavior shall follow the relevant lifecycle contract or design.

Every unit-test state machine shall make PLC startup and restart behavior explicit.

Do not allow retained lifecycle state to continue silently after PLC startup unless such behavior is explicitly defined by the relevant contract or design.

Concrete Test Case state machines shall make the execution sequence readable in code. The preferred structure is:

- `Idle`
- preparation-related state or states,
- one or more test states,
- `Completed`,
- reset-related state or states where needed.

Test evaluation logic shall only be placed in test states.

State bodies should stay compact and focus on lifecycle decisions, transitions, and owner-level orchestration. Complex preparation, assertion, event creation, or resource manipulation shall be delegated to the responsible helper block or separated clearly enough to preserve state-machine readability.

Multiple state machines inside one unit-test FB are a design smell. If they appear necessary, check whether the FB mixes responsibilities such as execution, upload, diagnostics, or resource preparation and should be refactored.

### Result And Event Ownership

Result-changing logic shall be placed where the relevant framework contract assigns the responsibility.

Do not duplicate owner-specific event generation in subordinate or surrounding blocks. Follow the owner/event responsibilities defined by the local contracts and design documents.

Use `UnitTestEvent...` APIs for PC-facing event stream data.

Use `UnitTestDiag...` only for PLC-local framework diagnostics.

### Unit Test Text And Event Payloads

Unit-test event text is allowed because PC-side reporting needs readable diagnostics.

Text payloads shall still be bounded and deliberate.

Prefer compact coded fields for machine-readable classification, such as result, owner scope, event type, state, and optional message code.

Use message text for the human-readable explanation that cannot be represented well by compact fields.

Do not build or copy long strings cyclically when a one-shot event or compact status value is sufficient.

Event buffers shall use fixed maximum sizes and shall make overflow/loss behavior explicit.

### Assertions

Assertion blocks shall be coded as pure evaluation helpers.

They shall not modify the tested resource.

They may retain internal state for one-shot finding behavior, edge handling, or first-cycle observation handling.

Assertion implementations shall follow the assertion interface and reset/enable semantics defined by the framework design and Test Case contract.

Assertion state shall be cleared only by the explicit `Reset` input. `Enable = FALSE` disables observation and direct evaluation from observation, but it shall not implicitly clear a latched result, previous value, edge count, or finding-emitted latch. It shall not suppress a separate explicit `Evaluate` request against accumulated observation state.

`Reset` shall have priority over `Enable`, `ObserveFirstCycle`, and assertion-specific evaluation inputs. While `Reset = TRUE`, the assertion shall not observe values, shall not evaluate, and shall not emit assertion-owned events.

The stable result output shall remain valid until the next explicit reset. A failed or error result shall not be downgraded to passed by a later good cycle within the same assertion lifecycle.

Assertion findings shall be emitted once per assertion lifecycle. Use an internal finding-emitted latch when the assertion can be called for multiple cycles after the finding was detected.

Assertion-generated events shall use the owning Test Case state passed through the assertion interface. Do not log an assertion-local state unless a later explicit design decision introduces assertion state machines as a dedicated exception.

Assertion implementations should stay self-contained. Do not extract shared assertion utilities unless an implementation review identifies a concrete consistency or maintainability benefit and the extraction has been aligned.

Assertion failure messages shall be standardized by check class, not by datatype. Similar checks across datatype variants shall use the same wording and differ only in datatype-specific value conversion.

Text values rendered in assertion messages shall be bounded previews. Use the configured assertion-value text length, quote rendered text values, and mark truncated previews with `...`.

Render text from native code units, without converting a complete WString before shortening. The complete quoted preview is limited to 40 output bytes: up to 38 content bytes without shortening, or 35 content bytes plus three dots and two quotes. Inspect at most 39 input code units to determine a scalar preview. Preserve printable ASCII `16#20..16#7E`; replace every other code unit with exactly one output byte `16#D7`. Classify WORD/WCHAR values before narrowing. Preserve quotes and backslashes literally, without escape expansion.

Zero terminates scalar String/WString previews. Zero in selected BYTE/CHAR/WORD/WCHAR array data is rendered as the replacement byte and does not terminate the preview. Invalid or zero-length array preview requests retain the quoted-empty fallback; validate the complete requested range without overflowing before reading its bounded prefix.

Preview construction shall not modify comparison data, native comparison conversions, predicates or lifecycle behavior. Array text bridges shall render diagnostics directly from the original diagnostic window: the existing minimum-length prefix for Contains/Equal/StartsWith and the existing suffix window for EndsWith. Element-oriented CHAR/WCHAR array diagnostics shall use array-element rendering, including replacement of zero. Expected String/WString operands retain scalar rendering.

Allowed common Assertion utilities are limited to aligned bounded text-value rendering and the specifically agreed REAL/LREAL classification, finite tolerance comparison and bounded numeric diagnostic rendering helpers. These numerical helpers are internal implementation support, not project-facing Assertion APIs. Failed/error Assertion finding event helpers remain in the Logging area. Other generic event wrappers, message formatters, result escalation helpers or value-conversion layers still require a specific aligned decision.

#### Floating-Point Assertions

Classify active floating operands and tolerance before ordered comparison or arithmetic. Prefer explicit local error variables and a dedicated Configuration error region for invalid domains, following the configuration-handling recommendation below. Validation remains effective after Failed; held Error suppresses functional comparison and further failed findings. Respect Reset and observation eligibility, including mandatory first enabled baseline observation. Use the typed safe tolerance helper only for finite valid operands. Preserve the family-specific array domains defined by TCC-059 through TCC-065 in `contracts/test-case-contract.md`; do not apply scalar finite-only validity indiscriminately to arrays.

Render numeric diagnostics through the agreed typed formatters only when constructing a new one-shot finding. Default to six significant digits, round to nearest with ties to even, and clamp requested precision to 1..9 for REAL and 1..17 for LREAL. Use compact fixed notation for decimal exponents from -4 through SignificantDigits - 1 and scientific notation otherwise. Preserve explicit NaN, signed infinity and signed zero. Diagnostic rounding never changes comparison values; numeric output is not a quoted text preview.

### Preparation Blocks

Preparation blocks may modify the tested resource only while their owning Test Case is actively executing the preparation phase.

Preparation side effects shall be visible in code. If a preparation changes multiple relevant resource areas, the code shall use regions or concise comments to make those changes reviewable.

Preparation blocks shall report their execution state to the owning Test Case through `UDT_UnitTestPreparationStatus`.

The standard Preparation interface shall use `Enable` as a level-based execution and resource-ownership signal and `Status` as the structured status output.

Reusable Preparation blocks shall not read or write Test Case, Test Suite, Run Control, or PC-facing framework DBs directly. They communicate only through their block interface and the returned Preparation status.

Reusable Preparation blocks shall not emit PC-facing result, aggregation, lifecycle, or framework diagnostic events. Timeout supervision, timeout diagnostics, and conversion of Preparation failure into a Test Case result belong to the owning Test Case or Test Case sequencer.

Preparation blocks shall not perform functional assertion logic. A Preparation establishes the start condition for the following Test Case states; it does not decide whether the tested scenario passed or failed.

`Ready` in a Preparation status means that the Preparation is callable and not actively changing the tested resource. It does not mean that the target condition has already been reached.

`ExecutionStatus = Idle` means that the Preparation is not actively working. Do not derive `Ready = TRUE` from `Idle`; set `Ready` only when the Preparation can actually accept execution.

`Running` means that the Preparation is actively trying to establish the target condition. `Completed` means that the target condition has been reached.

`Ready` and `Completed` may be true at the same time if the target condition is reached and the Preparation no longer actively manipulates the resource. `Running` shall not be true together with `Ready` or `Completed`.

If `Enable = FALSE` while the target condition has not been reached, the Preparation shall stop active resource manipulation and return to `Ready` without reporting `Completed`.

If `Enable = FALSE` after the target condition has been reached, the Preparation may keep reporting `Completed` as long as it does not perform further active preparation work. If maintaining the reached condition requires active writes, that behavior shall be explicit in the block interface or documentation.

Multi-cycle Preparation blocks shall make their internal progress observable through `State`, `ExecutionStatus`, and the status flags. Preparation-specific states may be local to the Preparation implementation; they are diagnostic state values and are not part of the full-owner lifecycle contract.

Reusable Preparation blocks shall keep scenario-specific thresholds, target values, or resource references on the block interface unless the value is a fixed implementation detail of the Preparation itself.

Preparation names shall describe the start condition they establish, not the Test Case that happens to use them.

### One-Shot Behavior

One-shot event and finding behavior shall be implemented with explicit latch or previous-cycle variables.

The variable names shall make the one-shot purpose visible, for example `Completed_old`, `EventWritten`, or `FindingLatched`.

Do not rely on implicit side effects in the event buffer to prevent repeated event creation.

### Generic Versus Concrete Code

Generic framework code shall not make concrete tests unreadable.

Concrete test code may be repetitive when the repetition makes TIA Portal debugging easier and prevents hidden behavior.

If boilerplate becomes excessive, prefer scaffolding or generation that creates readable SCL over runtime indirection that is hard to debug.

## Test Component Style Conventions

### Test Naming

Concrete Test Case names shall describe the tested behavior or scenario, not only the tested block.

Preparation names shall describe the start condition they establish.

Assertion names shall describe the checked relation or condition.

### Test Suite Formatting

Test Suites with repeated Test Case calls shall use consistent call formatting.

Prefer clear repeated calls over generic indirection when this improves TIA Portal debugging.

### Preparation Side Effects

Preparation blocks shall make resource side effects visible through names, interfaces, and regions.

Avoid hiding significant resource manipulation behind generic preparation names.

### Test Case Resource Ownership

Concrete Test Cases that are not pure static read-only checks and write external resources shall make their resource ownership visible in code.

The resource ownership semantics are defined by the Test Case contract under External resource ownership and Reset. The style requirement is that concrete Test Case code makes active resource writes easy to review.

Clearly distinguish Preparation stimulus, test-state stimulus, public Reset requests and observation in the code.

Use separate regions for preparation-related resource writes and test-stimulus resource writes so reviewers can distinguish setup from the actual behavior under test.

Test Suite and Test Case configuration shall make resource-sharing assumptions visible where they affect safe parallel execution.

Pure static-check Test Cases shall keep their read-only nature visible and shall not create side effects.

### Assertion Interfaces

Assertion interfaces shall make checked values explicit.

Within each declaration group, follow the common Assertion input order below. Declaration order is a style convention, not an additional Test Case contract requirement.

The common assertion input order is:

1. `Reset`
2. `Enable`
3. optional observation or evaluation controls such as `ObserveFirstCycle` or `Evaluate`
4. `Name`
5. `ResourceName`
6. `State`
7. checked value inputs such as `IN`
8. expected values, limits, ranges, tolerances, or assertion-specific parameters

Use `State` for the owning Test Case state passed through the assertion interface. Do not introduce an assertion-local state parameter into the standard assertion interface.

Use `Name` for the already composed hierarchical assertion name. The caller owns composition of names such as `<TestCaseName>.<AssertionName>`.

Use `ResourceName` only for optional tested-resource context in emitted events. It shall default to an empty string when the assertion does not need resource context.

Use `Result` as the standard assertion output. A project-specific Assertion UDT is not prohibited by this convention. Do not expose external state or execution-status structures unless a dedicated design decision defines an exception.

When an assertion contains tolerance or boundary semantics, make these semantics visible in the interface names and comments on definition fields.

Use `Limit` for strict comparison thresholds. Use `Minimum` and `Maximum` for inclusive boundary semantics.

Use `Tolerance` for tolerance-based numeric assertions. Unless a more specific assertion explicitly states otherwise, tolerance assertions use absolute tolerance semantics, and negative tolerance values are assertion configuration errors.

Use `ObserveFirstCycle` only for assertions that can validly observe and evaluate without a previous enabled observation. It shall default to `TRUE`. With `ObserveFirstCycle = FALSE`, the first enabled call after Reset or re-enable shall not observe checked values and shall not evaluate them; continuously enabled calls after it are observed normally.

A disabled call makes the next enabled call a new first enabled call without clearing other latched assertion state. Reset while enabled also makes the next non-Reset enabled call a new first enabled call because Reset clears the previous-enable state.

Stateful observation assertions that need a previous value or previous signal sample shall use the first enabled call to establish that baseline and shall not expose `ObserveFirstCycle` when observation without the baseline is invalid.

Use `Evaluate` for stateful assertions that observe over time and evaluate the accumulated observation on a separate owner-controlled condition.

Do not gate or delay an explicit `Evaluate` request through `Enable` or `ObserveFirstCycle`; Reset shall suppress it, and assertion configuration validity still applies. Sequence assertions observe the current input before processing an explicit evaluation request. Edge-count assertions process an explicit evaluation request against the already accumulated edge count without adding a current-cycle edge solely because `Evaluate = TRUE`. Preserve these family-specific semantics unless a separate framework decision changes them.

Array assertions follow the same reset, enable, result, and assertion-owned finding semantics as scalar assertions. Range-based array assertions use `StartIndex` and `Length`; `Length = 0` is an assertion configuration error. Assertions that compare against an expected array use the expected array bounds as the expected segment length unless the concrete assertion explicitly defines a separate range parameter.

`AssertArrayNoValueChange_*` assertions use an external `Memory : ARRAY[*] OF <Type>` reference memory. Follow `test-case-contract.md`, TCC-068 through TCC-071: retain the first successfully captured snapshot until Reset, including across disabled calls before the first comparison. Track validity in a persistent `SnapshotValid : Bool := FALSE`, independently of `Result`; set it only after successful validation and copying, preserve it while disabled, and clear it on Reset. Do not use `Result = UnitTest.Result.NotEvaluated` as proof that no snapshot exists. Capture leaves that result unchanged; comparison starts only after two consecutive enabled non-Reset calls, including after re-enable. Reset does not require clearing physical `Memory`; held Error prevents capture until Reset. The memory array shall provide at least `Length` elements starting at its own lower bound, independently of the actual array bounds.

As a good practice, handle runtime-checkable Assertion configuration errors, such as a negative tolerance or an invalid range definition, before normal signal evaluation in a dedicated `REGION Configuration error`. This separation is a readability recommendation, not a mandatory region or nesting structure; a clear check within signal evaluation is also acceptable. Validation must precede operations that require valid configuration and preserve Reset and observation eligibility. Configuration errors set the assertion result to `UnitTest.Result.Error`, emit an assertion error finding when applicable, update required memorized values before returning, and shall not be reported as functional failed findings.

Assertions that can emit both functional failed findings and assertion error findings within one assertion lifecycle shall use separate one-shot latches. Use `FindingEmitted` for functional failed findings and `ErrorEmitted` for assertion error findings. Reset shall clear both latches. A prior failed finding shall not suppress a later assertion error finding. The separate latches do not permit a functional failed finding after the assertion result has become `UnitTest.Result.Error`; result priority and failed-event suppression remain mandatory.

## Observability And Debuggability

### Unit Test Status Data

Unit-test framework status data shall make the current execution position observable without inspecting internal variables.

At minimum, framework owners that expose status should make lifecycle state, running/completed/error information, and aggregated result information visible through structured status data.

State values exposed to status structures shall be copied from local owner state variables.

### Unit Test Events

PC-facing unit-test events are the primary source for CI-relevant result observation.

Events shall contain enough structured information to identify the owner, result, state, resource, and human-readable message where needed.

Do not rely on PLC-local diagnostics for CI-relevant test result reporting.

### Unit Test Diagnostics

PLC-local unit-test diagnostics shall be limited to framework-support conditions that are not suitable as normal PC-facing result events.

Examples:

- event buffer full,
- event loss detected,
- upload/consumer handover inconsistency,
- invalid internal state,
- unsupported configuration.

Diagnostic data shall not replace result events for normal test pass/fail/error outcomes.

### TIA Portal Debuggability

Concrete Test Suites and Test Cases shall remain understandable in TIA Portal online views.

Prefer explicit state names, status copies, and clear call structure over runtime indirection that requires external tooling to understand the active test path.

Framework abstraction is useful only while it does not hide the owner, active state, resource identity, or result source.

### Debug Verbosity

Debug verbosity levels may be introduced for framework diagnostics if they can be implemented without affecting deterministic result behavior.

Debug verbosity shall not change test results.

Debug verbosity shall not create PC-facing result event spam.

## Generated And Scaffolded Unit Test Code

### Unit Test Scaffolds

UnitTest samples are also the preferred place for scaffold-style starter blocks.

Scaffold blocks may include prepared, commented-out calls that a project developer can activate intentionally after copying the blocks into a project.

Scaffold blocks shall not execute project-specific behavior by default.

Scaffold blocks that are intended to be delivered with the library shall use their intended final names.

Avoid naming conflicts by suffixing or otherwise qualifying local implementation blocks, not by weakening the scaffold/library names.

Do not use placeholder words such as `Template` or `Sample` in a block name if that name is expected to remain in a real project.

### Generated Test Code

Generated UnitTest code shall preserve the distinction between framework code, concrete tests, preparation, assertions, utilities, and exchange data.

Generated concrete Test Case names shall describe the tested behavior or scenario, not only the generation index.

Generated Test Suites shall use clear repeated call structure when that improves TIA Portal debugging.

Generated code shall not hide active Test Case selection behind runtime indirection unless that indirection is explicitly part of the framework design.

### Regeneration Boundaries

If UnitTest code is generated from a repository-internal configuration or other source, the generated part shall be clearly identifiable.

Do not manually edit generated UnitTest code unless it is intentionally converted into maintained manual code.
