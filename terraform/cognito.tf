# =============================================================================
# COGNITO USER POOL & PRE-SIGNUP LAMBDA TRIGGER
# =============================================================================

# 1. IAM Role for PreSignUp Lambda Trigger
resource "aws_iam_role" "cognito_pre_signup" {
  name = "${var.project_name}-${var.environment}-pre-signup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-pre-signup-role"
  }
}

resource "aws_iam_role_policy_attachment" "cognito_pre_signup_basic" {
  role       = aws_iam_role.cognito_pre_signup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 2. Package Lambda Source Code
data "archive_file" "cognito_pre_signup" {
  type        = "zip"
  output_path = "${path.module}/cognito_pre_signup.zip"

  source {
    content  = <<-EOT
def handler(event, context):
    """
    Cognito PreSignUp Lambda Trigger.
    Enforces that only verified @rice.edu email addresses can register.
    """
    req = event.get('request', {})
    user_attrs = req.get('userAttributes', {})
    email = user_attrs.get('email', '') or event.get('userName', '')
    email = email.strip().lower()

    if not email.endswith('@rice.edu'):
        raise Exception("Access restricted: Registration is exclusively permitted for verified @rice.edu email addresses.")

    return event
EOT
    filename = "index.py"
  }
}

# 3. PreSignUp Lambda Function
resource "aws_lambda_function" "cognito_pre_signup" {
  filename         = data.archive_file.cognito_pre_signup.output_path
  source_code_hash = data.archive_file.cognito_pre_signup.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-cognito-pre-signup"
  role             = aws_iam_role.cognito_pre_signup.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 5

  tags = {
    Name = "${var.project_name}-cognito-pre-signup"
  }
}

# 4. Lambda Permission for Cognito Invocations
resource "aws_lambda_permission" "cognito_pre_signup" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_pre_signup.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.pool.arn
}

# 5. Cognito User Pool
resource "aws_cognito_user_pool" "pool" {
  name                     = "${var.project_name}-${var.environment}-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  lambda_config {
    pre_sign_up = aws_lambda_function.cognito_pre_signup.arn
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Rice URL Shortener - Verification Code"
    email_message        = "Welcome to Rice URL Shortener & QR Studio. Your verification code is {####}. This code expires in 24 hours."
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  lifecycle {
    ignore_changes = [schema]
  }

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

# 6. Cognito User Pool Web Client
resource "aws_cognito_user_pool_client" "client" {
  name                                 = "${var.project_name}-${var.environment}-web-client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  generate_secret                      = false
  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  supported_identity_providers = var.enable_saml_sso ? ["COGNITO", var.saml_provider_name] : ["COGNITO"]
}

# 7. SAML 2.0 / Shibboleth Federation Readiness (Rice NetID SSO)
resource "aws_cognito_identity_provider" "rice_saml" {
  count         = var.enable_saml_sso ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = var.saml_provider_name
  provider_type = "SAML"

  provider_details = merge(
    var.saml_metadata_url != "" ? { MetadataURL = var.saml_metadata_url } : {},
    var.saml_metadata_file != "" ? { MetadataFile = file(var.saml_metadata_file) } : {}
  )

  attribute_mapping = {
    email    = "mail"
    name     = "displayName"
    username = "netid"
  }
}

resource "aws_cognito_user_pool_domain" "auth_domain" {
  count        = var.enable_saml_sso ? 1 : 0
  domain       = "${var.project_name}-${var.environment}-auth"
  user_pool_id = aws_cognito_user_pool.pool.id
}
