import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common/rice_button.dart';
import '../../widgets/common/rice_card.dart';
import '../../widgets/common/rice_footer.dart';

enum AuthViewMode {
  signIn,
  signUp,
  confirmSignUp,
  forgotPassword,
  confirmForgotPassword,
}

class AuthView extends StatefulWidget {
  final AuthController authController;
  final AuthViewMode initialMode;

  const AuthView({
    super.key,
    required this.authController,
    this.initialMode = AuthViewMode.signIn,
  });

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  late AuthViewMode _mode;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    widget.authController.addListener(_onAuthControllerUpdate);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthControllerUpdate);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onAuthControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _switchMode(AuthViewMode newMode) {
    setState(() {
      _mode = newMode;
      _localError = null;
      _infoMessage = null;
      widget.authController.clearError();
    });
  }

  String? _effectiveError() {
    return _localError ?? widget.authController.errorMessage;
  }

  void _validateRiceEmailOrThrow(String email) {
    AuthService.validateRiceEmail(email);
  }

  Future<void> _handleSignIn() async {
    if (widget.authController.isLoading) return;
    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _localError = "Please enter your Rice email address.");
      return;
    }
    try {
      _validateRiceEmailOrThrow(email);
    } catch (e) {
      setState(() => _localError = e.toString().replaceAll("FormatException: ", ""));
      return;
    }

    if (password.isEmpty) {
      setState(() => _localError = "Please enter your password.");
      return;
    }

    final success = await widget.authController.signIn(email: email, password: password);
    if (!success && widget.authController.errorMessage != null) {
      if (widget.authController.errorMessage!.contains("UserNotConfirmed")) {
        setState(() {
          _mode = AuthViewMode.confirmSignUp;
          _infoMessage = "Account unconfirmed. Please enter the verification code sent to $email.";
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (widget.authController.isLoading) return;
    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _localError = "Please enter your full name.");
      return;
    }

    if (email.isEmpty) {
      setState(() => _localError = "Please enter your Rice email address.");
      return;
    }

    try {
      _validateRiceEmailOrThrow(email);
    } catch (e) {
      setState(() => _localError = e.toString().replaceAll("FormatException: ", ""));
      return;
    }

    if (password.length < 8) {
      setState(() => _localError = "Password must be at least 8 characters long.");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _localError = "Passwords do not match. Please verify.");
      return;
    }

    final success = await widget.authController.signUp(
      email: email,
      password: password,
      displayName: name,
    );

    if (success) {
      setState(() {
        _mode = AuthViewMode.confirmSignUp;
        _infoMessage = "Account registered! A verification code has been sent to $email.";
      });
    }
  }

  Future<void> _handleConfirmSignUp() async {
    if (widget.authController.isLoading) return;
    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _localError = "Please enter the verification code.");
      return;
    }

    final success = await widget.authController.confirmSignUp(
      email: email,
      confirmationCode: code,
    );

    if (success) {
      setState(() {
        _mode = AuthViewMode.signIn;
        _codeController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _infoMessage = "Email verified successfully! You may now sign in.";
      });
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    try {
      _validateRiceEmailOrThrow(email);
    } catch (e) {
      setState(() => _localError = e.toString().replaceAll("FormatException: ", ""));
      return;
    }

    final success = await widget.authController.resendConfirmationCode(email: email);
    if (success) {
      setState(() {
        _infoMessage = "A new verification code has been sent to $email.";
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    if (widget.authController.isLoading) return;
    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _localError = "Please enter your Rice email address.");
      return;
    }

    try {
      _validateRiceEmailOrThrow(email);
    } catch (e) {
      setState(() => _localError = e.toString().replaceAll("FormatException: ", ""));
      return;
    }

    final success = await widget.authController.forgotPassword(email: email);
    if (success) {
      setState(() {
        _mode = AuthViewMode.confirmForgotPassword;
        _infoMessage = "Password reset code sent to $email. Please enter the code and new password.";
      });
    }
  }

  Future<void> _handleConfirmForgotPassword() async {
    if (widget.authController.isLoading) return;
    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty) {
      setState(() => _localError = "Please enter the password reset code.");
      return;
    }

    if (password.length < 8) {
      setState(() => _localError = "New password must be at least 8 characters long.");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _localError = "Passwords do not match.");
      return;
    }

    final success = await widget.authController.confirmForgotPassword(
      email: email,
      confirmationCode: code,
      newPassword: password,
    );

    if (success) {
      setState(() {
        _mode = AuthViewMode.signIn;
        _passwordController.clear();
        _confirmPasswordController.clear();
        _codeController.clear();
        _infoMessage = "Password reset successful! Please sign in with your new password.";
      });
    }
  }

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: RiceTheme.body(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: RiceTheme.body(fontSize: 14, color: RiceColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: RiceTheme.body(fontSize: 14, color: RiceColors.textSecondary.withValues(alpha: 0.7)),
        prefixIcon: Icon(prefixIcon, size: 20, color: RiceColors.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: RiceColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.riceBlue, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _effectiveError();

    return Scaffold(
      backgroundColor: RiceColors.surfaceBackground,
      body: Column(
        children: [
          // Rice Blue institutional banner
          Container(
            width: double.infinity,
            color: RiceColors.riceBlue,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: RiceColors.laurelGold, size: 32),
                    const SizedBox(width: 14),
                    Text(
                      "RICE UNIVERSITY",
                      style: RiceTheme.heading(
                        color: RiceColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Login Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: RiceCard(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon & Title
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: RiceColors.riceBlue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.link_rounded, size: 36, color: RiceColors.riceBlue),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "URL Shortener & QR Studio",
                          textAlign: TextAlign.center,
                          style: RiceTheme.heading(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: RiceColors.riceBlue,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _getTitleDescription(),
                          textAlign: TextAlign.center,
                          style: RiceTheme.body(fontSize: 14, color: RiceColors.textSecondary, height: 1.4),
                        ),

                        const SizedBox(height: 24),

                        // Error Banner
                        if (errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: RiceColors.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: RiceColors.errorRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline, color: RiceColors.errorRed, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: RiceTheme.body(color: RiceColors.errorRed, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Info / Success Banner
                        if (_infoMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: RiceColors.grassGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: RiceColors.grassGreen.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, color: RiceColors.treeGreen, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _infoMessage!,
                                    style: RiceTheme.body(color: RiceColors.treeGreen, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Mode-specific form
                        ..._buildModeFields(),

                        const SizedBox(height: 24),

                        // Dev Mode Auth Bypass: STRICTLY gated with (kDebugMode && authController.isDevMode)
                        // In release builds (`flutter build web --release`), kDebugMode is const false,
                        // allowing the Dart compiler to tree-shake this entire block and the string out of the bundle.
                        if (kDebugMode && widget.authController.isDevMode) ...[
                          const SizedBox(height: 12),
                          RiceButton(
                            label: "Bypass Auth (Dev Mode)",
                            icon: Icons.developer_mode_rounded,
                            variant: RiceButtonVariant.secondary,
                            isLoading: widget.authController.isLoading,
                            width: double.infinity,
                            onPressed: () => widget.authController.signInAsDev(),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Institutional Notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: RiceColors.lightGray,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 18, color: RiceColors.riceBlue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Restricted to verified @rice.edu email accounts.",
                                  style: RiceTheme.body(
                                    fontSize: 12,
                                    color: RiceColors.textSecondary,
                                    fontWeight: FontWeight.w500,
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
            ),
          ),

          const RiceFooter(),
        ],
      ),
    );
  }

  String _getTitleDescription() {
    switch (_mode) {
      case AuthViewMode.signIn:
        return "Sign in with your official Rice University (@rice.edu) account.";
      case AuthViewMode.signUp:
        return "Create your official Rice University URL Shortener account.";
      case AuthViewMode.confirmSignUp:
        return "Enter the verification code sent to your @rice.edu inbox.";
      case AuthViewMode.forgotPassword:
        return "Reset your password with your verified @rice.edu email.";
      case AuthViewMode.confirmForgotPassword:
        return "Enter the verification code and set a new password.";
    }
  }

  List<Widget> _buildModeFields() {
    switch (_mode) {
      case AuthViewMode.signIn:
        return _buildSignInFields();
      case AuthViewMode.signUp:
        return _buildSignUpFields();
      case AuthViewMode.confirmSignUp:
        return _buildConfirmSignUpFields();
      case AuthViewMode.forgotPassword:
        return _buildForgotPasswordFields();
      case AuthViewMode.confirmForgotPassword:
        return _buildConfirmForgotPasswordFields();
    }
  }

  List<Widget> _buildSignInFields() {
    return [
      _buildFieldLabel("Rice Email Address"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _emailController,
        hintText: "netid@rice.edu",
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) {
          if (_passwordController.text.isNotEmpty) {
            _handleSignIn();
          }
        },
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Password"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _passwordController,
        hintText: "••••••••",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleSignIn(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: RiceColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _switchMode(AuthViewMode.forgotPassword),
          child: Text(
            "Forgot password?",
            style: RiceTheme.body(fontSize: 13, color: RiceColors.riceBlue, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(height: 16),
      RiceButton(
        label: "Sign In",
        icon: Icons.login_rounded,
        variant: RiceButtonVariant.primary,
        isLoading: widget.authController.isLoading,
        width: double.infinity,
        onPressed: _handleSignIn,
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text("Don't have an account? ", style: RiceTheme.body(fontSize: 13, color: RiceColors.textSecondary)),
          TextButton(
            onPressed: () => _switchMode(AuthViewMode.signUp),
            child: Text(
              "Register with @rice.edu",
              style: RiceTheme.body(fontSize: 13, color: RiceColors.riceBlue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSignUpFields() {
    return [
      _buildFieldLabel("Full Name"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _nameController,
        hintText: "Sammy Owl",
        prefixIcon: Icons.person_outline,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Rice Email Address"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _emailController,
        hintText: "netid@rice.edu",
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Password (min 8 characters)"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _passwordController,
        hintText: "••••••••",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: RiceColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Confirm Password"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _confirmPasswordController,
        hintText: "••••••••",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleSignUp(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: RiceColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      const SizedBox(height: 20),
      RiceButton(
        label: "Create Account",
        icon: Icons.person_add_rounded,
        variant: RiceButtonVariant.primary,
        isLoading: widget.authController.isLoading,
        width: double.infinity,
        onPressed: _handleSignUp,
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text("Already have an account? ", style: RiceTheme.body(fontSize: 13, color: RiceColors.textSecondary)),
          TextButton(
            onPressed: () => _switchMode(AuthViewMode.signIn),
            child: Text(
              "Sign In",
              style: RiceTheme.body(fontSize: 13, color: RiceColors.riceBlue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildConfirmSignUpFields() {
    return [
      _buildFieldLabel("Rice Email"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _emailController,
        hintText: "netid@rice.edu",
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Verification Code (from email)"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _codeController,
        hintText: "123456",
        prefixIcon: Icons.pin_outlined,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleConfirmSignUp(),
      ),
      const SizedBox(height: 20),
      RiceButton(
        label: "Confirm Account",
        icon: Icons.verified_user_rounded,
        variant: RiceButtonVariant.primary,
        isLoading: widget.authController.isLoading,
        width: double.infinity,
        onPressed: _handleConfirmSignUp,
      ),
      const SizedBox(height: 12),
      RiceButton(
        label: "Resend Code",
        icon: Icons.refresh_rounded,
        variant: RiceButtonVariant.outline,
        isLoading: widget.authController.isLoading,
        width: double.infinity,
        onPressed: _handleResendCode,
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => _switchMode(AuthViewMode.signIn),
        child: Text(
          "Back to Sign In",
          style: RiceTheme.body(fontSize: 13, color: RiceColors.riceBlue, fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  List<Widget> _buildForgotPasswordFields() {
    return [
      _buildFieldLabel("Rice Email Address"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _emailController,
        hintText: "netid@rice.edu",
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleForgotPassword(),
      ),
      const SizedBox(height: 20),
      RiceButton(
        label: "Send Reset Code",
        icon: Icons.send_rounded,
        variant: RiceButtonVariant.primary,
        isLoading: widget.authController.isLoading,
        width: double.infinity,
        onPressed: _handleForgotPassword,
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => _switchMode(AuthViewMode.signIn),
        child: Text(
          "Back to Sign In",
          style: RiceTheme.body(fontSize: 13, color: RiceColors.riceBlue, fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  List<Widget> _buildConfirmForgotPasswordFields() {
    return [
      _buildFieldLabel("Rice Email Address"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _emailController,
        hintText: "netid@rice.edu",
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Password Reset Code"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _codeController,
        hintText: "123456",
        prefixIcon: Icons.pin_outlined,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("New Password (min 8 characters)"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _passwordController,
        hintText: "••••••••",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: RiceColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 16),
      _buildFieldLabel("Confirm New Password"),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _confirmPasswordController,
        hintText: "••••••••",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleConfirmForgotPassword(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: RiceColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      const SizedBox(height: 20),
      RiceButton(
        label: "Set New Password",
        icon: Icons.check_circle_rounded,
        variant: RiceButtonVariant.primary,
        isLoading: widget.authController.isLoading,
        width: double.infinity,
        onPressed: _handleConfirmForgotPassword,
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => _switchMode(AuthViewMode.signIn),
        child: Text(
          "Back to Sign In",
          style: RiceTheme.body(fontSize: 13, color: RiceColors.riceBlue, fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }
}
