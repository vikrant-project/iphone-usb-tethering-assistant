using System;
using System.Linq;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public class TelemetryService : ITelemetryService
{
    private CancellationTokenSource? _cts;
    private Task? _samplingTask;
    private long _sessionInitialRx;
    private long _sessionInitialTx;
    private DateTime _sessionStartTime;

    public event EventHandler<TelemetrySample>? TelemetryUpdated;
    public TelemetrySample? LatestSample { get; private set; }

    public void StartSampling(string networkInterfaceId)
    {
        StopSamplingAsync().GetAwaiter().GetResult();

        var nic = NetworkInterface.GetAllNetworkInterfaces()
            .FirstOrDefault(n => n.Id == networkInterfaceId);

        if (nic == null) return;

        _cts = new CancellationTokenSource();
        _sessionStartTime = DateTime.UtcNow;

        var stats = nic.GetIPv4InterfaceStatistics();
        _sessionInitialRx = stats.BytesReceived;
        _sessionInitialTx = stats.BytesSent;

        _samplingTask = Task.Run(() => RunLoopAsync(nic, _cts.Token));
    }

    public async Task StopSamplingAsync()
    {
        if (_cts != null)
        {
            _cts.Cancel();
            if (_samplingTask != null)
            {
                try { await _samplingTask; } catch (OperationCanceledException) { }
            }
            _cts.Dispose();
            _cts = null;
            _samplingTask = null;
        }
    }

    private async Task RunLoopAsync(NetworkInterface nic, CancellationToken ct)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(1));
        long prevRx = _sessionInitialRx;
        long prevTx = _sessionInitialTx;
        var prevTime = DateTime.UtcNow;

        while (!ct.IsCancellationRequested && await timer.WaitForNextTickAsync(ct))
        {
            var now = DateTime.UtcNow;
            var stats = nic.GetIPv4InterfaceStatistics();
            long currentRx = stats.BytesReceived;
            long currentTx = stats.BytesSent;

            double deltaSeconds = (now - prevTime).TotalSeconds;
            if (deltaSeconds <= 0) deltaSeconds = 1.0;

            double rxMbps = Math.Max(0.0, ((currentRx - prevRx) * 8.0) / (deltaSeconds * 1_000_000.0));
            double txMbps = Math.Max(0.0, ((currentTx - prevTx) * 8.0) / (deltaSeconds * 1_000_000.0));

            prevRx = currentRx;
            prevTx = currentTx;
            prevTime = now;

            var sample = new TelemetrySample
            {
                TimestampUtc = now,
                DownloadSpeedMbps = rxMbps,
                UploadSpeedMbps = txMbps,
                TotalBytesReceived = currentRx,
                TotalBytesSent = currentTx,
                SessionDownloadedMB = Math.Max(0.0, (currentRx - _sessionInitialRx) / (1024.0 * 1024.0)),
                SessionUploadedMB = Math.Max(0.0, (currentTx - _sessionInitialTx) / (1024.0 * 1024.0)),
                SessionDuration = now - _sessionStartTime
            };

            LatestSample = sample;
            TelemetryUpdated?.Invoke(this, sample);
        }
    }
}

