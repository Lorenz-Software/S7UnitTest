# Assertion Authoring

Assertions are reusable checks that a Test Case calls while it evaluates a scenario. They do not own the Test Case lifecycle. The Test Case decides when an Assertion is reset, when it is enabled, and how its result contributes to the Test Case result.

Use Assertions to keep checks readable and repeatable. Put scenario flow, stimulus handling, resource ownership, and final Test Case result handling in the Test Case. Put the actual value check into the Assertion.

## Assertion Model

Assertions evaluate one condition and publish one assertion-local result. The owning Test Case provides the lifecycle context through the Assertion interface.

The common interface concepts are:

- `Reset` clears assertion-local state and suppresses observation and evaluation.
- `Enable` defines when the Assertion observes and performs observation-driven evaluation.
- `ObserveFirstCycle`, when present, defines whether the first enabled call may observe checked values.
- `Evaluate`, when present, requests evaluation of a stateful Assertion independently from observation enablement.
- `Name` is the full hierarchical Assertion event name assigned by the owning Test Case.
- `ResourceName` is optional tested-resource context for diagnostics.
- `State` is the owning Test Case state, not an Assertion-local state.
- `Result` retains its evaluation state until Reset and follows the selected family's allowed progression; a held Passed value is not proof that a new observation was evaluated. Disable or a new Test Case state does not clear it.

The Assertion does not build its own hierarchy. The Test Case passes a name in the form:

```text
<runControlName>.<suiteName>.<testCaseName>.<assertionName>
```

For normal Assertion calls, build this from the Test Case name and one assertion-local name:

```scl
Name := CONCAT(IN1 := #ControlData.Name, IN2 := '.', IN3 := 'Feedback')
```

Budget the complete event name, not just its local suffix or the Test Case name. Require `LEN(testCaseName) + 1 + LEN(assertionName) <= UnitTest.TextLength.Name`, using the actual parent hierarchy. Passing owner-name validation alone does not validate appended Assertion names. For varying bindings, account for the supported parent-name lengths rather than checking only one short example. Choose concise, meaningful, distinct local segments; do not truncate complete names to fit. Check `ResourceName` separately against its own contract limit. Review the assembled names before handoff, including whether shortening would merge identities.

Do not interpret `Enable = FALSE` as a reset. Disabling an Assertion pauses observation and observation-driven evaluation, but it must not clear a failed or error result from the same Test Case execution or suppress a separate explicit `Evaluate` request.

## Instance Ownership And Data Variations

An array of Assertion FB instances is a collection of independently stateful checks. This is different from an array Assertion such as `AssertEqualArray_*`, which checks an array-valued input through one Assertion instance. Select the former as a call/data representation and the latter by the property being checked; neither implies the other.

A behavioral scenario, a data row, a checked property and a stateful Assertion instance are different design choices. Reusing a framework Assertion type does not imply sharing its mutable instance. Select instance ownership together with the Test Case's execution structure and required diagnostics, not simply from the number of variables or rows. Keep independently meaningful checked properties explicit; reuse is not a reason to collapse them into one opaque Boolean check.

| Observation arrangement | Instance choice and reason |
| --- | --- |
| The same property is observed repeatedly over cycles | Use the same instance as intended by its immediate or collection/history semantics; this is one observation responsibility, not several independent check sites. |
| Independent check sites within one test state | Prefer separate instances with stable meaningful names, preserving their results and failure identities. |
| Homogeneous check sites represented by arrays | An array element is a separate instance, not reuse of its neighbour. Corresponding binding/Expected/result arrays and bounded loops may express the same independent checks more clearly than individually written calls. Neither representation has a general priority. |
| The same property is checked across meaningful framework test states | Reuse can fit when its observation/history and result semantics remain compatible. Keep the Assertion identity stable and pass the actual Test Case State as the existing diagnostic step context. |
| Checks need independent results or findings even if an earlier check fails | Use separate instances or separate Test Case executions. Merely advancing a test state does not clear a latched result or provide a fresh finding lifecycle. |
| Different data samples share one instance within one state | Treat this as a justified exception: a concrete benefit, intentionally sufficient first-failure/aggregate semantics and unambiguous existing diagnostic context must outweigh the loss of independent results. A row count alone is not a justification. |

