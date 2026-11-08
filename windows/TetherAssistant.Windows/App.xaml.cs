using System;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.UI.Xaml;
using TetherAssistant.Windows.Services;
using TetherAssistant.Windows.ViewModels;

namespace TetherAssistant.Windows;

public partial class App : Application
{
    public static IServiceProvider Services { get; private set; } = null!;
    private Window? _window;

    public App()
    {
        InitializeComponent();
        Services = ConfigureServices();
    }

    private static IServiceProvider ConfigureServices()
    {
        var services = new ServiceCollection();

        // Infrastructure Services
        services.AddSingleton<INetworkAdapterService, NetworkAdapterService>();
        services.AddSingleton<ITelemetryService, TelemetryService>();
        services.AddSingleton<IDiagnosticsService, DiagnosticsService>();
        services.AddSingleton<ISessionRepository, SessionRepository>();

        // ViewModels
        services.AddTransient<DashboardViewModel>();
        services.AddTransient<NetworkViewModel>();
        services.AddTransient<DiagnosticsViewModel>();
        services.AddTransient<SettingsViewModel>();

        return services.BuildServiceProvider();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _window = new MainWindow();
        _window.Activate();

        var adapterService = Services.GetRequiredService<INetworkAdapterService>();
        adapterService.StartListening();
    }
}

