# Harbor Standalone Deployment Pattern

- Status: accepted
- Deciders: Venkata Mutyala, Alanis Swanepoel
- Date: 2025-08-31
- Tags: harbor, implementation, deployment-pattern, docker-compose, standalone

Technical Story: 

## Context and Problem Statement

Now that Harbor has been selected, our immediate goal is to integrate it into our ecosystem efficiently, without the large upfront cost of a complex, multi-node deployment. We are adopting a "crawl, walk, run" approach.

How can we deploy Harbor for its initial rollout in a way that is quick to implement, simple to understand, and straightforward to manage, while establishing a foundation for potential future enhancements like high availability?

## Decision Drivers

- **Tiered Architecture for Resilience:** The core/replica model across data centers is a deliberate choice for availability and disaster recovery.
- **Cache Durability and Protection:** The plan for long-lived caches on core nodes, protected from the churn of short-lived replica caches, is a key driver for ensuring upstream stability.
- **Strict Upstream Isolation:** Forcing replicas to only talk to cores is a key security and control pattern.
- **Predictability through Immutability:** Using an immutable model is a core operational principle that dictates the entire management lifecycle.
- **Frictionless Bootstrapping:** The "no auth" decision is a specific trade-off to simplify a critical process.
- **DNS-based Service Discovery:** Choosing DNS over LBs is a significant architectural choice for resilience, performance, and cost.
- **Environment Parity:** Ensuring the solution works seamlessly from a developer's laptop to production is a major driver of adoption and efficiency.

## Considered Options

- Core/Replica Immutable Pattern (Self-hosted)
- Simple Standalone Pattern (Self-hosted)
- Kubernetes-based Deployment (Self-hosted)
- Hosted Harbor as a Service (e.g., container-registry.com)
- Traditional Mutable Server Pattern (Self-hosted)

## Decision Outcome

Chosen option: "**Core/Replica Immutable Pattern (Self-hosted)**", because it best meets our drivers for resilience, cache durability, and operational predictability.

The implementation will follow a tiered architecture consisting of **Core** nodes and **Replica** nodes, both managed as immutable deployments via Terraform and Docker Compose.

- **Architecture**:
    - **Core Nodes** will run in at least two different datacenters for high availability. They will connect directly to upstream registries and maintain a long-term cache of 180 days.
    - **Replica Nodes** will be deployed in various locations. They will be configured to use the Core nodes exclusively as their upstream proxy and will never talk to external registries. Replicas will maintain a short-term cache of 14 days.

- **Networking and Availability**:
    - A **DNS-based** approach will be used for service discovery, load balancing, and health checks (e.g., via Route53) for both core and replica pools, avoiding the need for dedicated load balancers.
    - DNS will support geo-based routing and round-robin distribution to available nodes.

- **Operations and Configuration**:
    - **Authentication** will be disabled for image pulls to ensure a frictionless bootstrapping process for clusters.
    - The entire setup is **immutable**; nodes will be rebuilt from scratch for any maintenance or updates.
    - The cache on Core nodes will need to be repopulated via a manual or scheduled job after a rebuild.
    - **Local development** will use HTTP, while CI (GitHub Actions) and production environments will use HTTPS. Production certificates will be managed manually via Let's Encrypt.

### Positive Consequences

- **High Resilience:** The core/replica model across multiple datacenters with DNS failover provides strong protection against single-point-of-failure outages.
- **Cache Protection:** The tiered caching strategy protects the primary, long-term cache from being wiped out by the frequent rebuilds of ephemeral replica nodes.
- **Consistent Environments:** The pattern works for local development, CI, and production, reducing surprises and bugs.

### Negative Consequences

- **Manual Cache Repopulation:** The cache on core nodes must be manually or semi-manually rebuilt after every deployment, which can be time-consuming.
- **Manual Certificate Management:** The process for generating and deploying Let's Encrypt certificates for production nodes is a manual, operational task.
- **Increased Architectural Complexity:** While resilient, the core/replica model is more complex to understand and troubleshoot than a single standalone instance.

## Pros and Cons of the Options

### Core/Replica Immutable Pattern

-   **Good**, because the tiered core/replica architecture provides high resilience and protects the primary cache.
-   **Good**, because the immutable nature of the deployment leads to highly predictable and repeatable behavior.
-   **Good**, because using DNS for load balancing and failover is a cost-effective and scalable solution.
-   **Good**, because the pattern is consistent across local development, CI, and production environments.
-   **Bad**, because rebuilding the primary cache after a deployment is an operational burden.
-   **Bad**, because it requires manual management of TLS certificates for production environments.
-   **Bad**, because adding, removing, or changing nodes requires manual DNS record updates.
-   **Bad**, because the overall architecture is more complex than a simple standalone deployment.

### Simple Standalone Pattern

-   **Good**, because the architecture is much simpler, making it easier to deploy, understand, and troubleshoot.
-   **Good**, because there are fewer components to manage, resulting in lower operational overhead.
-   **Bad**, because as a single point of failure, any unplanned outage or planned maintenance will result in downtime unless a complex manual DNS cutover is performed.
-   **Bad**, because the entire cache is vulnerable and destroyed during any rebuild, increasing load on upstream registries.

### Kubernetes-based Deployment

-   **Good**, because Kubernetes offers automated self-healing and rolling updates, which can significantly improve availability.
-   **Good**, because it integrates well with the cloud-native ecosystem for automating tasks like certificate management and monitoring.
-   **Bad**, because it creates a "chicken-and-egg" bootstrapping problem, as the cluster itself may need the registry to deploy.
-   **Bad**, because this infrastructure-critical cluster would need to be managed differently from standard application clusters, creating operational complexity.
-   **Bad**, because the financial and resource cost of running a dedicated, resilient Kubernetes cluster across multiple datacenters is significantly high.

### Hosted Harbor as a Service

-   **Good**, because it completely eliminates the operational overhead of managing infrastructure, uptime, patching, and backups.
-   **Good**, because it provides instant setup and access to expert support from the vendor.
-   **Bad**, because it incurs a direct, recurring subscription cost.
-   **Bad**, because it offers less control and flexibility over configuration and version upgrades.
-   **Bad**, because storing images with a third party could introduce new security and data residency concerns.
-   **Bad**, because it is still vulnerable to internet routing and network pathing issues from our datacenters.

### Traditional Mutable Server Pattern

-   **Good**, because the cache and all other data persist across application updates, avoiding the need for constant cache rebuilds.
-   **Good**, because small updates can be deployed quickly without rebuilding an entire machine image.
-   **Bad**, because it is highly susceptible to "configuration drift," where servers become inconsistent and unreliable over time.
-   **Bad**, because the state of the server is not declaratively defined, which makes troubleshooting and disaster recovery more difficult and less predictable.
-   **Bad**, because this operational model goes against our established principle of using immutable infrastructure.

## Links