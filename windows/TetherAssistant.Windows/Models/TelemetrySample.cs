using System;

namespace TetherAssistant.Windows.Models;

public sealed record TelemetrySample
{
    public required DateTime TimestampUtc { get; init; }
    public required double DownloadSpeedMbps { get; init; }
    public required double UploadSpeedMbps { get; init; }
    public required long TotalBytesReceived { get; init; }
    public required long TotalBytesSent { get; init; }
    public required double SessionDownloadedMB { get; init; }
    public required double SessionUploadedMB { get; init; }
    public required TimeSpan SessionDuration { get; init; }

    public string FormattedDuration => 
        $"{(int)SessionDuration.TotalHours:D2}:{SessionDuration.Minutes:D2}:{SessionDuration.Seconds:D2}";
}

