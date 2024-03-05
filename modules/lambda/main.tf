terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/assets/dns_health_check"
  output_path = "dns_health_check.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  
  inline_policy {
    name = "lambda_health_check_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
         {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
         {
            "Effect": "Allow",
            "Action": "cloudwatch:PutMetricData",
            "Resource": "*"
         }
      ]
    })
  }
 }

resource "random_id" "lambda_function" {
  byte_length = 8
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = "dns_health_check_${random_id.lambda_function.hex}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "dns_health_check.lambda_handler"
  runtime       = "python3.9"
  timeout       = 15
  source_code_hash = data.archive_file.this.output_base64sha256

}
