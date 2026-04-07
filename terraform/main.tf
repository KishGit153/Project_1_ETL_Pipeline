terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- S3 Buckets ---
resource "aws_s3_bucket" "raw" {
  bucket        = "${var.project_name}-raw-${var.your_name}"
  force_destroy = true

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "processed" {
  bucket        = "${var.project_name}-processed-${var.your_name}"
  force_destroy = true

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.project_name}-athena-${var.your_name}"
  force_destroy = true

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

# --- Upload Glue script to S3 ---
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.raw.id
  key    = "scripts/glue_job.py"
  source = "../src/glue_job.py"
  etag   = filemd5("../src/glue_job.py")
}

# --- Glue Database ---
resource "aws_glue_catalog_database" "nyc_taxi_db" {
  name = "nyc_taxi_db"
}

# --- Glue Job ---
resource "aws_glue_job" "nyc_taxi_etl" {
  name         = "${var.project_name}-job"
  role_arn     = aws_iam_role.glue_role.arn
  glue_version = "4.0"

  command {
    script_location = "s3://${aws_s3_bucket.raw.bucket}/scripts/glue_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--RAW_BUCKET"          = "s3://${aws_s3_bucket.raw.bucket}/data/"
    "--PROCESSED_BUCKET"    = "s3://${aws_s3_bucket.processed.bucket}/output/"
    "--job-language"        = "python"
    "--enable-job-insights" = "true"
  }

  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 30

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

# --- Glue Crawler ---
resource "aws_glue_crawler" "processed_crawler" {
  name          = "${var.project_name}-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.nyc_taxi_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.processed.bucket}/output/"
  }

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

# --- Athena Workgroup ---
resource "aws_athena_workgroup" "nyc_taxi" {
  name = "${var.project_name}-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}