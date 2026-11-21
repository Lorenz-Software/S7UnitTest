# Repository Agent Workflow

This file defines collaboration in the public S7 UnitTest repository. Explicit
user instructions take precedence. Keep these rules self-contained and suitable
for publication, without private paths, credentials or internal work-item IDs.

## Product and responsibility

- S7 UnitTest is a PLC-side unit-test and behavior-analysis framework for Siemens
  S7. A separate PC application consumes its contracts and results.
- The PLC product owns the public communication contracts, layouts, versions,
  commands, lifecycle, results, events and acknowledgement behavior. Consumers
  follow those contracts; consumer behavior does not redefine them.
- This checkout owns public presentation, snapshot integration, packaging and
  publication. A separate development project supplies prepared product exports.
  Do not modify that project as a side effect of receiving work.
- Public delivery uses an archived TIA project, library mastercopies, user
  documentation, contracts and a standalone Authoring skill. It does not expose
  the development project's raw VCI tree or internal engineering infrastructure.
- Scope statements must follow the supplied qualification: TIA Portal V21,
  standard non-fail-safe S7 logic and the documented PLCSIM Advanced environment.
  Do not infer F-block support or functional-safety qualification.

## Start of work and Git

- Inspect the branch, remotes, tracked changes and untracked files before
  substantial work. Fetch when remote freshness matters. Do not assume branch
  names, remote destinations or existing integration history.
- Preserve unrelated user changes. Do not discard, overwrite, stash or clean them
  without authorization covering those changes. Never blanket-clean ignored
  files; preserve local task records and retained release evidence.
- Agree branch alignment before the initial commit. Once established, follow the
  agreed branch strategy rather than introducing permanent branches automatically.
- Commits, pushes, merges, tags, releases, branch deletion and history changes need
  explicit authorization unless already covered by the user's instructions.
  Preparing a task or release candidate is not publication approval.
- Before committing, review the complete intended diff, including new files.
  Stage named paths and keep commits focused. Verify the destination before
  pushing; do not force-push or rewrite shared history by default.

## Local TODO workflow

- Use ignored `.local-work/` for planning and handoffs. Do not use
  `.git/info/exclude` as a substitute for repository ignore rules. Do not create
  remote issues or a separate issue-tracker workflow unless requested.
- Read `.local-work/README.md` for current focus and the task index. Create tasks
  from `.local-work/TEMPLATE.md` under `.local-work/tasks/` with stable numbered
  filenames. Retain completed tasks and do not renumber them.
- Before non-trivial work, update the existing task or create an appropriate one.
  Small direct requests need no separate task. Each task records its objective,
  scope, acceptance criteria, decisions, checks, progress and next step.
- Split substantial tasks into meaningful work packages. Execute one package at
  a time; the owner controls sequencing and explicitly starts each next package.
  Completing a package does not authorize starting the next. Keep the task index
  consistent with the detailed record.
- Use `open`, `in-progress`, `blocked`, `done` and `cancelled`. Mark work done only
  when its deliverables and acceptance criteria are met. Record concrete blockers
  and material decisions before dependent implementation.
- A TODO does not authorize product-contract changes, engineering/runtime access
  or publication. Resolve actual questions with the owner while continuing
  independent work within scope.
- Keep temporary scripts, exports and probes under ignored `.tmp/`; generated
  packaging and release inputs belong under ignored `artifacts/`. Verify exclusion
  before writing local-only content. Never force-add task records or evidence.
- If the local store is missing, recreate its index and template when needed and
  report the missing history. Do not infer completion from absent records.

## Product orientation

Before relevant product work, inspect the available owning documents:

1. `README.md` and `LICENSE`.
2. `docs/framework-architecture.md`, the framework model and relevant guides under
   `docs/authoring/`, and the responsible documents under `contracts/`.
3. `docs/library-usage.md`, `docs/project-use.md`,
   `docs/selftest-coverage.md` and `docs/help.md` as relevant.
4. `skills/s7unittest-framework-authoring/SKILL.md` for framework test authoring,
   and `tools/scl/README.md` when using the indentation utility.

These are expected product paths, not a claim that the first import has happened.
Report missing inputs rather than inventing APIs, build commands or evidence.

## Snapshot integration

- Use the prepared revision-pinned product exporter and supplied artifact manifest.
  Export into a fresh temporary directory, inspect it, then import selected files.
  Never aim the exporter at the populated repository root.
- Verify the exact source revision, input/output paths, file sets, hashes,
  component versions and artifact provenance. Distinguish producer history from
  the public receiving commit; do not fabricate history or alter manifest hashes.
