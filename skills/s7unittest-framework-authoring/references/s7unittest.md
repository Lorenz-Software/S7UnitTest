# S7 Framework Integration

Use this reference to implement or revise agreed scenarios. Resource paths below are relative to the skill root, not this reference directory. Match framework resources using [framework resources](framework-resources.md) before selecting templates or API entries.

For SCL implementation, changes or technical review, apply the general source-authoring and review resources included in the selected Authoring package. Resolve them through the framework-resource reference above; no second installed skill is required. Retain the UnitTest-specific scenario, Assertion and framework decisions below without creating a competing general coding policy.

## Implement Agreed Scenarios

### 1. Classify The Requested Owner

Classify each requested artifact as one of:

- Run Control
- Test Suite
- Test Case
- Preparation

Generate only the requested owner and directly required supporting structure. Do not expand the task into unrelated framework levels.

Use the consuming project's existing structure and place each owner in its appropriate area and hierarchy. For first-time setup or an ambiguous/missing structure, present a concrete proposal for owner integration, folders and Software Unit placement where relevant, and agree it with the user before creating that structure. Do not require or exclude Software Units, copy this repository's Self-Test layout, or create a parallel hierarchy just because a template is available. Existing explicit project rules or an already agreed structure need no redundant approval.

Resolve the agreed structure's technical symbol/access consequences under the general styleguide, including actual Mastercopy destination placement. Public Authoring API eligibility does not by itself establish technical reachability, and original `Published` metadata is not a blanket restriction on library use. Apply the included general guidance to constant lookup and any needed local implementation constants; retain authoritative framework/contract definitions rather than inventing another Authoring constant policy.

### 2. Select The Execution Pattern

For Run Control and Test Suite owners, select one pattern:

- `serial`: ordered execution or shared/exclusive resources
- `parallel`: all children are explicitly independent
- `parallel-slots`: children are assigned to explicit concurrent slots

Do not infer parallel safety. Ask which pattern to use when ordering, concurrency, or resource ownership is unclear.

For `parallel-slots`, verify that every child has exactly one valid slot assignment, slot bounds are continuous and supported by the selected Orchestrator, and children sharing an exclusive resource cannot execute in the same slot. Record the ordering, independence, slot, and ownership facts that justify the selected pattern.

Do not select an execution pattern from EventBuffer size or expected event volume. The existing framework Orchestrators enforce their capacity constraints internally while preserving their serial, parallel, or slot-based execution meaning. Do not invent an `adaptive` Orchestrator or template.

For Test Cases, select one pattern:

- `static`: direct implementation for an immediate static check or deliberately custom lifecycle
- `single-state`: one test state coordinated by `UnitTestCaseSequencer`
- `single-state-preparation`: one test state with a Preparation block
- `multi-state`: sequential test states coordinated by `UnitTestCaseSequencer_MultiTestState`
- `multi-state-preparation`: sequential test states with a Preparation block

Prefer a Sequencer-based Test Case unless the supplied intent explicitly calls for a static check or custom lifecycle. Create a Preparation block only when the resource must be brought to a defined target condition before testing.

#### Choose Test-State Granularity

Choose the representation from the accepted behavioral questions, actual DUT call/observation order, required isolation and failure attribution, and evidenced execution/storage constraints. Explain the consequential choice briefly in the test plan or implementation rationale. Compare plausible alternatives when they lead to different observation or diagnostic semantics; no fixed worksheet is required. Do not select a pattern merely to reuse four Assertions, shorten generated source, avoid declarations, or reproduce a reference project's layout.

Separate execution structure from call/data representation. An array of independent instances is not sequential reuse of one instance, and a loop over it does not imply progression across PLC cycles. Choose both dimensions deliberately; neither array form nor individually written calls has a universal priority.

| Execution structure | Prefer when | Check before selecting |
| --- | --- | --- |
| Immediate checks in one test state | Use a single test state for a coherent check that needs no separate multi-invocation phase sequence. | Preserve each observation and the actual DUT call-ownership constraints; calls may be written individually or grouped over distinct instances. A small stateless calculation does not by itself require one example per PLC cycle. |
| Framework multi-test-state Sequencer | Prefer the multi-test-state Sequencer when a scenario has successive stimulus/observation phases spanning invocations. Also use meaningful states where logged step context is needed. | Let the framework own phase progression, state context and supervision. Choose meaningful phases, such as fill, reject an extra write and drain, not one state per cycle, operation or data row. State identifies a finding but does not create independent Assertion results or clear latched failure. |
| Separate Test Case instances | Questions require independent baselines, execution/result identities, ownership or incompatible observation histories | Group related properties without multiplexing independent scenarios or duplicating equivalent datatype/value matrices. |
| Bounded data iteration across invocations | A concrete workload, call-order or resource constraint justifies distributing homogeneous samples across cycles | Account for retained progress, Reset/Abort, finite completion and diagnostic limitations; compare direct checks and framework states rather than treating a row counter as free infrastructure. |