Before instance reuse, resolve the selected family's actual observation-driven versus explicit evaluation, result/finding latching, Enable/re-enable behavior and any initial baseline or collection history. Disabling, changing IN/Expected/Name, or advancing State does not reset that state. A logged State identifies a finding that actually occurred; it does not guarantee another finding after a prior Failed/Error. In particular, an edge/sequence/history Assertion is not an immediate comparison with a reusable empty baseline at every new state.

Keep each instance's hierarchical name stable during an execution. Do not rebuild row-specific Assertion names or invent message-text protocols as a substitute for missing step identity. A snapshot array for engineering inspection does not replace required normal failure attribution. Multi-test-state is not mandatory merely because instances could be shared there; select meaningful steps using the [Test Case structure criteria](test-case.md#choosing-test-states).

Call each Assertion instance once per Test Case invocation, using its activation/evaluation inputs to express observation. A bounded loop may call all elements of a fixed owned instance array in that same invocation; there is no required wait between different elements. Keep each element's input, Expected, actual output, activation and result correctly aligned, with stable meaningful event identities rather than opaque indices alone. If DUT calls share an output location, observe or copy before overwrite; separate output storage needs no redundant copy. Arrays do not imply a retained cross-cycle row counter or another state machine, nor do they inherently reduce instance storage, cyclic calls or reservations. Select them for clarity and homogeneous bindings, not automatically for shorter code.

Do not call one instance repeatedly for different rows in one cycle. Reset it only in the enclosing Test Case Reset, never between rows or states to make it appear independent or erase an unsuccessful result. New independent executions retain their own required final-result and Reset handling. Concurrent Cases always have private mutable Assertion state.

Weigh distinct-instance storage, unconditional cyclic calls, repeated source and event reservations against the required observation and diagnostic semantics; neither minimum instance count nor one set per row is an objective. Resource concerns need concrete support, not an invented capacity threshold. Prefer separate instances for independently relevant check sites even when sharing would compile and keep the overall Case unsuccessful.

## First-Cycle Observation

Use `ObserveFirstCycle` only when the Assertion can validly observe and evaluate without a previous enabled sample. It defaults to `TRUE`.

- With `ObserveFirstCycle = TRUE`, the first enabled call after Reset or re-enable contributes observed values.
- With `ObserveFirstCycle = FALSE`, that first enabled call does not observe checked values or perform direct evaluation from observation.
- A disabled call makes the next enabled call a new first enabled call without clearing other latched Assertion state.
- Reset while enabled makes the next non-Reset enabled call a new first enabled call.

This setting controls observation, not the scheduling of a separate explicit `Evaluate` request. Do not use it to delay explicit evaluation. Assertions that require a previous enabled value or signal sample use their first enabled call to establish a mandatory baseline and do not expose `ObserveFirstCycle`.

## Choosing An Assertion

Start with the behavior you want to express, then choose a matching Assertion by both comparison semantics and the failure information it preserves. Correct comparison alone is not sufficient when a poorer representation hides the values needed to investigate a failure.

