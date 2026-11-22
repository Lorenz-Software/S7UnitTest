# Understand And Author S7 SCL

Use the selected [rule sources](rule-sources.md). Apply requirements while constructing the artifact, not only after a failed import. The steps below concern engineering reasoning; actual project operations remain subject to its workflow and authorization.

## Establish Behavior And Change Boundaries

Inspect the target declarations/body, relevant callers, dependencies and configuration. Identify the public inputs/results, actual storage owners, retained/inter-call state, shared writes, call multiplicity/order and error/reset paths that matter to the requested behavior. An FC can access persistent global/caller storage; an FB can still provide a stateless calculation. Derive effects from code and bindings, not block kind alone.

Use accepted requirements to distinguish intended behavior from implementation observations. For a change, identify what must remain unchanged: interfaces, identity/version metadata, attributes, namespace, data ownership, numerical relationships and unaffected control paths. Trace affected consumers and types before changing a shared definition. Do not silently turn a code-cleanup task into an interface or attribute migration.

Resolve the actual consuming-project placement and dependencies using the guide's [Software Unit, namespace and library-copy contexts](s7-styleguide.md#software-units-namespaces-and-library-copies). Apply it to the destination copies, not merely the original library header. Determine whether each call is local, cross-unit or mixed, and whether the required namespace, publication and relation facts are established. Do not infer technical visibility from public API eligibility or require Software Unit access settings in a project without those units.

Ask about a missing domain fact only when it materially changes the implementation or its effects. If ranges or reset/restart behavior are unspecified, determine what existing declarations/contracts establish before asking; do not invent narrower inputs to justify otherwise unsafe code. Keep independent work moving without creating a fixed series of approval gates.

## Qualify Uncertain Constructs Before Replication

Before introducing unfamiliar syntax, instruction bindings or a native import representation, inspect a matching compiler-checked example or the applicable Siemens documentation for the selected CPU/TIA version. Read the actual declaration sections, type definitions and formal signatures involved. An example is evidence only for the context in which it was checked; establish whether its relevant target, access mode, datatype and import-route conditions match. Do not infer acceptance from another language or transfer a representation between declaration contexts without evidence.

When a consequential language, binding or import uncertainty remains, use this bounded procedure before repeating the pattern across sources:

1. State the exact unresolved claim and what would establish it: accepted syntax/type binding, preserved imported structure/value, effective property or executable behavior. Do not replace the claim with the weaker question of whether an import reports success.
2. Select the smallest useful dependent combination. For example, include a structured type, the FB interface/body that uses it and a caller with the actual binding; checking the UDT or unused declaration alone does not establish that the combination works. Include an instruction's actual instance/formal type where that is the uncertainty, not only a look-alike user declaration.
3. Use the approved native path and an ignored isolated project when isolation is needed. Do not add probes to production/library sources or another owner's project. If native qualification is outside the current authority, report the unresolved claim and proposed bounded check; do not connect or present a source-only draft as qualified.
4. Inspect all participating probe objects explicitly, including any object not reached by the normal call path. Apply the project's compilation/diagnostic procedure to that combination and read back the relevant identities, declaration/body structure, values and effective properties. If the tool cannot establish coverage or the required readback, retain that concrete gap instead of assuming the unused object was checked.
5. Compare the native result with the intended combination. Keep language/type acceptance, import/storage/property preservation and behavior as separate claims. Run behavioral checks only when the claim requires them and the scope permits them; metadata or syntax qualification does not itself require a PLC runtime test.
6. Record the accepted representation, evidence and CPU/TIA/context/import-route limits in the project's work evidence. Resolve defects or required unknowns before broad native use of that pattern. Follow the project's final complete-rebuild gates; a bounded qualification does not replace them.

Routine edits using a matching verified pattern need no separate probe. Reuse the existing qualification within its stated scope, while still verifying each changed artifact's required stored properties. Do not turn one failed spelling into a prohibition on an entire declaration section or one successful probe into support for all object/datatype combinations.

## Derive Typed Expressions Before Rendering

Resolve the actual declarations of local variables, external symbols/constants, parameters and instruction results before rendering dependent expressions. Read the external definition rather than inferring its type from a familiar name, current numeric value or catalog description. If a consequential declaration is unavailable, keep that expression's type qualification explicitly unresolved while continuing independent work; do not claim a completed technical review or ask the user to choose an avoidable cast.

