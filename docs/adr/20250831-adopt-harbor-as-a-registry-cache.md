# Adopt Harbor as a Registry Cache

- Status: accepted
- Deciders: Venkata Mutyala, Alanis Swanepoel
- Date: 2025-08-30
- Tags: registry, caching, container, devops

Technical Story: 

## Context and Problem Statement

Our cluster bootstrap and upgrade processes depend on multiple external container registries, including Quay.io and GHCR.io. This direct dependency introduces several critical risks to our operations:

1.  **Reliability:** We have experienced service outages from these upstream registries, which have caused critical failures, such as pausing cluster upgrades mid-process.
2.  **Throttling:** We are subject to inconsistent and changing rate limits that can disrupt automated processes. The alternative, managing authentication tokens for each cluster to bypass these limits, creates significant operational overhead.
3.  **Connectivity:** We have faced persistent network routing issues between our data centers (e.g., Hetzner) and specific registries, leading to unreliable image pulls.

How can we insulate our operations from the availability, throttling, and network instability of external container registries?

## Decision Drivers

- Increase the reliability and availability of container images.
- Eliminate build failures caused by external registry rate-limiting.
- Centralize control and management of upstream registry access.
- Reduce operational overhead of managing registry credentials across clusters.

## Considered Options

- Harbor
- Sonatype Nexus Repository
- JFrog Artifactory
- Cloud-hosted registry caches (e.g., AWS ECR, GCP Artifact Registry)
- Basic Docker Registry (`registry:2` image)
- CNCF Distribution (backend for Docker Registry)
- A custom "registry router" / facade

## Decision Outcome

Chosen option: "Harbor", because it is a well-supported open-source project that directly addresses our needs for reliability and centralized control, has good integration with infrastructure-as-code tools like Terraform, and offers a straightforward operational model.

### Positive Consequences

- No rate limits unless we specify them internally.
- Built-in image vulnerability scanning via Trivy.
- Supports proxying a number of upstream repositories with various caching rules.
- Ability to manage configuration easily via Terraform and Docker Compose.

### Negative Consequences

- **Operational Overhead:** We are now responsible for the uptime, monitoring, and security patching of the Harbor instance.
- **New Single Point of Failure:** The service acts as a centralized dependency; its failure will block all CI/CD pipelines and cluster provisioning.
- **Implementation-Specific Trade-offs:** The planned immutable deployment model requires the cache to be rebuilt during maintenance, and the use of local storage makes cache data ephemeral.

## Pros and Cons of the Options

### Harbor

-   **Good**, because it has strong support for infrastructure-as-code via Terraform.
-   **Good**, because the Docker Compose deployment model simplifies management and upgrades for a single node.
-   **Good**, because it includes built-in vulnerability scanning with Trivy.
-   **Good**, because it can proxy multiple upstream repositories with flexible caching rules.
-   **Good**, because it eliminates external rate limits, giving us full control.
-   **Bad**, because our immutable deployment model requires the cache to be rebuilt during maintenance.
-   **Bad**, because a high-availability (HA) deployment is complex, requiring shared storage and management of multiple stateful components like Postgres and Redis.

### Sonatype Nexus Repository

-   **Good**, because it is a powerful, universal artifact manager that supports many package types.
-   **Bad**, because its broad feature set adds complexity that is not required for our specific use case of caching Kubernetes images.
-   **Bad**, because it was not investigated in-depth due to its perceived complexity for this narrow use case.

### JFrog Artifactory

-   **Good**, because it is a mature and feature-rich universal artifact manager.
-   **Bad**, because prior operational experience with the tool showed it to be complex and difficult to manage.

### Cloud-hosted registry caches

-   **Good**, because they are fully managed services, which would eliminate operational overhead.
-   **Good**, because they typically offer high availability and scalability out of the box.
-   **Bad**, because they introduce vendor lock-in to a specific cloud provider.
-   **Bad**, because they were perceived to be a premium-cost solution compared to self-hosting.
-   **Bad**, because they could still suffer from the same network routing issues between the cloud provider and our data centers.

### Basic Docker Registry (`registry:2` image)

-   **Good**, because it is lightweight, simple to run, and familiar to the team.
-   **Bad**, because it lacks advanced features like a user interface, vulnerability scanning, and robust user management.
-   **Bad**, because it is not designed to act as a caching proxy for multiple, disparate upstream registries.
-   **Bad**, because it does not perform automatic garbage collection, requiring manual intervention to clean up storage when it runs out of space.

### CNCF Distribution

-   **Good**, because it is the foundational open-source project for Docker Registry v2 and is highly performant.
-   **Good**, because it supports using S3 pre-signed URLs, which offloads the data transfer from the service to S3 directly.
-   **Good**, because it supports non-AWS S3-compatible object storage providers.
-   **Bad**, because it is primarily a library/backend, not a full-featured product, lacking a UI and other user-friendly features.
-   **Bad**, because it is not designed to easily proxy multiple upstream registries.
-   **Bad**, because testing revealed a critical bug where caching to S3 could fail silently, compromising the reliability of the cache.

### A custom "registry router" / facade

-   **Good**, because it could provide a single entry point for all registry requests.
-   **Bad**, because it is not a cache; it only routes requests and does not solve the problems of upstream availability or outages.
-   **Bad**, because it does not protect against upstream rate-limiting.
-   **Bad**, because it is still vulnerable to the same network routing issues between our data centers and the upstream registries.

## Links

- [Harbor Project Website](https://goharbor.io/)
- [Harbor Terraform Provider](https://registry.terraform.io/providers/goharbor/harbor/latest/docs)
- [Sonatype Nexus Repository](https://www.sonatype.com/products/nexus-repository)
- [JFrog Artifactory](https://jfrog.com/artifactory/)
- [Docker Hub Registry Image](https://hub.docker.com/_/registry)
- [CNCF Distribution Project (GitHub)](https://github.com/distribution/distribution/)
- [HTTP Toolkit Blog: Docker Registry Facade](https://httptoolkit.com/blog/docker-image-registry-facade/)