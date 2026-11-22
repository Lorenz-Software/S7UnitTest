# Library Usage

The framework is delivered as master copies, not as library types. Open the supplied native library in TIA Portal and copy the required objects into the consuming project. Master copies provide no automatic type-version binding or guided instance updates.

## Contents And Layout

The library uses this consumer-oriented layout rather than reproducing the project tree:

| Library location | Content |
| --- | --- |
| Root | The `UnitTestConstants` and `LoggingConstants` tables. |
| `Common` | The existing `ExecuteUnitTests` and `ConfigureUnitTests` integration scaffolds; shared helpers under `Utilities`, preserving its `Convert`, `CountToken` and `FindToken` subfolders. |
| `DataTypes` | Reusable framework UDTs together in one folder. |
| `Logging` | Event creation, FIFO and logging utilities; `DB_UnitTestEventBuffer` under `DataBlocks`. |
| `Preparation` | Reusable preparation handling and mocks. |
| `RunControl` | Sequencer, Suite Orchestrators and utilities; Run Control examples under `Examples`; `DB_UnitTestRunControl` and `DB_UnitTestRunConfig` under `DataBlocks`. |
| `TestSuites` | Sequencer, Test Case Orchestrators, mocks and utilities; Suite examples under `Examples`; `DB_UnitTestSuiteControl` and `DB_UnitTestSuiteConfig` under `DataBlocks`. |
| `TestCases` | Sequencers, mocks and utilities; Test Case examples under `Examples`. |
| `Assertions` | `BasicTypes`, `Arrays` and `Utilities`, retaining datatype and functional subdivisions. |

The library includes reusable implementations and their internal dependencies, not just public authoring entry points. Public authoring API, internal helpers and editable integration scaffolds remain distinct; Published metadata alone does not establish this classification.

Examples and entry scaffolds require project-specific configuration and calls; distributing them does not provide a ready-wired test application. The existing `ExecuteUnitTests` and `ConfigureUnitTests` scaffolds do not supply a concrete Run Control instance.

The library does not include concrete instance DBs such as `IDB_UnitTestRunControl`; the consuming project creates its own instances. It also excludes `90_UnitTest`, Self-Test Suites/Cases, Mirrors, evaluation DUTs, transient probes and diagnostic-consumer validation wiring. The reusable diagnostic-consumer FB itself remains eligible framework content.

## Constants And Contract Data

Keep `UnitTestConstants` as one table with unchanged symbolic names. Project settings are `UnitTest.SuiteArray.Length`, `UnitTest.EventBuffer.Length`, `UnitTest.EventBuffer.ResetHeadroom` and `UnitTest.EventBuffer.ExecutionHeadroom`. The remaining framework/contract definitions are not consumer configuration; their authoritative meanings remain in the existing contracts.

Deliver the single `LoggingConstants` table from the same Software Unit with unchanged `Logging.Severity.*` names, types and values. It is a shared contract dependency, not an optional project prerequisite. Both tables are required in inventory generation, source qualification and native copying; omitted tables, duplicate constant symbols and unresolved framework/logging symbols block preparation. Internal timer and integer-limit constants remain local to their owning blocks; consumers do not need `CommonConstants`.

Master-copy delivery does not relax the PLC/PC contract. Preserve the required DB names, field paths, structures, access attributes and contract metadata. Check fixed constants against the delivered framework baseline. On updates, compare explicitly instead of blindly overwriting project-adjusted constants or configuration values. Master copies provide no automatic type-version binding or guided instance updates.

## Integration

Use [Run Control](authoring/run-control.md), [Test Suites](authoring/test-suite.md) and [Test Cases](authoring/test-case.md) for the concrete application binding. The delivered integration scaffolds are editable examples, not a ready-wired application.

The [inventory.json](https://github.com/Lorenz-Software/S7UnitTest/releases/download/v2.0.0/inventory.json) supplied with each framework release records the objects delivered in that library. For component versions and artifact checksums, use the metadata accompanying the corresponding release downloads. Preserve the required names, structures and behavior defined in the [contracts](../contracts/README.md).

## Language And Help

The delivered titles and comments use English (USA). Activate `en-US` in the consuming project's languages and select it as editing/reference language when inspecting that text. Already-imported English titles and field comments can be inspected after enabling that project language without reimporting the objects.

See [Library API Help](help.md) for the standalone HTML package, API scope and library-side Shift+F1 lookup. See [Project Use And Validation](project-use.md) when working with the archived framework project rather than consuming the library.
