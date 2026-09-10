# Roadmap — Personal AI Execution System

Mục tiêu: tiến hóa **My Time Manager** thành một hệ thống thực thi cá nhân có AI Agent
hiểu được tasks, calendar, time intervals, notes và focus history — **mà không viết lại
ứng dụng hiện có**. Toàn bộ lớp AI được *thêm vào* phía trên domain layer đã có.

> Trạng thái nền tảng: refactor domain layer đã hoàn tất (xem
> `ARCHITECTURE_REFACTOR_REPORT.md`). UI/Bloc/Controller đã đi qua domain
> repositories/services, không còn gọi trực tiếp `DatabaseManager`. Đây chính là
> điểm bám (attach point) cho AgentRuntime → Tool System.

---

## Nguyên tắc kiến trúc cốt lõi

Agent **không** phụ thuộc trực tiếp vào Ollama hay llama.cpp:

```
AgentRuntime → AiEngine (abstraction) → Ollama / llama.cpp / Cloud
AgentRuntime → ToolRegistry → Domain Services/Repositories → DatabaseManager → SQLite
```

- SQLite vẫn là **source of truth**. LLM **không** chạm SQLite; chỉ gọi domain tools.
- Backend inference thay đổi được mà không sửa Agent.
- Cloud AI là **tùy chọn**; chế độ local giữ dữ liệu ở máy.

---

## Ràng buộc bắt buộc (áp dụng cho MỌI phase)

1. Không viết lại app: giữ Flutter, SQLite, BLoC/Cubit + ChangeNotifier, Firebase,
   navigation, calendar sync, models hiện có.
2. Không thêm Rust trừ khi có yêu cầu kỹ thuật chứng minh được.
3. Làm theo **từng phase**; sau mỗi phase: chạy test → `flutter analyze` → kiểm tra
   compile → review kiến trúc → báo cáo ngắn → nêu việc còn lại. Dừng nếu phase hiện
   tại lộ ra vấn đề kiến trúc.
4. Inspect code liên quan **trước khi** sửa (`lib/data`, `lib/domain`, `lib/screen_*`,
   `lib/home`, `packages/`, `pubspec.yaml`).
5. Ưu tiên tái dùng domain services/repositories sẵn có; không nhân đôi domain logic.
6. AI lỗi **không bao giờ** được làm hỏng dữ liệu ứng dụng.
7. Thao tác destructive cần xác nhận rõ ràng; Agent không được vượt qua policy.
8. Vòng lặp tool của Agent phải có giới hạn cứng (max iteration).
9. Không chạy inference dài trên UI isolate; UI phải giữ responsive.
10. Không thêm dependency không cần thiết.

---

## Các phase

### Phase 0 — Architectural Audit (KHÔNG code AI)
Sản phẩm là một báo cáo, không phải code:
- **A. Kiến trúc hiện tại:** UI, state management, domain/data access, database, sync,
  code theo nền tảng.
- **B. Domain capability đã có:** liệt kê API sẵn sàng cho Agent (đọc/tạo/sửa/hoàn tất
  task, đọc/tạo calendar event, đọc/tạo time interval, đọc focus session, đọc notes).
- **C. Domain API còn thiếu:** đề xuất interface nhỏ nhất cần bổ sung (ví dụ focus
  statistics, note query an toàn) nếu chưa có.
- **D. Vị trí đề xuất** cho: AI Gateway, Agent Runtime, Context Builder, Tool Registry,
  Tool Executor, AI config, Model management — **chưa implement**.
- **Kết thúc Phase 0: dừng và báo cáo trước khi làm tiếp.**

### Phase 1 — AI Abstraction (provider-independent)
Tạo `lib/ai/core/`: `ai_engine.dart`, `ai_request.dart`, `ai_response.dart`,
`ai_message.dart`, `ai_stream_event.dart`, `ai_capabilities.dart`; `lib/ai/config/ai_config.dart`.
`AiEngine` hỗ trợ tối thiểu: `generate`, `stream`, `isAvailable`; system/user/assistant
messages, streaming, structured output, model id, context length, capabilities,
cancellation, errors, availability. **Agent không bao giờ import class riêng của Ollama.**

