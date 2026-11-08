using System;
using TetherAssistant.Windows.Core;
using TetherAssistant.Windows.Models;
using TetherAssistant.Windows.Services;

namespace TetherAssistant.Windows.ViewModels;

public class DashboardViewModel : ObservableObject
{
    private readonly INetworkAdapterService _adapterService;
    private readonly ITelemetryService _telemetryService;

    private bool _isConnected;
    private string _connectionStatusText = "Disconnected";
    private string _adapterName = "No Apple Adapter";
    private double _downloadSpeedMbps;
    private double _uploadSpeedMbps;
    private string _sessionDuration = "00:00:00";
    private string _sessionDataTransferred = "0.0 MB";

    public bool IsConnected
    {
        get => _isConnected;
        set => SetProperty(ref _isConnected, value);
    }

    public string ConnectionStatusText
    {
        get => _connectionStatusText;
        set => SetProperty(ref _connectionStatusText, value);
    }

    public string AdapterName
    {
        get => _adapterName;
        set => SetProperty(ref _adapterName, value);
    }

    public double DownloadSpeedMbps
    {
        get => _downloadSpeedMbps;
        set => SetProperty(ref _downloadSpeedMbps, value);
    }

    public double UploadSpeedMbps
    {
        get => _uploadSpeedMbps;
        set => SetProperty(ref _uploadSpeedMbps, value);
    }

    public string SessionDuration
    {
        get => _sessionDuration;
        set => SetProperty(ref _sessionDuration, value);
    }

    public string SessionDataTransferred
    {
        get => _sessionDataTransferred;
        set => SetProperty(ref _sessionDataTransferred, value);
    }

    public DashboardViewModel(INetworkAdapterService adapterService, ITelemetryService telemetryService)
    {
        _adapterService = adapterService;
        _telemetryService = telemetryService;

        _adapterService.AdapterStateChanged += OnAdapterStateChanged;
        _telemetryService.TelemetryUpdated += OnTelemetryUpdated;

        if (_adapterService.CurrentAdapter != null)
        {
            UpdateAdapterState(_adapterService.CurrentAdapter);
        }
    }

    private void OnAdapterStateChanged(object? sender, AdapterInfo? adapter)
    {
        UpdateAdapterState(adapter);
    }

    private void UpdateAdapterState(AdapterInfo? adapter)
    {
        if (adapter != null)
        {
            IsConnected = true;
            ConnectionStatusText = "Connected via USB";
            AdapterName = $"{adapter.Name} ({adapter.Description})";
            _telemetryService.StartSampling(adapter.Id);
        }
        else
        {
            IsConnected = false;
            ConnectionStatusText = "Waiting for iPhone USB...";
            AdapterName = "No Apple Adapter Detected";
            DownloadSpeedMbps = 0.0;
            UploadSpeedMbps = 0.0;
            _ = _telemetryService.StopSamplingAsync();
        }
    }

    private void OnTelemetryUpdated(object? sender, TelemetrySample sample)
    {
        DownloadSpeedMbps = sample.DownloadSpeedMbps;
        UploadSpeedMbps = sample.UploadSpeedMbps;
        SessionDuration = sample.FormattedDuration;
        SessionDataTransferred = $"{sample.SessionDownloadedMB + sample.SessionUploadedMB:F1} MB";
    }
}

