using System;
using System.Net;
using System.Net.NetworkInformation;
using TetherAssistant.Windows.Models;
using Xunit;

namespace TetherAssistant.Tests;

public class AdapterDetectionTests
{
    [Fact]
    public void AdapterInfo_FormattedSpeed_UnderOneGigabit_DisplaysMbps()
    {
        var adapter = new AdapterInfo
        {
            Id = "{12345678-ABCD-EF01-2345-6789ABCDEF01}",
            Name = "Ethernet 2",
            Description = "Apple Mobile Device Ethernet",
            Status = OperationalStatus.Up,
            IpAddress = IPAddress.Parse("172.20.10.2"),
            SubnetMask = IPAddress.Parse("255.255.255.240"),
            GatewayAddress = IPAddress.Parse("172.20.10.1"),
            DnsServer = IPAddress.Parse("172.20.10.1"),
            SpeedBitsPerSecond = 480_000_000, // 480 Mbps (USB 2.0 High-Speed ceiling)
            IsAppleTethering = true,
            DetectedAtUtc = DateTime.UtcNow
        };

        Assert.Equal("480 Mbps", adapter.SpeedFormatted);
    }

    [Fact]
    public void AdapterInfo_FormattedSpeed_AtOrAboveOneGigabit_DisplaysGbps()
    {
        var adapter = new AdapterInfo
        {
            Id = "{12345678-ABCD-EF01-2345-6789ABCDEF02}",
            Name = "Ethernet 3",
            Description = "USB NCM Host Device",
            Status = OperationalStatus.Up,
            IpAddress = IPAddress.Parse("172.20.10.2"),
            SubnetMask = IPAddress.Parse("255.255.255.240"),
            GatewayAddress = IPAddress.Parse("172.20.10.1"),
            DnsServer = IPAddress.Parse("172.20.10.1"),
            SpeedBitsPerSecond = 1_000_000_000, // 1 Gbps (USB 3.2 Gen 1 CDC-NCM link)
            IsAppleTethering = true,
            DetectedAtUtc = DateTime.UtcNow
        };

        Assert.Equal("1.0 Gbps", adapter.SpeedFormatted);
    }
}
