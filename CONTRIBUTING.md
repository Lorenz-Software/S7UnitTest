# Contributing to S7 UnitTest

Bug reports, documentation improvements, and focused pull requests are welcome.
The [Framework Model](docs/authoring/framework-model.md) introduces the components
and their responsibilities.

## Questions and Bug Reports

Use [Discussions](https://github.com/Lorenz-Software/S7UnitTest/discussions) for
questions and ideas, and [Issues](https://github.com/Lorenz-Software/S7UnitTest/issues)
for reproducible problems. Check existing reports before opening a new one.

Include the following where relevant:

- S7 UnitTest framework/library version or source commit.
- TIA Portal version and update, PLCSIM Advanced version, and simulated CPU type/firmware.
- A minimal SCL example or steps to reproduce, including the starting conditions.
- Expected behavior and actual behavior.
- Assertion names/results and relevant compiler diagnostics, logs or event captures, if available.
- When using the PC application: PLCSIM.UnitTest version, access profile, and whether the run used WPF or CLI.

Report problems specific to the PC application in the
[PLCSIM.UnitTest repository](https://github.com/Lorenz-Software/PLCSIM.UnitTest).
For PLC/PC integration problems, include both sides' versions and observations.
Remove credentials and confidential project information from attachments.

## Pull Requests

- Keep each change focused on one problem or improvement.
- Explain the problem, resulting behavior, and checks performed. Link an existing report when available.
- Add or update relevant regression tests when framework or tooling behavior changes.
- Update affected documentation and examples alongside the implementation.

Discuss changes to public APIs, lifecycle semantics, result handling, or PLC/PC
contracts before implementation. Follow the
[architecture](docs/framework-architecture.md) and [public contracts](contracts/README.md).

Use English for code comments and documentation, and preserve the existing
formatting and CRLF line endings. Keep generated libraries, help/skill ZIPs,
release inventories, build output and local engineering state out of commits.

### PLC Project Changes

The editable framework and Self-Tests are supplied as
[`Project/S7_UnitTest.zap21`](Project/S7_UnitTest.zap21), stored through Git LFS.
Retrieve it with TIA Portal V21 into a separate working directory. See
[Project Use](docs/project-use.md) for project roles and validation.

For changes to the archived project, identify the affected objects and include a
reviewable SCL diff or focused source excerpts with the pull request. Explain how
the archive was updated and what was validated. Keep the change scoped; do not
add an unrelated working project or a second source tree to the repository.

The native library contains mastercopies. Check relevant consumer integration
separately when a change affects copied objects or their dependencies; see
[Library Usage](docs/library-usage.md).

## Validation

Run checks appropriate to the change:

- **Documentation:** verify Markdown formatting and affected links.
- **PLC code:** follow [Project Use](docs/project-use.md) and select relevant coverage using [Self-Test Coverage](docs/selftest-coverage.md).
- **Tooling:** run the affected tool's documented offline checks; the [SCL indentation helper](tools/scl/README.md) includes its focused test.
- **Authoring skill:** preserve declared framework compatibility, required resources and package hash consistency. Check affected catalogs, templates and guidance together.

Native PLC validation requires the documented TIA Portal V21 environment. The
supported execution scope is standard non-fail-safe PLC logic in PLCSIM Advanced.
Report source review, native compilation, library-consumer checks and runtime
tests separately, including their environment and results. State which checks
you could not perform. A successful compile alone does not establish a passing
test run or complete event-stream evidence.

## License

S7 UnitTest is provided under the [MIT license](LICENSE).
