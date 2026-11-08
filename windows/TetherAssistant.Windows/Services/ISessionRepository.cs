using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace TetherAssistant.Windows.Services;

public sealed record SessionRecord(
    Guid Id,
    DateTime StartTimeUtc,
    DateTime? EndTimeUtc,
    long BytesReceived,
    long BytesSent,
    double PeakDownloadSpeedMbps,
    string AdapterName
);

public interface ISessionRepository
{
    Task SaveSessionAsync(SessionRecord record);
    Task<IReadOnlyList<SessionRecord>> GetRecentSessionsAsync(int limit = 50);
    Task ClearHistoryAsync();
}

