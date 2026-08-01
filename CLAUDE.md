# CLAUDE.md — working on this book

Context for continuing *Microsoft Agent Framework for .NET Engineers*.
Read this before touching a chapter.

---

## Status

| | Done | Remaining |
|---|---|---|
| Front matter | Title page, Introduction | — |
| Chapters | **1–12, all drafted** | — |
| Appendices | A, B, C, D | — |

Build is clean: `latexmk -pdf main.tex`, 248 pages, zero unresolved references.

**A full draft exists.** Every chapter and appendix is written. What remains is
not drafting but the debt below — two unrun experiments, the screenshots, the
verifyboxes, and one section only the author can finish.

**Debt ledgers, reported by CI on every build:**
- 27 screenshots outstanding (`make shots`)
- 23 `verifybox` blocks
- **Two unrun experiments, both fully specified, neither reporting results:**
  the orchestration benchmark (Ch. 7 §7.7, scored by Ch. 9 §9.5) and the
  cold-start measurement (Ch. 10 §10.5.3, owed to Ch. 6 §6.2). See item 7 below.
- **Ch. 11 §11.6's conflict-of-interest disclosure needs the author's review** —
  written generically because only the author knows the specifics. See item 8.

Overfull hboxes: **43**, and zero overfull vboxes. The consistency, index and
version-bump passes added none of either; the last two each removed one.
Check any change the same way: build once with it reverted, once
with it in, and diff the `Overfull` lists — comparing the *multiset of sizes*,
because line numbers shift and make a plain `diff` of the log noisy. Attributing
boxes by reading `main.log` nesting does not work.

**Count vboxes too.** `grep -c 'Overfull' main.log` lumps hbox and vbox together.
An overfull **vbox** means a `center`+`tabularx` block grew past a page — those
cannot break, so a long table plus adjacent admonitions overflows by hundreds of
points. The fix is to split the table into subsections, not to shrink the text.
A long `\pkg{}` name in a natural-width first column also squeezes the `X`
description column badly; move such rows into a displayed list instead.

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

