using TetherAssistant.Windows.Core;
using TetherAssistant.Windows.Models;
using TetherAssistant.Windows.Services;

namespace TetherAssistant.Windows.ViewModels;

public class NetworkViewModel : ObservableObject
{
    private readonly INetworkAdapterService _adapterService;
    private AdapterInfo? _adapter;

    public AdapterInfo? Adapter
    {
        get => _adapter;
        set => SetProperty(ref _adapter, value);
    }

    public NetworkViewModel(INetworkAdapterService adapterService)
    {
        _adapterService = adapterService;
        _adapter = _adapterService.CurrentAdapter;

        _adapterService.AdapterStateChanged += (s, a) =>
        {
            Adapter = a;
        };
    }
}

