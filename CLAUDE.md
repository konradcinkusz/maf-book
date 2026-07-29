# CLAUDE.md — working on this book

Context for continuing *Microsoft Agent Framework for .NET Engineers*.
Read this before touching a chapter.

---

## Status

| | Done | Remaining |
|---|---|---|
| Front matter | Title page, Introduction | — |
| Chapters | 1, 2, 3, 4, 5, 6, **7** | 8, 9, 10, 11, 12 |
| Appendices | A, B, C, D | — |

Build is clean: `latexmk -pdf main.tex`, 180 pages, zero unresolved references.
Every unwritten chapter already exists as a stub with a section outline and
compiles as part of the book, so the PDF is always whole.

**Debt ledgers, reported by CI on every build:**
- 19 screenshots outstanding (`make shots`)
- 16 `verifybox` blocks
- **Appendix B's benchmark tables are still empty** — Chapter 7 specifies the
  experiment and deliberately reports no results. See item 7 below.

Overfull hboxes: **40**. Chapters 5 and 6 added none (6 removed a pre-existing
one); Chapter 7 added two, both in Appendix D's manifest and both under 6 pt,
which is smaller than the entries already there. Check any new chapter the same
way: build once with the chapter stubbed out, once with it in, and diff the
`Overfull` lists. Attributing boxes by reading `main.log` nesting does not work.

Note that long `\code{}` identifiers inside `\needscreenshot` instruction text
land in Appendix D's narrow manifest column and overflow badly there — one such
line cost 81 pt. Write screenshot instructions in prose, naming APIs in words
rather than in `\code{}`.

---

## Non-negotiable conventions

**Verify before writing.** Every chapter so far has been written *after* searching
the current docs and NuGet, and every one of them turned up something that
contradicted prior assumptions. Do not write API surface from memory. Sources, in
order of authority:

1. `nuget.org/profiles/MicrosoftAgentFramework` — package names and versions
2. `learn.microsoft.com/en-us/agent-framework/` — current API
3. `github.com/microsoft/agent-framework` `dotnet/samples/` — working code
4. `devblogs.microsoft.com/agent-framework/` — features and rationale

> **Network note (added Chapter 4).** In the Claude Code web sandbox,
> `learn.microsoft.com` and `devblogs.microsoft.com` are blocked by egress policy,
> and `api.github.com` requires `add_repo`. What *does* work, and is strictly more
> authoritative than either: shallow-clone the upstream repo and read the source.
> ```
> git clone --depth 1 --filter=blob:none https://github.com/microsoft/agent-framework.git
> ```
> `api.nuget.org` is also reachable, so shipped package contents can be checked
> directly — download the `.nupkg`, unzip, and read the generated XML doc file in
> `lib/net10.0/`. That is how the naming question below was settled definitively
> rather than by inference from documentation.

**Mark what you have not compiled.** Wrap it in `\begin{verifybox}`. Nothing ships
to a reader with one attached. Removing a verifybox means the listing compiled —
not that it was reread and felt right.

**Versions live in `preamble.tex` only** (`\mafcore`, `\mafext`). Never write a
version number into a chapter.

**ASCII inside listings.** No em-dashes or smart quotes in `csharp`, `xmlcode`,
`shellcmd`, `yamlcode`. `listings` cannot handle multi-byte UTF-8 in verbatim
mode. The preamble maps common offenders, but ASCII is safer.

**Screenshots** via `\needscreenshot{key}{caption}{precise capture instructions}`.
A placeholder prints until `figures/screenshots/key.png` exists. Two to four per
chapter, each teaching something — no decoration.

**Voice.** British English, second person, senior audience. The book is allowed
to say the framework is the wrong tool, that documentation is stale, and that the
author has not verified something. No marketing register.

**Prefer measurements to assertions.** The differentiator is original data. A
claim about what is faster or more reliable needs a method and a number, or an
explicit label as judgement.

