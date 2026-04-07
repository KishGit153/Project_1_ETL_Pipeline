output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed.bucket
}

output "glue_job_name" {
  value = aws_glue_job.nyc_taxi_etl.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.nyc_taxi.name
}