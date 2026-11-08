using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public class DiagnosticsService : IDiagnosticsService
{
    private readonly INetworkAdapterService _adapterService;

    public DiagnosticsService(INetworkAdapterService adapterService)
    {
        _adapterService = adapterService;
    }

    public async Task<DiagnosticSuiteResult> RunFullDiagnosticsAsync(CancellationToken cancellationToken = default)
    {
        var stages = new List<DiagnosticStageResult>();
        var adapter = _adapterService.CurrentAdapter;

        // Stage 1: Driver & Link State
        var s1 = TestDriverAndLink(adapter);
        stages.Add(s1);
        if (s1.Severity == DiagnosticSeverity.Failure)
        {
            return BuildResult(stages, "Physical connection or Apple Mobile Device Ethernet driver missing.");
        }

        // Stage 2: Gateway Reachability (172.20.10.1)
        var s2 = await TestGatewayPingAsync("172.20.10.1", cancellationToken);
        stages.Add(s2);
        if (s2.Severity == DiagnosticSeverity.Failure)
        {
            return BuildResult(stages, "iPhone detected, but gateway ping failed. Check if Personal Hotspot is turned ON.");
        }

        // Stage 3: DNS Resolution
        var s3 = await TestDnsResolutionAsync(cancellationToken);
        stages.Add(s3);
        if (s3.Severity == DiagnosticSeverity.Failure)
        {
            return BuildResult(stages, "DNS resolution timed out. Carrier mobile data may be exhausted or offline.");
        }

        // Stage 4: Internet WAN Reachability
        var s4 = await TestWanConnectivityAsync(cancellationToken);
        stages.Add(s4);

        bool isAllHealthy = stages.TrueForAll(s => s.Severity == DiagnosticSeverity.Pass);
        return BuildResult(stages, isAllHealthy 
            ? "Tethered connection is fully healthy and performing optimally." 
            : "Minor network degradation detected.");
    }

    private static DiagnosticStageResult TestDriverAndLink(AdapterInfo? adapter)
    {
        if (adapter == null || adapter.Status != OperationalStatus.Up)
        {
            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.DriverAndPhysicalLink,
                StageName = "Physical Link & Driver",
                Severity = DiagnosticSeverity.Failure,
                LatencyMilliseconds = 0,
                Details = "No active Apple Ethernet adapter detected.",
                TroubleshootingAdvice = "Connect USB cable, tap 'Trust This Computer' on iPhone, and ensure Apple Devices / iTunes is installed."
            };
        }

        return new DiagnosticStageResult
        {
            Stage = DiagnosticStage.DriverAndPhysicalLink,
            StageName = "Physical Link & Driver",
            Severity = DiagnosticSeverity.Pass,
            LatencyMilliseconds = 0,
            Details = $"Adapter {adapter.Name} is operational ({adapter.SpeedFormatted}).",
            TroubleshootingAdvice = null
        };
    }

    private static async Task<DiagnosticStageResult> TestGatewayPingAsync(string gatewayIp, CancellationToken ct)
    {
        var sw = Stopwatch.StartNew();
        try
        {
            using var ping = new Ping();
            var reply = await ping.SendPingAsync(IPAddress.Parse(gatewayIp), 1500);
            sw.Stop();

            if (reply.Status == IPStatus.Success)
            {
                return new DiagnosticStageResult
                {
                    Stage = DiagnosticStage.GatewayReachability,
                    StageName = "iPhone Gateway Ping (172.20.10.1)",
                    Severity = DiagnosticSeverity.Pass,
                    LatencyMilliseconds = reply.RoundtripTime,
                    Details = $"Gateway responded in {reply.RoundtripTime} ms over USB bus.",
                    TroubleshootingAdvice = null
                };
            }

            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.GatewayReachability,
                StageName = "iPhone Gateway Ping (172.20.10.1)",
                Severity = DiagnosticSeverity.Failure,
                LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                Details = $"Ping returned: {reply.Status}",
                TroubleshootingAdvice = "Toggle Personal Hotspot OFF and ON in iPhone Settings."
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.GatewayReachability,
                StageName = "iPhone Gateway Ping (172.20.10.1)",
                Severity = DiagnosticSeverity.Failure,
                LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                Details = ex.Message,
                TroubleshootingAdvice = "Ensure iPhone is unlocked and Personal Hotspot is active."
            };
        }
    }

    private static async Task<DiagnosticStageResult> TestDnsResolutionAsync(CancellationToken ct)
    {
        var sw = Stopwatch.StartNew();
        try
        {
            var hostEntry = await Dns.GetHostEntryAsync("one.one.one.one", ct);
            sw.Stop();

            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.DnsResolution,
                StageName = "DNS Resolution",
                Severity = DiagnosticSeverity.Pass,
                LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                Details = $"Resolved to {hostEntry.AddressList[0]} in {sw.Elapsed.TotalMilliseconds:F1} ms.",
                TroubleshootingAdvice = null
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.DnsResolution,
                StageName = "DNS Resolution",
                Severity = DiagnosticSeverity.Failure,
                LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                Details = ex.Message,
                TroubleshootingAdvice = "Cellular carrier DNS failed to respond. Check mobile data balance."
            };
        }
    }

    private static async Task<DiagnosticStageResult> TestWanConnectivityAsync(CancellationToken ct)
    {
        var sw = Stopwatch.StartNew();
        try
        {
            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(3) };
            using var response = await client.GetAsync("http://cp.cloudflare.com/generate_204", ct);
            sw.Stop();

            if (response.StatusCode == HttpStatusCode.NoContent)
            {
                return new DiagnosticStageResult
                {
                    Stage = DiagnosticStage.InternetWanReachability,
                    StageName = "Internet WAN Probe",
                    Severity = DiagnosticSeverity.Pass,
                    LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                    Details = "Direct WAN connection confirmed via Cloudflare edge.",
                    TroubleshootingAdvice = null
                };
            }

            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.InternetWanReachability,
                StageName = "Internet WAN Probe",
                Severity = DiagnosticSeverity.Warning,
                LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                Details = $"Received status {(int)response.StatusCode}",
                TroubleshootingAdvice = "Possible captive portal or carrier proxy restriction."
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticStageResult
            {
                Stage = DiagnosticStage.InternetWanReachability,
                StageName = "Internet WAN Probe",
                Severity = DiagnosticSeverity.Failure,
                LatencyMilliseconds = sw.Elapsed.TotalMilliseconds,
                Details = ex.Message,
                TroubleshootingAdvice = "Check if iPhone cellular data switch is toggled ON."
            };
        }
    }

    private static DiagnosticSuiteResult BuildResult(IReadOnlyList<DiagnosticStageResult> stages, string summary)
    {
        return new DiagnosticSuiteResult
        {
            TimestampUtc = DateTime.UtcNow,
            IsHealthy = stages.TrueForAll(s => s.Severity == DiagnosticSeverity.Pass),
            Stages = stages,
            OverallSummary = summary
        };
    }
}

