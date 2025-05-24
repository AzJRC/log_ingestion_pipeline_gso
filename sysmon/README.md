# Sysmon guide

## What's sysmon?

TODO

## Sysmon coverage

TODO 

## Sysmon installation 

Installing Sysmon is an easy and straighforward task, but not many people know how to configure advanced parameters during the installation process.

    Remember that privileges are required to install Sysmon.

### Quick installation

You can download Sysmon from the [Sysinternals Documentation page](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon). If for any reason you require a previous version of Sysmon, unfortunately Microsoft does not keep the record of older binaries; however, user `super0xbad1dea` made [this](https://github.com/super0xbad1dea/SysmonVersions) repository which keep track of Sysmon since version `9.01` up to `15.11`.

Once downloaded, decrompress the file to get three executables:
- `Sysmon.exe` is used both in systems x64 and x86
- `Sysmon64.exe` is used in systems x64
- `Sysmon64a.exe` is used in systems x64 with ARM architecture

Run the following command to install Windows Sysmon in your current computer:

```PowerShell
Sysmon.exe -i -accepteula
```

### Advanced parameters

Sysmon has extra options and parameters to customize the installation. To see the most common options, you can just run `Sysmon.exe` and a help output will appear in the terminal.

To see all available options, you can add the `-s` parameter to see the installation schema file. The first section of the schema enlists the available options. A more detailed explanaition of the use of these parameters can be found in the section [Command-line configuration](#command-line-configuration).

### Hiding sysmon

You can use the `-d` option to change the driver name of Sysmon.

```PowerShell
Sysmon.exe -i -d monkeyd -accepteula
```

Also, you can change the name of the service itself. To do so, you must rename the executable file from `Sysmon.exe` to `<desired_name>.exe`.

```PowerShell
Monkey.exe -i -d monkeyd -accepteula
```

This will install Sysmon with the service name as `Monkey` and driver name as `monkeyd`.

Be careful when renaming the Sysmon service. If you forget the name, you'll have issues later when trying to interact with the application. For example, if for some reason you need to look for the registry keys of Sysmon, you'll need to search instead the new driver's name and service's name.

### Enabling other Hash Algorithms

By default, Sysmon will use `SHA256` to hash all images detected in its events, but you can change this by using the `-h` parameter.

```PowerShell
Sysmon.exe -c -h SHA1,SHA2
```

Available hashing algorithms include `SHA1`, `SHA2`, `MD5`, and `IMPHASH`. If you want to enable all of them, you can type an asterisk (`*`).

### Other recommendations

- Change the service description of Sysmon from "System Monitor Service" to something else. You can leverage WMI or manually modify the Registry Key value `Description` located at `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Sysmon\`. This will make your Sysmon installation a little bit more stealthy in a very secure manner.
- If you are working in a big organization, renaming the Sysmon Service and Sysmon driver may provide value, but keep in mind the risks of forgetting the new names.
- It is not recommended to change the altitude number of Sysmon, even if its for making the service stealthier. The risks are high.
- Adminsitrative users can (unload the Sysmon driver)[https://www.ired.team/offensive-security/defense-evasion/unloading-sysmon-driver] with the `fltMC.exe` LoLBin. You can prevent this behavior by setting up a Domain Group Policy. Also, you can detect this behavior when `fltMC.exe` is executed by inspecting the Sysmon Event Log `ID 1: Process Creation` with the following detail information:

```PowerShell
CommandLine: "C:\Windows\system32\fltMC.exe" unload SysmonDrv
```

- If you are having issues uninstalling Sysmon, you can use the command `Sysmon.exe -u force`.

### Linux sysmon

TODO

## What happen when I install Sysmon?

Upon Sysmon installation, a driver (SysmonDrv) and a service (Sysmon) will be installed in the current box, and Eventlog Manifest using `wevtutil.exe` will be automatically configured, and finally the following default configuration will be enabled:
- Monitor `Event ID 1: ProcessCreate`
- Monitor `Event ID 5: ProcessTerminate`
- Monitor `Event ID 6: DriverLoad`
- Monitor `Event ID 1: FileCreateTime`
- `SHA256` will be used to hash all images detected by Sysmon.

Moreover, it is good to know that Sysmon will create 2 registry keys under the following paths (assuming default driver name and service name were used when installing Sysmon):

```PowerShell
HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Sysmon
HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\SysmonDrv
```

The first one specifies the configuration pararmeters of the service that talks to the Sysmon driver. The second is the Kernel Driver Service that loads the Sysmon driver with an [altitude number](https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/load-order-groups-and-altitudes-for-minifilter-drivers#minifilter-altitudes) of 385201. 

This particular piece of information is very important, as organizations or users may face issues when understanding why its Sysmon service isn't capturing all events. The altitude number is, simple terms, a priority number that tells Windows Services in which order they will be placed in between the Windows API and the Windows File System. If you happen to have various EDR and Antivirus software solutions in your box, and one of them also happens to have a lower altitude number, any action perfomed by that service will take precedence to Sysmon. You can check allocated altitude numbers in [this](https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/allocated-altitudes) reference page (though, for some reason Sysmon doesn't appear here).

To learn more about drivers, minifilters, and altitude numbers and their relevance, you are encouranged to read the following Microsoft Documentation resources:

- [About file system filter drivers](https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/about-file-system-filter-drivers)
- [Filter Manager Concepts](https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/filter-manager-concepts)
- [Understanding Mini-Filter Drivers for Windows Vulnerability Research & Exploit Development](https://medium.com/@WaterBucket/understanding-mini-filter-drivers-for-windows-vulnerability-research-exploit-development-391153c945d6)

## Sysmon configuration

### Command-line configuration

To view a summary of the current configuration of your Sysmon installation, you can run the following command:

```PowerShell
Sysmon.exe -c
```

You can also reset the configuration of Sysmon by adding a double dash (`--`) as the value of the `-c` parameter.

```PowerShell
Sysmon.exe -c --
```

Keep in mind that modifying the configuration file of Sysmon will generate the `EventId 16: ConfigChange`, which if monitored by security solutions, it may generate alerts that will fire alarms.

To review the complete configuration of your current Sysmon installation, you'll need to run the command with the `-s` parameter. The following list contains the available command-line options:

1. *Command-Line Only Options*
    - **`-i [optional]`**: Install Sysmon. Can optionally specify a configuration file.
    - **`-c [optional]`**: Load a configuration file without installing or updating Sysmon.
    - **`-u [optional]`**: Uninstall Sysmon. Can optionally specify to remove the configuration.
    - **`-m`**: Output the manifest for the current Sysmon configuration.
    - **`-z <instance>`**: Specify a clipboard monitoring instance (required argument).
    - **`-t [optional]`**: Enable debug mode, useful for troubleshooting.
    - **`-btf [optional]`**: Enable or configure BTF (e.g., enhanced telemetry or feature-specific logging).
    - **`-service`**: Run Sysmon as a service.
    - **`-s [optional]`**: Print the Sysmon configuration schema.
    - **`-nologo`**: Suppress the Sysinternals logo in output.
    - **`-accepteula`**: Automatically accept the Sysinternals license agreement.
    - **`--`**: Use default configuration settings.

2. *Configuration File Options*
    - **`-a <directory>`**: Set the directory for archiving log files.
    - **`CaptureClipboard`**: Enable clipboard capture logging.
    - **`-d <driver>`**: Specify a custom driver name for Sysmon.
    - **`-dns [optional]`**: Enable DNS query logging, can specify additional settings.
    - **`-g <pipe>`**: Monitor named pipes, requires configuration rule.
    - **`-h <algorithms>`**: Set the hashing algorithms used (e.g., SHA1, SHA256).
    - **`DnsLookup <resolver>`**: Specify DNS resolver for hostname resolution.
    - **`-k <access>`**: Monitor process access attempts, requires rule configuration. **DEPRECATED**
    - **`-l [optional]`**: Enable image load event logging.
    - **`-n [optional]`**: Monitor network connections.
    - **`-r [optional]`**: Check for certificate revocation.
    - **`FieldSizes <sizes>`**: Define field sizes for log outputs.

When using any of these parameters, you must include always the `-c` option. This tells Sysmon that you are applying a configuration option.

    Important: Not all parameters seem to work. These are apparently bugs in the application itself, and therefore you'll normally stick to the XML configuration file, and the command-line configuration will essentially be limited to inspecting your current configuration.

### XML Configuration file

Configuring Sysmon using the XML file is often the prefered method, especialy with projects like the ones made by `SwiftOnSecurity` on [`sysmon-config`](https://github.com/SwiftOnSecurity/sysmon-config) or by `olafhartong` on [`sysmon-modular`](https://github.com/olafhartong/sysmon-modular), which will made our lives more easier when it comes to create a tailored configuration of our Sysmon instance.

#### Configuration file overview


#### Event Types and Schema


#### Event filtering


