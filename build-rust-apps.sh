#!/bin/bash
set -e

# docker login before doing all this

# Producer
docker build -t hortonew/rabbitmq-rust-app apps/2-rabbitmq-rust-app-producer
docker tag hortonew/rabbitmq-rust-app hortonew/rabbitmq-rust-app:latest
docker tag hortonew/rabbitmq-rust-app hortonew/rabbitmq-rust-app:0.0.8
docker push hortonew/rabbitmq-rust-app:latest
docker push hortonew/rabbitmq-rust-app:0.0.8

# Consumer
docker build -t hortonew/rabbitmq-rust-app-consumer apps/2-rabbitmq-rust-app-consumer
docker tag hortonew/rabbitmq-rust-app-consumer hortonew/rabbitmq-rust-app-consumer:latest
docker tag hortonew/rabbitmq-rust-app-consumer hortonew/rabbitmq-rust-app-consumer:0.0.4
docker push hortonew/rabbitmq-rust-app-consumer:latest
docker push hortonew/rabbitmq-rust-app-consumer:0.0.4
