# AI Architecture Report — My Time Manager

**Scope:** Add a local-first AI assistant to My Time Manager — an agent that can
read and act on the user's tasks, calendar, time intervals, notes, and focus
history — **without rewriting the app**. Everything is additive under `lib/ai/`
and `lib/screen_ai/`, sitting on top of the existing domain layer.

**Companion documents:** `Roadmap.md` (the 12-phase plan), `docs/PHASE_0_ARCHITECTURAL_AUDIT.md`
(pre-work audit), `ARCHITECTURE_REFACTOR_REPORT.md` (the earlier domain
refactor that made this possible).

---

## 1. Goal and result

Build a provider-independent AI layer where the agent drives the app through the
same domain services the UI uses, and the inference backend (Ollama, llama.cpp,
or a future cloud provider) can change without touching the agent.

**Result:** all 12 roadmap phases plus two follow-ups completed.
`flutter analyze lib` = 346 issues, **0 errors** (346 are pre-existing
info/warning lints in legacy screens; the AI code adds none). `flutter analyze
lib/ai lib/screen_ai` = **No issues found**. AI test suite ≈ **210 tests, all
passing**, fully headless (no real backend needed). App still builds on all
existing targets (Android/iOS/Windows/macOS/Linux/Web).

---

## 2. Layered architecture

```
UI (lib/screen_ai)  — AiAssistantPage, AiSettingsPage, AiModelsPage
        │  ChangeNotifier controllers
AI Gateway (lib/ai/gateway)  — picks a provider for the platform + mode
        │  returns an AiEngine
Agent Runtime (lib/ai/agent) — controlled tool loop, tracing, workflows
        │
   ┌────┴─────────────────────────┐
   │                              │
AiEngine (lib/ai/core)      ToolRegistry / ToolExecutor (lib/ai/tools)
   │  provider-independent        │  + ActionPolicy (lib/ai/policy)
   │                              │
Providers (lib/ai/providers)   Domain tools → lib/domain services/repositories
   ├─ ollama/  (HTTP)                 │
   └─ llama_cpp/ (FFI, opt-in)   DatabaseManager (unchanged) → SQLite
```

Supporting pieces: `lib/ai/context` (targeted context builder), `lib/ai/config`
(AiConfig + persistence), `lib/ai/models` (model management), `lib/ai/analytics`
(deterministic metrics).

**Two invariants, verified by grep across the codebase:**
1. The **agent never learns which backend is used** — nothing above the provider
   folder imports `OllamaAiEngine`/`LlamaCppAiEngine`; the agent depends only on
   `AiEngine`.
2. The **LLM never touches the database** — no file under `lib/ai` imports
   `database_manager`, `sqflite`, or the `Sqlite*` adapters. Tools reach data
   only through `lib/domain` repositories/services.

---

## 3. Phase-by-phase summary

| Phase | Delivered | Verified |
| --- | --- | --- |
| 0 | Architectural audit (no code) | Report only |
| 0.5 | Domain groundwork: `FocusRepository` interface + `FocusStatisticsService` | 49 tests |
| 1 | AI abstraction: `AiEngine`, request/response/message/stream/capabilities, config, cancellation, exceptions | 27 tests |
| 2 | Ollama provider (HTTP): generate, stream (NDJSON), tool-calls, health check, errors, cancellation | 30 tests |
| 3 | Domain Tool System: `Tool`/`ToolRegistry`/`ToolExecutor`/`ToolArgs` + 16 domain tools (task/calendar/time/focus/analytics) | 37 tests |
| 4 | Agent Runtime: controlled tool loop, max-iterations, malformed-call/error/cancel handling, tracing | 12 tests |
| 5 | Context Engine: targeted, deterministic `AgentContext` + `ContextBuilder` | 10 tests |
| 6 | Safety/Permission model: `ActionPolicy` (read/write/destructive) + confirmation flow | 12 tests |
| 7 | AI UI: assistant screen (streaming status, cancel, approve/reject dialog) + AI Settings | analyze-clean |
| 8 | Local Model Management: `ModelInfo`/`ModelRegistry`/`ModelManager` + `OllamaModelManager` + UI | 17 tests |
| 9 | llama.cpp backend: `LlamaBackend` port + `LlamaCppAiEngine` + `GgufModelDownloader` (sha256) + `LlamaCppModelManager` | 18 tests |
| 10 | Platform routing: `AiGateway` + `ProviderCandidate` + `PlatformKind` | 14 tests |
| 11 | Intelligence layer: deterministic `ProductivityMetricsService` + `get_productivity_metrics` tool | 17 tests |
| 12 | Personal Execution Agent: Daily Planning / Weekly Review / Rescheduling workflows | 17 tests (incl. runtime) |
| +1 | `LlamaCppDartBackend` (wraps `llama_cpp_dart`, opt-in) | — |
| +2 | `AiEngineFactory` wires the gateway into the assistant entry | 18 tests |