An internal phase controller inside one test state remains a justified exception, not the default representation of a fixed trace. Explain why framework test states would obscure or fail to express that scenario. Choosing one DUT call per invocation does not imply choosing a private phase controller.

| Call/data representation | Useful when | Check before selecting |
| --- | --- | --- |
| Individually declared instances and explicit calls | Bindings or observations differ, or explicit names/call sites make intent clearest | Accept useful repetition; avoid scattering each stimulus and expectation across unrelated sections. |
| Arrays of distinct Assertion instances with aligned data and bounded loop calls | Repeated checks of the same feature have homogeneous typed bindings and remain easier to understand together | Each element owns independent observation/result/finding state and a stable meaningful identity. Map input, Expected, actual output and result to the correct element. Call every owned element once per invocation, using its own activation inputs. No wait between different elements or cross-cycle row counter is implied. |
| One instance reused for several observations | Continuous observation or a justified reuse arrangement matches the selected family's semantics | Apply the ownership criteria in step 5; this is not interchangeable with arrays of independent instances. |

Array/loop grouping can compact declarations, bindings and calls, but does not itself reduce instance count, cyclic calls or reservation demand. If actual DUT calls share output storage, observe or copy that output before it is overwritten; independently stored outputs require no such extra copy. Do not introduce a generic test-data framework or per-row helper solely to enable this representation. Qualify the actual typed array declaration/binding using the included general guidance before claiming native support for a new representation.

An array of independent Assertion instances is not an array Assertion family such as `AssertEqualArray_*`. The former organizes calls/state; the latter defines a checked array property. Select them independently from the actual observation intent.

Data iteration is not in itself a second sequencer. A bounded index may select successive records or input vectors within one framework phase, provided it does not also select different behavioral phases. Its admissibility alone is not a reason to prefer it; apply the Assertion ownership/diagnostic criteria in step 5 as well as the execution criteria above. A data table does not automatically provide separately reported, isolated parameterized tests. Keep phase completion finite and independent of the expected response or Passed. Evaluate the phase's required observations before advancing, preserve earlier results, and do not complete the final phase before its checks have evaluated. This is a semantic review, not a ban on counters, CASE statements or single-state templates.

Before defining a Test Case interface, classify it as `generally-reusable`, `resource-family`, or `dedicated`. Keep one stable behavior-oriented scenario per Test Case. Select whether the tested FB or FC is instantiated and called inside the Test Case or externally in the PLC program. Prefer external calls when the same behavior can be tested across different block types through explicit stimulus and feedback interfaces.

For a Preparation, select one reuse model before defining its interface:

- `generally-reusable`: no dependency on a concrete resource family
- `resource-family`: one stable typed resource interface used by multiple resource instances or Test Cases
- `dedicated`: intentional binding to one resource instance, Test Case, or scenario because further abstraction would not provide meaningful reuse

Choose the narrowest useful reuse scope that retains a clear interface and real binding benefit. A dedicated Preparation is appropriate when abstraction would not provide useful reuse. Do not turn one Preparation into a mode-selected collection of unrelated target conditions.

#### Derive Timeout Configuration Bottom-Up

- Inventory the children and stateful resources actually invoked on normal, Reset, and Abort paths before assigning Test Case, Test Suite, or Run Control timeout values.
- Use available owned implementation code to estimate deterministic cycle paths. For externally owned resources, use supplied source and dependency-analysis evidence. Treat configured or test-intent timing bounds as authoritative where code alone cannot bound dynamic behavior.
- Derive a serial parent path from the sum of relevant child paths and a parallel parent path from the longest child path. For parallel-slots, take the longest child path in each parallel slot and sum those slot bounds because the slots execute sequentially. Add lifecycle, dispatch, and PLC-cycle overhead.
- Derive Reset and Abort timeouts from their actual dispatch and nested-baseline paths rather than from normal execution assumptions. Include capacity-related waiting where the selected Orchestrator can defer subordinate Reset dispatch.
- Keep every timeout positive and large enough that a parent cannot preempt a valid child path or suppress the child's own timeout handling.
- When source, dependency evidence, configured bounds, PLC-cycle bounds, or supplied test intent are insufficient, ask the user for the missing maximum duration or timeout. Do not invent a value or silently retain a template example.
- Keep given integration conditions, conditions established by the test, and unresolved assumptions distinct. Derive consequential capacity, service and overhead bounds from the actual supported arrangement; a conservative label does not justify an arbitrary free-space threshold, wait or margin. Leave unsupported bounds explicitly unqualified in a source-only draft rather than promote them to mandatory consumer requirements. Rely on the selected Orchestrator's capacity/reservation behavior instead of adding a competing project-side gate without an evidenced need.

