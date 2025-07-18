# On the Fly Note-Taking: Google SecOps Demo - Log Ingestion, Threat detection, Incident Response, and Investigation

This file documents the process I followed on the fly; i.e., at the same time of writing this file, to set up a demonstration of Google Security Operations to ingest events, detect and incident, respond to an incident, and investigate the incident.

1. **Log Ingestion**: Is the process of setting up the telemetry pipeline that is received by the security solution, in this case GSO. The ingestion phase will cover the deployment of a log ingestion pipeline and the deliberated generation of suspicious and malicious events.

2. **Threat Detection**: The process of generating alerts in the security solution. For Google SecOps, this corresponds to enabling Mandiant curated detection, developing custom detection rules.

3. **Incident Response**: The process of inspecting the alerts generated by the security solution, assign responsibles, and perform triaging operations. If applicable, leverage SOAR workflows to automate actions.

4. **Investigation**: The process of analyzing the data and information from the incident. Afterwards, forensic operations can be pursued in the affected hosts to determine the root causes of the incident.

Moreover, there are other features of Google SecOps that we will cover, like the Looker Dashboards, useful for analytics in every phase of security operations. Other advanced features like Google Threat Intelligence and Google SecOps SOAR connectors (alerts) are out-of-scope of this demo.

## Environment Prerequisites

For this demo I will be using Proxmox VE 8.3.3 to run some virtual machines:

- Windows Server 2019 (Domain Controller, DC)
- Windows 10 Pro (Workstation, WS)
- Windows 10 Pro (Optional Windows Event Collector, WEC; WS otherwise)
- Optionally, an OPNSense Firewall (Optional Gateway, GW)

Additionally, you can create another VM for Kali Linux or just use your host/physical computer for that matter.

There is no reason to use Proxmox VE (VirualBox or VMWare would also do the trick) or to virtualize the environment, as long as you have the equipment though.

Most of the setup for this environment was taken from The Cyber Mentor's YouTube video [Hacking Active Directory for Beginners](https://www.youtube.com/watch?v=VXxH4n684HE&t=1304s&ab_channel=TheCyberMentor)
, with a few additions. You can follow along that video while considering the extra configuration steps listed in this file.

![Topology](/media/gso_demo_topology.jpg)

### Proxmox Configuration

