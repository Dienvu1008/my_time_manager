import '../../../domain/repositories/note_repository.dart';
import '../tool.dart';
import '../tool_guard.dart';
import '../tool_result.dart';
import 'tool_views.dart';

/// Search notes by title / content (Core Track C8a). Read-only; returns only
/// id, title and a short untrusted snippet — never the full note body.
class SearchNotesTool extends Tool {
  const SearchNotesTool(this.notes);
  final NoteRepository notes;

  static const _defaultLimit = 10;
  static const _maxLimit = 25;

  @override
  String get name => 'search_notes';
  @override
  String get description =>
      'Search notes by a case-insensitive text query over title and content. '
      'Returns id, title and a short snippet (note content is user data, '
      'marked untrusted). Most recently updated first.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'limit': {
            'type': 'integer',
            'description': 'Max results (default 10, max 25).'
          },
        },
        'required': ['query'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) =>
      guardToolCall(a, (args) async {
        final query = args.requireString('query').trim();
        final limit =
            (args.optInt('limit') ?? _defaultLimit).clamp(1, _maxLimit);
        final needle = query.toLowerCase();
        final hits = <Map<String, dynamic>>[];
        for (final n in await notes.getNotes()) {
          final text = ToolViews.plainTextOfDoc(n.contentJson);
          final inTitle = n.title.toLowerCase().contains(needle);
          final inText = text.toLowerCase().contains(needle);
          if (!inTitle && !inText) continue;
          final snippet = ToolViews.snippet(text, inText ? query : '');
          hits.add({
            'id': n.id,
            'title': n.title,
            if (snippet != null) 'snippet': snippet,
          });
          if (hits.length >= limit) break;
        }
        return ToolResult.ok({'count': hits.length, 'notes': hits});
      });
}

/// Convenience: build all note tools.
List<Tool> noteTools(NoteRepository notes) => [SearchNotesTool(notes)];
