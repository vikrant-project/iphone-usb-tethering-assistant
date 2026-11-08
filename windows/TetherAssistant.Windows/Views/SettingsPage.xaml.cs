using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml.Controls;
using TetherAssistant.Windows.ViewModels;

namespace TetherAssistant.Windows.Views;

public sealed partial class SettingsPage : Page
{
    public SettingsViewModel ViewModel { get; }

    public SettingsPage()
    {
        InitializeComponent();
        ViewModel = App.Services.GetRequiredService<SettingsViewModel>();
    }
}

