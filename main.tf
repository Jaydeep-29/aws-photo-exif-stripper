provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "uploads" {
  bucket = "company-uploads-bucket-unique"
}

resource "aws_s3_bucket" "processed" {
  bucket = "company-processed-bucket-unique"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_exif_stripper_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_exif_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.uploads.arn}/*",
          "${aws_s3_bucket.processed.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "exif_strip" {
  function_name = "exif-stripper"
  handler       = "main.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.processed.bucket
    }
  }
}

resource "aws_s3_bucket_notification" "uploads_notification" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.exif_strip.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_s3_invocation]
}

resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exif_strip.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

resource "aws_iam_user" "user_a" {
  name = "UserA"
}

resource "aws_iam_user_policy" "user_a_policy" {
  name = "UserABucketAPolicy"
  user = aws_iam_user.user_a.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      Resource: "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

resource "aws_iam_user" "user_b" {
  name = "UserB"
}

resource "aws_iam_user_policy" "user_b_policy" {
  name = "UserBBucketBPolicy"
  user = aws_iam_user.user_b.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: ["s3:GetObject"],
      Resource: "${aws_s3_bucket.processed.arn}/*"
    }]
  })
}

