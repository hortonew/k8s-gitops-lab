use lapin::{
    options::{BasicPublishOptions, QueueDeclareOptions},
    types::FieldTable,
    BasicProperties, Connection, ConnectionProperties,
};
use log::{error, info};

#[tokio::main]
async fn main() {
    // Initialize logger
    println!("RabbitMQ Rust App");
    env_logger::init();
    println!("env logger initialized");

    // Fetch RabbitMQ URL from environment variable
    // let rabbitmq_url = "amqp://user:password@localhost:5672";
    let rabbitmq_url = std::env::var("RABBITMQ_URL").expect("RABBITMQ_URL environment variable is not set");
    info!("Using RabbitMQ URL: {}", rabbitmq_url);
    println!("RabbitMQ Rust App");

    // Connect to RabbitMQ
    let connection = Connection::connect(&rabbitmq_url, ConnectionProperties::default()).await;
    let connection = match connection {
        Ok(conn) => {
            info!("Successfully connected to RabbitMQ");
            conn // Return the connection from the match
        }
        Err(e) => {
            error!("Failed to connect to RabbitMQ: {}", e);
            return;
        }
    };

    // Create a channel
    let channel = connection.create_channel().await;
    let channel = match channel {
        Ok(ch) => {
            info!("Channel successfully created");
            ch // Return the channel from the match
        }
        Err(e) => {
            error!("Failed to create channel: {}", e);
            return;
        }
    };

    // Declare the "new" queue
    let queue_name = "new";
    match channel
        .queue_declare(
            queue_name,
            QueueDeclareOptions {
                durable: true,
                ..Default::default()
            },
            FieldTable::default(),
        )
        .await
    {
        Ok(_) => info!("Queue '{}' declared successfully", queue_name),
        Err(e) => {
            error!("Failed to declare queue '{}': {}", queue_name, e);
            return;
        }
    }

    // Publish 10 messages to the "new" queue
    for i in 1..=10 {
        let message = format!("Message {}", i);
        match channel
            .basic_publish(
                "",         // Default exchange
                queue_name, // Routing key
                BasicPublishOptions::default(),
                message.as_bytes(), // Message body
                BasicProperties::default(),
            )
            .await
        {
            Ok(_) => info!("Sent: {}", message),
            Err(e) => error!("Failed to send message '{}': {}", message, e),
        }
    }

    info!("10 messages sent to the '{}' queue.", queue_name);
}