Apply the guide's [constant scope and reuse rules](s7-styleguide.md#constants): use a suitable accessible existing definition, or declare a named local implementation invariant when none exists. Do not leave an ordinary implementation marker unresolved merely because a previous project used a global constant. Do not substitute a local number for a missing contract-owned definition or silently rewrite preserved existing artifacts outside scope.

Use the general guide's [directed conversion matrix and context rules](s7-styleguide.md#directed-conversion-matrix) for the actual CPU/TIA. Author conversions against the IEC-on rules regardless of the target block's setting; do not select IEC-off-only implicit transitions. Preserve existing block settings and inspect them to interpret actual diagnostics, not to relax the coding rule. Documentary conversion availability, warning-free native acceptance and required value preservation are different claims. For arithmetic, comparisons, indexing, conversions and calls, reason from the resolved declarations through the consequential intermediate operations to the final assignment or formal parameter:

- Identify operand types, signedness, units and the relevant allowed ranges. A current example value is not the declared/required domain unless the scenario intentionally fixes it.
- Establish the operator/intermediate result types and any operand alignment under the applicable SCL/instruction semantics and IEC setting. Check intermediate overflow, underflow, sign interpretation, rounding and index/bound validity before considering only the final destination. Do not transfer arithmetic diagnostics to comparisons or interpret a wider assignment target as proof of a wider intermediate.
- Compare the resulting value/type with the assignment target or actual formal parameter, including direction and reference/copy/storage effects. Matching parameter names or widths does not establish semantic compatibility.
- Keep IEC-conforming implicit conversions when they are warning-free and preserve the required numerical meaning. Introduce explicit conversions at the operation/binding that needs them under the IEC-on rules, not for every differing pair. Converting an already overflowed intermediate or casting merely to suppress a warning is not a correct repair. Establish the relevant range before narrowing; do not widen everything mechanically or reinterpret a bit transfer as numeric conversion.
- Choose consistent local types for related calculations and working values so avoidable conversions do not accumulate. Preserve independently owned interfaces/constants. Reuse a converted intermediate only when a meaningful name and shared lifetime make the code clearer without unnecessary copying, persistent state or extra cyclic work. Fewer casts are not a reason to obscure information or compromise performance.

Apply the same reasoning to control expressions, state/count relationships, lengths, offsets, timers and loop limits as to payload calculations. A count may correctly match one API and still need a different deliberate representation in another expression. There is no requirement to publish a per-expression type table, add a cast to every operation or build a general parser; the obligation is correct authoring supported by actual types and ranges.