**Watch the margin.** The page is 17 cm wide and `\code{}` / `\api{}` / `\pkg{}`
do not hyphenate, so a long identifier at a line break produces an overfull hbox
that visibly runs into the margin. Reword, or move long identifier lists into a
displayed `itemize` or table. Check with `grep 'Overfull' main.log` after a build.
Aim for nothing over ~15 pt. Appendix A is the worst offender in the book (58
boxes) and is worth a cleanup pass at some point.

---

## Open questions — RESOLVED (Chapter 4 pass, July 2026)

All three were settled against the upstream source at `microsoft/agent-framework`
`main`, and cross-checked against the shipped `.nupkg` at `\mafcore`.

**1. `AgentThread` vs `AgentSession` — RESOLVED: `AgentSession`.**

`AgentThread` does not exist in the shipped package. Verified by unzipping
`Microsoft.Agents.AI.Abstractions` at both 1.10.0 (the book's pinned `\mafcore`)
and 1.15.0 and grepping the generated XML docs: 127 occurrences of `AgentSession`,
zero of `AgentThread`, zero of `AgentRunResponse`, zero of `ChatMessageStore`.
The upstream changelog records `[BREAKING] Renamed AgentThread to AgentSession`
(PR #3430), completed before 1.0.

The current vocabulary:

| Old | Current |
|---|---|
| `AgentThread` | `AgentSession` |
| `agent.GetNewThread()` | `await agent.CreateSessionAsync()` |
| `thread.Serialize()` | `await agent.SerializeSessionAsync(session)` |
| `agent.DeserializeThread(json)` | `await agent.DeserializeSessionAsync(json)` |
| `AgentRunResponse` | `AgentResponse` |

Note that serialisation **moved from the session to the agent and became async**.
That is a second change beyond the rename and it is easy to miss.

Swept through Chapters 1, 2, 3 and Appendices B and C. Labels renamed:
`sec:threads` → `sec:sessions`, `lst:thread-*` → `lst:session-*`, screenshot key
`vs-debugger-agentthread-watch` → `vs-debugger-agentsession-watch`. Both
verifyboxes deleted.

**2. `AsAIAgent` vs `CreateAIAgent` — RESOLVED: `AsAIAgent`.**

373 occurrences to 3 across `dotnet/src` and `dotnet/samples`. Swept; the
verifybox in Chapter 2 is now a note recording that `CreateAIAgent` predates the
rename.

**3. `McpClient.CreateAsync` vs `McpClientFactory.CreateAsync` — RESOLVED:
`McpClient.CreateAsync`,** with transport options as an object initialiser. 16
occurrences to 0 in upstream samples. Chapter 3 §3.6 verifybox deleted.

---

## Workflow API — RESOLVED (Chapter 5 pass, July 2026)

Verified by reading `dotnet/src/Microsoft.Agents.AI.Workflows/` and
`.Workflows.Generators/` plus `dotnet/samples/03-workflows/` at `main`. Several
things differ from what the Chapter 5 brief assumed; all of them are now written
into the chapter and are reusable by Chapters 6, 7 and 8.

**Builder methods take `ExecutorBinding`, not `Executor`.** `ExecutorBinding` has
implicit conversions from `Executor`, `AIAgent`, `RequestPort` and `string` (a
placeholder bound later). *That* is the mechanism behind "an agent is an executor;
so is a function" — it is not a metaphor, it is four `implicit operator`
declarations. Chapter 7 should lean on this: the four orchestration patterns are
builders over the same binding type.

**Executor routing is configured through `ProtocolBuilder` / `ConfigureProtocol`,**
not the older `RouteBuilder` / `ConfigureRoutes` (`RouteBuilder` still exists,
reachable via `ProtocolBuilder.ConfigureRoutes`). Base types are `Executor`,
`Executor<TIn>` and `Executor<TIn,TOut>`; the handler is
`HandleAsync(msg, IWorkflowContext, CancellationToken)`.

**Type mismatch on an edge is a silent drop.** No exception, no warning event.
The only evidence is an OTel tag on the edge span, whose values are `delivered`,
`dropped type mismatch`, `dropped target mismatch`, `dropped condition false`,
`exception`, `buffered` (`Observability/EdgeRunnerDeliveryStatus.cs`). Chapter 8
owes a worked "find the dropped delivery in the trace" section — Chapter 5 §5.3
promises it.

**`Build()` validates reachability only.** The source carries a long comment
setting out four honest reasons why edge type-compatibility cannot be checked at
build time, the binding one being that executors may come from async factories
while `Build()` must stay synchronous for DI. Quoted in substance in §5.3; worth
re-reading before writing anything that claims the framework validates graphs.

**Routing matches the runtime type exactly**, via `message.GetType()`. An
interface-typed handler never fires. Agent nodes emit `List<ChatMessage>`, so
downstream executors must declare that, not `IEnumerable<ChatMessage>`.

**Agents need a `TurnToken`.** They accumulate `ChatMessage`s and only take a turn
on receiving `TurnToken`. Every executor→agent edge therefore needs an adapter
sending both, declared with `[SendsMessage(typeof(...))]`.

**The source generators are real and undocumented elsewhere.** `[MessageHandler]`
on methods of a `partial` executor; seven diagnostics `MAFGENWF001`–`MAFGENWF007`
(missing `IWorkflowContext`, bad return type, not `partial`, not an `Executor`,
too few parameters, `ConfigureProtocol` already defined, `static` handler). The
generator package is `<DevelopmentDependency>true</DevelopmentDependency>` and is
packed to `analyzers/dotnet/cs`; upstream samples reference it explicitly as an
analyzer *in addition to* the Workflows package, which suggests it does not flow
transitively. **Not confirmed from a clean project — this is the one open
verifybox in §5.6.**

**Execution:** `InProcessExecution.RunAsync` / `RunStreamingAsync` /
`OpenStreamingAsync` / `ResumeAsync`, with environments `OffThread` (default),
`Lockstep` and `Concurrent`. `Lockstep` is the one for tests.

**Supersteps.** Messages sent during a step are delivered in the next one; state
goes through `QueueStateUpdateAsync` and is applied at the boundary. The boundary
is the checkpoint point — which is the setup Chapter 6 pays off.

**`workflow.ToMermaidString()` / `.ToDotString()`** exist
(`Visualization/WorkflowVisualizer.cs`). Cheap and worth using in later chapters.

---

## Durability API — RESOLVED (Chapter 6 pass, July 2026)

Verified against `Microsoft.Agents.AI.Workflows/Checkpointing/`,
`Microsoft.Agents.AI.Workflows.Declarative/`, and the `Checkpoint/`,
`HumanInTheLoop/` and `Declarative/` sample folders at `main`. **Two of the
Chapter 6 brief's assumptions were wrong** — see item 5 above for the checkpoint
type names, and below for the declarative format.

**Checkpointing is automatic once a manager is passed.** `RunStreamingAsync(workflow,
input, checkpointManager)` — one checkpoint per superstep, collected from
`SuperStepCompletedEvent.CompletionInfo.Checkpoint`. `CheckpointInfo` is just
`(SessionId, CheckpointId)`, so it is cheap to persist and hand to another process.

**Restore ≠ rehydrate.** `run.RestoreCheckpointAsync(info)` rewinds an existing
run in place; `InProcessExecution.ResumeStreamingAsync(freshWorkflow, info, manager)`
continues on a newly built graph in a process that never saw the original. Only
the second is durability. It requires graph construction to be a repeatable pure
function — which is why every upstream sample has a `WorkflowFactory.BuildWorkflow()`.

**What a checkpoint holds** (internal `Checkpoint` class): step number,
`WorkflowInfo`, `RunnerStateData`, scoped `StateData`, `EdgeStateData`, and a
`Parent` pointer. Executor instance fields are *not* in it. Checkpoints form a
**tree**, not a list — the parent pointer plus parent-filtered index means you can
replay from one point twice and keep both branches.

**Custom stores have an ordering contract.** `ICheckpointStore<T>.RetrieveIndexAsync`
must return oldest-first; `CheckpointManager` takes the last element as the latest.
An unordered store resumes the wrong checkpoint silently. Documented in the
interface's own remarks. Worth a test.

**AOT:** `CheckpointManager.CreateJson(store, options)` — the options argument is
what makes it work under disabled reflection. Sample: `Declarative/AotCheckpointing`.

**HITL:** `RequestPort.Create<TReq,TResp>(id)`; the port is an `ExecutorBinding`
like anything else. Emits `RequestInfoEvent` → `ExternalRequest`; answer with
`run.SendResponseAsync(request.CreateResponse(decision))`. Build the response
*from the request* — it carries the request id used to match concurrent asks.
**One interaction = two supersteps = two checkpoints**, and the checkpoint after
the request is a complete description of a workflow waiting for a person.

**Declarative workflows are NOT the builder graph in YAML.** This is the brief's
biggest error. The format is `kind: Workflow` + a trigger + a list of *actions*,
with `ConditionGroup`/`GotoAction` control flow and Power Fx expressions
(`=System.LastMessage.Text`, `Local.Foo`) — i.e. Copilot Studio's conversational
authoring model, compiled onto the same runtime via
`DeclarativeWorkflowBuilder.Build<TInput>(path, options)`. Action kinds seen in
samples: `SetVariable`, `SetTextVariable`, `ConditionGroup`, `GotoAction`,
`EndWorkflow`, `Question`, `SendActivity`, `SendMessage`, `CreateConversation`,
`RequestExternalInput`, `InvokeAzureAgent`, `InvokeMcpTool`, `InvokeFunctionTool`,
`HttpRequestAction`. `DeclarativeWorkflowOptions` carries `IMcpToolHandler` and
`IHttpRequestHandler` — the sandboxing seam.

**`StatefulExecutor<TState>` exists** and is the right answer to instance-field
state; it wraps read/cache/queued-write across checkpoints. Prefer it to raw
`OnCheckpointingAsync` / `OnCheckpointRestoredAsync`, which must be implemented as
a matched pair. `IResettableExecutor` is about *reuse* of shared instances, not
durability — do not conflate them.

**Nice upstream contrast to reuse:** `HumanInTheLoop/HumanInTheLoopBasic` and
`Checkpoint/CheckpointWithHumanInTheLoop` contain the same `JudgeExecutor` with the
same `_tries` counter, and only the checkpointed one has the hooks. Chapter 6 §6.2
uses this; Chapter 9 could use it as an evaluation-regression example.

---

## Orchestration API — RESOLVED (Chapter 7 pass, July 2026)

Verified against the orchestration builders and `Specialized/` in
`Microsoft.Agents.AI.Workflows`, plus `samples/03-workflows/_StartHere/03_*` and
`Orchestration/`. The brief was right about the four patterns and **missed a
fifth**.

**The "conveniences over the graph" claim is provable, not rhetorical.**
`SequentialWorkflowBuilder.Build()` constructs `new WorkflowBuilder(previous)` and
calls `AddEdge` in a loop; `ConcurrentWorkflowBuilder.Build()` calls
`AddFanOutEdge` then `AddFanInBarrierEdge`. Chapter 7 §7.1 cites this directly.
All five derive from `OrchestrationBuilderBase<TBuilder>`, which supplies
`WithName`, `WithDescription`, `WithOutputFrom`, `WithIntermediateOutputFrom`.

**Entry points** are all static on `AgentWorkflowBuilder`: `BuildSequential`,
`BuildConcurrent`, `CreateSequentialBuilderWith`, `CreateConcurrentBuilderWith`,
`CreateGroupChatBuilderWith(managerFactory)`, `CreateHandoffBuilderWith(agent)`,
`CreateMagenticBuilderWith(managerAgent)`.

**Handoff is richer than the brief suggested.** Transfers are injected tools with
the prefix `handoff_to_`. The tool description the model routes on is derived from
the target agent's `Description`, then `Name`, then `Instructions` — and
`WithHandoff` **throws** if all three are absent. A vague description does not
throw and degrades routing silently. Also present: `HandoffToolCallFilteringBehavior`
(`None` / `HandoffOnly` / `All`, and `HandoffOnly` is what people want but is not
the default), `EnableReturnToPrevious`, `WithAutonomousMode(turnLimit,
continuationPrompt, per-agent overrides)`, `WithTerminationCondition` (sync and
async), and `AddParticipants` — which, with no explicit handoffs declared, wires
every agent to every other agent.

**`GroupChatManager` is abstract**; the only required member is
`SelectNextAgentAsync`. It tracks `IterationCount` / `MaximumIterationCount`, and
has its own checkpointing hooks whose state keys are auto-prefixed
`GroupChatManager_` to isolate subclass state. A custom manager holding state must
use those hooks to survive a resume — same rule as Chapter 6 §6.2.
`RoundRobinGroupChatManager` is the only in-box implementation.

**Magentic is the fifth pattern and earned its own section (§7.6).** Manager agent
plus participants; `WithMaxRounds`, `WithMaxStalls`, `WithMaxResets`,
`RequirePlanSignoff`, `WithResponseLanguage`, `WithPromptOverrides`. It maintains
a `MagenticProgressLedger` (`IsRequestSatisfied`, `IsInLoop`, `IsProgressBeingMade`,
`NextSpeaker`, `InstructionOrQuestion`) — i.e. it distinguishes a round that made
no progress from one that merely took time, which no other pattern does. Emits
`MagenticPlanCreatedEvent` and `MagenticReplannedEvent`; lives in namespace
`Microsoft.Agents.AI.Workflows.Specialized.Magentic`. Prompts are English by
default and overridable via `MagenticDefaultPrompts` templates. **Plan sign-off is
a request port**, so it checkpoints and resumes like any Chapter 6 HITL gate.

**For the benchmark:** `UsageContent` / `UsageDetails` flow through messages and
`MessageMerger` merges them, so per-run token accounting is reachable from the
event stream. Turn count comes from `ExecutorInvokedEvent`.

---

## Open questions — NEW, unresolved

**4. `\mafcore` is behind. The core train is now 1.15.0** (published 22 July 2026);
`preamble.tex` still pins 1.10.0 and `\mafdate` says July 2026. Nothing written so
far is *wrong* because of this — the session naming was verified to hold at 1.10.0
too — but Appendix A's train table, dates and contents are a dated snapshot that
is now two trains stale.

Deliberately **not** bumped during the Chapter 4 pass, because changing `\mafcore`
invalidates Appendix A's whole table plus Chapter 1's timeline, and that is a
sweep of its own. Do it as a dedicated pass, not as a side effect of a chapter.

**5. `CheckpointStore` — RESOLVED in the Chapter 6 pass, and the Chapter 4 note
was itself half wrong.** It is `ICheckpointStore<TStoreObject>`, **generic**, not
`ICheckpointStore`. Corrections to what was previously written here:

- `JsonCheckpointStore` is an **abstract base class** (`ICheckpointStore<JsonElement>`),
  not a usable in-box store. `FileSystemJsonCheckpointStore` is the only concrete
  in-box implementation.
- `ICheckpointManager` and `InMemoryCheckpointManager` are **`internal`**. Do not
  name them to a reader. The public surface is the sealed `CheckpointManager`
  with `CreateInMemory()`, `CreateJson(store, options?)` and `Default`.

Chapter 6 §6.1 is written against the corrected surface. **Appendix A still needs
fixing** — fold this into the version-bump pass (item 4).

**6. New packages not in Appendix A.** `Microsoft.Agents.AI.Mem0`,
`Microsoft.Agents.AI.Valkey`, `Microsoft.Agents.AI.Mcp`,
`Microsoft.Agents.AI.LocalCodeAct`, `Microsoft.Agents.AI.Tools.Shell`,
`Microsoft.Agents.AI.Hosting.AspNetCore`,
`Microsoft.Agents.AI.Workflows.Declarative.Foundry` and
`.Workflows.Declarative.Mcp` all exist upstream and are absent from the appendix.
Fold in during the version-bump pass (item 4).

**7. The orchestration benchmark has not been run. This is now the book's biggest
outstanding debt.** Chapter 7 §7.7 fully specifies the experiment — one fixed task
with a checkable answer, five implementations with model/temperature/instructions
/tools held constant, four metrics (turn count, token cost, latency, success
rate), ≥20 runs per pattern, medians and spreads rather than best runs — and
reports **no results**, saying so in a warning box. Appendix B's tables are empty
and must stay empty until the runs happen.

This is the strongest external-publication material in the book and nobody has
published it well for 1.0. It needs an Azure/OpenAI budget and a few hours, not
more research. **Keep the raw event streams, not just the summary rows:**
Chapter 9 re-scores the same runs under an evaluation harness and Chapter 12
compares topologies empirically, and re-running to recover traces is expensive.

Until it is run, no comparative performance claim anywhere in the book may be
stated as fact. Chapter 7 labels all of its as judgement; keep that discipline.

---

## Remaining chapters

Each stub already has `\section` headings. Expand, don't restructure, unless the
verification pass says the structure is wrong.

### Chapter 8 — Middleware and Observability
**Angle:** the framework tells you what happened, not whether it was any good.
That gap is the thesis of the capstone.

**Already verified:** `OpenTelemetryAgent` as an automatic tracing decorator;
OTel GenAI semantic conventions; `Microsoft.Agents.AI.DevUI`;
`Aspire.Hosting.AgentFramework.DevUI`.

**Owed from Chapter 4:** §4.5 promises this chapter wires up the compaction
activity source. The attributes are real and already documented there —
`compaction.strategy`, `compaction.triggered`, `compaction.before.tokens` /
`after.tokens`, `.before.messages` / `.after.messages`, `compaction.duration_ms`,
plus `compaction.groups_summarized` and `compaction.summary_length` on the
summarisation path. Source: `Microsoft.Agents.AI/Compaction/CompactionTelemetry.cs`.

**Owed from Chapter 5:** §5.3 tells the reader that a workflow producing no output
is usually a silently dropped message, and that the way to find it is to look for
edge spans whose delivery status is not `delivered`. It names this chapter. Cover
the workflow activity source alongside the agent one, and show the actual span
tree for a fan-out/fan-in run — `OpenTelemetryWorkflowBuilderExtensions` and
`Observability/` in the Workflows package are the starting points.

**Verify:** the three middleware levels (agent, function, chat client) and their
registration; which spans and attributes are actually emitted.

**Build:** custom middleware computing a per-turn quality score attached as a span
attribute. Then the gap analysis: what MAF measures vs what it does not.

**Screenshots:** Aspire dashboard trace waterfall for a multi-agent run; DevUI
inspecting an agent. Both non-VS.

---

### Chapter 9 — Evaluation
**Angle:** how you find out yesterday's prompt change made things worse.

**Verify:** `Microsoft.Extensions.AI.Evaluation` API; Foundry evaluations. Note
there is now a `Microsoft.Agents.AI/Evaluation/` folder in the core package —
check what is in it before assuming evaluation lives entirely in the extensions.

**Reuse:** run the Chapter 7 benchmark under a scoring harness. Cover building an
evaluation set from production traces, and where regression gates belong in CI —
including the flakiness problem, which is the reason most teams abandon them.

**Owed from Chapter 7:** §7.7 states plainly that its binary correctness score is
not a quality measure, and names this chapter as the place that gap gets closed.
It also tells the reader to keep the raw event streams for exactly this purpose.
There is a `Microsoft.Agents.AI.Workflows/Evaluation/` folder as well as the core
package one — check both. Note also that §7.7's "report distributions, not best
runs" discipline is the same problem as evaluation flakiness, one chapter early;
the two sections should agree with each other.

---

### Chapter 10 — Hosting, Durability and A2A
**Already verified:** `Microsoft.Agents.AI.DurableTask`;
`Hosting.AzureFunctions`; `Foundry.Hosting`; `Microsoft.Agents.AI.A2A` +
`Hosting.A2A` + `Hosting.A2A.AspNetCore`; `AGUI` packages; Foundry hosted agents
wire up via `builder.Services.AddFoundryResponses(agent)` and
`app.MapFoundryResponses()`; scale-to-zero with filesystem intact, per-session
VM-isolated sandboxes.

**Make the distinction explicit:** durable extension = durability of the *host*;
workflow checkpointing = durability of the *graph*. Different problems.

**Owed from Chapter 6:** §6.2 exercise 4 sends the reader here for the cold-start
number and says rehydration cost must be measured separately before the hosting
claim can be judged. Chapter 6 also notes that pointing the file-system checkpoint
store at a mounted volume is what makes a run survive the container — the
scale-to-zero story has to be consistent with that. There is also
`WorkflowHostingExtensions.AsAIAgent(Workflow, ...)`: a workflow can be hosted as
an agent, which is the natural bridge from Chapter 6 into this chapter.

**Build:** Aspire AppHost (agent + Postgres + OTLP collector + Blazor); a .NET
agent delegating to a Python agent over A2A — few people will have built this and
it demos extremely well; measure cold start after scale-to-zero.

**Note:** this is the one chapter that legitimately requires an Azure
subscription. Say so at the top.

---

### Chapter 11 — The Agent Harness
**Already verified:** `Microsoft.Agents.AI.Harness` provides `HarnessAgent`;
`chatClient.AsHarnessAgent(maxContextTokens, maxOutputTokens,
new HarnessAgentOptions {...})`; `FileSystemAgentFileStore`;
`HarnessConsole.RunAgentAsync`. Built-in providers: `FileMemoryProvider`,
`FileAccessProvider`, `TodoProvider`, `AgentModeProvider` (plan vs execute),
`AgentSkillsProvider`, `BackgroundAgentsProvider`, hosted web search, sandboxed
`ShellExecutor` (.NET only). Middleware: `ToolApprovalAgent`,
`OpenTelemetryAgent`. Pluggable `AgentFileStore` backends. There is also a
`Microsoft.Agents.AI/Harness/` folder in the core package — check the split.

**Correction already applied to Chapter 1:** CodeAct is **not Python-only** —
`Microsoft.Agents.AI.Hyperlight` exists for .NET, and there is now a
`Microsoft.Agents.AI.LocalCodeAct` as well. Benchmark from the BUILD post:
27.81s → 13.23s, 6,890 → 2,489 tokens on a multi-step workload.

**The honest section:** what the harness means for third-party agent cockpits.
The overlap with AgentHelm is substantial and should be stated plainly rather than
avoided.

---

### Chapter 12 — Capstone
No new API surface. One system using everything prior: ingest MAF GenAI traces,
score workflow-run quality, compare orchestration topologies empirically, surface
wasted turns. End with what v1 deliberately leaves out.

---

## After each chapter

1. `latexmk -pdf main.tex` — must be zero errors, zero unresolved refs
2. `make shots` — confirm new screenshot requests are registered
3. Update `docs/index.html`: flip that chapter's `class="todo"` to `class="done"`
4. Update the Status table at the top of this file
5. Tag if it is a meaningful milestone: `git tag -a v0.4.0 -m "Chapter 4"`

Appendix B's measurement tables stay empty until the experiments are actually run.
Do not fill them with plausible numbers.
