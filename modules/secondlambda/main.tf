resource "aws_iam_role" "lambda_role" {
  name = "second_lambda_role"

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
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "second_lambda_policy"
  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:Describe*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "oam:ListSinks"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "arn:aws:iam::*:role/aws-service-role/events.amazonaws.com/AWSServiceRoleForCloudWatchEvents*",
        "Condition" : {
          "StringLike" : {
            "iam:AWSServiceName" : "events.amazonaws.com"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "oam:ListAttachedLinks"
        ],
        "Resource" : "arn:aws:oam:*:*:sink/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ses:*"
        ],
        "Resource" : "*"
      },
      {
        "Action" : [
          "sqs:*"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "s3-object-lambda:*"
        ],
        "Resource" : "*"
      }
    ]
  })
  role = aws_iam_role.lambda_role.name
}

data "archive_file" "zipPythonCode" {
  type        = "zip"
  source_dir  = "${path.module}/pythonCode/"
  output_path = "${path.module}/pythonCode/lambda_function.zip"
}

resource "aws_lambda_function" "s3_lambda2" {
  function_name    = "second_s3_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = base64sha256(data.archive_file.zipPythonCode.output_path)
  filename         = data.archive_file.zipPythonCode.output_path
}

resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = var.bucketName

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda2.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.prefix
  }

  lambda_function {
    lambda_function_arn = var.function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.prefix2
  }

  depends_on = [aws_lambda_permission.s3_lambda_permission, aws_lambda_permission.s3_lambda_permission2]
}

resource "aws_lambda_permission" "s3_lambda_permission2" {
  statement_id  = "AllowExecutionFromS3Bucket2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda2.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

resource "aws_lambda_permission" "s3_lambda_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}