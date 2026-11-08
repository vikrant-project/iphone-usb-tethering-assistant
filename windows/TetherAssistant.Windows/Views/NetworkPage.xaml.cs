using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml.Controls;
using TetherAssistant.Windows.ViewModels;

namespace TetherAssistant.Windows.Views;

public sealed partial class NetworkPage : Page
{
    public NetworkViewModel ViewModel { get; }

    public NetworkPage()
    {
        InitializeComponent();
        ViewModel = App.Services.GetRequiredService<NetworkViewModel>();
    }
}