### 3. Select The Template

Map the chosen pattern to one template:

| Owner | Pattern | Template |
|---|---|---|
| Run Control | serial | `assets/templates/run-control-serial.scl` |
| Run Control | parallel | `assets/templates/run-control-parallel.scl` |
| Run Control | parallel-slots | `assets/templates/run-control-parallel-slots.scl` |
| Test Suite | serial | `assets/templates/test-suite-serial.scl` |
| Test Suite | parallel | `assets/templates/test-suite-parallel.scl` |
| Test Suite | parallel-slots | `assets/templates/test-suite-parallel-slots.scl` |
| Test Case | static | `assets/templates/test-case-static.scl` |
| Test Case | single-state | `assets/templates/test-case-single-state.scl` |
| Test Case | single-state-preparation | `assets/templates/test-case-single-state-preparation.scl` |
| Test Case | multi-state | `assets/templates/test-case-multi-state.scl` |
| Test Case | multi-state-preparation | `assets/templates/test-case-multi-state-preparation.scl` |
| Preparation | target-state preparation | `assets/templates/preparation.scl` |

### 4. Derive Names

Follow the consuming project's agreed block-naming convention. Where no project convention applies, these are good-practice examples, not mandatory forms:

- `UnitTestRunControl`
- `UnitTestSuite_<Subject>`
- `UnitTestCase_<Scenario>`
- `Preparation_<TargetCondition>`

Choose block identifiers separately from textual runtime owner and logging names; they need not be identical. Do not rename existing artifacts merely to adopt an example.

Build runtime owner names as hierarchical names defined by the framework contract. End assertion event names with `Assert<CheckedDetail>`. Keep the checked detail concise and meaningful; do not duplicate the Test Case hierarchy in a local variable name.

Calculate the assembled event-name length from the actual parent names, separators and local suffix before generating calls. Owner-name validation does not prove that appended Assertion names fit. Use the matching contract's `UnitTest.TextLength.Name` and check `ResourceName` separately; for variable bindings, establish the supported name budget. Shorten meaningful segments deliberately, never truncate the final name or merge identities. See the packaged Assertion Authoring guide for the complete-name budget and instance-selection guidance.

Framework-owned Orchestrator diagnostics use the parent name plus `.Orchestrator`. Do not generate a competing project-specific Orchestrator identity.

### 5. Resolve The Required Blocks