Apply the guide's [loop termination rules](s7-styleguide.md#loop-bounds-and-termination) to the actual start, bound and increment, including the update needed to exit and paths with no iterations. Before rendering a dependent access, dereference or division, establish its preconditions through explicit control flow rather than assuming a preceding Boolean operand suppresses evaluation. Separate calls with mutable side effects from larger expressions under the guide's [Boolean logic rules](s7-styleguide.md#boolean-logic); pure value calculations do not need artificial aliases.

## Preserve Numeric Meaning And Source Context

Choose the intended value and precision, then a supported source representation and operation. Distinguish mathematical representability from literal/import/storage preservation. Use ordinary literals where adequate; precision-sensitive boundaries, adjacent values and special values need evidence that their required distinctions survive. A type qualifier or rounded display is not that evidence.

Resolve whether a conversion transfers a representation or converts a numerical value from the documented instruction semantics. Do not create special values through unintended exceptions or assume that a host-language calculation proves native identity. Preserve requirements or accepted test relationships; changed data is not a reason to relax Expected values, tolerances or functional acceptance.

For integer-valued rounding, select the operation using the guide's [rounding decision table](s7-styleguide.md#select-rounding-by-required-meaning). Resolve negative values, exact ties, the actual instruction result type and applicable domain/range checks before generating the expression; a conversion call alone does not specify the intended rounding.

Select declaration initializers, local constants, bounds, CASE labels and executable expressions according to their different supported contexts. Constant operands do not automatically make arithmetic/function calls legal in a declaration or branch label. Preserve meaningful symbolic relationships without duplicating contract-defined numbers or introducing an unnecessary phase variable.

## Resolve Data Roles And Attributes

Before filling declarations, determine object kind, section, datatype category, access mode and the actual defining storage/type owner. Resolve required effective properties from the general matrix and the consuming project's roles/refinement, then select a supported representation within its documented/native qualification scope.

Distinguish FC formals from actual storage, FB instance data from globals, formal references from owned data, and inter-call persistence from power-failure retention. Instance DB properties follow the owning FB rather than an independent instance-DB policy. Read native OB/instruction/type definitions rather than inventing fields or applying a generic code-block header to every object.

Trace actual storage overlap between parameters and indirect/global access using the existing transfer model, including elementary copies, structured references and optimization-boundary copies. Independently named formals need not mean independent storage. Do not rely on an unstated copy-back order; determine whether asynchronous changes can be overwritten on return. Resolve ownership/synchronization within scope instead of adding blanket snapshots or locks, changing interfaces, or assuming every overlap is invalid.

Check applicable containers and defining members separately. Correct member values do not establish a correct container or vice versa. Do not use a blanket datatype replacement to strip attributes, add an elementary-field bundle everywhere, treat omitted tokens as safe defaults, or assume accepted but discarded source attributes took effect. Reuse matching qualified representations without extending them to unrelated contexts.

Preserve existing settings outside the approved change. For new artifacts, apply the current rules from the start. If support or a required effective property is unresolved, identify the exact context and evidence needed; do not weaken the property to make an import pass. Technical evidence does not itself authorize changing interface roles or making a private area externally writable.

## Make Cyclic Behavior And Ownership Explicit

Use the appropriate FC/FB/storage arrangement for the actual behavior. Distinguish local per-call calculations, persistent instance state and external/shared storage. Establish initial, reset, restart and inactive behavior where relevant; do not invent subject Reset semantics for a stateless operation.

Prepare required defaults and validation decisions before the logic that consumes them. Follow the applicable state/error-handling and declaration rules; do not scatter configuration decisions across branches or allow an unwritten temporary to become an implicit previous-cycle input. Make command/acknowledgement ownership and cleanup explicit rather than clearing another owner's signal.

Reason through the actual invocation sequence: stimulus, timers/edges, state dispatch, subordinate call, current results, outputs and previous-cycle memorization. A command written after a subordinate/external call has not already been processed by it. Preserve framework-defined ordering when a domain contract supplies it instead of imposing generic boilerplate. Identify actual time sources/units and the effect of call gaps; additional calls do not necessarily advance a timer.

Choose Siemens instructions, internal elapsed-time accumulation or a reusable custom timer by the guide's [timer criteria](s7-styleguide.md#timers-and-runtime-values), not a fixed technology preference. Trace instance ownership, calls, observations, preset changes and supported reset behavior for the selected mechanism. For code relying on [ENO](s7-styleguide.md#eno), establish its generation, relevant settings and observation/rearm sequence before using it as error evidence; preserve settings outside the approved change.

Use the state-machine structure prescribed by the selected rules and meaningful responsibilities. Distinguish a true transition-owning state machine from bounded data/action selection when applying CASE/ELSE rules. Keep transitions, wait endpoints, terminal/release conditions and side effects visible; do not add a parallel phase controller or a forced control-state mirror merely for syntax convenience.

## Render The Actual Artifact

Apply the selected rules for identifiers, quoted declaration names, metadata, namespace/context-sensitive references, comments, regions, call layout and readable indentation while generating source. Keep valid artifact-kind-specific headers rather than blindly copying an FB header to a UDT or DB. Preserve stable identities on edits/moves and distinguish an independent copy from the same renamed artifact under the project policy.

When preparing an import file, honor the project's actual format/encoding/newline requirements at the file boundary; do not apply disk-file BOM handling to transport JSON or unrelated document formats. Preserve text, attributes and intended visible indentation through the writer and validate the final artifact before native mutation. Source tabs are not evidence that native import preserves indentation: use the project's qualified import representation and inspect the stored base level, nesting and continued calls before replication or handoff. Keep transport-specific whitespace handling separate from canonical source style. A fallback writer must satisfy the same requirements, not recreate weaker rules to bypass a failed import.

Before handoff or an authorized native change, apply [change review and verification](review-and-verification.md) to the resulting source, not only the construction plan. Correct newly identified engineering defects within the approved scope without changing intended behavior, weakening required properties or hiding unavailable evidence.
