# Windows Event Forwarding Guide

In this section of the repository you'll find everything I know about Windows Event Forwarding (WEF). I'll try to keep this section updated with new discoveries, recommendations, configuration guides, and resources.

## What's Windows Event Forwarding

WEF is a functionality embedded in the Windows Operating System that simplifies the process of centralizing Windows Event Logs. As with other solutions, WEF has various benefits and caveats. Let's describe WEF by enlisting the good and bad things of it.

|                                                           Advantage                                                           |                                                                       Disadvantage                                                                      |
|:-----------------------------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------:|
|      WEF does not require software installation of any kind; it uses built-in features and capabilities of the Windows OS     | Although it is not mandatory, WEF is highly recommended to be configured in an environment with a Domain Controller (DC)                                |
|                                     WEF can be configured and deployed in just few minutes                                    | In really big environments, WEF could require more strict policies and careful implementation to keep the environment secure                            |
|    Centralized events offer the possibility to threat hunters and security analyst to inspect the Windows Domain seamlessly   | WEF cannot be configured to forward the events to a third-party solution. It can only forward the events to another Windows System.                     |
| Implementing an agentless architecture with WEF minimizes security risks, like agent overhead or expanding the attack surface | You'll need deep knowledge of the Windows OS and Windows capabilities to be able to support and troubleshoot WEF. Agents are easier to manage than WEF. 

One of the best resource I have found in the Microsoft Official Documentation that introduces WEF pretty well is [here](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/use-windows-event-forwarding-to-assist-in-intrusion-detection). I encourage you to read about WEF in that resource.

### Collectors and Forwarders

Windows Event Forwarding depends on two main components: Windows Event Collectors (WECs) and Windows Event Forwarders (or WEF clients). The former are the choosen workstations or servers that will collect the Windows Event Logs from the WEF clients.

According to Microsoft documentation, a unique WEC can support around 3000 events per second, but this is very subjective (There is no mention of the specs of the computer receiving the events). However, most community-based suggestions and recommendations say that a WEC can indeed allocate around 2000 to 4000 workstations.

A well deployed WEF architecture will load balance event forwarding in enough WECs, and also will ensure that the forwarded events are filtered on advance to minimize noise and reduce the consumption of space in the collectors.

## Configuration and Deployment

### Configuration through GPOs

Windows Event Forwarding is often configured in Windows Domains, as this makes the implementation more straighforward and simple. Follow the steps to set up WEF successfully.

1. **Determine the number of WECs you will need in your environment**
2. **Enable WinRM in your WECs and WEC clients***
3. **Configure the WEC URI in your clients**
4. **Allow the Network Service to read the Security Event Log**
5. **Create a source-initiated subscription**
6. **Troubleshoot and test**

I recorded [this video](https://youtu.be/6rhsk8LB2NM) showing the implementation of WEF.