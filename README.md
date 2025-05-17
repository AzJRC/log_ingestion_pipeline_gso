# Log Ingestion Pipeline Architecture

TODO

## Stages

TODO

### Preamble:
Functional heterogeneous network environment with at least the following characteristics:
 - Selected Windows computers are managed by a Windows Domain Controller
 - At least one Windows computer to take the rol of a Windows Event Collector
 - At least one Linux computer (Ubuntu or Debian recommneded) to take the rol of Google SecOps Forwarder
 - Optional, extra Windows non-domain managed computer.
 - Optional, extra Linux computer.
 - Optional, Network Firewall to segregate the laboratory environment.

TODO

### Stage 1: Set up Google SecOps Forwarder

TODO

### Stage 2: Deploy and Configure Windows Sysmon

TODO

### Stage 3: Set up Windows Event Collector and Windows Event Forwarding

https://github.com/HASecuritySolutions/WECComputerGroupMgmt/blob/main/maintain_computer_groups.ps1
TODO

### Stage 4: Set up NXLog Agents in Windows Systems

TODO

### Stage 5: Set up Rsyslog in Linux Systems

TODO
Stage 6: Set up bulit-in remote logging in hardware/network equipment


Stage 7: Verify ingestion
