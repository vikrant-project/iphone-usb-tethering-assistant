using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Windows.Input;
using TetherAssistant.Windows.Core;
using TetherAssistant.Windows.Models;
using TetherAssistant.Windows.Services;

namespace TetherAssistant.Windows.ViewModels;

public class DiagnosticsViewModel : ObservableObject
{
    private readonly IDiagnosticsService _diagnosticsService;
    private bool _isRunning;
    private string _overallSummary = "Click 'Run Diagnostics' to test your tethered connection.";
    private bool _isHealthy = true;

    public bool IsRunning
    {
        get => _isRunning;
        set => SetProperty(ref _isRunning, value);
    }

    public string OverallSummary
    {
        get => _overallSummary;
        set => SetProperty(ref _overallSummary, value);
    }

    public bool IsHealthy
    {
        get => _isHealthy;
        set => SetProperty(ref _isHealthy, value);
    }

    public ObservableCollection<DiagnosticStageResult> Stages { get; } = new();

    public ICommand RunDiagnosticsCommand { get; }

    public DiagnosticsViewModel(IDiagnosticsService diagnosticsService)
    {
        _diagnosticsService = diagnosticsService;
        RunDiagnosticsCommand = new AsyncRelayCommand(RunDiagnosticsAsync, () => !IsRunning);
    }

    private async Task RunDiagnosticsAsync()
    {
        IsRunning = true;
        Stages.Clear();
        OverallSummary = "Running 4-stage diagnostic pipeline...";

        var result = await _diagnosticsService.RunFullDiagnosticsAsync();

        foreach (var stage in result.Stages)
        {
            Stages.Add(stage);
        }

        IsHealthy = result.IsHealthy;
        OverallSummary = result.OverallSummary;
        IsRunning = false;
    }
}

