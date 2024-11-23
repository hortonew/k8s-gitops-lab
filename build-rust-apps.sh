#!/bin/bash
set -e

# Producer
docker build -t hortonew/rabbitmq-rust-app apps/2-rabbitmq-rust-app-producer
docker tag hortonew/rabbitmq-rust-app hortonew/rabbitmq-rust-app:latest
docker tag hortonew/rabbitmq-rust-app hortonew/rabbitmq-rust-app:0.0.6
docker push hortonew/rabbitmq-rust-app:latest
docker push hortonew/rabbitmq-rust-app:0.0.6

# Consumer
docker build -t hortonew/rabbitmq-rust-app-consumer apps/2-rabbitmq-rust-app-consumer
docker tag hortonew/rabbitmq-rust-app-consumer hortonew/rabbitmq-rust-app-consumer:latest
docker tag hortonew/rabbitmq-rust-app-consumer hortonew/rabbitmq-rust-app-consumer:0.0.2
docker push hortonew/rabbitmq-rust-app-consumer:latest
docker push hortonew/rabbitmq-rust-app-consumer:0.0.2
