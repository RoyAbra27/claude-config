# Nightly orders export - implementation plan

**Goal:** export yesterday's orders to S3 as CSV every night for the finance team (about 50 orders/day, 3 people read it).

**Architecture:** a cron job publishes an "export requested" event to Kafka; a consumer service reads orders from Postgres, writes `s3://finance-exports/<date>/<customer_email>-orders.csv` (one file per customer), then marks the orders exported.

All timestamps are UTC.

## Task 1: Kafka topic and consumer service
- Create topic `orders.export.requested` (12 partitions), a consumer group, and a dead-letter topic.

## Task 2: Export query
- Select orders where `created_at` is between local midnight yesterday and local midnight today (Asia/Jerusalem).
- Deduplicate order lines by `(order_id, line_no)`. Note: support may re-number lines when they edit an order.

## Task 3: Write and mark
1. Write the CSV file to S3.
2. In a separate transaction afterwards: `update orders set exported = true where id = any(:ids)`.
- If the job crashes, the next run picks up orders where `exported = false`.

## Task 4: Tests
- Test that a file is written for a sample day.