| Check intent | Typical Assertion family |
| --- | --- |
| Compare one value exactly | `AssertEqual_*`, `AssertNotEqual_*` |
| Compare one numeric value with limits | `AssertLessThan_*`, `AssertLessEqual_*`, `AssertGreaterThan_*`, `AssertGreaterEqual_*`, `AssertInRange_*`, `AssertNotInRange_*` |
| Compare floating-point values with tolerance | `AssertEqualTolerance_*`, `AssertNotEqualTolerance_*` |
| Compare date/time values | `AssertEarlierThan_*`, `AssertLaterThan_*`, `AssertInTimespan_*`, `AssertNotInTimespan_*` |
| Check that a value does not change | `AssertNoValueChange_*` |
| Check a Boolean edge count | `AssertRisingEdgeCnt*`, `AssertFallingEdgeCnt*`, `AssertNoRisingEdge`, `AssertNoFallingEdge` |
| Check a single bit in a bitfield | `AssertTrueBit_*`, `AssertFalseBit_*`, `AssertEqualBit_*`, `AssertNotEqualBit_*` |
| Check a group of bits through a mask | `AssertTrueMask_*`, `AssertFalseMask_*`, `AssertEqualMask_*`, `AssertNotEqualMask_*` |
| Check whether a bitfield contains at least one bit state | `AssertContainsTrue_*`, `AssertContainsFalse_*`, `AssertContainsBit_*` |
| Check an observed value sequence | `AssertSequence_*` |
| Check an array segment | `AssertEqualArray_*`, `AssertArrayContainsValue_*`, `AssertArrayContainsArray_*`, `AssertArrayAllEqual_*`, `AssertArrayNoValueChange_*` |
| Check text stored in arrays | `AssertArrayEqualString_*`, `AssertArrayContainsString_*`, `AssertArrayStartsWithString_*`, `AssertArrayEndsWithString_*`, and WString variants |
| Check token length or token count in byte/word arrays | `AssertLengthUntil*_*`, `Assert*TokenCnt*_*`, `AssertNo*Token_*` |

If more than one Assertion could fit, prefer the one that best describes the intent and yields useful supported diagnostics. A single-bit check is clearer than a full-mask check when the test is really about one named bit. A range check is clearer than two separate less/greater checks when the value must stay inside one interval. Preserve the accepted exact/tolerant, range, timing and history meaning; a more convenient message never justifies weakening the check.

### Review The Resulting Failure Information

Assess the finding as it can be understood in the PC client: the configured owner/Assertion name, available ResourceName and State context, and the selected family's actual Failed/Error message together. Resolve message behavior from the matching catalog/source or documented family, not an imagined client rendering. For a plausible failed observation, check:

- **Location:** Can the reader identify the subject, checked property and relevant step or data variant? Stable meaningful Assertion identities and actual framework State context must distinguish the required check sites; an opaque array index, generic Check1 name or shared state alone may not do so.
- **Expectation:** Is the required value, bound, interval, state or behavior understandable from the name and supported message? A concise property name supplies domain meaning missing from a generic comparison text; it need not repeat the whole hierarchy or explain the complete scenario.
- **Observation:** Does the chosen Assertion retain the relevant actual value, expected value or violated condition rather than only a precomputed TRUE/FALSE verdict? Use supported, bounded diagnostic information appropriate to the property, not mandatory complete array dumps or arbitrary extra logging.

Prefer a direct type-matching value Assertion when it preserves the intended relationship and more useful evidence. For example, `AssertEqual_Real` with `IN := MeasuredValue` and `Expected := RequiredValue` can report the compared values; `AssertEqual_Bool` with `IN := (MeasuredValue = RequiredValue)` can only describe the Boolean predicate. The latter discards numerical evidence before the Assertion receives it. Apply the same reasoning to numeric ranges, state comparisons and other supported families rather than mechanically asserting every expression against TRUE.

Boolean Assertions remain appropriate for genuinely Boolean outputs and coherent domain predicates without a better matching Assertion. Name a composite predicate by its meaning, but do not treat naming alone as recovery of discarded independent information. Split independently relevant expectations where a composite FALSE cannot identify the violated property. Do not require one Assertion per variable, reject all Boolean composition or add extra Assertions merely to increase message volume.

