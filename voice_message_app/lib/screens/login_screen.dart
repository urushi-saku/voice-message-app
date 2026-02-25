// ========================================
// ログイン画面
// ========================================
// ユーザーのメールアドレスとパスワードでログインする画面
//
// 【画面構成】
// 1. タイトル（ログイン）
// 2. メールアドレス入力フィールド
// 3. パスワード入力フィールド
// 4. ログインボタン
// 5. 登録画面へのリンク
//
// 【バリデーション】
// - メール形式チェック
// - パスワード長チェック（6文字以上）
//
// 【特徴】
// - StatefulWidget: フォーム入力内容を管理
// - Formウィジェット: 複数入力フィールドを一括管理
// - Consumer<AuthProvider>: ログイン状態監視・ボタン操作

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// ログイン画面ウィジェット
///
/// 【StatefulWidget を使用】
/// - ユーザーの入力値を保持
/// - パスワード表示/非表示の切り替え状態を管理
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ========================================
  // フォーム管理
  // ========================================
  /// 【GlobalKey<FormState>】
  /// Form全体の状態を管理する鍵
  /// - _formKey.currentState!.validate() で全フィールドのバリデーション実行
  /// - エラーがあればfalse、なければtrueを返す
  final _formKey = GlobalKey<FormState>();

  /// 【TextEditingController】
  /// 入力フィールドのテキスト値を管理
  /// - メール入力値: _emailController.text
  /// - パスワード入力値: _passwordController.text
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// パスワード表示フラグ（true=非表示, false=表示）
  bool _obscurePassword = true;

  @override
  void dispose() {
    // ウィジェット破棄時にコントローラーをクリア
    // メモリリーク防止
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========================================
  // メールアドレスのバリデーション
  // ========================================
  /// 【処理】
  /// 1. 空文字列チェック
  /// 2. メール形式チェック（正規表現）
  /// 3. エラーメッセージまたはnullを返す
  ///
  /// 【戻り値】
  /// - エラー時: エラーメッセージ文字列
  /// - OK時: null
  /// （nullが返されるとバリデーションOK）
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailRegex.hasMatch(value)) {
      return '有効なメールアドレスを入力してください';
    }

    return null;
  }

  // ========================================
  // パスワードのバリデーション
  // ========================================
  /// 【処理】
  /// 1. 空文字列チェック
  /// 2. 最小文字数チェック（6文字以上）
  /// 3. エラーメッセージまたはnullを返す
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }

    if (value.length < 6) {
      return 'パスワードは6文字以上で設定してください';
    }

    return null;
  }

  // ========================================
  // ログイン処理
  // ========================================
  /// 【処理フロー】
  /// 1. Form のバリデーション実行（_formKey.currentState!.validate()）
  /// 2. バリデーション OK の場合：
  ///    a. AuthProvider を取得（context.read）
  ///    b. AuthProvider.login() を呼び出し
  ///    c. 成功時: '/home' へ遷移（pushReplacementNamed）
  ///    d. 失敗時: エラーメッセージをSnackBarで表示
  /// 3. バリデーション NG: エラー表示、処理中止
  ///
  /// 【context.read vs Consumer】
  /// - context.read: 一度だけProviderを取得（再描画トリガーなし）
  /// - Consumer: Providerを監視し続ける（再描画トリガーあり）
  /// ここではログイン処理1回なのでreadを使用
  ///
  /// 【mounted チェック】
  /// - async処理後、ウィジェットがまだ存在するか確認
  /// - 存在しない場合の例外を防ぐ
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (success && mounted) {
        // パスワードマネージャーに保存を促す
        TextInput.finishAutofillContext();
        // ログイン成功時、ホーム画面に遷移
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        // エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'ログインに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========================================
                // タイトル
                // ========================================
                const SizedBox(height: 48),
                const Text(
                  'ログイン',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'アカウントにログインして、ボイスメッセージの送受信を始めましょう',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),

                // ========================================
                // ログインフォーム
                // ========================================
                Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        // メールアドレス入力フィールド
                        TextFormField(
                          controller: _emailController,
                          validator: _validateEmail,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'メールアドレス',
                            hintText: 'example@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // パスワード入力フィールド
                        TextFormField(
                          controller: _passwordController,
                          validator: _validatePassword,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ========================================
                        // ログインボタン
                        // ========================================
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  disabledBackgroundColor: Colors.grey[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'ログイン',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ========================================
                // またはの分割線
                // ========================================
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'または',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),

                // ========================================
                // Google ログインボタン
                // ========================================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final success = await authProvider.loginWithGoogle();
                      if (mounted) {
                        if (success) {
                          Navigator.of(context).pushReplacementNamed('/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  authProvider.error ?? 'Google ログインに失敗しました'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 20),
                    label: const Text(
                      'Google でログイン',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ========================================
                // 登録リンク
                // ========================================
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'アカウントを持っていませんか？',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/register');
                        },
                        child: const Text(
                          '登録',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
