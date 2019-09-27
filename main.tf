provider "aws" {
  region = "us-east-1"
  profile = "irdn"
}

module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda"

  function_name = "baby-size-infro"
  description   = "Fetch size info and post to slack"
  handler       = "main.handler"
  runtime       = "python3.7"
  timeout       = 300

  source_path = "${path.module}/main.py"

  environment = {
    variables = {
      SLACK_TOKEN = var.slack_token
    }
  }
}

variable "slack_token" {
    description = "Token to use when communicating with slack"
    type = string
}


resource "aws_cloudwatch_event_rule" "babycron" {
    name = "fridays-at-8"
    description = "Fires on fridays"
    schedule_expression = "cron(0 8 ? * 6 *)"
}


resource "aws_cloudwatch_event_target" "run_baby" {
    rule = "${aws_cloudwatch_event_rule.babycron.name}"
    target_id = "lambda"
    arn = "${module.lambda.function_arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_baby" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = module.lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.babycron.arn}"
}