Apply this review when choosing explicit instances, instance arrays and sequential reuse, not only after source generation. A distinct array element must retain a meaningful failure identity; State identifies a finding actually emitted but does not clear latching or guarantee later findings. A private snapshot requiring engineering inspection is not a substitute for required normal failure attribution. Failures should locate and describe the observed deviation; the message need not prove its underlying technical cause. Distinguish a reported property mismatch from an Assertion configuration/domain Error without inventing a cause unsupported by the observation.

Account for the selected family's rendering limits: rounded Real/LReal text may make unequal values look equal, and shortened text/array previews may omit differences. Neither equal-looking diagnostics nor a successfully rendered message proves comparison equality or completeness. Do not change Expected, tolerance or test intent to improve display. If supported names/context/messages cannot provide required diagnostic clarity, state the concrete limit and align a scoped improvement; do not invent message-text protocols, new contract fields or client behavior.

This is an ordinary semantic review of representative plausible failures, not a mandatory fault injection for every Assertion, new report schema or independent logging contract.

## Scalar Assertions

Scalar Assertions are located below `Assertions/BasicTypes/<Type>`.

They are the default choice for checking one PLC value. The available families depend on the datatype:

- Boolean values support equality, inequality, no-value-change, and rising/falling edge count checks.
- Signed and unsigned integer values support equality, ordering, range, no-value-change, and sequence checks.
- `Real` and `LReal` support equality, ordering, range, no-value-change, and tolerance checks.
- `String` and `WString` support equality, inequality, contains, starts-with, ends-with, and no-value-change checks.
- date and time datatypes support equality, earlier/later checks, timespan checks, and no-value-change checks.
- `Char` and `WChar` support equality and no-value-change checks.

Use scalar Assertions when the checked behavior is naturally represented by one value.

`AssertNotEqual_Bool`, `AssertNotEqual_String` and `AssertNotEqual_WString` pass when `IN` differs from `Expected`; equal values produce `Failed`. Text inequality compares the complete received native value case-sensitively, without trimming. Empty operands are valid: two empty values fail inequality, while empty versus nonempty passes. A shortened diagnostic preview never limits the comparison; differing complete values can pass even when their previews are identical. A previously latched `Failed` still remains until Reset.

These Assertions use the same Reset, Enable, ObserveFirstCycle and context inputs as their equality counterparts. Reset suppresses observation and findings; eligible equality emits one failed finding before Reset, with `Assertion failed: values are equal. Expected = ..., Actual = ...`. Text-preview formatting is diagnostic only.

### Text Diagnostic Previews

Text previews contain at most 40 output bytes including their two quotes. Values fitting within 38 content bytes are shown without shortening; longer values show 35 content bytes followed by `...`. Printable ASCII bytes remain unchanged, including literal quotes and backslashes. Other native code units render as one byte `16#D7`; its displayed glyph depends on the consumer. Wide values are classified before narrowing, so a non-ASCII wide character cannot accidentally appear as its low byte.

Zero ends a scalar String/WString preview. In a selected character-array window, zero is data: it renders as `16#D7`, and subsequent selected elements remain visible. Array bridge diagnostics retain their existing prefix or suffix window; element-oriented CHAR/WCHAR array findings render the selected element as array data. Invalid or zero-length diagnostic-array requests render quoted empty text. These rules affect diagnostics only: comparisons still use their complete native operands and existing selection semantics, not normalized or shortened previews.

For scalar `AssertContains_*`, `AssertStartsWith_*` and `AssertEndsWith_*` on String/WString, the search pattern (`Fragment`, `Prefix` or `Suffix`) must be nonempty. An empty pattern produces `Error` during eligible observation, even after a previous `Failed`; disabling observation or suppressing the first enabled cycle does not trigger that check. Reset suppresses checking and findings and permits clean reuse. An empty actual text with a nonempty pattern is a normal non-match. Exact text equality still permits empty operands.

## Floating-Point Domains