### Phase 2 — Ollama Provider (Desktop trước: Windows/macOS/Linux)
`lib/ai/providers/ollama/ollama_ai_engine.dart`: cấu hình endpoint (configurable, không
hard-code), chọn model, health check, generate, streaming, timeout, cancellation, error
message rõ ràng. Chỉ provider này biết API của Ollama. **Chưa làm llama.cpp.**

### Phase 3 — Domain Tool System
`ToolRegistry` + tools, mỗi tool có: name, description, input schema, execution, result,
error handling; dùng structured arguments. LLM gọi domain tools (không truy cập SQLite,
không SQL tùy ý). Bộ tool tối thiểu:
- Task: `list_tasks`, `get_task`, `create_task`, `update_task`, `complete_task`
- Calendar: `list_calendar_events`, `get_calendar_event`, `create_calendar_event`, `update_calendar_event`
- Time planning: `list_time_intervals`, `create_time_interval`, `update_time_interval`
- Focus: `list_focus_sessions`, `get_focus_statistics`
- Notes: chỉ khi domain API note đủ an toàn
- Analytics (read-only): `get_productivity_summary`, `get_planning_accuracy`, `get_focus_summary`

> Lưu ý kỹ thuật (từ audit): `create/update_time_interval` kích hoạt side-effect
> NotificationService (audio/local notifications) — cần chạy có Flutter binding hoặc
> làm side-effect này injectable để tool chạy được headless.

### Phase 4 — Agent Runtime (domain-specific, không phải coding agent)
Vòng lặp tool có kiểm soát: max iteration, validate tool-call, xử lý tool-call dị dạng,
timeout, cancellation, structured tool result, tracing/logging, final response. Không
bao giờ vòng lặp vô hạn.

### Phase 5 — Context Engine
`ContextBuilder` dựng context **có chọn lọc** (không dump cả DB): current date/time,
tasks, lịch hôm nay, calendar sắp tới, focus gần đây, notes liên quan, thống kê năng
suất. Context: tối thiểu, liên quan, có cấu trúc, deterministic, inspectable, testable.
Agent xin thêm dữ liệu qua tool khi cần.

### Phase 6 — Safety / Permission Model
Phân loại tool: `READ_ONLY` / `WRITE` / `DESTRUCTIVE`. Destructive luôn cần xác nhận rõ
ràng. Write thường: kiến trúc cho phép UI tùy chọn yêu cầu xác nhận (Approve/Reject).
LLM không được bỏ qua policy.

### Phase 7 — AI UI (đơn giản trước)
Giao diện AI Assistant tích hợp vào app hiện có, ưu tiên tương tác với dữ liệu thật
(ví dụ "Plan my day tomorrow" → đề xuất + [Apply plan]). Chưa cần chatbot phức tạp.

### Phase 8 — Local Model Management
`ModelManager`, `ModelRegistry`, `ModelInfo` (id, name, format, size, contextLength,
capabilities, downloadUrl, checksum, platformSupport). Hỗ trợ: list, download, verify,
delete, select. **Không nhúng model lớn vào binary** — tải riêng.

### Phase 9 — llama.cpp Backend
`LlamaCppAiEngine` cho Android/iOS/macOS/Windows/Linux khi khả thi. Dùng binding/FFI
llama.cpp trưởng thành sẵn có — **không tự viết inference engine**. Agent không biết
llama.cpp tồn tại.

### Phase 10 — Platform Model Routing
Chiến lược chọn provider/model theo nền tảng qua AI Gateway. Policy: Local Only /
Hybrid / Cloud Optional (ví dụ Windows→Ollama, Android/iOS→llama.cpp, macOS→cả hai,
Cloud→fallback tùy chọn). Provider layer phải expose capabilities; không giả định mọi
nền tảng chạy model cùng kích thước/tăng tốc.

### Phase 11 — Intelligence Layer (deterministic analytics)
Tính bằng code ứng dụng, không để LLM tự tính: `PlanningAccuracy`, `ExecutionRate`,
`FocusEfficiency`, `EstimationBias`, `RescheduleRate`, `DeadlineMissRate`,
`WorkloadScore`. LLM diễn giải số liệu chứ không bịa số.

