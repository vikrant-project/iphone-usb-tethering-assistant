using System;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public interface ITelemetryService
{
    event EventHandler<TelemetrySample>? TelemetryUpdated;
    void StartSampling(string networkInterfaceId);
    Task StopSamplingAsync();
    TelemetrySample? LatestSample { get; }
}