- Resolve every called block and interface from `references/block-catalog.yaml`.
- Resolve each Assertion from `references/assertion-catalog.yaml` based on the checked condition and actual data type.
- Prefer a direct matching Assertion over adapting values solely to fit a different Assertion.
- Assess semantic fit and resulting failure information together before selecting the Assertion and instance arrangement. Read the matching family's supported Failed/Error text and combine it with the configured stable name and ResourceName/State context: a reader in the PC client should locate the check, understand the expectation and see the relevant actual deviation. Prefer typed direct checks over precomputed Boolean verdicts that discard those values; retain genuine Boolean/coherent composite checks where appropriate. Preserve accepted comparison semantics and account for rounding/truncation and finding-latch limits. State diagnostic gaps without inventing log formats, contract fields or client behavior. Follow the packaged Assertion Authoring guide's failure-information review; no per-Assertion injected fault or fixed worksheet is required.
- Select only Assertions required by the supplied acceptance criteria.
- Use the included source-authoring and review guidance to choose and verify source representations for the accepted stimulus and Expected values before writing calls. Preserve every required distinction, including finite precision boundaries, and the agreed exact/tolerant relationship; do not relax a check to accommodate a changed fixture. A host-side conversion or rounded diagnostic does not establish target identity. Keep genuinely missing target evidence explicit in a source-only handoff, not in a new runtime release DB or startup gate merely recording review progress.
- Prefer direct actual/expected comparisons when checking values. If a composite condition expresses a coherent domain property, prefer assigning it to a clearly named Boolean signal before the Assertion. The name must describe the information conveyed, not merely label the expression as valid. Split overloaded conditions into meaningful signals and, where needed, separate Assertions; naming must not conceal several independent expectations. Keep failure attribution and relevant actual values useful. Neither Assertion minimization nor one Assertion per variable is a goal.
- Distinguish reuse of an Assertion implementation/type from reuse of one mutable instance. For independently meaningful check sites within one test state, prefer distinct instances with stable property identities, represented by explicit declarations/calls or arrays of independent instances with aligned data and bounded loop calls as justified by readability. Repeated cyclic observation of the same property is the normal use of one instance, not a collection of independent checks. Across meaningful framework test states, one instance may continue checking the same property with its stable name and the logged State identifying the observation step, if its family semantics and required result granularity permit it. Do not switch to multi-state merely to justify sharing an instance.
- Resolve immediate versus collection/history behavior, latched Failed/Error, Enable transitions, first-cycle/baseline handling and explicit Evaluate before reusing an instance. State changes and changing Name/Expected/IN do not reset it or guarantee new findings after failure. If every check needs its own result or finding even after another check fails, use separate instances or separate Case executions; states alone do not provide that independence. Call each Assertion instance once per Test Case invocation and reset it only in the enclosing Reset, not between rows or states. Concurrent Cases never share mutable Assertion state.
- Reusing one instance for different independent samples within the same state is an exception, not the default data-driven pattern. It needs a concrete benefit, intentionally sufficient first-failure/aggregate semantics and unambiguous attribution through existing diagnostic context. Do not compensate for a missing framework step identity by changing Assertion names per row or inventing log-text protocols. Private snapshots do not replace required normal failure attribution. Weigh distinct-instance storage, cyclic calls and reservations against these obligations; neither minimum instance count nor one instance per variable/data row is a goal. Follow the packaged Assertion Authoring guide for the complete ownership criteria.
- Keep project-specific behavior in the owner block; keep generic lifecycle and orchestration behavior in the selected Sequencer or Orchestrator.

`ConfigureUnitTests` and `ExecuteUnitTests` are optional, project-adapted integration examples, not ready-to-call framework helpers. Their separate `integrationExamples` classification records provenance, not a mandatory API or naming scheme. Establish where the consuming application configures the hierarchy, initializes the EventBuffer and startup Reset, and cyclically calls the concrete Run Control. If reusing those examples, inspect and adapt their actual configuration and concrete instance binding; a declared interface alone does not establish an executable integration. Alternatively implement the same responsibilities directly in the application entry or another project-owned adapter. Resolve actual cycle-time/startup bindings and existing storage/folders from project context without inventing them. This is authoring context, not an engineering access procedure.

### 6. Instantiate The Template

- Replace every `{{...}}` marker with concrete project data or generated SCL.
- Standalone declaration and statement markers accept SCL directly; they are not comment-prefixed. Use an empty replacement where the slot is optional, or supply an explicit SCL comment when only an explanation is needed. Description markers remain comments. Do not require a dummy first line to prevent a declaration or statement from being commented out.
- Remove optional declaration sections that remain empty and would make the SCL invalid.
- Apply the included source-authoring and review method and authoritative general/project rules to declaration contexts, representations and effective attributes. Preserve required template attributes and qualified container/defining-member settings rather than stripping them to fit a datatype. Missing qualification remains unresolved; do not weaken a scaffold or change test meaning to make an import pass.
- Use the included general guidance for supported constant/declaration/statement rendering. Keep the UnitTest distinction between invariant scenario facts and variable bindings, and preserve framework-derived state relationships without assuming their arithmetic is valid in every source context.
- Prefer descriptive named constants, configuration values, or parameters when a number carries framework, scenario, timing, sizing, or domain meaning. Numeric literals remain acceptable when their meaning is self-evident or they express a direct framework-defined relationship.
- Generate a fresh UUID for each newly generated exported block header that requires one.
- Preserve the template's execution order, regions, lifecycle-signal flow, result handling, status update, finalization, command cleanup, and previous-cycle memorization.
- Configure the selected Sequencer or Orchestrator before its call.
- Call project-specific children after the generic Sequencer or Orchestrator has produced their command signals.
- Consolidate results and status after subordinate calls.
- Do not locally reproduce command propagation, lifecycle events, monitoring, or state-machine behavior already owned by a selected framework block.

