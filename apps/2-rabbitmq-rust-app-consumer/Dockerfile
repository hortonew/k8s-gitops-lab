# Builder stage
FROM rust:latest AS builder

WORKDIR /app

# Step 1: Copy dependency files to pre-cache dependencies
COPY Cargo.toml .

# Step 2: Create a dummy main.rs to allow dependency installation
RUN mkdir -p src && echo "fn main() {}" > src/main.rs

# Step 3: Pre-cache dependencies by building the dummy project
RUN cargo build --release

# Step 4: Copy the actual source code
COPY src/ ./src/

# Step 5: Rebuild the application with the real code
RUN cargo build --release

# Final stage
FROM debian:bookworm-slim

WORKDIR /app

# Install required runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libssl3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy only the binary and required assets from the builder stage
COPY --from=builder /app/target/release/rabbitmq-rust-app-consumer /app/

# Ensure the binary is executable
RUN chmod +x /app/rabbitmq-rust-app-consumer

# Set the default command
CMD ["/app/rabbitmq-rust-app-consumer"]
