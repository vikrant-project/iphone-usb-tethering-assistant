using System.Threading.Tasks;
using System.Windows.Input;
using TetherAssistant.Windows.Core;
using TetherAssistant.Windows.Services;

namespace TetherAssistant.Windows.ViewModels;

public class SettingsViewModel : ObservableObject
{
    private readonly ISessionRepository _sessionRepository;
    private bool _notificationsEnabled = true;
    private int _samplingIntervalSeconds = 1;
    private string _statusMessage = string.Empty;

    public bool NotificationsEnabled
    {
        get => _notificationsEnabled;
        set => SetProperty(ref _notificationsEnabled, value);
    }

    public int SamplingIntervalSeconds
    {
        get => _samplingIntervalSeconds;
        set => SetProperty(ref _samplingIntervalSeconds, value);
    }

    public string StatusMessage
    {
        get => _statusMessage;
        set => SetProperty(ref _statusMessage, value);
    }

    public ICommand ClearHistoryCommand { get; }

    public SettingsViewModel(ISessionRepository sessionRepository)
    {
        _sessionRepository = sessionRepository;
        ClearHistoryCommand = new AsyncRelayCommand(ClearHistoryAsync);
    }

    private async Task ClearHistoryAsync()
    {
        await _sessionRepository.ClearHistoryAsync();
        StatusMessage = "Session history wiped cleanly.";
    }
}