### 7. Implement Owner-Specific Logic

For a Run Control:

- Configure Test Suites and their execution pattern.
- Use the selected Run Control Sequencer and Test Suite Orchestrator.
- Pass public command storage directly to the Run Control Sequencer's `CmdData` in-out parameter and leave command consumption/acknowledgement to it. Do not add enclosing writes that clear Start, Abort or Reset before the Sequencer accepts them.
- Retain the Suite Orchestrator state and technical result in initialized persistent fields (`UnitTest.State.Uninitialized` and `UnitTest.Result.NotEvaluated`). Pass both through `OrchestratorState` and `OrchestratorResult` to the Sequencer before the later Orchestrator call refreshes those same fields. Do not use temporary handover fields, separate shadow values or a reordered call sequence. Keep `LifecycleSignals.Completed` as the raw child snapshot; the Sequencer separately requires helper `Completed` for regular completion. Reset, Abort, error and timeout exits retain their own completion conditions.
- Aggregate functional child Failed at the Run Control, not in the Orchestrator's technical result. On first entry to Completing, compose and publish the final owner result before final events; retain it through later Completing and Completed calls until Reset, with CompletionDelay unchanged.
- Map lifecycle signals, combined configuration error, result, status, finalization events, and command cleanup according to the template.

For a Test Suite:

- Configure Test Cases and their execution pattern.
- Use the Test Suite Sequencer and selected Test Case Orchestrator.
- Retain initialized Orchestrator state/result in persistent fields and pass the paired previous-call values to the Sequencer before refreshing them from the later Orchestrator call. Keep raw child lifecycle signals independent of helper completion. Regular completion requires completed children and helper Completed; Reset, Abort, error and timeout exits remain separate. Aggregate functional child Failed at the Suite and retain its result after first final publication through Completing/Completed until Reset, as shown in the template.
- Keep Test Case calls and project-specific configuration in the Test Suite owner.
- Rely on the selected framework Test Case Orchestrator for global EventBuffer reservation, capacity-gated Start dispatch, reservation release, and capacity-aware Reset dispatch. Do not add competing reservation logic around it.
- When a deliberately direct Test Suite implementation omits the generic Orchestrator, implement the equivalent normal-execution global reservation and capacity-gating behavior and the equivalent capacity-aware Reset behavior required by the Test Suite contract.

For a Test Case:

