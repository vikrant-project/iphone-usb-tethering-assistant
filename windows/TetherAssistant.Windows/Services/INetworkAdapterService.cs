using System;
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public interface INetworkAdapterService
{
    event EventHandler<AdapterInfo?>? AdapterStateChanged;
    AdapterInfo? CurrentAdapter { get; }
    Task<AdapterInfo?> ScanForAdapterAsync(CancellationToken cancellationToken = default);
    void StartListening();
    void StopListening();
}

