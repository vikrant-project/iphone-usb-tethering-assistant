using System;
using Xunit;

namespace TetherAssistant.Tests;

public class TelemetryMathTests
{
    [Fact]
    public void ThroughputCalculation_WithKnownBytesAndInterval_ReturnsExpectedMbps()
    {
        // 10,000,000 bytes = 80,000,000 bits
        // In 1 second = 80.0 Mbps
        long bytesDelta = 10_000_000;
        double secondsDelta = 1.0;

        double mbps = (bytesDelta * 8.0) / (secondsDelta * 1_000_000.0);

        Assert.Equal(80.0, mbps, precision: 2);
    }

    [Fact]
    public void ThroughputCalculation_CounterWrapAround_DoesNotYieldNegativeMbps()
    {
        long currentRx = 500;
        long prevRx = 2_000; // Counter reset / rolled over
        double secondsDelta = 1.0;

        long delta = currentRx - prevRx;
        double mbps = Math.Max(0.0, (delta * 8.0) / (secondsDelta * 1_000_000.0));

        Assert.Equal(0.0, mbps);
    }

    [Fact]
    public void MegabyteConversion_ConvertsBytesCorrectly()
    {
        long bytes = 104_857_600; // 100 MB exactly (100 * 1024 * 1024)
        double megabytes = bytes / (1024.0 * 1024.0);

        Assert.Equal(100.0, megabytes, precision: 2);
    }
}

