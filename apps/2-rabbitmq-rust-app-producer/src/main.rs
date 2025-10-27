use lapin::{
    options::{BasicPublishOptions, QueueDeclareOptions},
    types::FieldTable,
    BasicProperties, Connection, ConnectionProperties,
};
use log::{error, info};
use pyroscope::PyroscopeAgent;
use pyroscope_pprofrs::{pprof_backend, PprofConfig};

#[tokio::main]
async fn main() {
    if let Err(e) = run().await {
        error!("Application error: {}", e);
        std::process::exit(1);
    }
}

async fn run() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logger
    println!("RabbitMQ Rust App");
    env_logger::init();
    println!("env logger initialized");

    // Get Pyroscope configuration from environment variables
    let pyroscope_url =
        std::env::var("PYROSCOPE_SERVER_ADDRESS").unwrap_or_else(|_| "http://pyroscope.pyroscope.svc.cluster.local:4040".to_string());
    let app_name = std::env::var("PYROSCOPE_APPLICATION_NAME").unwrap_or_else(|_| "rabbitmq-rust-producer".to_string());

    info!("Initializing Pyroscope profiling...");
    info!("Pyroscope URL: {}", pyroscope_url);
    info!("Application Name: {}", app_name);

    // Initialize Pyroscope agent
    let agent = PyroscopeAgent::builder(&pyroscope_url, &app_name)
        .backend(pprof_backend(PprofConfig::new().sample_rate(100)))
        .tags(vec![("service", "rabbitmq-producer"), ("component", "producer")])
        .build()?;

    // Start the profiling agent
    let agent_running = agent.start()?;
    info!("Pyroscope profiling started successfully");

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
            return Err(Box::new(e));
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
            return Err(Box::new(e));
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
            return Err(Box::new(e));
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

    // Stop profiling on shutdown
    info!("Stopping Pyroscope profiling...");
    let agent_ready = agent_running.stop()?;
    agent_ready.shutdown();
    info!("Pyroscope profiling stopped");

    Ok(())
}
