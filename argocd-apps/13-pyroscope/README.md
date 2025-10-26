# Pyroscope - Continuous Profiling

Pyroscope is deployed for continuous profiling of the RabbitMQ Rust applications.

## Configuration

- **Chart**: grafana/pyroscope v1.10.0
- **Namespace**: pyroscope
- **Service Port**: 4040
- **Resources**: 200m/256Mi requests, 500m/512Mi limits
- **Persistence**: Disabled (ephemeral storage for lab)

## Accessing Pyroscope

Via port-forward:
```bash
just port-forward
# Then visit: http://localhost:4040
```

Or directly:
```bash
kubectl port-forward -n pyroscope svc/pyroscope 4040:4040
```

## Integration with Rust Applications

To send profiles from Rust applications to Pyroscope, you need to:

### 1. Add Pyroscope Client Library

Add to `Cargo.toml`:
```toml
[dependencies]
pyroscope = "0.5"
pyroscope_pprofrs = "0.2"
```

### 2. Initialize Pyroscope Agent

In your Rust application's `main.rs`:

```rust
use pyroscope::{PyroscopeAgent, Result};
use pyroscope_pprofrs::{pprof_backend, PprofConfig};

fn main() -> Result<()> {
    // Initialize Pyroscope agent
    let agent = PyroscopeAgent::builder("http://pyroscope.pyroscope.svc.cluster.local:4040", "rust-app")
        .backend(pprof_backend(PprofConfig::new().sample_rate(100)))
        .tags([("service", "rabbitmq-producer")]) // or "rabbitmq-consumer"
        .build()?;

    // Start the agent
    let agent_running = agent.start()?;

    // Your application code here...
    
    // Stop the agent on shutdown
    let agent_ready = agent_running.stop()?;
    agent_ready.shutdown();
    
    Ok(())
}
```

### 3. Environment Variable Configuration

Alternatively, configure via environment variables in the Kubernetes deployment:

```yaml
env:
- name: PYROSCOPE_SERVER_ADDRESS
  value: "http://pyroscope.pyroscope.svc.cluster.local:4040"
- name: PYROSCOPE_APPLICATION_NAME
  value: "rust-rabbitmq-producer"  # or "rust-rabbitmq-consumer"
- name: PYROSCOPE_SAMPLE_RATE
  value: "100"
```

## Viewing Profiles in Grafana

Pyroscope is integrated with Grafana:

1. Visit Grafana: http://localhost:3000 (admin/admin)
2. Go to "Explore"
3. Select "Pyroscope" datasource
4. Query profiles by application name
5. View flame graphs and profile data

You can also correlate profiles with:
- **Metrics** from Prometheus (CPU usage, memory, etc.)
- **Logs** from Loki (errors, events)

## ServiceMonitor

Pyroscope exposes metrics that are scraped by Prometheus:
- Release label: `prometheus`
- Metrics endpoint: `/metrics`

## Resources

- [Pyroscope Documentation](https://grafana.com/docs/pyroscope/)
- [Rust SDK](https://grafana.com/docs/pyroscope/latest/configure-client/language-sdks/rust/)
- [Profile Types](https://grafana.com/docs/pyroscope/latest/view-and-analyze-profile-data/profiling-types/)