Choose REAL/LREAL Assertions using the operand roles, not only the comparison predicate.

| Assertion family | Expected data or baseline | Actual data |
| --- | --- | --- |
| Ordinary scalar equality, ordering, range, tolerance and no-value-change | Checked reference values and bounds must be finite. | Must be finite; invalid active observation produces Error, including the initial no-value-change baseline. |
| `AssertEqualArray_*` | Every expected element must be finite; otherwise Error. | Non-finite elements are mismatches against valid expected data. |
| `AssertArrayContainsValue_*`, `AssertArrayContainsArray_*`, `AssertArrayAllEqual_*` | Expected NaN produces Error; signed infinity is valid. | NaN never matches; infinity matches only the same sign. A search may still succeed at another position. |
| `AssertArrayNoValueChange_*` | Initial snapshot NaN produces Error before capture; signed infinity is valid. | Later NaN is a mismatch; unchanged same-sign infinity matches. |

This table applies to REAL/LREAL variants only. Finite values include subnormals and both zero signs. Every floating tolerance must be finite and nonnegative. Valid finite extreme operands remain valid; a difference greater than the largest finite value is outside every valid tolerance, including maximum-finite versus `-1` with maximum-finite tolerance.

Domain validation follows observation eligibility and Reset priority. It still detects invalid data after a held Failed result and escalates to Error. A first enabled scalar no-value-change call observes a mandatory baseline even though comparison needs a later sample. Array no-value-change Assertions instead retain their first successfully captured reference until Reset, as described below. Numeric-domain rules do not add `ObserveFirstCycle` to baseline-dependent Assertions.

Numeric diagnostics default to six significant digits, rounded to nearest with ties to even, with compact fixed or scientific notation. They explicitly render `NaN`, `+Inf`, `-Inf`, `0` and `-0`; rounding affects messages only. Classification, safe comparison and numeric rendering helpers are internal framework support, not substitutes for selecting a project-facing Assertion.

## Floating-Point Classification

Use these REAL/LREAL Assertions when the class of a floating value is itself the checked condition. Unlike ordinary numeric comparisons, they accept NaN and both infinities as valid checked data; a class mismatch is `Failed`, not `Error`.

| Assertion family | Pass condition |
| --- | --- |
| `AssertIsNaN_*` | `IN` is quiet or signaling NaN, of either sign. |
| `AssertIsFinite_*` | `IN` is normal, subnormal or either signed zero. |
| `AssertIsInfinite_*` | `IN` is positive or negative infinity, not NaN. |
| `AssertArrayAllElementsFinite_*` | Every selected element is finite. |
| `AssertArrayContainsNonFinite_*` | At least one selected element is NaN or infinity. |
| `AssertArrayContainsNaN_*` | At least one selected element is NaN. |
| `AssertArrayHasNoNaN_*` | No selected element is NaN; infinity is allowed. |
| `AssertArrayContainsInfinity_*` | At least one selected element is positive or negative infinity. |
| `AssertArrayHasNoInfinity_*` | No selected element is infinite; NaN is allowed. |

Each family has `Real` and `LReal` variants. They use the standard Reset, Enable, ObserveFirstCycle and context inputs and publish Result. They do not take Expected, Tolerance, Evaluate or an infinity-sign selector. Reset suppresses checking and findings; disabling preserves the current result. A held Failed or Error remains until Reset.

Array classifiers read only the selected `IN` range. `StartIndex : DInt` is an absolute declared array index; `Length : USInt` selects 1..255 elements. Bind a stable array for the call; the Assertion does not modify it or retain a snapshot. Invalid selection produces Error during eligible observation, including after a previous Failed result. Specials outside the selection do not affect the result. Range arithmetic is widened internally without changing these public parameter types.

Failed scalar diagnostics include the actual rendered value. An array failure caused by a forbidden element identifies the first offending absolute index and value; a missing-class failure identifies the selected range without inventing an offending index. Failed and Error findings have independent one-shot histories. Existing safe numeric formatting affects messages only. These classifier rules do not relax the ordinary-family domain policies above.

