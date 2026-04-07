# NYC Taxi ETL Pipeline

An end-to-end ETL pipeline on AWS built with Terraform, processing 3.5 million 
rows of NYC Taxi trip data through a serverless data lake architecture.

## Architecture

S3 (raw) → AWS Glue PySpark job → S3 (Parquet) → Athena (SQL queries)

All infrastructure is provisioned as code using Terraform.

## Tech Stack

- **Terraform** — infrastructure as code
- **AWS S3** — data lake (raw and processed layers)
- **AWS Glue** — serverless PySpark ETL job
- **AWS Athena** — serverless SQL querying
- **AWS IAM** — least privilege roles and policies

## What the Pipeline Does

1. Ingests raw NYC Yellow Taxi Parquet data into S3
2. Runs a Glue PySpark job that:
   - Drops rows with null values in key columns
   - Casts columns to correct types
   - Filters out invalid trips (zero distance, zero fare)
   - Adds a derived `fare_per_mile` column
3. Writes cleaned data back to S3 as Parquet
4. Glue Crawler catalogues the schema into the Glue Data Catalog
5. Athena queries the processed data via SQL

## Results

- **3,560,826** clean rows processed
- Average fare per mile analysed by passenger count
- Top 10 most expensive trips identified

## How to Run

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform installed

### Deploy
```bash
cd terraform
terraform init
terraform apply -var="your_name=yourname"
```

### Upload data
```bash
aws s3 cp yellow_tripdata_2026-01.parquet s3://nyc-taxi-etl-raw-yourname/data/
```

### Run the pipeline
```bash
aws glue start-job-run --job-name nyc-taxi-etl-job
```

### Tear down
```bash
terraform destroy -var="your_name=yourname"
```

## Production Considerations

- Would add Step Functions for orchestration and error handling
- Would scope IAM permissions down further (no wildcards)
- Would add data quality checks before writing to processed layer
- Would partition output by date for better Athena query performance
- Would use Terraform remote state (S3 backend) for team environments