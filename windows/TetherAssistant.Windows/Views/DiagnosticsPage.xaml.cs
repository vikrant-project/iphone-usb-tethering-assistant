using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml.Controls;
using TetherAssistant.Windows.ViewModels;

namespace TetherAssistant.Windows.Views;

public sealed partial class DiagnosticsPage : Page
{
    public DiagnosticsViewModel ViewModel { get; }

    public DiagnosticsPage()
    {
        InitializeComponent();
        ViewModel = App.Services.GetRequiredService<DiagnosticsViewModel>();
    }
}