## Bitfield Assertions

Bitfield Assertions are available for `Byte`, `Word`, `DWord`, and `LWord`.

Use them when the value represents bits or flags, not an ordered number. For these datatypes, ordering comparisons are intentionally not the main model.

Bit numbering starts at `0` for the least significant bit:

- `Byte`: `0..7`
- `Word`: `0..15`
- `DWord`: `0..31`
- `LWord`: `0..63`

Mask Assertions default to all bits of the datatype. An empty mask is a configuration error because it would check no bit.

Use:

- bit Assertions for one named bit,
- mask Assertions for a defined group of bits,
- raw equality Assertions when the complete bitfield value is the expected behavior,
- contains Assertions when at least one bit matching the condition is enough.

## Sequence Assertions

Sequence Assertions check that observed values follow an expected order. They do not check timing, cycle count, or duration.

Use them when the Test Case state machine defines the observation window and the Assertion only has to validate the order of values inside that window.

Typical control:

- `Enable` starts or continues observation.
- `ObserveFirstCycle` selects whether the first enabled call contributes to the sequence observation.
- `Evaluate` tells the Assertion to finalize the observed sequence.
- `Expected` provides the complete expected sequence as an array.

The Test Case owns when observation starts and when evaluation happens. `Evaluate` is not gated by `Enable` or `ObserveFirstCycle`; Reset still suppresses it. A Sequence Assertion includes the current input in its sequence observation before processing an explicit evaluation request.

Edge-count Assertions intentionally use different explicit-evaluation semantics. Their first enabled call establishes the signal baseline, and an explicit `Evaluate` checks the already accumulated edge count without adding a current-cycle edge solely because evaluation was requested.

For the rising/falling edge-count `InRange` and `NotInRange` Assertions, `Minimum` and `Maximum` define an inclusive interval. Equal bounds select one valid count. Reversed bounds (`Minimum > Maximum`) produce `Error` on explicit evaluation, even when `Enable = FALSE` or the Assertion has already reported `Failed`. Invalid bounds without `Evaluate` do not trigger evaluation or stop edge observation. Reset suppresses evaluation and findings; otherwise Error remains latched until Reset, with an error finding independent of any earlier failed finding.

If the scenario needs timing rules, express those rules in the Test Case state machine or Sequencer rather than hiding them inside the Sequence Assertion.

## Array Assertions

Array Assertions are located below `Assertions/Arrays/<Type>`.

Use array Assertions when the behavior is a property of an array segment rather than one scalar value.

The common range parameters are:

- `StartIndex`: first element of the monitored array range.
- `Length`: number of monitored elements.

`Length = 0` is invalid. The monitored range must fit into the provided array.

Common array checks:

- `AssertEqualArray_*`: compares a monitored segment against an expected array.
- `AssertArrayContainsValue_*`: checks whether a value occurs inside the monitored segment.
- `AssertArrayContainsArray_*`: checks whether a contiguous expected pattern occurs inside the monitored segment.
- `AssertArrayAllEqual_*`: checks whether all monitored elements equal one expected value.
- `AssertArrayNoValueChange_*`: checks that the monitored segment remains unchanged.

`AssertArrayNoValueChange_*` needs an external `Memory` array, usually static Test Case data, with at least `Length` elements from its own lower bound; its bounds need not match `IN`. The first eligible enabled call after initialization or Reset validates and stores the initial snapshot and leaves `Result = NotEvaluated`. That snapshot remains the reference until Reset, independently of whether a comparison has already produced a result.

Disabling pauses comparison but preserves the reference, result and finding history. Re-enabling does not copy another snapshot: the first re-enabled call does not compare, and the next continuously enabled call compares against the retained reference. For example, capturing `10`, disabling, changing the input to `20`, and re-enabling reports the change on the following enabled call rather than accepting `20` as a new reference.

