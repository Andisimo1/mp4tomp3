resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

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
  name = "lambda_policy"
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

resource "aws_lambda_layer_version" "layer" {
  compatible_architectures = ["x86_64"]
  compatible_runtimes      = ["python3.10"]
  layer_name               = "Layer"
  s3_bucket                = "bucket-for-task-convertor-mp4-to-mp3"
  s3_key                   = "mypackage.zip"
}

resource "aws_lambda_function" "s3_lambda" {
  function_name    = "s3_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = base64sha256(data.archive_file.zipPythonCode.output_path)
  filename         = data.archive_file.zipPythonCode.output_path
  timeout          = 300
  layers           = [aws_lambda_layer_version.layer.arn]
}

output "function_name" {
  value = aws_lambda_function.s3_lambda.function_name
}

output "function_arn" {
  value = aws_lambda_function.s3_lambda.arn
}