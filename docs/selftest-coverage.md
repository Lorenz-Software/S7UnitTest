# Assertion Selftest Coverage

## Scope

Assertion Selftests cover functional behavior classes, with focused runtime checks for representation-specific differences and semantic source review for equivalent mechanisms. They do not require one complete runtime matrix per concrete Assertion FB.

The authoritative test inventory is the reviewed Suite/TestCase source, not a historical allocation table or a target count in this guide. Sequencer, Orchestrator, result-utility, status-view and EventBuffer coverage is separate. Reducing duplicate Selftests does not remove production Assertions or change contracts, versions or behavior.

## Review Rules

- Test behavior classes rather than repeating the same complete matrix for every block name.
- Distinguish predicate coverage from mechanism coverage. Every different predicate needs discriminating positive/negative or boundary results; common Reset, Enable and finding behavior can have a reviewed representative.
- Transfer only a named mechanism such as observation gating or snapshot retention. A representative predicate does not establish a different predicate's correctness.
- Keep runtime checks for IEEE widths, adjacent floating values, overflow/rounding, full-width characters and upper-byte tokens. Type-name substitution is not evidence for those differences.
- Check results, meaningful count/reference-memory outputs and temporal boundaries. Do not assert private state merely because it is observable.
- Avoid exact finding sentences, severity/state/context tuples and complete event histories in ordinary Assertion evaluation tests. Keep focused one-shot/Failed-to-Error behavior where it is the actual subject. Numeric formatting and EventStream protocol behavior remain separate functional subjects.
- Reduce redundant fixtures and checkpoints, not just TestCase containers.
- Keep independent stateful scenarios independent. Do not serialize unrelated scenarios through a numeric mode or additional resets on one DUT instance.
- Preserve Error after Failed, observation versus explicit evaluation, snapshot retention/reuse, invalid initial capture and full-value comparisons beyond diagnostic previews.

## Implementation Classes

These classes identify mechanisms to compare. They are not new framework base classes and do not imply that independently implemented FBs inherit correct behavior.

| Class | Representative mechanisms | Runtime targets | Transfer boundary |
| --- | --- | --- | --- |
| Direct comparison | Reset, first enabled observation, held result, finding latch | B01, B08 | Predicate remains checked in each functional family; does not cover explicit Evaluate or configuration errors. |
| Edge observation/evaluation | Previous signal, count accumulation, explicit Evaluate ordering, Reset | B06, B07 | Rising/falling and InRange/NotInRange result differences remain; no transfer to Sequence Assertions. |
| Persistent array snapshot | First capture, disabled retention, resumed comparison, Reset, capacity | B02-B05 | Float validation is not equivalent to BOOL copying; retain F14, F16, F17 and the LREAL conversion exception. |
| Ordinary floating comparison | Domain validation, finite comparison, tolerance and array predicates | F03, F04, F07-F15 | Different array quantifiers/search algorithms are retained; classification Assertions have a different valid-input domain. |
| Floating representation | Exponent/fraction masks, native conversion, tolerance precision, formatting | F01-F06, targeted F14 | Width-specific mechanisms retain runtime checks rather than relying on type-name substitution. |
| Scalar classification | NaN/finite/infinite predicates with valid special input data | F18 | All three predicates remain discriminated; LREAL transfer requires matching helper bindings and control flow. |
| Array classification | Selected-window iteration, existential/universal predicates, range validation | F19, F20 | All six predicates remain discriminated; error/recovery mechanism is checked on a representative implementation. |
| Native text operations | Full-value comparison, Contains/StartsWith/EndsWith, empty/overlong inputs | T01-T06 | Native wide-character behavior remains in T05; previews are never the comparison oracle. |
| Array token counting | Overlap, count predicates, selection bounds and configuration recovery | K01-K04 | WORD upper-byte behavior remains; not a substitute for the distinct legacy primitives in K05. |
| Legacy search primitives | Masked value-token count and length-until-not-equal compatibility | K05 | Retain the existing small BYTE compatibility checks; do not infer these algorithms from substring counting. |

## Coverage Map

These IDs name coverage responsibilities, not PLC block names, runtime configuration or a quota. A responsibility can require an additional check if its proposed source transfer is not justified. Multiple IDs can belong to one coherent test; unrelated stateful scenarios still need independent fixtures.

### BOOL

| ID | Functional coverage |
| --- | --- |
| B01 | BOOL equality/inequality truth table |
| B02 | Snapshot retained before first comparison across Disable/re-enable |
| B03 | Snapshot retained after a successful evaluation |
| B04 | Reset discards the old reference and permits a fresh capture |
| B05 | Insufficient memory capacity is rejected without modifying the reference |
| B06 | Edge-count functional result table |
| B07 | Edge observation versus explicit evaluation |
| B08 | Direct-comparison lifecycle |

The equality/inequality truth table covers both predicates. Edge-count checks distinguish rising/falling polarity and inclusive/complementary range predicates. The evaluation lifecycle includes evaluation while disabled and during the first enabled call, an ordinary eligible observation, invalid bounds, Failed-to-Error, Reset/reuse and rearming. Explicit Evaluate does not itself manufacture an observation.