- Own stimulus, Preparation calls, Assertion calls, assertion aggregation, and the final Test Case result.
- Rely on the owning orchestration to ensure that only one Test Case controls a shared external resource at a time. Do not add peer coordination, locks or ownership registries inside Test Cases for that responsibility. Drive functional stimulus only during active Preparation/test execution, stop inactive influence before sequential reuse, and distinguish public Reset requests from functional stimulus under the Test Case contract's External resource ownership and Reset rules.
- Reset Assertions only in `UnitTest.State.Reset` and enable them only in the states defined by the test intent.
- Use `ObserveFirstCycle` only when the selected cataloged Assertion exposes it. Set it to `FALSE` when the first enabled call may precede processing by an externally called test object; otherwise retain the cataloged default unless the test intent requires a different observation boundary.
- Do not add `ObserveFirstCycle` to Assertions that require their first enabled call as a mandatory previous-value or signal baseline.
- Do not gate an explicit `Evaluate` request through `Enable` or `ObserveFirstCycle`. Preserve the cataloged family semantics: Sequence Assertions include the current input before explicit evaluation, while Edge-count Assertions evaluate only their previously accumulated count.
- Keep one stable behavior-oriented scenario; do not add mode or flow-selection parameters that combine unrelated scenarios.
- Put resource-instance values, variable stimulus, expectations, limits, tolerances, and timing on the interface. Keep invariant scenario facts as constants.
- Add `TestTime` as an input only when it varies by instance or tested-block configuration; otherwise use a scenario constant or another explicit finish condition.
- Prefer direct typed parameters, then existing production Control/resource UDTs, then an existing resource-ID getter/setter pattern. Use a UnitTest-specific interface UDT only as a justified coherent grouping exception.
- Do not modify production DUT, Control, or resource UDTs for UnitTest needs.
- Use inputs for read-only scenario data and in-out parameters for writable stimulus or resource data.
- Do not bind concrete global resources in generally reusable or resource-family Test Cases. Permit deliberate direct project binding only in a dedicated Test Case.
- Reuse an existing Preparation implementation before creating a new one. Each stateful Test Case instance still owns its own Preparation FB instance.
- Select framework Assertions first. Create a project- or TestCase-specific Assertion only when no existing Assertion or readable composition expresses the required check without complex inline Test Case logic.
- Give each stateful Test Case use separate instance state, ControlData, and hierarchical identity.
- Publish `PreparationStateCount`, `TestStateCount`, and `AssertionCountTotal` cyclically through `UpdateTestCaseStatusView`. Count the longest finite executable lifecycle path, use `PreparationStateCount := 0` when no Preparation state exists, require `TestStateCount > 0`, and keep all three values stable from `Idle AND Ready` through `Completed`.
- For `UnitTestCaseSequencer_MultiTestState`, use consecutive test states starting at `UnitTest.State.Running`. Keep direct offsets visible in supported executable expressions; the naming exception does not permit arithmetic CASE labels or computed declaration initializers. Select dispatch syntax through the general styleguide, without a redundant phase variable or duplicated framework state numbers. Apply the same distinction to Preparation-state offsets where the selected implementation defines them.
- Call every Test Case-owned stateful FB instance exactly once on every Test Case invocation. Keep one central call site outside lifecycle, scenario, Assertion, and prior-output conditions. Before the call, assign neutral owned command inputs and then apply only the stimulus required in the current cycle; capture outputs after the call. Fixed loops are allowed when they call a fixed owned instance set unconditionally. This normal rule does not apply to stateless FCs or DUTs called by an external owner.
- Treat omitted DUT calls, call sites distributed across branches, actual multiple execution of the same DUT instance in one invocation, and direct manipulation of private DUT instance data as distinct, exceptional testability arrangements, not normal implementation patterns. Use one only for a concrete narrowly bounded scenario whose purpose, intervention, expected observation, ownership and applicability have been explicitly examined and accepted. Approval is specific to that arrangement; it is not a general waiver. Continue the unaffected Test Case lifecycle and monitoring normally and do not treat outputs from an omitted call as a fresh DUT reaction.
- Reset every stateful local DUT, fixture, scenario controller, event capture, command history, and memorized test value when the enclosing Test Case enters `UnitTest.State.Reset`. Establish one deterministic fixture base state independently of whether the preceding run completed, aborted, failed, or ended with an error.
- Reset an owned stateful FB with valid reset configuration through its public interface, using its actual edge or level semantics, and monitor its defined reset baseline. For a DUT whose agreed target is Idle, do not additionally require DUT Ready to be TRUE. Framework Full Owner Idle/Ready and Test Case startability requirements remain unchanged. Derive Test Case readiness from the required fixture baseline rather than from the enclosing state or an elapsed cycle.
- Reset previous-cycle memories to values consistent with the first post-reset observation. Preserve template ordering so current-cycle evaluation and event emission occur before values are memorized and command bits are cleared.
- Release shared, reserved, or producer-owned state through its owner protocol or a Preparation. Do not overwrite state the Test Case does not own merely to make the fixture appear reset.
- Do not make expected values depend on stale state from a preceding run. When a scenario intentionally uses invalid configuration or another non-resettable test condition, first reset the fixture with a valid setup and introduce the tested invalid condition only after the fixture reset is complete.
- Give independent stateful scenarios separate Test Cases when they have independent purposes, baselines, stimulus sequences, expected results, or pass/fail identities, or when combining them would require a mid-Test-Case reset or mode-selected flow. Keep a genuine multi-cycle behavior, multiple Assertions of one stimulus sequence, and jointly tested interacting instances in one Test Case. Do not multiplex unrelated scenarios with a numeric scenario-step controller.

For a Preparation:

- Use `Enable : Bool` and `Status : UDT_UnitTestPreparationStatus` as the framework interface. Do not add framework names, Control data, Result, separate ConfigError, or event handling.
- Pass variable targets and read-only resource values as inputs. Pass writable stimulus and resource data as in-out parameters by default.
- Do not modify DUT or resource UDTs for UnitTest needs. Introduce a Preparation interface UDT only when it groups coherent signals and remains reusable at the selected scope.
- Drive the resource toward the requested target condition only while enabled and active. Perform no resource writes while disabled.
- Handle every resource state expected during normal operation and converge to the target condition without depending on a previous run. Reserve Error for exceptional states that cannot be handled meaningfully.
- Publish `Ready`, `Completed`, and `Error` as current resource-condition projections even while disabled; keep `Running` false while disabled.
- Treat `Completed` as the currently reached target condition, not as a latched result from an earlier invocation. This permits the Test Case Sequencer to skip unnecessary active preparation.
- Publish `Running` only while enabled and actively driving the resource.
- Do not own the DUT call, Test Case timeout monitoring, Assertions, events, or final Test Case result.
- Do not hard-code a parent-specific hierarchy into a Preparation block. Generally reusable and resource-family Preparations must not bind concrete global resource instances directly.