---

## 4. Files created

**Domain groundwork (Phase 0.5):**
- `lib/domain/repositories/focus_repository.dart` (interface),
  `lib/data/repositories/sqlite_focus_repository.dart`,
  `lib/domain/services/focus_statistics_service.dart`.

**AI core / config (`lib/ai/core`, `lib/ai/config`):**
- core: `ai_engine.dart`, `ai_message.dart`, `ai_tool_call.dart`,
  `ai_tool_definition.dart`, `ai_capabilities.dart`, `ai_request.dart`,
  `ai_response.dart`, `ai_stream_event.dart`, `ai_exception.dart`,
  `ai_cancellation_token.dart`.
- config: `ai_config.dart`, `ai_config_service.dart`.

**Providers (`lib/ai/providers`):**
- `ollama/ollama_wire.dart`, `ollama/ollama_ai_engine.dart`.
- `llama_cpp/llama_backend.dart`, `llama_cpp/llama_cpp_ai_engine.dart`,
  `llama_cpp/llama_cpp_dart_backend.dart` (opt-in, commented body).

**Tools (`lib/ai/tools`):**
- `tool.dart`, `tool_result.dart`, `tool_args.dart`, `tool_registry.dart`,
  `tool_executor.dart`.
- `domain/`: `tool_views.dart`, `task_tools.dart`, `calendar_tools.dart`,
  `time_planning_tools.dart`, `focus_tools.dart`, `analytics_tools.dart`,
  `domain_tools.dart`.

**Agent (`lib/ai/agent`):**
- `agent_runtime.dart`, `agent_config.dart`, `agent_result.dart`,
  `agent_trace.dart`; `workflows/agent_workflow.dart`,
  `workflows/workflow_runner.dart`.

**Context / policy / models / analytics / gateway:**
- context: `agent_context.dart`, `context_builder.dart`.
- policy: `action_policy.dart`, `confirmation.dart`.
- models: `model_info.dart`, `model_registry.dart`, `model_manager.dart`,
  `ollama_model_manager.dart`, `gguf_model_downloader.dart`,
  `llama_cpp_model_manager.dart`.
- analytics: `metric_inputs.dart`, `productivity_metrics.dart`,
  `metrics_sample_builder.dart`.
- gateway: `platform_kind.dart` (+ `_io`/`_stub` conditional impls),
  `provider_candidate.dart`, `provider_selection.dart`, `ai_gateway.dart`,
  `ai_engine_factory.dart`.

**UI (`lib/screen_ai`):**
- `ai_assistant_controller.dart`, `ai_assistant_page.dart`,
  `ai_assistant_entry.dart`, `ai_settings_controller.dart`,
  `ai_settings_page.dart`, `ai_models_controller.dart`, `ai_models_page.dart`.

**Tests:** mirrored under `test/ai/{core,providers,tools,agent,context,policy,models,gateway,analytics}`
plus `test/domain/focus_statistics_service_test.dart`.

## 5. Files modified (existing app)

- `lib/app/app.dart` — provide the domain repos/services (incl. `FocusRepository`
  interface + `FocusStatisticsService`) app-wide. (No AI engine is provided
  here; the assistant builds its own via the gateway.)
- `lib/home/component_widgets/app_drawer.dart` — added "AI Assistant" and
  "AI Settings" drawer entries (push routes; Home navigation unchanged).
- `pubspec.yaml` — added `crypto` (pure Dart, for GGUF sha256 verification).

**Not modified:** `DatabaseManager`, schema, migrations, domain models, sync
services, or any existing screen's behaviour.

---

## 6. Dependencies

- **Added:** `crypto` (pure Dart). Reused existing `http` (Ollama + downloads),
  `shared_preferences` (config), `path_provider` (model dir).
- **Not added by default:** `llama_cpp_dart` (native, iOS/Android/macOS only) —
  intentionally opt-in so the app keeps building on desktop/web. No cloud AI SDK.
