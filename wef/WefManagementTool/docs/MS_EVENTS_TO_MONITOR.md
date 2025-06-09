# Microsoft's suggested events to monitor

The following table classifies Microsoft recommended Windows Event IDs into the specified domains suggested in [DEPLOY_CUSTOM_EVENTLOGS.md](/wef/WefManagementTool/docs/DEPLOY_CUSTOM_EVENTLOGS.md), along with their criticality and summaries. The table is sorted first by Domain (alphabetically), then by Potential Criticality (High >  > Medium > Low), and finally by ascending Event ID within each group.

## Mapping

| Domain | Current Windows Event ID | Potential Criticality | Event Summary | Notes |
|:---:|:---:|:---:|:---:|---|
| Applications and Services | 5124 | High | A security setting was updated on the OCSP Responder Service | Applies only to Windows Server |
| Applications and Services | 4868 | Medium | The certificate manager denied a pending certificate request. |  |
| Applications and Services | 4870 | Medium | Certificate Services revoked a certificate. |  |
| Applications and Services | 4882 | Medium | The security permissions for Certificate Services changed. |  |
| Applications and Services | 4885 | Medium | The audit filter for Certificate Services changed. |  |
| Applications and Services | 4890 | Medium | The certificate manager settings for Certificate Services changed. |  |
| Applications and Services | 4892 | Medium | A property of Certificate Services changed. |  |
| Applications and Services | 5120 | Medium | OCSP Responder Service Started |  |
| Applications and Services | 5121 | Medium | OCSP Responder Service Stopped |  |
| Applications and Services | 5122 | Medium | A configuration entry changed in OCSP Responder Service |  |
| Applications and Services | 5123 | Medium | A configuration entry changed in OCSP Responder Service |  |
| Applications and Services | 5376 | Medium | Credential Manager credentials were backed up. |  |
| Applications and Services | 5377 | Medium | Credential Manager credentials were restored from a backup. |  |
| Applications and Services | 5480 | Medium | IPsec Services failed to get the complete list of network interfaces on the computer. (IPsec service issue) |  |
| Applications and Services | 5483 | Medium | IPsec Services failed to initialize RPC server. IPsec Services could not be started. (IPsec service issue) |  |
| Applications and Services | 5484 | Medium | IPsec Services has experienced a critical failure and has been shut down. (IPsec service issue) |  |
| Applications and Services | 5485 | Medium | IPsec Services failed to process some IPsec filters on a plug-and-play event for network interfaces. (IPsec service issue) |  |
| Applications and Services | 5827 | Medium | The Netlogon service denied a vulnerable Netlogon secure channel connection from a machine account. |  |
| Applications and Services | 5828 | Medium | The Netlogon service denied a vulnerable Netlogon secure channel connection using a trust account. |  |
| Applications and Services | 6145 | Medium | One or more errors occurred while processing security policy in the Group Policy objects. (GPO processing error) |  |
| Applications and Services | 6273 | Medium | Network Policy Server denied access to a user. |  |
| Applications and Services | 6274 | Medium | Network Policy Server discarded the request for a user. |  |
| Applications and Services | 6275 | Medium | Network Policy Server discarded the accounting request for a user. |  |
| Applications and Services | 6276 | Medium | Network Policy Server quarantined a user. |  |
| Applications and Services | 6277 | Medium | Network Policy Server granted access to a user but put it on probation (host did not meet health policy). |  |
| Applications and Services | 6278 | Medium | Network Policy Server granted full access to a user (host met health policy). |  |
| Applications and Services | 6279 | Medium | Network Policy Server locked the user account due to repeated failed authentication attempts. |  |
| Applications and Services | 6280 | Medium | Network Policy Server unlocked the user account. |  |
| Applications and Services | 4869 | Low | Certificate Services received a resubmitted certificate request. |  |
| Applications and Services | 4871 | Low | Certificate Services received a request to publish the certificate revocation list (CRL). |  |
| Applications and Services | 4872 | Low | Certificate Services published the certificate revocation list (CRL). |  |
| Applications and Services | 4873 | Low | A certificate request extension changed. |  |
| Applications and Services | 4874 | Low | One or more certificate request attributes changed. |  |
| Applications and Services | 4875 | Low | Certificate Services received a request to shut down. |  |
| Applications and Services | 4876 | Low | Certificate Services backup started. |  |
| Applications and Services | 4877 | Low | Certificate Services backup completed. |  |
| Applications and Services | 4878 | Low | Certificate Services restore started. |  |
| Applications and Services | 4879 | Low | Certificate Services restore completed. |  |
| Applications and Services | 4880 | Low | Certificate Services started. |  |
| Applications and Services | 4881 | Low | Certificate Services stopped. |  |
| Applications and Services | 4883 | Low | Certificate Services retrieved an archived key. |  |
| Applications and Services | 4884 | Low | Certificate Services imported a certificate into its database. |  |
| Applications and Services | 4886 | Low | Certificate Services received a certificate request. |  |
| Applications and Services | 4887 | Low | Certificate Services approved a certificate request and issued a certificate. |  |
| Applications and Services | 4888 | Low | Certificate Services denied a certificate request. |  |
| Applications and Services | 4889 | Low | Certificate Services set the status of a certificate request to pending. |  |
| Applications and Services | 4891 | Low | A configuration entry changed in Certificate Services. |  |
| Applications and Services | 4893 | Low | Certificate Services archived a key. |  |
| Applications and Services | 4894 | Low | Certificate Services imported and archived a key. |  |
| Applications and Services | 4895 | Low | Certificate Services published the CA certificate to Active Directory Domain Services. |  |
| Applications and Services | 4898 | Low | Certificate Services loaded a template. |  |
| Applications and Services | 4902 | Low | The Per-user audit policy table was created. (Security event source registered) |  |
| Applications and Services | 4904 | Low | An attempt was made to register a security event source. |  |
| Applications and Services | 4905 | Low | An attempt was made to unregister a security event source. |  |
| Applications and Services | 4909 | Low | The local policy settings for the TBS were changed. |  |
| Applications and Services | 4910 | Low | The Group Policy settings for the TBS were changed. |  |
| Applications and Services | 5888 | Low | An object in the COM+ Catalog was modified. |  |
| Applications and Services | 5889 | Low | An object was deleted from the COM+ Catalog. |  |
| Applications and Services | 5890 | Low | An object was added to the COM+ Catalog. |  |
| Identity & Access | 4964 | High | Special groups have been assigned to a new logon. |  |
| Identity & Access | 4765 | High | SID History was added to an account. |  |
| Identity & Access | 4766 | High | An attempt to add SID History to an account failed. |  |
| Identity & Access | 4618 | High | A monitored security event pattern has occurred. (Security monitoring alert) |  |
| Identity & Access | 4649 | High | A replay attack was detected. (May be a benign false positive) |  |
| Identity & Access | 4719 | High | System audit policy was changed. |  |
| Identity & Access | 4794 | High | An attempt was made to set the Directory Services Restore Mode. |  |
| Identity & Access | 4897 | High | Role separation enabled. (Certificate Services role separation) |  |
| Identity & Access | 4720 | Low | A user account was created. |  |
| Identity & Access | 4722 | Low | A user account was enabled. |  |
| Identity & Access | 4723 | Low | An attempt was made to change an account’s password. |  |
| Identity & Access | 4724 | Medium | An attempt was made to reset an account’s password. |  |
| Identity & Access | 4725 | Low | A user account was disabled. |  |
| Identity & Access | 4726 | Low | A user account was deleted. |  |
| Identity & Access | 4727 | Medium | A security-enabled global group was created. |  |
| Identity & Access | 4728 | Low | A member was added to a security-enabled global group. |  |
| Identity & Access | 4729 | Low | A member was removed from a security-enabled global group. |  |
| Identity & Access | 4730 | Low | A security-enabled global group was deleted. |  |
| Identity & Access | 4731 | Low | A security-enabled local group was created. |  |
| Identity & Access | 4732 | Low | A member was added to a security-enabled local group. |  |
| Identity & Access | 4733 | Low | A member was removed from a security-enabled local group. |  |
| Identity & Access | 4734 | Low | A security-enabled local group was deleted. |  |
| Identity & Access | 4735 | Medium | A security-enabled local group was changed. |  |
| Identity & Access | 4737 | Medium | A security-enabled global group was changed. |  |
| Identity & Access | 4738 | Low | A user account was changed. |  |
| Identity & Access | 4740 | Low | A user account was locked out. |  |
| Identity & Access | 4741 | Low | A computer account was changed. |  |
| Identity & Access | 4742 | Low | A computer account was changed. |  |
| Identity & Access | 4743 | Low | A computer account was deleted. |  |
| Identity & Access | 4744 | Low | A security-disabled local group was created. |  |
| Identity & Access | 4745 | Low | A security-disabled local group was changed. |  |
| Identity & Access | 4746 | Low | A member was added to a security-disabled local group. |  |
| Identity & Access | 4747 | Low | A member was removed from a security-disabled local group. |  |
| Identity & Access | 4748 | Low | A security-disabled local group was deleted. |  |
| Identity & Access | 4749 | Low | A security-disabled global group was created. |  |
| Identity & Access | 4750 | Low | A security-disabled global group was changed. |  |
| Identity & Access | 4751 | Low | A member was added to a security-disabled global group. |  |
| Identity & Access | 4752 | Low | A member was removed from a security-disabled global group. |  |
| Identity & Access | 4753 | Low | A security-disabled global group was deleted. |  |
| Identity & Access | 4754 | Medium | A security-enabled universal group was created. |  |
| Identity & Access | 4755 | Medium | A security-enabled universal group was changed. |  |
| Identity & Access | 4756 | Low | A member was added to a security-enabled universal group. |  |
| Identity & Access | 4757 | Low | A member was removed from a security-enabled universal group. |  |
| Identity & Access | 4758 | Low | A security-enabled universal group was deleted. |  |
| Identity & Access | 4759 | Low | A security-disabled universal group was created. |  |
| Identity & Access | 4760 | Low | A security-disabled universal group was changed. |  |
| Identity & Access | 4761 | Low | A member was added to a security-disabled universal group. |  |
| Identity & Access | 4762 | Low | A member was removed from a security-disabled universal group. |  |
| Identity & Access | 4767 | Low | A user account was unlocked. |  |
| Identity & Access | 4768 | Low | A Kerberos authentication ticket (TGT) was requested. |  |
| Identity & Access | 4769 | Low | A Kerberos service ticket was requested. |  |
| Identity & Access | 4770 | Low | A Kerberos service ticket was renewed. |  |
| Identity & Access | 4771 | Low | Kerberos pre-authentication failed. |  |
| Identity & Access | 4772 | Low | A Kerberos authentication ticket request failed. |  |
| Identity & Access | 4774 | Low | An account was mapped for logon. |  |
| Identity & Access | 4775 | Low | An account could not be mapped for logon. |  |
| Identity & Access | 4776 | Low | The domain controller attempted to validate the credentials for an account. |  |
| Identity & Access | 4777 | Low | The domain controller failed to validate the credentials for an account. |  |
| Identity & Access | 4778 | Low | A session was reconnected to a Window Station. |  |
| Identity & Access | 4779 | Low | A session was disconnected from a Window Station. |  |
| Identity & Access | 4781 | Low | The name of an account was changed. |  |
| Identity & Access | 4782 | Low | The password hash of an account was accessed. |  |
| Identity & Access | 4783 | Low | A basic application group was created. |  |
| Identity & Access | 4784 | Low | A basic application group was changed. |  |
| Identity & Access | 4785 | Low | A member was added to a basic application group. |  |
| Identity & Access | 4786 | Low | A member was removed from a basic application group. |  |
| Identity & Access | 4787 | Low | A nonmember was added to a basic application group. |  |
| Identity & Access | 4788 | Low | A nonmember was removed from a basic application group. |  |
| Identity & Access | 4789 | Low | A basic application group was deleted. |  |
| Identity & Access | 4790 | Low | An LDAP query group was created. |  |
| Identity & Access | 4793 | Low | The Password Policy Checking API was called. (Password policy check) |  |
| Identity & Access | 4800 | Low | The workstation was locked. |  |
| Identity & Access | 4801 | Low | The workstation was unlocked. |  |
| Identity & Access | 4802 | Low | The screen saver was invoked. |  |
| Identity & Access | 4803 | Low | The screen saver was dismissed. |  |
| Identity & Access | 5140 | Low | A network share object was accessed. (File share accessed by user) |  |
| Identity & Access | 6272 | Low | Network Policy Server granted access to a user. (NPS authentication succeeded) |  |
| Identity & Access | 4706 | Medium | A new trust was created to a domain. |  |
| Identity & Access | 4707 | Low | A trust to a domain was removed. |  |
| Network | 4960 | Medium | IPsec dropped an inbound packet that failed an integrity check. (Possible packet tampering) |  |
| Network | 4961 | Medium | IPsec dropped an inbound packet that failed a replay check. (Possible replay attack) |  |
| Network | 4962 | Medium | IPsec dropped an inbound packet that failed a replay check (low sequence number). (Possible replay attack) |  |
| Network | 4963 | Medium | IPsec dropped an inbound clear text packet that should have been secured. (Potential policy mismatch or spoofing) |  |
| Network | 4965 | Medium | IPsec received a packet from a remote computer with an incorrect Security Parameter Index (SPI). (Possible packet corruption) |  |
| Network | 4976 | Medium | During Main Mode negotiation, IPsec received an invalid negotiation packet. (Possible network issue or tampering) |  |
| Network | 4977 | Medium | During Quick Mode negotiation, IPsec received an invalid negotiation packet. (Possible network issue or tampering) |  |
| Network | 4978 | Medium | During Extended Mode negotiation, IPsec received an invalid negotiation packet. (Possible network issue or tampering) |  |
| Network | 4983 | Medium | An IPsec Extended Mode negotiation failed. The corresponding Main Mode security association has been deleted. |  |
| Network | 4984 | Medium | An IPsec Extended Mode negotiation failed. The corresponding Main Mode security association has been deleted. |  |
| Network | 5027 | Medium | The Windows Firewall Service was unable to retrieve the security policy from local storage. (Using last known policy) |  |
| Network | 5028 | Medium | The Windows Firewall Service was unable to parse the new security policy. (Reverting to last known policy) |  |
| Network | 5029 | Medium | The Windows Firewall Service failed to initialize the driver. (Will enforce current policy) |  |
| Network | 5030 | Medium | The Windows Firewall Service failed to start. |  |
| Network | 5035 | Medium | The Windows Firewall Driver failed to start. |  |
| Network | 5037 | Medium | The Windows Firewall Driver detected a critical runtime error. Terminating. |  |
| Network | 5038 | Medium | Code integrity determined that the image hash of a file is not valid. (File hash mismatch or disk error) |  |
| Network | 5453 | Medium | An IPsec negotiation with a remote computer failed because the IKE/AuthIP service is not started. |  |
| Network | 5480 | Medium | (See Applications and Services domain above for Event 5480) |  |
| Network | 5483 | Medium | (See Applications and Services domain above for Event 5483) |  |
| Network | 5484 | Medium | (See Applications and Services domain above for Event 5484) |  |
| Network | 5485 | Medium | (See Applications and Services domain above for Event 5485) |  |
| Network | 5632 | Low | A request was made to authenticate to a wireless network. |  |
| Network | 5633 | Low | A request was made to authenticate to a wired network. |  |
| Network | 5712 | Low | A Remote Procedure Call (RPC) was attempted. |  |
| Network | 6144 | Low | Security policy in the Group Policy objects has been applied successfully. |  |
| Network | 4946 | Low | A change has been made to Windows Firewall exception list. A rule was added. |  |
| Network | 4947 | Low | A change has been made to Windows Firewall exception list. A rule was modified. |  |
| Network | 4948 | Low | A change has been made to Windows Firewall exception list. A rule was deleted. |  |
| Network | 4949 | Low | Windows Firewall settings were restored to the default values. |  |
| Network | 4950 | Low | A Windows Firewall setting has changed. |  |
| Network | 4951 | Low | A rule has been ignored because its major version number was not recognized by Windows Firewall. |  |
| Network | 4952 | Low | Parts of a rule have been ignored because its minor version number was not recognized by Windows Firewall. The other parts of the rule will be enforced. |  |
| Network | 4953 | Low | A rule has been ignored by Windows Firewall because it could not parse the rule. |  |
| Network | 4954 | Low | Windows Firewall Group Policy settings have changed. The new settings have been applied. |  |
| Network | 4956 | Low | Windows Firewall has changed the active profile. |  |
| Network | 4957 | Low | Windows Firewall did not apply the following rule. |  |
| Network | 4958 | Low | Windows Firewall did not apply the following rule because the rule referred to items not configured on this computer. |  |
| Network | 4979 | Low | IPsec Main Mode and Extended Mode security associations were established. |  |
| Network | 4980 | Low | IPsec Main Mode and Extended Mode security associations were established. |  |
| Network | 4981 | Low | IPsec Main Mode and Extended Mode security associations were established. |  |
| Network | 4982 | Low | IPsec Main Mode and Extended Mode security associations were established. |  |
| Network | 4985 | Low | The state of a transaction has changed. (Transactional resource manager event) |  |
| Network | 5024 | Low | The Windows Firewall Service has started successfully. |  |
| Network | 5025 | Low | The Windows Firewall Service has been stopped. |  |
| Network | 5031 | Low | The Windows Firewall Service blocked an application from accepting incoming connections on the network. |  |
| Network | 5032 | Low | Windows Firewall was unable to notify the user that it blocked an application from accepting incoming connections on the network. |  |
| Network | 5033 | Low | The Windows Firewall Driver has started successfully. |  |
| Network | 5034 | Low | The Windows Firewall Driver has been stopped. |  |
| Network | 5039 | Low | A registry key was virtualized. (Registry virtualization due to UAC) |  |
| Network | 5040 | Low | A change has been made to IPsec settings. An Authentication Set was added. |  |
| Network | 5041 | Low | A change has been made to IPsec settings. An Authentication Set was modified. |  |
| Network | 5042 | Low | A change has been made to IPsec settings. An Authentication Set was deleted. |  |
| Network | 5043 | Low | A change has been made to IPsec settings. A Connection Security Rule was added. |  |
| Network | 5044 | Low | A change has been made to IPsec settings. A Connection Security Rule was modified. |  |
| Network | 5045 | Low | A change has been made to IPsec settings. A Connection Security Rule was deleted. |  |
| Network | 5046 | Low | A change has been made to IPsec settings. A Crypto Set was added. |  |
| Network | 5047 | Low | A change has been made to IPsec settings. A Crypto Set was modified. |  |
| Network | 5048 | Low | A change has been made to IPsec settings. A Crypto Set was deleted. |  |
| Network | 5050 | Low | An attempt to programmatically disable the Windows Firewall using a call to InetFwProfile.FirewallEnabled(False). |  |
| Security & Auditing | 1102 | Medium to High | The audit log was cleared. |  |
| Security & Auditing | 4621 | Medium | Administrator recovered system from CrashOnAuditFail – system will allow non-admin logons (some auditable events may have been missed). |  |
| Security & Auditing | 4675 | Medium | SIDs were filtered. |  |
| Security & Auditing | 4692 | Medium | Backup of data protection master key was attempted. |  |
| Security & Auditing | 4693 | Medium | Recovery of data protection master key was attempted. |  |
| Security & Auditing | 4713 | Medium | Kerberos policy was changed. |  |
| Security & Auditing | 4714 | Medium | Encrypted data recovery policy was changed. |  |
| Security & Auditing | 4715 | Medium | The audit policy (SACL) on an object was changed. |  |
| Security & Auditing | 4716 | Medium | Trusted domain information was modified. |  |
| Security & Auditing | 4739 | Medium | Domain Policy was changed. |  |
| Security & Auditing | 4764 | Medium | A security-disabled group was deleted. |  |
| Security & Auditing | 4764 | Medium | A group’s type was changed. |  |
| Security & Auditing | 4780 | Medium | The ACL was set on accounts that are members of administrators groups. |  |
| Security & Auditing | 4816 | Medium | RPC detected an integrity violation while decrypting an incoming message. |  |
| Security & Auditing | 4865 | Medium | A trusted forest information entry was added. |  |
| Security & Auditing | 4866 | Medium | A trusted forest information entry was removed. |  |
| Security & Auditing | 4867 | Medium | A trusted forest information entry was modified. |  |
| Security & Auditing | 4896 | Medium | One or more rows have been deleted from the certificate database. |  |
| Security & Auditing | 4906 | Medium | The CrashOnAuditFail value has changed. |  |
| Security & Auditing | 4907 | Medium | Auditing settings on an object were changed. |  |
| Security & Auditing | 4908 | Medium | Special Groups Logon table modified. |  |
| Security & Auditing | 4912 | Medium | Per User Audit Policy was changed. |  |
| Security & Auditing | 5152 | Low | The Windows Filtering Platform blocked a packet. |  |
| Security & Auditing | 5153 | Low | A more restrictive Windows Filtering Platform filter has blocked a packet. |  |
| Security & Auditing | 5154 | Low | The Windows Filtering Platform has permitted an application or service to listen on a port for incoming connections. |  |
| Security & Auditing | 5155 | Low | The Windows Filtering Platform has blocked an application or service from listening on a port for incoming connections. |  |
| Security & Auditing | 5156 | Low | The Windows Filtering Platform has allowed a connection. |  |
| Security & Auditing | 5157 | Low | The Windows Filtering Platform has blocked a connection. |  |
| Security & Auditing | 5158 | Low | The Windows Filtering Platform has permitted a bind to a local port. |  |
| Security & Auditing | 5159 | Low | The Windows Filtering Platform has blocked a bind to a local port. |  |
| Security & Auditing | 5378 | Low | The requested credentials delegation was disallowed by policy. |  |
| Security & Auditing | 5440 | Low | The following callout was present when the Windows Filtering Platform Base Filtering Engine started. |  |
| Security & Auditing | 5441 | Low | The following filter was present when the Windows Filtering Platform Base Filtering Engine started. |  |
| Security & Auditing | 5442 | Low | The following provider was present when the Windows Filtering Platform Base Filtering Engine started. |  |
| Security & Auditing | 5443 | Low | The following provider context was present when the Windows Filtering Platform Base Filtering Engine started. |  |
| Security & Auditing | 5444 | Low | The following sublayer was present when the Windows Filtering Platform Base Filtering Engine started. |  |
| Security & Auditing | 5446 | Low | A Windows Filtering Platform callout has been changed. |  |
| Security & Auditing | 5447 | Low | A Windows Filtering Platform filter has been changed. |  |
| Security & Auditing | 5448 | Low | A Windows Filtering Platform provider has been changed. |  |
| Security & Auditing | 5449 | Low | A Windows Filtering Platform provider context has been changed. |  |
| Security & Auditing | 5450 | Low | A Windows Filtering Platform sublayer has been changed. |  |
| Security & Auditing | 5451 | Low | An IPsec Quick Mode security association was established. |  |
| Security & Auditing | 5452 | Low | An IPsec Quick Mode security association ended. |  |
| Security & Auditing | 5456 | Low | PAStore Engine applied Active Directory storage IPsec policy on the computer. |  |
| Security & Auditing | 5457 | Low | PAStore Engine failed to apply Active Directory storage IPsec policy on the computer. |  |
| Security & Auditing | 5458 | Low | PAStore Engine applied locally cached copy of Active Directory storage IPsec policy on the computer. |  |
| Security & Auditing | 5459 | Low | PAStore Engine failed to apply locally cached copy of Active Directory storage IPsec policy on the computer. |  |
| Security & Auditing | 5460 | Low | PAStore Engine applied local registry storage IPsec policy on the computer. |  |
| Security & Auditing | 5461 | Low | PAStore Engine failed to apply local registry storage IPsec policy on the computer. |  |
| Security & Auditing | 5462 | Low | PAStore Engine failed to apply some rules of the active IPsec policy on the computer. |  |
| Security & Auditing | 5463 | Low | PAStore Engine polled for changes to the active IPsec policy and detected no changes. |  |
| Security & Auditing | 5464 | Low | PAStore Engine polled for changes to the active IPsec policy, detected changes, and applied them to IPsec Services. |  |
| Security & Auditing | 5465 | Low | PAStore Engine received a control for forced reloading of IPsec policy and processed the control successfully. |  |
| Security & Auditing | 5466 | Low | PAStore Engine polled for changes to the Active Directory IPsec policy – Active Directory unreachable, using cached policy. |  |
| Security & Auditing | 5467 | Low | PAStore Engine polled for changes to the Active Directory IPsec policy – no changes found (returned to normal). |  |
| Security & Auditing | 5468 | Low | PAStore Engine polled for changes to the Active Directory IPsec policy – changes found and applied (cached copy no longer used). |  |
| Security & Auditing | 5471 | Low | PAStore Engine loaded local storage IPsec policy on the computer. |  |
| Security & Auditing | 5472 | Low | PAStore Engine failed to load local storage IPsec policy on the computer. |  |
| Security & Auditing | 5473 | Low | PAStore Engine loaded directory storage IPsec policy on the computer. |  |
| Security & Auditing | 5474 | Low | PAStore Engine failed to load directory storage IPsec policy on the computer. |  |
| Security & Auditing | 5477 | Low | PAStore Engine failed to add quick mode filter. |  |
| Security & Auditing | 5479 | Low | IPsec Services has been shut down successfully. (IPsec service stopped) |  |
| Security & Auditing | 6008 | Low | The previous system shutdown was unexpected. |  |
| System | 4608 | Low | Windows is starting up. |  |
| System | 4609 | Low | Windows is shutting down. |  |
| System | 4610 | Low | An authentication package has been loaded by the Local Security Authority. |  |
| System | 4611 | Low | A trusted logon process has been registered with the Local Security Authority. |  |
| System | 4612 | Low | Internal resources allocated for the queuing of audit messages were exhausted, leading to the loss of some audits. |  |
| System | 4614 | Low | A notification package has been loaded by the Security Account Manager. |  |
| System | 4615 | Low | Invalid use of LPC port. |  |
| System | 4616 | Low | The system time was changed. |  |
| System | 4622 | Low | A security package has been loaded by the Local Security Authority. |  |
| System | 4624 | Low | An account was successfully logged on. |  |
| System | 4625 | Low | An account failed to log on. |  |
| System | 4634 | Low | An account was logged off. |  |
| System | 4646 | Low | IKE DoS-prevention mode started. (IPsec Ike logging) |  |
| System | 4647 | Low | User initiated logoff. |  |
| System | 4648 | Low | A logon was attempted using explicit credentials. |  |
| System | 4650 | Low | An IPsec Main Mode security association was established. Extended Mode was not enabled. Certificate authentication was not used. |  |
| System | 4651 | Low | An IPsec Main Mode security association was established. Extended Mode was not enabled. A certificate was used for authentication. |  |
| System | 4652 | Low | An IPsec Main Mode negotiation failed. |  |
| System | 4653 | Low | An IPsec Main Mode negotiation failed. |  |
| System | 4654 | Low | An IPsec Quick Mode negotiation failed. |  |
| System | 4655 | Low | An IPsec Main Mode security association ended. |  |
| System | 4656 | Low | A handle to an object was requested. |  |
| System | 4657 | Low | A registry value was modified. |  |
| System | 4658 | Low | The handle to an object was closed. |  |
| System | 4659 | Low | A handle to an object was requested with intent to delete. |  |
| System | 4660 | Low | An object was deleted. |  |
| System | 4661 | Low | A handle to an object was requested. |  |
| System | 4662 | Low | An operation was performed on an object. |  |
| System | 4663 | Low | An attempt was made to access an object. |  |
| System | 4664 | Low | An attempt was made to create a hard link. |  |
| System | 4665 | Low | An attempt was made to create an application client context. |  |
| System | 4666 | Low | An application attempted an operation. |  |
| System | 4667 | Low | An application client context was deleted. |  |
| System | 4668 | Low | An application was initialized. |  |
| System | 4670 | Low | Permissions on an object were changed. |  |
| System | 4671 | Low | An application attempted to access a blocked ordinal through the TBS. |  |
| System | 4672 | Low | Special privileges assigned to new logon. |  |
| System | 4673 | Low | A privileged service was called. |  |
| System | 4674 | Low | An operation was attempted on a privileged object. |  |
| System | 4688 | Low | A new process has been created. |  |
| System | 4689 | Low | A process has exited. |  |
| System | 4690 | Low | An attempt was made to duplicate a handle to an object. |  |
| System | 4691 | Low | Indirect access to an object was requested. |  |
| System | 4694 | Low | Protection of auditable protected data was attempted. |  |
| System | 4695 | Low | Unprotection of auditable protected data was attempted. |  |
| System | 4696 | Low | A primary token was assigned to process. |  |
| System | 4697 | Low | Attempt to install a service. |  |
| System | 4698 | Low | A scheduled task was created. |  |
| System | 4699 | Low | A scheduled task was deleted. |  |
| System | 4700 | Low | A scheduled task was enabled. |  |
| System | 4701 | Low | A scheduled task was disabled. |  |
| System | 4702 | Low | A scheduled task was updated. |  |
| System | 4704 | Low | A user right was assigned. |  |
| System | 4705 | Low | A user right was removed. |  |
| System | 4709 | Low | IPsec Services was started. |  |
| System | 4710 | Low | IPsec Services was disabled. |  |
| System | 4711 | Low | (Detailed IPsec policy application events – see below) |  |
| System | 4712 | Low | IPsec Services encountered a potentially serious failure. |  |
| System | 24577 | Low | Encryption of volume started. |  |
| System | 24578 | Low | Encryption of volume stopped. |  |
| System | 24579 | Low | Encryption of volume completed. |  |
| System | 24580 | Low | Decryption of volume started. |  |
| System | 24581 | Low | Decryption of volume stopped. |  |
| System | 24582 | Low | Decryption of volume completed. |  |
| System | 24583 | Low | Conversion worker thread for volume started. |  |
| System | 24584 | Low | Conversion worker thread for volume temporarily stopped. |  |
| System | 24588 | Low | The conversion operation on volume %2 encountered a bad sector error. Please validate the data on this volume. |  |
| System | 24595 | Low | Volume %2 contains bad clusters. These clusters will be skipped during conversion. |  |
| System | 24621 | Low | Initial state check: Rolling volume conversion transaction on %2. |  |
| System | 5049 | Low | An IPsec Security Association was deleted. |  |
| System | 5478 | Low | IPsec Services has started successfully. |  |
| System | 4700 | Low | A scheduled task was enabled. |  |
| System | 4701 | Low | A scheduled task was disabled. |  |
| System | 4702 | Low | A scheduled task was updated. |  |
| System | 4704 | Low | A user right was assigned. |  |
| System | 4705 | Low | A user right was removed. |  |
| System | 4707 | (See Identity & Access domain above for Event 4707) | (Trust removed; listed above) |  |
| System | 4709 | Low | IPsec Services was started. |  |
| System | 4710 | Low | IPsec Services was disabled. |  |
| System | 4711 | Low | (Detailed IPsec policy application events – see below) |  |
| System | 4712 | Low | IPsec Services encountered a potentially serious failure. |  |
| System | 5632 | (See Network domain above for Event 5632) | (Wireless auth request; listed above) |  |
| System | 5633 | (See Network domain above for Event 5633) | (Wired auth request; listed above) |  |
| System | 5712 | (See Network domain above for Event 5712) | (RPC attempt; listed above) |  |
| System | 6008 | (See Security & Auditing domain above for Event 6008) | (Unexpected shutdown; listed above) |  |
| System | 6144 | (See Network domain above for Event 6144) | (GPO applied; listed above) |  |
| System | 6272 | (See Identity & Access domain above for Event 6272) | (NPS granted access; listed above) |  |
| System | N/A (legacy 561) | Low | A handle to an object was requested. |  |
| System | N/A (legacy 563) | Low | Object open for delete. |  |
| System | N/A (legacy 613) | Low | IPsec policy agent started. |  |
| System | N/A (legacy 614) | Low | IPsec policy agent disabled. |  |
| System | N/A (legacy 615) | Low | IPsec policy agent. |  |
| System | N/A (legacy 616) | Low | IPsec policy agent encountered a potential serious failure. |  |
| System | 24577 | Low | Encryption of volume started. |  |
| System | 24578 | Low | Encryption of volume stopped. |  |
| System | 24579 | Low | Encryption of volume completed. |  |
| System | 24580 | Low | Decryption of volume started. |  |
| System | 24581 | Low | Decryption of volume stopped. |  |
| System | 24582 | Low | Decryption of volume completed. |  |
| System | 24583 | Low | Conversion worker thread for volume started. |  |
| System | 24584 | Low | Conversion worker thread for volume temporarily stopped. |  |
| System | 24588 | Low | The conversion operation on volume %2 encountered a bad sector error. Please validate the data on this volume. |  |
| System | 24595 | Low | Volume %2 contains bad clusters. These clusters will be skipped during conversion. |  |
| System | 24621 | Low | Initial state check: Rolling volume conversion transaction on %2. |  |
| System | 5049 | Low | An IPsec Security Association was deleted. |  |
| System | 5478 | Low | IPsec Services has started successfully. |  |

* Adapted from [Microsoft’s Events to Monitor list](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/appendix-l--events-to-monitor), which provides the current event IDs, recommended criticality, and descriptions for each event.
* Legacy-only events are not included in the table.

### Important notes

- Events were categorized in each domain based on intent rather than source channel.
- Some events span multiple domains, however, I tried to keep them organized in the domain that makes more sense for the future use of the event.
- **Work in progress...**