### 8. Refactor An Existing Test Case

When revising a dedicated Test Case for reuse:

1. Capture its current scenario semantics before changing declarations: test-state sequence, stimulus behavior, Preparation, Assertion activation and evaluation, result aggregation, finalization events, and relevant cycle behavior.
2. Inventory concrete global bindings, instance-specific values, tested-block dependencies, and invariant scenario facts.
3. Select `generally-reusable`, `resource-family`, or `dedicated` as the target. Do not generalize when the result would require mode, flow, Assertion-selection, or test-type parameters.
4. Extract only variable bindings and scenario parameters to direct parameters, existing production UDTs, or an existing resource-ID accessor. Do not modify production UDTs.
5. Preserve internal or external tested-block call ownership unless the user explicitly decides to change it. Treat a call-ownership change as a behavior decision because it can alter call order and cycle delay.
6. Preserve lifecycle states, command handling, Preparation behavior, Assertion semantics, result priority, status publication, and final events. Prefer the existing framework Sequencer and helpers over recreating equivalent logic.
7. Give every refactored use separate Test Case, Sequencer, Preparation, Assertion, ControlData, and hierarchical identity state.
8. Validate the original binding and at least one additional binding. Report the extracted dependencies, retained constants, selected reuse class, and any intentional semantic change.

Do not invent additional test intent while refactoring. If reuse requires changing stimuli, expected behavior, acceptance criteria, lifecycle flow, or call ownership without an explicit decision, stop and request that decision.

### 9. Refactor An Existing Preparation

When revising a dedicated Preparation for reuse:

1. Capture its target condition, supported normal starting states, exceptional error conditions, active stimulus, internal progress, and `Ready`, `Running`, `Completed`, and `Error` behavior before changing declarations.
2. Inventory concrete global resource bindings, instance-specific targets, limits, timing values, and invariant target-condition details.
3. Select `generally-reusable`, `resource-family`, or `dedicated` as the target. Do not generalize when the result would require target-condition modes or combine unrelated target states.
4. Extract only variable resource and target-condition dependencies to direct parameters, existing production UDTs, or an existing resource-ID accessor. Do not modify production UDTs.
5. Preserve level-based `Enable`, disabled-state status projection, writes only during delegated active ownership, normal-state convergence, and exceptional Error meaning.
6. Keep DUT instantiation and calls outside the Preparation. Do not introduce names, ControlData, Result, events, or Test Case timeout handling.
7. Give every concurrent use a separate Preparation FB instance and separate progress state.
8. Validate the original binding and at least one additional resource binding. Report extracted dependencies, retained constants, selected reuse class, and any intentional semantic change.

Do not invent a new target condition while refactoring. If reuse requires changing target semantics, normal-state coverage, Error meaning, disabled behavior, or resource ownership, stop and request that decision.

## Validate The Generated Result

Before presenting generated SCL, review it against the actual stated/agreed scenario using the intent-first review in the matching AI-assisted authoring guide resolved through `references/framework-resources.md`. Distinguish normal operation, deliberate fault stimulation and protected invariants before interpreting individual operations. Report confirmed contradictions separately from missing evidence and optional improvements; do not reopen clear intent or weaken framework/ownership constraints. Then apply the relevant rules from `references/validation-checklist.yaml` and verify all of the following:

- The selected pattern matches explicit ordering and resource-ownership constraints.
- Execution structure follows the behavior, call/observation boundaries, isolation, diagnostic needs and evidenced costs. Explicit calls or distinct-instance arrays are selected separately for readable bindings; do not confuse instance arrays with single-instance reuse or array-valued Assertion families. Successive multi-invocation stimulus/observation phases normally use framework test states; an internal phase controller or cross-cycle data iteration has a concrete justification. Direct checks and bounded data iteration remain available where they are clearer and preserve the required semantics; do not force one state per data row.
- EventBuffer size did not influence Orchestrator selection and no nonexistent Adaptive variant was introduced.
- Every referenced framework block exists in the catalogs and no `internalBlocks` entry is used directly.
- Every call matches the cataloged interface and uses no invented parameter.
- Every template marker has been resolved.
- Complete the included declaration/property review against the matching styleguides and verify that required UnitTest scaffold properties were preserved. Keep native qualification limits explicit; no second matrix or assertion of effective properties from source equality/compilation alone.
- New exported blocks have unique UUIDs where required.
- Fully assembled owner and Assertion event names, including actual parent prefixes and separators, fit the matching contract limits and remain distinct; ResourceName fits its separate limit. Owner validation alone is not sufficient evidence for Assertion suffixes.
- Configuration errors are combined before they influence readiness or state-machine execution.
- Lifecycle signals are prepared before the Sequencer or Orchestrator call. For composed Run Control/Suite owners, raw child completion is not gated on the helper's own completion; paired initialized persistent helper state/result feed the Sequencer before being refreshed by the Orchestrator.
- Project-specific subordinate calls occur after generic command generation.
- Results and status are consolidated after subordinate calls. Run Control/Suite regular completion waits for children and helper Completed; functional child Failed is aggregated by the owner, and the published owner result remains held through Completing/Completed until Reset.
- Finalization events and command cleanup remain in the template-defined order.
- Assertions reset, observe, explicitly evaluate where applicable, and aggregate exactly as required by the supplied test intent; first-cycle observation follows the selected Assertion interface and external call order. Independent check sites within one state normally have separate instances; continuous observation and meaningful multi-state reuse preserve stable identities and compatible history. Any same-state sample reuse has an explicit benefit and sufficient first-failure/attribution semantics. State context does not promise further findings after a latched failure; resource savings do not justify lost required results.
- Checked information is explicit: composite signals have meaningful domain names and manageable content, independent expectations are not hidden in an opaque predicate, and failures remain attributable. Review a plausible resulting PC-side finding using the supported message and configured name/resource/state context: location, expectation and relevant actual deviation remain understandable, with rendering/latching limits explicit. Do not equate a readable verdict with a proven root cause or count Boolean operators/Assertions as a quality measure.
- Test Case lifecycle metadata describes the longest finite executable path and is valid and stable over the required lifecycle interval.
- A selected framework Test Case Orchestrator owns EventBuffer reservation behavior without project-side duplication; a direct Test Suite implementation provides the contractually equivalent capacity behavior.
- Stateful Test Case fixtures reach the same defined base state after reset from completed, active, aborted, failed, and error paths where those paths are applicable.
- A generated stateful Test Case can execute at least twice consecutively without PLC restart and without inheriting scenario, DUT, event-capture, command-history, assertion, result, or memorized-value state from the preceding run.
- Every Test Case-owned stateful FB is called exactly once per Test Case invocation outside conditional execution, after neutral input defaults and current-cycle stimulus preparation.
- Test Case readiness waits for the actual nested fixture baseline, and shared state is released through its owner rather than overwritten by a non-owner fixture.
- Independent stateful scenarios are separate Test Cases unless their interaction or temporal sequence is the approved behavior under test.
- Complete the included numeric/type/source review, then reconcile the declarations and executable use with the agreed stimulus and Expected meanings. Keep direct framework state relationships visible in supported contexts. Resolve material representation discrepancies before claiming a runnable handoff; distinguish source/native evidence without another lifecycle gate.
- Timeout values are positive, derived bottom-up from the actual child paths and selected execution pattern, and supported by source, dependency evidence, configured bounds, or explicit user input.
- Serial, Parallel, or ParallelSlots selection is justified by explicit ordering, independence, slot, and resource-ownership facts, and every slot assignment is valid.
- No project-specific block duplicates generic lifecycle events, monitoring, orchestration, or sequencing behavior.
- Preparation reuse scope, interfaces, normal-state coverage, disabled behavior, and resource writes satisfy the Preparation validation rules.
- Refactored Test Cases preserve their recorded scenario and lifecycle semantics and expose only variable dependencies.
- Refactored Preparations preserve their recorded target-condition, Enable/status, resource-ownership, and Error semantics and expose only variable dependencies.
- No DUT implementation, acceptance criterion or mandatory integration prerequisite was invented or changed. Consequential bounds have a traceable basis; given conditions, test-established conditions and unresolved assumptions remain distinguishable in the code and handoff, not only in the analysis.

Report the chosen owner pattern, selected template, and any explicit assumptions together with the generated result. Surface unresolved authoring decisions instead of silently choosing behavior.