- No Rust, no Ollama/llama.cpp installers bundled — the app talks to a local
  Ollama server over HTTP, and (opt-in) loads llama.cpp via the binding.

---

## 7. Safety, privacy, and correctness guarantees

- **Local-first / privacy:** default `AiConfig` is `AiMode.localOnly` pointing at
  a local Ollama endpoint; no network call at startup; personal data does not
  leave the device unless the user explicitly selects a cloud provider (none
  ships today).
- **Permission model:** every tool declares a `ToolRisk` (readOnly / write /
  destructive). `ActionPolicy` (default `confirmWrites`) auto-runs reads, requires
  confirmation for writes, and **never auto-runs destructive actions**. Missing a
  confirmation handler defaults to *deny*. The LLM cannot bypass this — the gate
  is inside `ToolExecutor`, which every tool call passes through.
- **AI failure never corrupts data:** tools convert their own errors into a
  structured `ToolResult`; the executor wraps any stray exception; the agent
  wraps engine failures into an error result instead of throwing.
- **Bounded loops:** the agent enforces `maxIterations` and per-turn timeouts,
  and supports cancellation end to end.
- **Deterministic analytics:** productivity metrics are computed in Dart; the
  model interprets them and is told not to recompute. Metrics with no data source
  (e.g. reschedule count) report honestly rather than being fabricated.

---

## 8. Database and platform impact

- **Database:** none. Schema stays at v11; no migration, table, trigger, backup,
  or sync change. Tools go through domain repositories that delegate 1:1 to the
  unchanged `DatabaseManager`.
- **Platform:** the app still builds on all existing targets. Ollama (HTTP) works
  wherever the device can reach a local server (desktop-first). llama.cpp is
  mobile-first and opt-in; enabling it adds native artifacts to iOS/Android/macOS
  only and does not affect other targets. The gateway is web-safe (conditional
  `dart:io` import).

---

## 9. Known limitations / remaining work

- **llama.cpp is wired but not switched on:** `LlamaCppDartBackend` (which imports
  `llama_cpp_dart`) ships with a commented body and is not referenced by the
  default build, so no native dependency is pulled in yet. Enabling it is a
  documented 4-step opt-in (add dep → add artifact → provide the backend factory
  to `AiEngineFactory` → uncomment). The engine, port, downloader, and manager
  are all implemented and tested against a fake backend.
- **Tool-calling on llama.cpp:** local GGUF chat models don't reliably support
  structured function-calling through a raw prompt, so `LlamaCppAiEngine` reports
  `toolCalling: false`. On mobile the agent answers as text; full tool-driven
  workflows require Ollama (desktop) today. This is reported honestly via
  `AiCapabilities`, and the gateway can require tool-calling when needed.
- **No cloud provider** is implemented (it exists only as a gateway concept).
- **Focus-per-interval is an approximation** in the metrics sample builder (focus
  is tracked per task, split across that task's intervals) — documented in code.
- **No end-to-end run has been verified in this environment** (needs a running
  Ollama server / a mobile device with the native artifact). All logic is
  covered headlessly with fakes / MockClient / temp dirs.
- **Streaming to the UI** shows progress via the tracer and the final text at
  once; token-by-token streaming of the final answer is a future enhancement.

---

## 10. How to run it

**Ollama (desktop, works today):**
1. Run a local Ollama server (`ollama serve`) with a tool-capable model pulled.
2. In the app: Drawer → **AI Settings** → Load models → pick a model → Save.
3. Drawer → **AI Assistant** → chat, or use the quick actions (Plan my day /
   Weekly review / Reorganize). Writes prompt an Approve/Reject dialog.

**llama.cpp (mobile, opt-in):** follow the steps in
`lib/ai/providers/llama_cpp/llama_cpp_dart_backend.dart`, then construct the
assistant with an `AiEngineFactory` that supplies the backend factory + model
path.

---

## 11. Ready for use?

**YES for local Ollama on desktop**, end-to-end pending a live smoke test on your
machine. The architecture goal is fully met: the agent runs through
`AiEngine` and reaches data only via the domain layer, with the backend chosen by
the gateway per platform — no component knows or depends on which backend is
active. Mobile llama.cpp is architecturally complete and one opt-in step away.

No AI dependency runs at startup, no personal data leaves the device by default,
and the existing app is unchanged in behaviour, schema, and platform support.