### Phase 12 — Personal Execution Agent (workflow cấp cao)
- **Daily Planning:** đọc calendar/tasks/deadlines/thời gian rảnh/focus → phân tích
  workload → đề xuất lịch → xin duyệt → tạo time intervals.
- **Weekly Review:** đọc task hoàn tất/bỏ lỡ, focus sessions → tính metrics → nhận diện
  pattern → tóm tắt.
- **Rescheduling:** đọc task chưa xong + lịch còn lại → ưu tiên → đề xuất lịch mới →
  xin duyệt → áp dụng.

---

## Yêu cầu xuyên suốt

**Testing** (mỗi phase phải có test): AI Engine (serialize request, parse response,
streaming, errors, timeouts, cancellation); Tools (arg hợp lệ/không hợp lệ, permissions,
domain errors); Agent (single-turn, tool call, nhiều tool call, tool failure, max
iteration, output dị dạng, cancellation); Context (chọn context liên quan, giới hạn
token, data rỗng, dataset lớn); Platform (`flutter analyze`, `flutter test`, build/test
nền tảng khi khả thi).

**Observability:** log/trace có cấu trúc cho agent request, context sinh ra, model
request/response, tool call + arguments + result, số iteration, thời gian, errors, final
response. Có debug mode. Không log dữ liệu nhạy cảm khi không cần.

**Performance:** không inference dài trên UI isolate; dùng async/native phù hợp. UI hỗ
trợ: streaming response, cancel generation, trạng thái agent busy / tool executing,
errors.

**Privacy:** local-first. Chế độ local giữ tasks/calendar/notes/focus ở máy; không âm
thầm gửi dữ liệu cá nhân lên cloud — chỉ khi người dùng chủ động chọn provider ngoài.

---

## Ánh xạ vị trí đề xuất trong repo (chốt ở Phase 0)

```
lib/ai/
    core/         # AiEngine + request/response/message/stream/capabilities (Phase 1)
    providers/
        ollama/   # OllamaAiEngine (Phase 2)
        llama_cpp/ # LlamaCppAiEngine (Phase 9)
    config/       # AiConfig, provider/model routing (Phase 1, 10)
    tools/        # ToolRegistry, Tool, ToolExecutor — gọi lib/domain (Phase 3)
    agent/        # AgentRuntime, tool loop, tracing (Phase 4)
    context/      # ContextBuilder / ContextEngine (Phase 5)
    policy/       # Permission model READ_ONLY/WRITE/DESTRUCTIVE (Phase 6)
    models/       # ModelManager/ModelRegistry/ModelInfo (Phase 8)
    analytics/    # deterministic metrics (Phase 11)

lib/screen_ai/    # AI Assistant UI (Phase 7)
```
> Vị trí cuối cùng sẽ được xác nhận trong báo cáo Phase 0 sau khi audit; ưu tiên tận
> dụng `lib/domain` (services/repositories) làm cầu nối duy nhất tới dữ liệu.

---

## Quy trình mỗi phase

Inspect → Design (giải thích trước khi code) → Implement (thay đổi nhỏ nhất, mạch lạc)
→ Test (`flutter analyze`, `flutter test`, build nền tảng nếu khả thi) → Review (kiến
trúc, error handling, dependency, platform, backward-compat) → Report theo mẫu:

```
Phase:
Status:
Implemented:
Files changed:
Tests:
Architecture decisions:
Known limitations:
Recommended next step:
```

Không tuyên bố phase hoàn tất nếu không compile hoặc test đỏ mà không báo rõ.

---

## Định hướng ưu tiên

Không tối ưu số dòng code. Tối ưu: **đúng kiến trúc, dễ bảo trì, portable đa nền tảng,
tiến độ tăng dần.** Đích cuối: Agent chạy qua `AiEngine` mà không cần biết backend là
Ollama, llama.cpp hay Cloud.

**Bước tiếp theo:** thực hiện **Phase 0 — Architectural Audit**, KHÔNG code AI, rồi dừng
và báo cáo trước khi sang Phase 1.