BOOL snapshots cover retention before comparison and after successful evaluation, fresh capture after Reset and insufficient capacity without reference modification. They represent only the common snapshot-lifetime mechanism of floating variants, not floating-domain validation.

### Floating Point

| IDs | Functional coverage |
| --- | --- |
| F01, F02 | REAL and LREAL bit classification |
| F03, F04 | Tolerance boundaries and arithmetic limits |
| F05, F06 | Numeric rendering |
| F07 | Scalar equality domains |
| F08 | Ordering and inclusive/exclusive boundaries |
| F09 | Element-wise array equality |
| F10 | Array contains value |
| F11 | Array contains array |
| F12 | All selected elements equal |
| F13 | Array no-value-change domain/tolerance behavior |
| F14 | Scalar/array baseline domains |
| F15 | Floating result/error lifecycle |
| F16 | NaN while disabled must not replace the snapshot |
| F17 | Invalid initial capture must not become a valid snapshot |
| F18 | Scalar classification truth table |
| F19 | Selected-array classification results |
| F20 | Classifier range rejection and recovery |

Keep separate native REAL/LREAL bit-layout, precision/tolerance and numeric-formatting checks. Ordinary comparison domains can have a main representative only after reviewing the corresponding source/helper mechanisms. Equality, ordering, element-wise equality, contains-value, contains-array and universal equality remain distinct predicates/algorithms.

Scalar classification discriminates NaN, finite and infinity, including both infinity signs. Selected-array classification covers every existential/universal predicate, finite/NaN/infinity/mixed vectors, selected-window exclusion and traversal boundaries. Range/recovery coverage includes invalid selections, widened end arithmetic, Error after Failed, held Error and Reset/reuse.

Floating snapshots retain disabled-NaN rejection, invalid initial capture, unchanged reference storage and Reset recovery. The LREAL infinity-sign/baseline check exercises its native LWORD identity path; BOOL retention does not establish that behavior.

### Text

| ID | Functional coverage |
| --- | --- |
| T01 | STRING Contains |
| T02 | STRING StartsWith |
| T03 | STRING EndsWith |
| T04 | Full STRING equality/inequality |
| T05 | Wide-character and native-width exceptions |
| T06 | Search configuration/lifecycle |

Keep native Contains/StartsWith/EndsWith match/no-match, empty and overlong boundaries, full-value equality/inequality, case/length differences and differences beyond the diagnostic preview. WSTRING checks distinguish high-byte values, zero low bytes and last-capacity-character differences rather than repeat the ordinary STRING matrix. BYTE/STRING and WORD/WSTRING bridges retain their own conversion and range checks.

Search configuration/recovery has a representative lifecycle with invalid-pattern Error, observation gating, independent one-shot finding counts, Failed-to-Error and Reset/reuse. A BOOL direct-comparison representative does not establish text-search configuration handling.

### Bitfields

| ID | Functional coverage |
| --- | --- |
| K01 | BYTE array-token counting/search |
| K02 | Count predicate boundaries |
| K03 | Token selection/configuration recovery |
| K04 | WORD full-width exception |
| K05 | Existing legacy primitive compatibility |

Token counting covers overlapping candidates, adjacency, shifted bounds, selected-window exclusion, absence, last complete matches and incomplete suffixes. Each count predicate has a discriminating boundary. Independent invalid selections and a coherent observation/Failed/Error/Reset sequence cover configuration recovery.

WORD checks distinguish same-low-byte/different-high-byte tokens, full-width adjacency and masks selecting high bits. Legacy masked-value counting, zero-mask behavior and length-until-not-equal retain their own compatibility checks; they are not inferred from array-token substring counting.

## Project And Execution

The archived framework project separates reusable implementation in `03_Handling` from framework Self-Tests in `90_UnitTest`. The coverage map above addresses Assertions; it does not claim to enumerate all framework tests. See [Project Use And Validation](project-use.md) and the [architecture](framework-architecture.md) for project roles and execution context.

## Source-Transfer Evidence

The unit of review is a named mechanism and its explicit variations, not a broad claim that all Assertions are equivalent.

Compare validation order, observation/evaluation order, guards/result priority, loop bounds/early exits, reference/state memory, output writes and native helper bindings. AI-assisted review may explain the comparison; name substitution, whitespace-normalized equality, hashes or passing representatives alone do not establish semantic equivalence. Literal expected values need an independent intent basis.

Important distinctions include:

- BYTE/WORD counting needs native upper-byte vectors even when control flow agrees.
- STRING/WSTRING search still requires native wide-character checks.
- REAL/LREAL snapshot infinity identity uses different native widths/conversions.
- BOOL snapshots have no floating NaN/finite/tolerance validation.
- Edge-count Assertions have previous-signal memory and explicit Evaluate ordering that direct comparisons do not represent.

Refresh the transfer review when relevant source/helpers/contracts change. Retain a candidate's distinct behavior rather than forcing a target count. Formatting-only changes do not justify repeating a full datatype matrix.

## Verification Limits

Sampling removes direct runtime execution of some variant paths. Semantic review is a different evidence channel, not unchanged measured branch coverage or protection against every compiler/integration fault. This map covers the identified mechanisms, not every cataloged Assertion.

A source comparison and an executed runtime check are different evidence. Do not infer complete datatype, branch or integration coverage from a representative passing test.