Configure [NTP servers](https://developers.google.com/time/guides#linux) in Proxmox host to ensure that the virtual machines have a proper time when initialized.

Create the virtual machines with [Windows Server 2019](https://pve.proxmox.com/wiki/Windows_2019_guest_best_practices) and two with [Windows 10](https://pve.proxmox.com/wiki/Windows_10_guest_best_practices). Finally, create a last VM for the [OPNSense Firewall](https://www.zenarmor.com/docs/network-security-tutorials/opnsense-installation).

![Demo topology diagram](/media/gso_demo_ntpconfig.png)

### OPNSense Firewall

Deploy the firewall as the gateway between your physical network and your virtual network. No special configuration is implemented here.

### Windows Server 2019 - Domain Controller

#### Essential settings

1. **Change the computer hostname**. For Example: `DC01` or `LAB-DC`.
2. **Configure static IPv4 addressing**. 
    - If you decided to include the OPNsense Firewall as separator between the physical network and the virtual environment, use the internal network address. For example, I used the network `172.16.0.0/24` and I assigned the IP address `172.16.0.100` to my DC.
    - If you didn't add the OPNsense Firewall, still assign a static free address from your local network.
3. **Configure the timezone**.
4. **Run Windows Update**.
5. Make sure you **enable Windows Remote Desktop**.
    - In my lab, one of my WS will have two NICs, one facing the physical network and another facing to the virtual network. This is to avoid having to set up port forwarding or VPNs.
    - Having a direct connection to that WS, and it having access to the virtual network, I can use Windows RDP to access any computer in the laboratory.

Once you have your DC with the most essential configurations ready, move to *AD Users and Computers* to create some user accounts and give your environment a little bit more of context and live.

#### Create users

1. **Create a normal user account** with a weak password (E.g. 'Password1').
2. **Create an administrator user account** with a barely secure password by right-clicking the Administrator user and selecting the *copy* option (E.g. 'P4ssw0rd.').
3. **Create a service account** (E.g. 'SQL Service') with a somewhat secure password that is  included in the user's description in plaintext (E.g. 'MyS3cur3P4ssw0rd!').

#### Create a network share

Create a basic network share. Go to *File and Storage Services > Shares* and create a new *Quick SMB Share*. Name the share as you which; you can leave all settings in their default values. As an example, I created the network share `C:\Shares\Developers`.

If you cannot find the shares feature, you may need to install the File Server role to enable the functionality.

![File Server Role](/media/gso_demo_sharesrole.png)

#### Create a Service Principal Name

Another configuration needed for our practice is to set up the stage for a *kerberoasting* attack by creating a *[Service Principal Name (SPN)](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/register-a-service-principal-name-for-kerberos-connections?view=sql-server-ver17)* tied to the service account we created earlier. The command below is used to create the SPN.

```
setspn -s MSSQLSvc/AJRC-DC.ajrc.local:1433 ajrc\sql.srv
```

You can read more about the `setspn` command [here](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc731241(v=ws.11)#viewing-spns).

```
> hostname
AJRC-DC

> net user
User accounts for \\AJRC-DC

-------------------------------------------------
Administrator  david.cahun  Guest
krbtgt         sebastian.gomez  sql.srv
The command completed successfully.

> setspn -s MSSQLSvc/AJRC-DC.ajrc.local:1433 ajrc\sql.srv
Checking domain DC=ajrc,DC=local

Registering ServicePrincipalNames for CN=SQL Service,CN=Users,DC=ajrc,DC=local
    MSSQLSvc/AJRC-DC.ajrc.local:1433
Updated object

> setspn -T ajrc.local -Q */*
Checking domain DC=ajrc,DC=local

CN=AJRC-DC,OU=Domain Controllers,DC=ajrc,DC=local
    Dfsr-12F29C2E-B797-4787-9364-D31B6C55EB04/AJRC-DC.ajrc.local
    ldap/AJRC-DC.ajrc.local/ForestDnsZones.ajrc.local
    ldap/AJRC-DC.ajrc.local/DomainDnsZones.ajrc.local
    ldap/AJRC-DC.ajrc.local
    
    ...

    ldap/AJRC-DC.ajrc.local/AJRC

CN=krbtgt,CN=Users,DC=ajrc,DC=local
    kadmin/changepw

CN=SQL Service,CN=Users,DC=ajrc,DC=local
    MSSQLSvc/AJRC-DC.ajrc.local:1433

Existing SPN found!
```

#### Disable Windows Defender

Following the same argument of *The Cyber Mentor*'s YT video, create a GPO to disable Windows Defender.

The goal of this demo is to demonstrate how real red team attacks can be detected with Google SecOps. If Windows Defender is in the way, it will be more difficult to make that demonstration.

Of course, in a real environment we want Windows Defender enabled as another layer of defense. The detection mechanisms that we will implement will only miss the AV Evasion techniques and subtechniques.

Create the GPO `Disable Windows Defender` at the domain level. Right-click to the new GPO and make sure that the `Enforced` option is selected.

Then, in the GPO, enable the policy `Turn off Microsoft Defender Antivirus` under `Computer Configuration > Policies > Administrative Templates > Microsoft Defender Antivirus`.

![Turn Off Microsoft Defender Antivirus Policy](/media/gso_demo_turnoffdefender.png)

#### Enable Windows Remote Desktop (Optional)

You can also enable Windows RDP for all clients, which will be helpful if you are using Proxmox as your virtualization engine.

In the path:

```
Computer Configuration -> Policies -> Administrative Templates -> Windows Components -> Remote Desktop Services -> Remote Desktop Session Host -> Connections
```

Enable the policy `Allow users to connect remotely using Remote Desktop Services`.

### Windows 10 Pro - Workstation

1. In the network adapters, **configure the domain server address with the DC's address**. Failing in setting up this correctly will unable you to join the domain.
2. **Configure the appropiate timezone**.
3. **Turn on network discovery and file sharing**.
4. In the windows search explorer, type *About your PC* and click on *Rename this PC (Advanced)*. In the *System Properties* window, **join to the windows domain** (and change your hostname if you have not do it yet).

![Join a Windows Domain](/media/gso_demo_joindomain.png)

Restart the computer and then login with the domain administrator account `[DomainName]\Administrator`. Open *Computer Management*, and in `Local Users and Groups > Groups`, add one of the previously created users as (local) administrator.

![Add user as local administrator](/media/gso_demo_addlocaladmin.png)

### Windows 10 Pro - WEC

Repeat the same steps listed in the section [Windows 10 Pro - Workstation](#windows-10-pro---workstation). Just make sure that in this computer you add two different local administrators.

If you decide to set up this machine as a WEC, follow the instructions of the section [Collect the Logs in the WEC (Optional)](#collect-the-logs-in-the-wec-optional)

## Ingestion Pipeline and Blue Team Side Visibility Settings

Now that the environment context is up and running, let's enable the observability mechanisms that will help us detect suspicious and malicious incidents.

### Install BindPlane Agents

To forward the collected events to Google SecOps, you will need an agent. Google recommends using the partner solution BindPlane, but if you do not have access to this solution, you can always use another alternative:

1. Winlogbeat (Elastic)
2. NXLog
3. Rsyslog for Windows

The benefit of using BindPlane solution, besides being optimized for Google SecOps, is that you can make the ingestion pipeline point-to-point. With the other alternatives, you'll need to use the proxy solution [Google SecOps Forwarder](#) 

```
[TODO] Dev Note: Add documentation of Google SecOps Forwarder.
```

This demo asumes that we are going to use the [Cloud BindPlane Agent](https://bindplane.com/).

#### Access the web portal

1. Go to `https://bindplane.com/` and sign in with your account.
2. Add a source configuration that consumes standard windows event logs.
3. Add a destination configuration that sends logs to Google SecOps.
    - Use `gRPC` protocol
    - Use `JSON` authentication method and paste the content of the `auth.json` file provided by Google SecOps.
    - Optionally, add your domain in the namespace value.
    - Optionally, add the label `env` with value `test`.
4. In the agents tab, click on `Install agents`
5. Copy the installation script in a privileged terminal for each computer you want to install BindPlane.
    - If using WECs, you will only install BindPlane in these computers.
    - In such case, you'll need to tweek the source configuration of your agents to read the custom event logs.
6. Make sure the computers' hostname appears in the web UI.

![](/media/gso_demo_installbindplaneagent.png)
![](/media/gso_demo_bindplaneagentsadded.png)

You can read more about BindPlane agent [here](#TODO )

```
[TODO] Dev Note: Add documentation of BindPlane.
```

### Deploy Windows Sysmon

To deploy Windows Sysmon in a Windows domain effectively, read this [file](/sysmon/README.md) and the [Documentation on Windows Sysmon Deployment](/sysmon/docs/WINDOWS_SYSMON_DEPLOYMENT.md) (You can deliberately use the vulnerable shared folder we created earlier to install Sysmon).

### Enable Detailed Windows logging

Windows by default is very quiet. You need to enable more granular audit policies.

Either on target machine or via GPO, run the following command to enable all logging mechanisms:

```
AuditPol /set /category:* /success:enable /failure:enable
```

```diff
- Warning: Enabling all logging mechanisms may affect the performance of the machine or fill the disk space
```

Or if you think you know which audit categories are relevant for each tactic and technique, you can also specify by category:

```
AuditPol /get /category:*
[Output all categories]

AuditPol /set /subcategory:"Logon" /success:enable /failure:enable
AuditPol /set /subcategory:"Process Creation" /success:enable
```

Moreover, sometimes we want to monitor commands. Event [4688](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4688) can be extended by running the following command:

```
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f
```

This will make the event *4688* populate the *command line* field.

For more granular inspection of scripting activities, you can monitor any executed PowerShell command by enabling *Script Block Logging* and/or *Module Logging*:

```
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1
```

Finally, keep in mind that with Sysmon, some of these events are better covered. For example, process creation with Sysmon is far more detailed that event *4688* even with the command line field populated, and the structure of the query is easier to query, read, and parse.

```diff
+ Important: You do not need to enable all logging at once. In the following sections, I'll give you the details of which event logs are important to monitor for each adversary technique, and which advanced logging features should be enabled in such case.
```

### Collect the Logs in the WEC (Optional)

To set up the WEC, read this [file](/wef/README.md). You could find the **Wef Managment Tool** very useful for this task.

## Performing the Attacks and Identifying the Relevant Events

All the attacks outlined in this section are taken from The Cyber Mentor's YouTube video [Hacking Active Directory for Beginners](https://youtu.be/VXxH4n684HE?si=gjWkzIV0L4qcJqys)

**Note**: Keep in mind that this document is mostly about detection techniques rather than mitigation techniques. You won't find information about how to mitigate and prevent the adversary techniques described below.

### LLMNR Poisoning

LLMNR (Link Local Multicast Name Resolution) is a Windows feature that allows computers to resolve names of other computers in a network, as a fallback when DNS services fail or are not enabled.

#### Detecting LLMNR Poisoning

This detection scenario focuses on identifying LLMNR poisoning and related credential relay attacks. These attacks exploit weaknesses at the network protocol layer (LLMNR/NBNS) and typically leave little direct evidence on the compromised Windows host itself. As a result, defenders must rely on correlating indirect artifacts across multiple log sources to detect such activities.

---

The primary approach to identifying LLMNR poisoning or SMB relay attacks is to monitor for patterns that combine suspicious network activity with authentication events, revealing potential attempts of initial access.

1. Network Indicators
    - Captured by Sysmon Event ID `22` on Windows endpoints, filtering through a maintained list of known trusted domains to help isolate unusual queries.
    - Adversaries might try to perform initial access after a successful LLMNR Poisoning attack, and therefore, Sysmon Event ID `3` logs the resulting connection attempt to an SMB or RDP service on the attacker's machine.

2. Network Firewall Logs or Windows Filtering Platform (WFP) events
    - SMB typically uses `TCP/445`.
    - LLMNR uses `UDP/5355` and NBNS uses `UDP/137`.
    - Look for connections initiated from previously unseen hosts or unexpected external sources.

3. Authentication events (Initial Access)
    - **Failed network logons** (`Windows Event ID 4625`, Logon Type 3 or 7), originating from unexpected IP addresses shortly after suspicious network activity.
    - **Successful network logons** (`Windows Event ID 4624`, Logon Type 3 or 7) from unusual sources, particularly following failed attempts or DNS anomalies.
    - **Logons with explicit credentials** (`Event ID 4648`), which may suggest credential relay or the use of remote access tools such as `xfreerdp` or `remmina`.

Sysmon Event ID `22` records DNS queries performed by Windows processes. This becomes significant in LLMNR poisoning scenarios where a user mistypes a network share (e.g., `\\FileServet\Folder`; notice the type 'Servert' instead of 'Server'), triggering a name resolution attempt that may be hijacked by a malicious responder. 

The `QueryName` field captures the originally requested name, and the `QueryResults` field lists the IP addresses that responded, which may include the attacker’s IP (if not spoofed). For example:

```xml
<Data Name="QueryResults">
  fe80::eb26:b9d4:acb3:81b8;::ffff:192.168.68.123;
</Data>
```

Notice that if a user directly types a path with an IP (e.g., `\\192.168.68.123\Files`), some implementations may register misleading `QueryName` values such as `wpad`, while still recording connections to the attacker.

In summary, on the victim's worksation:
- **Sysmon Event ID 22 (DNS Query)**: Indicates a name resolution attempt, potentially triggered by mistyping or by malicious influence.
- **Sysmon Event ID 3 (Network Connection)**: Logs the resulting connection attempt to an SMB or RDP service on the attacker's machine.
- **Windows Event ID 4624 (Successful Logon)**: Reveals a successful connection to the victim's computer after the adversary has deciphered (using `hashcat` for example) the password.

If all the previous events occur, this represents a [Credential Access (TA0006)](https://attack.mitre.org/tactics/TA0006/) scenario. If the unauthorized access event never occurs, this represents a [Collection (TA0009)](https://attack.mitre.org/techniques/T1557/001/) scenario. Some might also consider this an [Initial Access (TA0001)](https://attack.mitre.org/tactics/TA0001/) attempt. More details about this technique can be found in Mitre Att&ck for [Adversary-in-the-Middle (T1557.001)](https://attack.mitre.org/techniques/T1557/001/).

The following YARA-L rule demonstrates how to correlate these multi-stage events to detect potential LLMNR poisoning or SMB relay activity:

```YARA
rule ajrc_llmnrPoisoningInitialAccess {
  meta:
    author = "Alejandro Javier Rodríguez Cantón"
    description = "Detect internal LLMNR poisoning and credential use via DNS query, RDP connection, and login events"
    severity = "High"
    priority = "Medium"
    rule_version = "1.0"
    response = "Investigate shared resource attempts and validate remote connections."
    mitre_tactic = "TA0001, TA0006, TA0009"
    mitre_technique = "T1557.001"

  events:
    // DNS query to untrusted host
    $e_dns.metadata.event_type = "NETWORK_DNS"
    $e_dns.metadata.vendor_name = "Microsoft"
    not $e_dns.network.dns.questions.name in regex %AjrcLocal_trustedHostsAndDomains
    re.regex($e_dns.network.dns.answers.data, `192\.168\.\d{1,3}\.\d{1,3}|172\.16\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3}\.\d{1,3}`)
    $e_dns.principal.asset.hostname = $hostname

    // RDP connection (Sysmon 3)
    $e_conn.metadata.event_type = "NETWORK_CONNECTION"
    $e_conn.metadata.vendor_name = "Microsoft"
    $e_conn.target.port = 3389
    $e_conn.principal.asset.hostname = $hostname
    $e_conn.principal.ip = $victim_ip

    // Login event (explicit credentials, Logon Type 7 or 10)
    $e_logon.metadata.event_type = "USER_LOGIN"
    $e_logon.metadata.vendor_name = "Microsoft"
    not $e_logon.target.user.userid = /SYSTEM/ nocase
    $e_logon.extensions.auth.auth_details = /Logon Type: (7|10)/
    $e_logon.principal.asset.hostname = $hostname
    $e_logon.principal.ip = $victim_ip
    $e_logon.metadata.product_event_type = $logon_evtid

    // Enforce event sequencing: DNS -> connection -> login
    $e_dns.metadata.event_timestamp.seconds <= $e_conn.metadata.event_timestamp.seconds
    $e_conn.metadata.event_timestamp.seconds <= $e_logon.metadata.event_timestamp.seconds

  match:
    $hostname over 30m

  outcome:
    $risk_score = max(90 - if($logon_evtid = "4625", 40, 0))

  condition:
    $e_dns and $e_conn and $e_logon
}
```

**Important notes on tunning**

- This detection relies on trusted domain lists (`%Domain_trustedHostsAndDomains`).
- The rule currently does not incorporate firewall logs; however, including external or host firewall events can further strengthen detection and minimize false positives.
- Adjust the correlation window (30m) and monitored port values to align with your organization’s typical network and authentication behavior.

The following are sample events in their raw format used for the detection rule.
```XML
<!-- Sysmon 22: DNS -->

<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
    <System> ... </System>
    <EventData>
        <Data Name="RuleName">-</Data> 
        <Data Name="UtcTime">2025-07-05 17:31:31.516</Data> 
        <Data Name="ProcessGuid">{3b1ba004-6170-6869-f909-000000000700}</Data> 
        <Data Name="ProcessId">10812</Data> 
        <Data Name="QueryName">test</Data>     
        <Data Name="QueryStatus">0</Data>
        <Data Name="QueryResults">fe80::eb26:b9d4:acb3:81b8;::ffff:192.168.68.123;</Data> 
        <Data Name="Image">C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe</Data> 
        <Data Name="User">AJRC\sebastian.gomez</Data> 
    </EventData>
</Event>

<!-- Sysmon 3: Network Connection -->
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
    <System> ... </System>
    <EventData>
        <Data Name="RuleName">RDP</Data> 
        <Data Name="UtcTime">2025-07-05 18:56:16.044</Data> 
        <Data Name="ProcessGuid">{3b1ba004-3804-6867-1300-000000000700}</Data> 
        <Data Name="ProcessId">64</Data> 
        <Data Name="Image">C:\Windows\System32\svchost.exe</Data> 
        <Data Name="User">NT AUTHORITY\NETWORK SERVICE</Data> 
        <Data Name="Protocol">tcp</Data> 
        <Data Name="Initiated">false</Data> 
        <Data Name="SourceIsIpv6">false</Data> 
        <Data Name="SourceIp">192.168.68.123</Data> 
        <Data Name="SourceHostname">-</Data> 
        <Data Name="SourcePort">58900</Data> 
        <Data Name="SourcePortName">-</Data> 
        <Data Name="DestinationIsIpv6">false</Data> 
        <Data Name="DestinationIp">192.168.68.21</Data> 
        <Data Name="DestinationHostname">WS01.ajrc.local</Data> 
        <Data Name="DestinationPort">3389</Data> 
        <Data Name="DestinationPortName">ms-wbt-server</Data> 
    </EventData>
</Event>

<!-- 4624: Successful Logon -->
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
    <System> ... </System>
    <EventData>
        <Data Name="SubjectUserSid">S-1-5-18</Data> 
        <Data Name="SubjectUserName">WS01$</Data> 
        <Data Name="SubjectDomainName">AJRC</Data> 
        <Data Name="SubjectLogonId">0x3e7</Data> 
        <Data Name="LogonGuid">{00000000-0000-0000-0000-000000000000}</Data> 
        <Data Name="TargetUserName">sebastian.gomez</Data> 
        <Data Name="TargetDomainName">AJRC</Data> 
        <Data Name="TargetLogonGuid">{00000000-0000-0000-0000-000000000000}</Data> 
        <Data Name="TargetServerName">localhost</Data> 
        <Data Name="TargetInfo">localhost</Data> 
        <Data Name="ProcessId">0x504</Data> 
        <Data Name="ProcessName">C:\Windows\System32\svchost.exe</Data> 
        <Data Name="IpAddress">192.168.68.123</Data> 
        <Data Name="IpPort">0</Data> 
    </EventData>
</Event>
```

#### Exploiting LLMNR Poisoning

This section demonstrates how an attacker can exploit LLMNR poisoning to capture NTLM credentials for offline cracking.

---

An attacker can leverage **Responder**, a popular tool from the Impacket suite, to perform LLMNR (and NBNS) spoofing and capture NTLM hashes.

Run Responder on the attacking machine with the following command:

- `-I` specifies the network interface (e.g., `eth0` or `ens33`).
- `-w` enables WPAD proxy authentication capture.
- `-F` forces NTLM authentication for WPAD.
- `-v` runs Responder in verbose mode for detailed output.

```bash
responder -I {net-if} -wF -v
```

**This example uses Responder version 3.1.6.0.**

![Running Responder from the Impacket Suite](/media/gso_demo_llmnrpoisonresponder.png)

Once responder is listening, the victim must attempt to access to a network resource, such as connecting to a Windows share, using a reference that triggers name resolution. If this reference is either:

- A non-existent hostname (e.g., `\\Files`), or
- An explicit IP address linked to the attacker (usually via spoofing or poisoning at the link-layer)

![Victim trying to access a malicious remote resource](/media/gso_demo_llmnrclienttricked.png)

then Responder will respond to the LLMNR/NBNS requests, prompting the victim to send NTLM authentication information.

Responder displays the captured NTLM hashes in its console output. These can then be cracked offline using hashcat:

```bash
hashcat -m 5600 {capture-file} {wordlist} -O [--force]
```

- `-m 5600` specifies the NetNTLMv2 hash mode.
- `{capture-file}` is the file containing the extracted hashes.
- `{wordlist}` is your chosen wordlist for the attack (e.g., `rockyou.txt`).
- `-O` enables optimized kernel execution.
- Optional `--force` might be required if you are using a VM.

![Cracking a NTLMv2 password with Hashcat](/media/gso_demo_llmnrpoisonhashcat.png)

You may use any comprehensive wordlist. The [SecLists](https://github.com/danielmiessler/SecLists) GitHub repository provides a wide range of curated wordlists suitable for password attacks. Moreoever, be aware that hashcat relies on hardware acceleration (GPU). As such, it will generally not run effectively inside a virtual machine and should be executed directly on a physical host equipped with a compatible GPU.

### SMB Relay

#### Blue Team: Detect SMB Relay Attack


```XML
<!-- 
    In contrast to the previous attack example with LLMNR Poisoning, since we deactivated the 
    responders SMB and HTTP, Sysmon events 3 and 22 do not generate. There is no DNS or LLMNR server
    answering the queries.
    The only way to detect potential openess to SMB Relay attack is through netowrk or host firewall logs.
-->

<!-- 4624: Successful Logon
    - LogonType: Value 3 represents authentication over the network
    - TargetUserName: Affected user account. This user account is likely a local administrator.
    - LmPackageName or AuthenticationPackageName: Must contain NTLM
    - WorkstationName: The computer's name that (should have) connected from the network
    - IpAddress: The computer's IP address that (should have) connected from the network. 
    
    Notice that if the IP address does not correspond to the workstation, this is a big red flag. You'll need an asset inventory table/list for this analysis.
-->
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
    <System> ... </System>
    <EventData>
        <Data Name="SubjectUserSid">S-1-0-0</Data> 
        <Data Name="SubjectUserName">-</Data> 
        <Data Name="SubjectDomainName">-</Data> 
        <Data Name="SubjectLogonId">0x0</Data> 
        <Data Name="TargetUserSid">S-1-5-21-4242100987-1054838966-2613292805-1104</Data> 
        <Data Name="TargetUserName">sebastian.gomez</Data> 
        <Data Name="TargetDomainName">AJRC</Data> 
        <Data Name="TargetLogonId">0x50d06a3</Data> 
        <Data Name="LogonType">3</Data> 
        <Data Name="LogonProcessName">NtLmSsp</Data> 
        <Data Name="AuthenticationPackageName">NTLM</Data> 
        <Data Name="WorkstationName">WEC01</Data> 
        <Data Name="LogonGuid">{00000000-0000-0000-0000-000000000000}</Data> 
        <Data Name="TransmittedServices">-</Data> 
        <Data Name="LmPackageName">NTLM V2</Data> 
        <Data Name="KeyLength">128</Data> 
        <Data Name="ProcessId">0x0</Data> 
        <Data Name="ProcessName">-</Data> 
        <Data Name="IpAddress">192.168.68.123</Data> 
        <Data Name="IpPort">54446</Data> 
        <Data Name="ImpersonationLevel">%%1833</Data> 
        <Data Name="RestrictedAdminMode">-</Data> 
        <Data Name="TargetOutboundUserName">-</Data> 
        <Data Name="TargetOutboundDomainName">-</Data> 
        <Data Name="VirtualAccount">%%1843</Data> 
        <Data Name="TargetLinkedLogonId">0x0</Data> 
        <Data Name="ElevatedToken">%%1842</Data> 
    </EventData>
</Event>

<!-- 
    Events 4672 will be generated after 4624. 
    There's nothing special about them except that they must appear for the affected <TargetUserName>
-->

<!-- 
    Event 5140: Access to shared objects over the network 
    For this event to appear, you must have File Share auditing policy enabled.
    Inspect the <IpAddress> from which a shared resource was read. if the IP address
    is not known or suspicious, alert.
    -->
<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
    <System> ... </System>
    <EventData>
        <Data Name="SubjectUserSid">S-1-5-21-4242100987-1054838966-2613292805-1104</Data> 
        <Data Name="SubjectUserName">sebastian.gomez</Data> 
        <Data Name="SubjectDomainName">AJRC</Data> 
        <Data Name="SubjectLogonId">0x50d01b0</Data> 
        <Data Name="ObjectType">File</Data> 
        <Data Name="IpAddress">192.168.68.123</Data> 
        <Data Name="IpPort">60032</Data> 
        <Data Name="ShareName">\\*\C$</Data> 
        <Data Name="ShareLocalPath">\??\C:\</Data> 
        <Data Name="AccessMask">0x1</Data> 
        <Data Name="AccessList">%%4416</Data> 
    </EventData>
</Event>

<!-- 
    Monitor for Sysmon Event 1 (process creation) and 11 (file create) for any
    post exploitation activity. You can correlate via LogonUID field.

    11:40 - 11:44
-->
```

#### Red Team: Peform SMB Relay Attack

Adversary set up:

1. Turn off SMB and HTTP Responders `gedit /usr/share/responder/Responder.conf`
2. Identify if the target has SMB signign enabled
    - `nmap --script=smb2-security-mode.nse -p445 {target}`: The host must have a message similar to `Message signing is enabled but not required`.

![](/media/gso_demo_smbrelaysmbsignenum.png)

Victim action:

1. The victim must have Network discovery enabled.
2. The victim must attempts to access a shared resource using a reference that triggers unsuccessful DNS name resolution.

Adversary enumeration:

2. Run responder `responder -I eth0 -wF -v` (HTTP and SMB servers must appear 'OFF')
3. Run NTLMRelayx `netlmrelayx -tf {file_targets} -smb2support [-i]`
    - The `{file_targets}` is a text file that lists the computers to which the captured NTLM hashes are going to be forwarded.
    - The `-i` flag will allow you to start an interactive shell with the remote computer using `nc` (netcat).

![](/media/gso_demo_smbrelaysetupntlmrelayx.png)

![](/media/gso_demo_smbrelayattacksuccess.png)

