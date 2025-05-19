# Log Ingestion Pipeline Architecture

## About This Repository

This repository provides technical documentation and implementation guidance for establishing a log ingestion pipeline for observability and security monitoring. Log ingestion architectures can be complex due to diverse environmental conditions, organizational needs, policy constraints, and infrastructure limitations.

The primary objective of this repository is to demonstrate a sample architecture suitable for medium-sized, heterogeneous computing environments. This includes environments composed of thousands of workstations and servers, primarily running Windows and Linux operating systems.

This repository is a subset of a broader initiative aimed at documenting and standardizing the deployment of Google Security Operations (SIEM and SOAR). While the final ingestion endpoint is assumed to be Google Security Operations, the concepts and components described here are designed to remain as agnostic and adaptable as possible.

## Log Ingestion Pipeline

![Log Ingestion Pipeline Diagram](https://github.com/user-attachments/assets/0b78f0e3-2b32-4acd-9363-b1e56e63b618)

### Overview

The proposed architecture focuses on ingesting logs from both network-based and endpoint-based sources. Ingestion of application-specific logs and third-party security appliances is considered out of scope for this demonstration due to the variability in software and implementation. However, references and supplementary material regarding additional sources may be found in the appendices of this repository.

### Terminology

To ensure clarity and consistency, the following terms are used throughout this documentation:

1. **Log Ingestion Pipeline**: Refers to the complete system that collects, processes, and transmits observability data (specifically event logs). The term "pipeline" emphasizes the data flow between components, whereas "architecture" refers more broadly to the structure of the system.

2. **Link**: In the context of this architecture, a link refers to a specific node where the data needs to pass thorugh in order to reach its final destination. An architecture with less links or nodes where to forward event data is often better in terms of latency and bandwidth consumption.

3. **Source**: The application, service, or operating system component that generates observability data. In this architecture, primary sources include:
   - **Windows**: Windows Event Logs and Microsoft Sysmon
   - **Linux**: AuditD and Sysmon for Linux

4. **Agent**: A software component installed on endpoints to collect and forward logs. In this demonstration, `NXLog` is used as the agent to handle event collection and transmission in some Windows systems.

### Architecture Scope

This architecture assumes a network composed of Windows and Linux systems, encompassing both workstations and servers. The overarching objective is to reliably forward relevant event data to the final ingestion platform—Google Security Operations—while minimizing forwarding latency and reducing agent overhead on endpoints.

The design favors simplicity and scalability, ensuring that the ingestion pipeline remains maintainable and extensible in more complex or production-grade environments.

## License

This repository is provided under the MIT License. See `LICENSE` for more information.

## Contact

For questions or contributions, please open an issue or submit a pull request.


Stage 7: Verify ingestion
