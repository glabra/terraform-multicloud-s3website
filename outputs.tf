output "s3_bucket_arn" {
    value = aws_s3_bucket.source.arn
    description = "ARN of the source S3 bucket"
}