**Versions live in `preamble.tex` only** — `\mafcore`, `\mafpreview`,
`\mafalpha`, `\mafdateexact`. Never write a version number into a chapter. The
one listing that needs a literal version (Chapter 2's CPM props) reaches the
macro through `escapeinside={(*@}{@*)}` rather than hardcoding it.

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

## Observability API — RESOLVED (Chapter 8 pass, July 2026)

Verified against `Microsoft.Agents.AI` (`AIAgentBuilder`, `OpenTelemetryAgent`,
`OpenTelemetryConsts`, `Compaction/CompactionTelemetry`) and the
`Observability/` folder of `Microsoft.Agents.AI.Workflows`.

**Middleware is the decorator pattern, not a bespoke abstraction.**
`AIAgentBuilder` + `DelegatingAIAgent`; `.Use(...)` overloads build an internal
`AnonymousDelegatingAIAgent`. In-box decorators: `UseOpenTelemetry`, `UseLogging`,
`UseAIContextProviders`, and the function-invocation `Use` overload.

**Function-level middleware requires a `FunctionInvokingChatClient` in the
pipeline** or the agent **throws at invoke time, not build time**. Documented in
the extension's own remarks. Written up as a warning in §8.1.

**Two activity source names, and both must be registered:**

| Emitter | Source name |
|---|---|
| Agents, chat clients, compaction | `Experimental.Microsoft.Agents.AI` |
| Workflows | `Microsoft.Agents.AI.Workflows` |

Register one and you get half a trace with no error. The `Experimental.` prefix is
a stability warning — do not hard-code it in startup, and expect it to change.

**Workflow spans:** `workflow.build`, `workflow.session`, `workflow_invoke`,
`executor.process`, `edge_group.process`, `message.send`. Events: `build.started`
/ `build.validation_completed` / `build.completed` / `build.error`, `session.*`,
`workflow.*`.

**The dropped-delivery query — this is the Chapter 5 §5.3 IOU, now paid.** Every
delivery attempt emits an `edge_group.process` span tagged
`edge_group.delivered` (bool) and `edge_group.delivery_status` (the string values
from the Chapter 5 notes). Filter `delivered = false` and the silent drop is one
query instead of an afternoon.

**Executor spans are SIBLINGS, not nested.** The source says so and explains why:
causality between executors is expressed with span **links**, because a superstep
runs its executors independently and nesting would misrepresent a fan-out. Most
viewers render links poorly, so the default view of a workflow trace hides the
causality. This contradicted the stub's "trace waterfall" framing and §8.4 was
written against the corrected model — **worth remembering for Chapter 12**, which
ingests these traces.

**Compaction telemetry (Chapter 4 §4.5's IOU, paid).** Activities
`compaction.compact`, `compaction.provider.invoke`, `compaction.summarize`. Tags
are the ones the Chapter 8 brief listed **plus** `compaction.compacted`,
`compaction.before.groups`, `compaction.after.groups`. The pair worth alerting on
is `triggered` vs `compacted`.

**Sensitive data is off by default** on both `OpenTelemetryAgent.EnableSensitiveData`
and `WorkflowTelemetryOptions.EnableSensitiveData`. The workflow options also carry
`DisableWorkflowBuild` / `DisableWorkflowRun` / `DisableExecutorProcess` /
`DisableEdgeGroupProcess` / `DisableMessageSend` for volume control — but disabling
edge spans disables the dropped-delivery query above.

**DevUI:** `builder.AddDevUI()` + `app.MapDevUI()`. **Loopback-only by default**,
with `DevUIOptions.AllowRemoteAccess`, a bearer token via options or the
`DEVUI_AUTH_TOKEN` environment variable, and a startup warning if insecurely
exposed.

---

## Evaluation API — RESOLVED (Chapter 9 pass, July 2026)

Verified against `Microsoft.Agents.AI/Evaluation/`,
`Microsoft.Agents.AI.Workflows/Evaluation/`,
`Microsoft.Agents.AI.Foundry/Evaluation/`, and the evaluation samples under
`samples/02-agents/`, `samples/03-workflows/` and `samples/05-end-to-end/`.

**The brief was wrong about where evaluation lives.** It is NOT mainly
`Microsoft.Extensions.AI.Evaluation`. The **core** package owns the abstraction:
`IAgentEvaluator` (batch: items in, `AgentEvaluationResults` out) plus
`AgentEvaluationExtensions.EvaluateAsync` on `AIAgent`. MEAI is adapted in via an
internal `MeaiEvaluatorAdapter`. §9.2 is written this way; the stub's heading
"Microsoft.Extensions.AI.Evaluation" was renamed to "The evaluation surface".

**Three implementations of one interface, forming a cost ladder:**

| Tier | Type | Cost |
|---|---|---|
| Local checks | `LocalEvaluator(params EvalCheck[])` | free, deterministic |
| Judge model | MEAI `IEvaluator` + `ChatConfiguration` | model calls |
| Hosted | `FoundryEvals : IAgentEvaluator` | server-side job + report URL |

**`EvalCheck` is just `delegate EvalCheckResult EvalCheck(EvalItem item)`.** Custom
checks are one-liners via `FunctionEvaluator.Create(name, (string response) => bool)`.
In-box: `KeywordCheck`, `NonEmpty`, `ContainsExpected`, `ToolCalledCheck`
(with `ToolCalledMode`), `ToolCallsPresent`, `ToolCallArgsMatch`, `HasImageContent`.
The upstream `CustomEvals` sample's first example is literally refusal detection —
the same thing Chapter 8 §8.7 recommends writing by hand.

**`numRepetitions` is a first-class parameter on `EvaluateAsync`** — runs each
query N times independently to measure consistency. This is Chapter 7 §7.7's
"distributions not best runs" discipline, built into the API. §9.2 and §9.6 both
lean on it.

**Results carry assertion methods for test frameworks:** `AssertAllPassed`,
`AssertNoFailedItems`, `AssertScoreAtLeast`, `AssertDimensionScoreAtLeast`. That
is the CI-gate story and it is in-box — §9.6 argues the mechanism was never the
problem, flakiness is.

**Workflow runs evaluate with a per-agent breakdown.** `run.EvaluateAsync(evaluator,
includeOverall, includePerAgent, ...)` → `AgentEvaluationResults.SubResults` keyed
by agent name. This is what makes the Chapter 7 comparison actionable: not "group
chat scored worse" but "the critic contributed nothing in 8 of 20 runs".

**`IConversationSplitter`** with `ConversationSplitters.LastTurn` / `.Full`
controls what counts as query vs response; `EvalItem.PerTurnItems` splits a
conversation into per-turn items.

**The Foundry catalogue directly scores what Chapter 8 §8.6 listed as
uninstrumented.** Constants on `FoundryEvals`: agent behaviour
(`intent_resolution`, `task_adherence`, `task_completion`,
`task_navigation_efficiency`); tool use (`tool_call_accuracy`, `tool_selection`,
`tool_input_accuracy`, `tool_output_utilization`, `tool_call_success`); quality
(`coherence`, `fluency`, `relevance`, `groundedness`, `response_completeness`,
`similarity`); safety (`violence`, `sexual`, `self_harm`). Evaluators are named by
**string**, so the set can grow without a package update and a name can silently
stop being recognised — §9.3 has a versionbox on pinning them.

---

## Hosting / A2A API — RESOLVED (Chapter 10 pass, July 2026)

Verified against `Microsoft.Agents.AI.Hosting`, `.Hosting.AspNetCore`,
`.DurableTask`, `.Hosting.AzureFunctions`, `.A2A`, `.Hosting.A2A`,
`.Hosting.A2A.AspNetCore` and `.Foundry.Hosting`.

**Agents register by name on the host builder:** `builder.AddAIAgent(name,
instructions, ...)` → `IHostedAgentBuilder`, then `.WithAITool(s)`,
`.WithInMemorySessionStore()`, `.WithSessionStore(...)`. Workflows have a parallel
set (`HostApplicationBuilderWorkflowExtensions`, `HostedWorkflowBuilder`).

**`AgentSessionStore` is abstract** with Save/Get/Delete. Session-store
registration takes `withIsolation = true` **by default** and wraps the store in an
`IsolationKeyScopedAgentSessionStore`.

**Session isolation is the security story and it is well documented in-source.**
`UseClaimsBasedSessionIsolation()` in `.Hosting.AspNetCore`. The provider's own
remarks warn that the claim **must uniquely identify the principal** — display
names, usernames and email aliases are unsafe, because two principals sharing a
value get the same isolation key and can read/overwrite each other's sessions.
Default claim is `ClaimTypes.NameIdentifier` (OIDC `sub`), and the remarks
explicitly note this is **not** Entra's `oid`. Missing claim ⇒ null key; decide
store behaviour for that case. §10.1 has this as a warning.

**Two durabilities, and Chapter 10 §10.3 makes the distinction a table:**
workflow checkpointing = durability of the *graph*; the durable extension =
durability of the *host*. They compose.

**`DurableAgentsOptions.DefaultTimeToLive` is 14 days.** Entities expire, so a
conversation resumed after the window comes back **empty rather than failing**.
Registration: `AddAIAgentFactory(name, factory, timeToLive?)` / `AddAIAgent(s)`.
Also `AsDurableAgentProxy(agent, services)`, `DurableAIAgent`, `AgentEntity`.

**A2A: the boundary disappears at the type level.** A remote agent becomes an
ordinary `AIAgent` via `card.AsAIAgent(...)`, `client.AsAIAgent(...)` or
`resolver.GetAIAgentAsync(...)`. So a remote agent can be a workflow node, a
handoff target or a tool — the §5.2 symmetry extended over the network. Server
side: `AddA2AServer(name)` + `MapA2AHttpJson(name, path)`. There is also an
AG-UI family (`.AGUI`, `.Hosting.AGUI.AspNetCore`) for agent→front-end streaming.

**Foundry hosting:** `AddFoundryResponses(agent, sessionStore?)` +
`MapFoundryResponses(prefix)`. `FileSystemAgentSessionStore` and
`InMemoryAgentSessionStore` are in-box. Also present and relevant to Chapter 11:
`ConsentAwareMcpClientAIFunction`, `McpConsentContext`, `ToolApprovalIdMap`,
`HostedSessionIsolationKeyProvider`, Foundry toolbox support with a health check.

**`WorkflowHostingExtensions.AsAIAgent(Workflow, ...)`** confirmed — a graph can
be hosted as a single agent, and callers never learn it was a graph.

---

## Harness API — RESOLVED (Chapter 11 pass, July 2026)

Verified against `Microsoft.Agents.AI.Harness`, the `Harness/` and `Skills/`
folders of `Microsoft.Agents.AI`, and `Microsoft.Agents.AI.Tools.Shell`.

**The split matters and answers the brief's question.** The Harness *package* is
three files (`HarnessAgent`, `HarnessAgentOptions`, `ChatClientHarnessExtensions`).
**Every provider lives in the core package** under `Harness/`: `AgentMode`,
`BackgroundAgents`, `FileAccess`, `FileMemory`, `FileStore`, `Loop`, `Todo`,
`ToolApproval` — plus `Skills/` at the core root. So a provider can be lifted onto
an ordinary agent; it is not harness-or-nothing. §11.1 makes this the framing.

**Signature correction.** It is `chatClient.AsHarnessAgent(options?,
loggerFactory?, services?)` — not the `(maxContextTokens, maxOutputTokens,
options)` form the old note recorded. Token limits are `MaxContextWindowTokens` /
`MaxOutputTokens` **on** `HarnessAgentOptions`.

**Compaction is DISABLED when options is null** — stated in the extension
method's own docs. A harness workload is exactly what overflows, so this is the
chapter's headline warning (§11.1). Options are mostly `Disable*` switches:
compaction, file memory, web search, todo, agent mode, skills, OpenTelemetry,
tool auto-approval, approval-response binding.

**`Loop/` is a real feature the brief did not mention, and §11.2.8 covers it.**
`LoopEvaluator` decides whether the agent is *done*: `AIJudgeLoopEvaluator` (chat
client judge, `VERDICT: DONE` / `VERDICT: MORE` markers, `JudgeVerdict` carries a
**gap analysis fed back as the next instruction**), `CompletionMarkerLoopEvaluator`,
`BackgroundTaskCompletionLoopEvaluator`, `DelegateLoopEvaluator`. Chapter 9's
judge cautions apply verbatim.

**Shell sandboxing is the best-designed part of the framework.**
`Microsoft.Agents.AI.Tools.Shell` ships `LocalShellExecutor` and
`DockerShellExecutor`. Local has `ConfineWorkingDirectory = true`,
`CleanEnvironment`, `ShellPolicy`, and an **`AcknowledgeUnsafe` flag you must
set**. Docker defaults: `Network = none`, `ReadOnlyRoot = true`,
`MountReadonly = true`, `User = 65534:65534` (nobody), `PidsLimit`,
`MaxOutputBytes = 64 KB`. `DockerNetworkMode.Host` is described in-source as
"strongly discouraged for untrusted code".

**Other defaults worth knowing:** `AgentModeState.CurrentMode` starts at
**`"plan"`**, not execute. Tool auto-approval is **on** by default.
`AgentSkillsProvider` exposes `load_skill` / `read_skill_resource` /
`run_skill_script` (progressive disclosure) plus ready-made auto-approval rules
`ReadOnlyToolsAutoApprovalRule` and `AllToolsAutoApprovalRule`.
`AgentFileStore` is abstract with `FileSystemAgentFileStore` and
`InMemoryAgentFileStore` in-box — the in-memory one is the test seam. Note its
`SearchAsync` takes a regex, so a naive custom store will be the bottleneck.

---

## Open questions — NEW, unresolved

**4. Version bump — DONE (August 2026), and it was not a find-and-replace.**
Verified against `api.nuget.org`: **the release-train model no longer exists.**
Since `1.11.1` (25 June 2026) the whole family publishes as ONE line — same base
version, same day — differing only by prerelease suffix. `\mafcore` is now
`1.16.0` (published 30 July 2026) with four tiers under it:

| Tier | Packages |
|---|---|
| stable | core, Abstractions, OpenAI, Workflows, Workflows.Generators, Workflows.Declarative, GitHub.Copilot, **Harness** |
| `-rc1` | Purview, Declarative |
| `-preview.260730.1` | Hosting family, Foundry family, A2A, DevUI, CosmosNoSql, Hyperlight, Tools.Shell, CopilotStudio, Anthropic, DurableTask, LocalCodeAct |
| `-alpha.260730.1` | Hosting.OpenAI, Valkey, Mcp |

**The harness went stable at 1.14.0.** Anything describing it as preview is now
wrong.

**Macros changed.** `\mafext` is **deleted** — there is no extensions train.
New: `\mafpreview`, `\mafalpha`, `\mafdateexact`. `\mafworkflows` is now an
alias for `\mafcore`. In Appendix A's *tables* use the short `\mafcore{}-preview`
form: the full build-dated string is 23 characters and blows out the version
column, costing ~45 overfull boxes. The exact strings live in §A.1 only.

**Packages left BEHIND the line are now the useful signal** and Appendix A has a
table of them: AzureAI (1.0.0-rc5, superseded), FoundryMemory (1.0.0-preview),
**Mem0 (1.0.0-preview from October 2025 — nine months stale)**, AGUI
(1.13.0-preview). Re-check these each pass; a package rejoining the line matters.

Swept: `preamble.tex`, Appendix A (rewritten §A.1 and all version columns,
headings made categorical since tiers now mix), Chapter 1, Chapter 2, the
introduction, Appendix C.

**Chapter 2's CPM listing is now macro-driven** via `escapeinside={(*@}{@*)}`,
so it cannot drift again — it had been hardcoded at 1.10.0, contradicting the
rest of the book. Verified the escape actually expands by compiling a probe with
an undefined macro inside it and confirming the error.

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

**7b. The cold-start measurement has not been run either.** Chapter 10 §10.5.3
specifies it — warm baseline, forced scale-to-zero, ≥20 cold invocations,
distribution not best run — and reports nothing, in a warning box. The step that
makes it publishable is **separating platform cold start from graph rehydration
cost**, which is why Chapter 6 §6.2 exercise 4 measures rehydration on its own.
Needs the same Azure subscription as the rest of Chapter 10. Smaller and cheaper
than item 7; do it first if budget is tight.

**8. Chapter 11 §11.6's AgentHelm disclosure is written generically and needs the
author.** The brief said the overlap with AgentHelm is substantial and should be
stated plainly rather than avoided. §11.6 does state it plainly — a disclosure
note, a list of what the platform now does for free, a list of what it does not
(multi-user, audit, policy enforcement, fleet-level questions), and the honest
conclusion to build on the harness rather than around it. But it names no
specifics about AgentHelm, because those were not verifiable from the repository
and inventing them would be worse than omitting them.

**Only the author can finish this section.** Decide whether to name the product
outright, and replace the generic overlap claim with the actual feature-by-feature
position. The structure is there; the facts are not. Leave it generic rather than
guessing if you would rather not name it in print.

---

## What is left

**All twelve chapters and four appendices are drafted.** There are no stubs. The
remaining work is finishing, not writing, and it is in rough priority order:

1. **Run the two experiments** (items 7 and 7b). Both are fully specified and
   report nothing. The cold-start one is cheaper — do it first. Until they run,
   Appendix B stays empty and no comparative performance claim may be stated as
   fact anywhere in the book.
2. **Chapter 11 §11.6** (item 8) — only the author can finish it.
   Items 4, 5 and 6 are now **done**.
3. **Screenshots and verifyboxes.** 27 and 23 respectively. Each verifybox is a
   promise to a reader that something was not compiled; clearing one means
   compiling the listing, not rereading it.
4. **Appendix A's margin cleanup.** The worst margin debt in the book.
5. **Re-verify versions before any release.** The family now moves as one line
   and ships often — `\mafcore` was three releases stale after six weeks. The
   check is cheap: query `api.nuget.org/v3-flatcontainer/<pkg>/index.json` for
   the core package and the four tier representatives, and re-check the
   behind-the-line table in Appendix A §A.1.
6. Optional: a glossary (superstep, executor binding, isolation key, delivery
   status, progress ledger) and a further-reading section. Neither is essential.

### Index pass — DONE (July 2026)

Roughly 80 entries became **397** across six index pages; every chapter and
appendix now has coverage, including Chapter 12 which had none.

**Conventions, so later additions match.** APIs use a sort key:
`\index{Name@\texttt{Name}}`. Concepts are lowercase with `!` subentries under a
shared head — the established heads are `workflow`, `edge`, `executor`,
`orchestration`, `evaluation`, `observability`, `hosting`, `session`, `harness`,
`compaction`, `memory`, `state`, `approval`, `packages`, `providers`,
`troubleshooting`, `sandbox`, `testing`, `measurement`, `scoring`, `handoff`,
`Magentic`, `CodeAct`, `diagnostics`, `span`, `MCP`. Prefer adding a subentry to
an existing head over inventing a new one.

**Two hard limits, both learned the hard way:**

- **Verbatim index entries must stay under about 29 characters.** The index is
  two-column and a single `\texttt{}` token wider than the column overflows. Ragged
  right (now set in `preamble.tex`) cannot help, because there is no break
  opportunity inside one word. Index longer type names by concept instead —
  `handoff!tool call filtering`, not the 32-character type name.
- **Package names never fit**, so they go under `packages!<name>` with the
  `Microsoft.Agents.AI.` prefix elided.

Entries were inserted immediately after `\label{sec:...}` anchors, which is
deterministic, keeps them out of prose, and indexes the page the section starts
on. The scripts that did it are disposable; the conventions above are not.

**Still worth doing:** Chapters 1–4 have lighter coverage than 5–12, because the
pass anchored on the section labels that exist and the early chapters have fewer.
Entries for individual listings and for the failure modes discussed in prose
would both add value.

### Consistency pass — DONE (July 2026)

Ran after the draft completed, to fix places where the appendices predated the
chapters and disagreed with them. Two were outright errors:

- **Appendix C said a type mismatch "surfaces at run time"** and implied the
  source generators catch it. Both wrong: it is a *silent drop*, and the
  generators catch handler shape (`MAFGENWF001`–`007`), not edge types. Rewritten
  against Ch. 5 §5.3 and pointed at Ch. 8's query.
- **Appendix C said multi-agent traces lose their parent-child relationship** and
  told the reader to check context propagation. Nothing is broken — executor
  spans are siblings by design. Rewritten against Ch. 8 §8.4.

Also fixed: Appendix A still said "threads" (pre-rename vocabulary) and still
described the checkpoint types wrongly (item 5); the seven never-mentioned
packages are now in Appendix A (item 6); Appendix C gained entries for hosting,
evaluation and the harness, which it had none of; Chapter 4 now tells the reader
the in-box storage backends exist *before* it spends thirty pages hand-rolling
one.

**One genuine defect found in a chapter:** Chapter 11 implied both CodeAct
packages sandbox. `LocalCodeAct` does not — its own description says it requires
external sandboxing, and syntax-tree validation is not a security boundary. Now
warned about in both Ch. 11 and Appendix A.

When revising a written chapter, the same rule applies as when drafting: verify
against the upstream source before changing any API detail. Every chapter pass so
far turned up something that contradicted the notes, including notes written
during an earlier pass.

## After each pass

1. `latexmk -pdf main.tex` — must be zero errors, zero unresolved refs
2. `make shots` — confirm screenshot requests are still registered
3. Update the Status table and debt ledgers at the top of this file
4. Check the overfull count by diffing against a build with the change reverted
5. Tag if it is a meaningful milestone: `git tag -a v0.4.0 -m "Chapter 4"`

Appendix B's measurement tables stay empty until the experiments are actually run.
Do not fill them with plausible numbers.

**Note on tagging:** `git push --tags` returns HTTP 403 through the sandbox's git
proxy, so tags created in a Claude Code web session exist locally only and are
lost when the container is reclaimed. Tag from a local clone instead.