Reset invalidates the reference and clears result, previous-enable state and finding history; it does not need to wipe `Memory`. A later eligible enabled call establishes a new snapshot. A held Error prevents capture until Reset. For REAL/LREAL, initial NaN rejects capture before any Memory write; later NaN during comparison is a mismatch, including after re-enable. Signed infinity and tolerance validation follow the floating-point rules above. These array snapshot rules do not change scalar `AssertNoValueChange_*` consecutive-sample behavior.

## Text In Arrays

Some interfaces store text in fixed arrays instead of PLC `String` or `WString` values. Use text-bridge array Assertions for these cases.

Supported mappings:

- `ARRAY OF CHAR` and `ARRAY OF BYTE` can be checked against `STRING`.
- `ARRAY OF WCHAR` and `ARRAY OF WORD` can be checked against `WSTRING`.

Supported check classes:

- equal,
- contains,
- starts with,
- ends with.

These Assertions evaluate only the configured array segment. They do not trim padding, remove nulls, validate encodings, or apply pattern matching. An empty expected text is a configuration error.

Use text-bridge Assertions when the test intent is text readability. Use indexed array Assertions when the exact element position is more important than the rendered text.

## Token Checks In Byte And Word Arrays

Token Assertions are available for byte and word arrays.

Use length-until-token Assertions when the position of a token defines the meaningful payload length.

Use token-count Assertions when the number of value or array-token occurrences is the behavior under test.

Array-token counts for BYTE/WORD use complete, non-overlapping matches in the selected range. After a match, searching continues after the entire token; adjacent complete tokens still count separately. For example, `[1,1,1]` contains `[1,1]` once, while `[1,1,1,1]` contains it twice. Token bounds are independent from input bounds, and WORD comparisons use the complete 16-bit value.

The array-token Assertions have no `Mask` input. Single-value token Assertions are a separate family with their existing masked comparison behavior. The framework's non-overlapping array-token policy does not change shared Common counting functions or unrelated consumers.

`Count` describes the last evaluated selected region, not a total across cycles. Disable and held Failed/Error retain it for valid configuration; active invalid configuration produces Error and clears the count. Reset clears result, count and finding history. A complete array token must fit the selected range or the configuration is invalid. In contrast, a nonempty text pattern longer than the searched text range is a normal non-match. Length-until-token Assertions still fail when the token is absent, including the `NotEqual` predicate.

Examples:

- a byte payload contains a separator byte exactly once,
- a word payload starts with data and ends before a known token,
- a communication buffer must not contain a forbidden token.

Token checks operate on array elements. They do not parse a protocol frame, validate checksums, or interpret headers. Keep protocol-specific interpretation in the Test Case or in a dedicated helper, and use Assertions for the concrete observable condition.

## Events And Diagnostics

Assertions can emit assertion-owned failed or error findings. They do not emit Test Case lifecycle events and they do not emit final Test Case result events.

The owning Test Case still aggregates Assertion results and emits the final Test Case result and Test Case aggregation events.

Assertion messages should be useful for finding the problem quickly:

- include expected and actual values where practical,
- include indexes when the failing element matters,
- prefer rendered text when the test intent is text,
- keep messages bounded and avoid cyclic message spam.

## Practical Guidance

Keep Assertion usage simple:

- Use one Assertion for one condition.
- Enable Assertions only in states where their condition is meaningful.
- Reset Assertions only on the Test Case reset path.
- Keep Assertion result aggregation in the Test Case result region.
- Do not drive resources from Assertions.
- Do not use Assertions to replace Test Case state-machine logic.

If an Assertion call becomes hard to understand, the Test Case probably mixes too much scenario logic into the check. Move scenario setup, stimulus, timing, or branching back into the Test Case and keep the Assertion focused on the condition being checked.
