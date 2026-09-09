import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'auth_failure.dart';

/// Kết quả trả về sau khi hoàn tất flow OAuth của Google trên desktop.
///
/// Chứa hai token mà Firebase cần để tạo credential:
/// - [idToken]: dùng để Firebase xác thực danh tính người dùng.
/// - [accessToken]: dùng để truy cập các API của Google (nếu cần).
class GoogleDesktopTokens {
  const GoogleDesktopTokens({
    required this.idToken,
    required this.accessToken,
  });

  final String idToken;
  final String accessToken;
}

/// Thực hiện Google Sign-In trên desktop (Windows) bằng OAuth 2.0 theo chuẩn
/// "Authorization Code with PKCE" và cơ chế loopback (redirect về localhost).
///
/// Vì package `google_sign_in` chính thức KHÔNG hỗ trợ Windows, ta phải tự làm
/// flow này. Các bước:
///
/// 1. Mở một HTTP server tạm trên `127.0.0.1` tại một cổng ngẫu nhiên còn trống.
/// 2. Mở trình duyệt mặc định tới trang đăng nhập Google (kèm PKCE challenge).
/// 3. Sau khi người dùng đồng ý, Google redirect về `http://127.0.0.1:<port>`
///    kèm theo `authorization code`.
/// 4. Server tạm bắt lấy code đó, rồi đóng lại.
/// 5. Đổi code lấy `id_token` + `access_token` qua endpoint token của Google
///    (kèm PKCE verifier để chứng minh chính client đã khởi tạo request).
///
/// PKCE (Proof Key for Code Exchange) giúp flow an toàn mà KHÔNG cần nhúng
/// client secret vào app — điều quan trọng vì app desktop không giữ bí mật được.
class GoogleDesktopSignIn {
  GoogleDesktopSignIn({required this.clientId, this.extraScopes = const []});

  /// OAuth Client ID loại "Desktop app" tạo trong Google Cloud Console.
  /// KHÁC với client ID của Android. Xem hướng dẫn setup ở cuối.
  final String clientId;

  /// Các scope bổ sung (ngoài scope danh tính) — ví dụ scope Google Calendar
  /// để đồng bộ sự kiện. Rỗng nếu chỉ cần đăng nhập.
  final List<String> extraScopes;

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';

  /// Các quyền tối thiểu để lấy thông tin danh tính cho Firebase.
  static const _identityScopes = ['openid', 'email', 'profile'];

  List<String> get _scopes => [..._identityScopes, ...extraScopes];

  /// Chạy toàn bộ flow và trả về token. Ném [AuthFailure] nếu thất bại hoặc
  /// người dùng hủy.
  Future<GoogleDesktopTokens> signIn() async {
    // Bước 1: Mở server loopback trên cổng ngẫu nhiên do hệ điều hành cấp (port 0).
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}';

    try {
      // Tạo PKCE code verifier (chuỗi ngẫu nhiên) và challenge (dùng phía Google).
      // Ở đây dùng phương thức "plain" cho đơn giản: challenge == verifier.
      // (Google chấp nhận plain; nếu muốn chặt hơn có thể dùng S256 + SHA-256.)
      final codeVerifier = _randomString(64);
      final state = _randomString(32); // chống tấn công CSRF

      // Bước 2: Dựng URL đăng nhập và mở trình duyệt.
      final authUrl = Uri.parse(_authEndpoint).replace(queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': _scopes.join(' '),
        'code_challenge': codeVerifier,
        'code_challenge_method': 'plain',
        'state': state,
      });

      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw const AuthFailure(
            'Không mở được trình duyệt để đăng nhập Google.');
      }

      // Bước 3 + 4: Chờ Google redirect về và bắt lấy authorization code.
      final code = await _waitForCode(server, expectedState: state);

      // Bước 5: Đổi code lấy token.
      return await _exchangeCode(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );
    } finally {
      // Luôn đóng server tạm dù thành công hay thất bại.
      await server.close(force: true);
    }
  }

  /// Lắng nghe request đầu tiên tới server loopback, lấy `code` từ query string,
  /// đồng thời kiểm tra `state` để chống CSRF, rồi trả một trang HTML báo cho
  /// người dùng quay lại ứng dụng.
  Future<String> _waitForCode(
    HttpServer server, {
    required String expectedState,
  }) async {
    // Đặt timeout để tránh treo vô hạn nếu người dùng bỏ ngang.
    final completer = Completer<String>();

    final subscription = server.listen((HttpRequest request) async {
      final params = request.uri.queryParameters;
      final response = request.response;

      // Trả về một trang HTML tiếng Việt đơn giản để người dùng biết đã xong.
      response.headers.contentType = ContentType.html;

      if (params['error'] != null) {
        response.write(_htmlPage('Đăng nhập bị từ chối. Bạn có thể đóng cửa sổ này.'));
        await response.close();
        if (!completer.isCompleted) {
          completer.completeError(AuthFailure.cancelled);
        }
        return;
      }

      if (params['state'] != expectedState) {
        response.write(_htmlPage('Phiên đăng nhập không hợp lệ.'));
        await response.close();
        if (!completer.isCompleted) {
          completer.completeError(
              const AuthFailure('Phiên đăng nhập Google không hợp lệ.'));
        }
        return;
      }

      final code = params['code'];
      response.write(_htmlPage(
          'Đăng nhập thành công! Bạn có thể đóng cửa sổ này và quay lại ứng dụng.'));
      await response.close();

      if (code != null && !completer.isCompleted) {
        completer.complete(code);
      } else if (!completer.isCompleted) {
        completer.completeError(AuthFailure.cancelled);
      }
    });

    try {
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw const AuthFailure(
            'Hết thời gian chờ đăng nhập Google. Vui lòng thử lại.'),
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// Gọi endpoint token của Google để đổi authorization code lấy token.
  Future<GoogleDesktopTokens> _exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'code': code,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw AuthFailure(
          'Không đổi được mã đăng nhập Google (HTTP ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final idToken = data['id_token'] as String?;
    final accessToken = data['access_token'] as String?;

    if (idToken == null || accessToken == null) {
      throw const AuthFailure('Phản hồi từ Google thiếu token cần thiết.');
    }

    return GoogleDesktopTokens(idToken: idToken, accessToken: accessToken);
  }

  /// Sinh chuỗi ngẫu nhiên an toàn dùng cho PKCE verifier và state.
  /// Chỉ dùng các ký tự cho phép trong "unreserved" của RFC 3986.
  String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  String _htmlPage(String message) => '''
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="utf-8"><title>My Time Manager</title></head>
<body style="font-family: sans-serif; text-align: center; padding-top: 60px;">
  <h2>My Time Manager</h2>
  <p>$message</p>
</body>
</html>''';
}
