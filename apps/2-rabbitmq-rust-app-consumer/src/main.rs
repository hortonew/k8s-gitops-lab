use futures_util::StreamExt;
use lapin::{
    options::{BasicConsumeOptions, QueueDeclareOptions},
    types::FieldTable,
    Connection, ConnectionProperties,
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
    println!("RabbitMQ Consumer App");
    env_logger::init();

    // Get Pyroscope configuration from environment variables
    let pyroscope_url =
        std::env::var("PYROSCOPE_SERVER_ADDRESS").unwrap_or_else(|_| "http://pyroscope.pyroscope.svc.cluster.local:4040".to_string());
    let app_name = std::env::var("PYROSCOPE_APPLICATION_NAME").unwrap_or_else(|_| "rabbitmq-rust-consumer".to_string());

    info!("Initializing Pyroscope profiling...");
    info!("Pyroscope URL: {}", pyroscope_url);
    info!("Application Name: {}", app_name);

    // Initialize Pyroscope agent
    let agent = PyroscopeAgent::builder(&pyroscope_url, &app_name)
        .backend(pprof_backend(PprofConfig::new().sample_rate(100)))
        .tags(vec![("service", "rabbitmq-consumer"), ("component", "consumer")])
        .build()?;

    // Start the profiling agent
    let agent_running = agent.start()?;
    info!("Pyroscope profiling started successfully");

    // Fetch RabbitMQ URL from environment variable
    // let rabbitmq_url = "amqp://user:password@localhost:5672";
    let rabbitmq_url = std::env::var("RABBITMQ_URL").expect("RABBITMQ_URL environment variable is not set");
    info!("Using RabbitMQ URL: {}", rabbitmq_url);

    // Connect to RabbitMQ
    let connection = Connection::connect(&rabbitmq_url, ConnectionProperties::default())
        .await
        .expect("Failed to connect to RabbitMQ");
    info!("Successfully connected to RabbitMQ");

    // Create a channel
    let channel = connection.create_channel().await.expect("Failed to create channel");
    info!("Channel successfully created");

    // Declare the "new" queue
    let queue_name = "new";
    channel
        .queue_declare(
            queue_name,
            QueueDeclareOptions {
                durable: true,
                ..Default::default()
            },
            FieldTable::default(),
        )
        .await
        .expect("Failed to declare queue");
    info!("Queue '{}' declared successfully", queue_name);

    // Start consuming messages
    let mut consumer = channel
        .basic_consume(queue_name, "consumer_tag", BasicConsumeOptions::default(), FieldTable::default())
        .await
        .expect("Failed to start consuming");
    info!("Started consuming messages from queue '{}'", queue_name);

    while let Some(delivery_result) = consumer.next().await {
        match delivery_result {
            Ok(delivery) => {
                let message = String::from_utf8_lossy(&delivery.data);
                info!("Received message: {}", message);

                // Acknowledge the message
                if let Err(e) = delivery.ack(Default::default()).await {
                    error!("Failed to acknowledge message: {}", e);
                } else {
                    info!("Message acknowledged");
                }
            }
            Err(e) => error!("Error in message delivery: {}", e),
        }
    }

    // Stop profiling on shutdown
    info!("Stopping Pyroscope profiling...");
    let agent_ready = agent_running.stop()?;
    agent_ready.shutdown();
    info!("Pyroscope profiling stopped");

    Ok(())
}
