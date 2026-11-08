using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using TetherAssistant.Windows.Views;

namespace TetherAssistant.Windows;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        ExtendsContentIntoTitleBar = true;
    }

    private void NavView_Loaded(object sender, RoutedEventArgs e)
    {
        NavView.SelectedItem = NavView.MenuItems[0];
        ContentFrame.Navigate(typeof(DashboardPage));
    }

    private void NavView_ItemInvoked(NavigationView sender, NavigationViewItemInvokedEventArgs args)
    {
        if (args.InvokedItemContainer is NavigationViewItem item)
        {
            switch (item.Tag?.ToString())
            {
                case "Dashboard":
                    ContentFrame.Navigate(typeof(DashboardPage));
                    break;
                case "Network":
                    ContentFrame.Navigate(typeof(NetworkPage));
                    break;
                case "Diagnostics":
                    ContentFrame.Navigate(typeof(DiagnosticsPage));
                    break;
                case "Settings":
                    ContentFrame.Navigate(typeof(SettingsPage));
                    break;
            }
        }
    }
}

