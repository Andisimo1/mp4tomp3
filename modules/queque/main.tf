resource "aws_sqs_queue" "Queue" {
  name = var.queueName
}

output "queueUrl" {
  value = aws_sqs_queue.Queue.url
}

output "queueArn" {
  value = aws_sqs_queue.Queue.arn
}