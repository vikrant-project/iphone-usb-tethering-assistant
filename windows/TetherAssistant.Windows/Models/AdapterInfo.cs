using System;
using System.Net;
using System.Net.NetworkInformation;

namespace TetherAssistant.Windows.Models;

public sealed record AdapterInfo
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public required string Description { get; init; }
    public required OperationalStatus Status { get; init; }
    public required IPAddress? IpAddress { get; init; }
    public required IPAddress? SubnetMask { get; init; }
    public required IPAddress? GatewayAddress { get; init; }
    public required IPAddress? DnsServer { get; init; }
    public required long SpeedBitsPerSecond { get; init; }
    public required bool IsAppleTethering { get; init; }
    public required DateTime DetectedAtUtc { get; init; }

    public string SpeedFormatted => SpeedBitsPerSecond >= 1_000_000_000 
        ? $"{SpeedBitsPerSecond / 1_000_000_000.0:F1} Gbps" 
        : $"{SpeedBitsPerSecond / 1_000_000.0:F0} Mbps";
}