- Present a concrete import/removal/retention plan before overwriting or deleting
  existing content unless that scope is already authorized. Preserve this workflow,
  public adaptations, branding, hosting configuration and local task records.
- Record deliberate receiving-side adaptations so future imports can reconcile
  them. Distinguish presentation changes from framework changes requiring source
  reconciliation. Preserve licensing and author attribution.
- Import the public documentation projections, not mixed development documents.
  Keep the architecture, Authoring Guides, contracts and useful integration
  guidance complete; do not replace technical content with summaries.
- Use the complete validated standalone Authoring bundle. A raw skill source
  directory is insufficient. Required bundled SCL references remain product
  dependencies even when their provenance includes `engineering-skill/`.
  This does not authorize shipping a separate Engineering skill or its tooling.
- Ship only the selected public SCL indentation utility and its documented test.
  Do not import internal exporters, library/help builders, evaluation projects,
  MCP tooling or development session infrastructure.
- Keep raw transfer evidence and producer details in ignored local storage.
  Publish only reviewed provenance appropriate to the public source association.
- Review public content for private machine paths, hostnames, credentials,
  internal task references, missing dependencies and broken navigation. Use actual
  public URLs; do not invent release links or badges.

## Framework and engineering boundaries

- Preserve the documented Run Control, Suite and Test Case hierarchy. Test Cases
  use Preparations, Test States and Assertions; sequencers and orchestrators
  provide the documented lifecycle and collection behavior at their own levels.
  Do not import another framework's inheritance model by analogy.
- Respect cyclic execution, state ownership, timeout/reset behavior, result
  semantics and the independent event/acknowledgement path. Consult the contracts
  rather than treating a completion bit alone as evidence of valid results.
- Native library delivery consists of mastercopies, not automatically
  version-bound library types. Describe selective copying, instance creation and
  application integration according to the user documentation.
- Agree material architecture, contract, interface or behavior changes with the
  owner. Routine implementation choices within approved scope need no repeated
  approval. Update owning documentation for approved changes.
- TIA archives are product inputs, not files to unpack, rewrite or regenerate
  casually. Publication work does not authorize TIA session changes, compilation,
  library rebuilding or changes in the development repository.
- Engineering operations and runtime actions require authorization for the
  concrete operation and target. This includes downloads, online control,
  configuration changes, restarts and global library installation. Do not disturb
  other sessions or compete with another event consumer for acknowledgement.

## Files, artifacts and verification

- Follow `.gitattributes`; use CRLF for repository text by default. Prefer Windows
  and PowerShell-compatible commands. Inspect required tool versions before use.
- Agree exact binary paths and storage before staging binaries. Use narrow LFS
  rules only for agreed versioned files. Native libraries, help ZIPs and packaged
  skill ZIPs are intended release assets; the unpacked skill remains public content.
  Do not copy broad LFS rules from the development repository automatically.
- Preserve transferred archive and manifest bytes. Reconcile affected artifacts
  after relevant public-side product changes; do not claim stale artifacts match
  modified source without evidence.
- Run checks appropriate to the change. Review documentation text and links;
  run `git diff --check`. Use the supplied focused checks for affected tools or
  skill content when relevant. Avoid unnecessary rebuilds and duplicate tests.
- Distinguish inherited evidence, newly executed offline checks, native TIA
  compilation and runtime observations. Record missing prerequisites and checks
  not executed. A successful export is not native or runtime qualification.
- Report archive-inspection limits honestly. The exporter copies the project
  archive by hash without inspecting its contents; supported library containers
  may retain declared opaque entries. Do not claim a full internal-content audit.
- Keep raw logs and verification output local. For publication, reconcile exact
  tags, versions, asset hashes and public source association; independently verify
  downloaded assets and the intended Latest release after authorized publication.

## Documentation and handoff

- Use English for repository content, comments, commit messages and local task
  records. Conversation with the owner may be in German.
- Keep durable product decisions in the owning documentation. Keep sequencing,
  temporary analysis and progress in the local store. This file defines stable
  rules rather than the current publication plan.
- Public documentation must work independently of private repositories and local
  task IDs. Introduce the framework concisely with concrete technical benefits;
  present the optional Authoring skill as a feature, not the primary product.
- At handoff, update the active task and `.local-work/README.md` with branch,
  changes, checks, limitations, open decisions and next step. Report Git status.
- For analysis-only requests, do not edit files. For action requests, complete
  authorized work and report the result without silently publishing it.
