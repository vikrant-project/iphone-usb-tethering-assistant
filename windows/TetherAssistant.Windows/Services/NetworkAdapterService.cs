using System;
using System.Linq;
using System.Management;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public class NetworkAdapterService : INetworkAdapterService
{
    private const string AppleTetheringGateway = "172.20.10.1";
    private const string AppleSubnetMask = "255.255.255.240";
    private ManagementEventWatcher? _pnpWatcher;

    public event EventHandler<AdapterInfo?>? AdapterStateChanged;
    public AdapterInfo? CurrentAdapter { get; private set; }

    public Task<AdapterInfo?> ScanForAdapterAsync(CancellationToken cancellationToken = default)
    {
        var interfaces = NetworkInterface.GetAllNetworkInterfaces();

        foreach (var nic in interfaces)
        {
            if (nic.OperationalStatus != OperationalStatus.Up) continue;
            if (nic.NetworkInterfaceType != NetworkInterfaceType.Ethernet) continue;

            var ipProps = nic.GetIPProperties();
            var gateway = ipProps.GatewayAddresses
                .FirstOrDefault(g => g.Address.ToString() == AppleTetheringGateway);

            if (gateway == null) continue;

            var unicast = ipProps.UnicastAddresses
                .FirstOrDefault(u => u.IPv4Mask != null && u.IPv4Mask.ToString() == AppleSubnetMask);

            if (unicast == null) continue;

            bool isAppleUsb = VerifyAppleUsbHardwarePresent();

            var adapter = new AdapterInfo
            {
                Id = nic.Id,
                Name = nic.Name,
                Description = nic.Description,
                Status = nic.OperationalStatus,
                IpAddress = unicast.Address,
                SubnetMask = unicast.IPv4Mask,
                GatewayAddress = gateway.Address,
                DnsServer = ipProps.DnsAddresses.FirstOrDefault(),
                SpeedBitsPerSecond = nic.Speed,
                IsAppleTethering = isAppleUsb,
                DetectedAtUtc = DateTime.UtcNow
            };

            CurrentAdapter = adapter;
            return Task.FromResult<AdapterInfo?>(adapter);
        }

        CurrentAdapter = null;
        return Task.FromResult<AdapterInfo?>(null);
    }

    public void StartListening()
    {
        NetworkChange.NetworkAddressChanged += OnNetworkChanged;
        NetworkChange.NetworkAvailabilityChanged += OnNetworkChanged;

        try
        {
            var query = new WqlEventQuery(
                "SELECT * FROM __InstanceOperationEvent WITHIN 2 " +
                "WHERE TargetInstance ISA 'Win32_PnPEntity' AND TargetInstance.DeviceID LIKE '%VID_05AC%'");

            _pnpWatcher = new ManagementEventWatcher(query);
            _pnpWatcher.EventArrived += (s, e) => OnNetworkChanged(s, EventArgs.Empty);
            _pnpWatcher.Start();
        }
        catch
        {
            // Fallback: network change hooks are sufficient
        }

        _ = ScanForAdapterAsync();
    }

    public void StopListening()
    {
        NetworkChange.NetworkAddressChanged -= OnNetworkChanged;
        NetworkChange.NetworkAvailabilityChanged -= OnNetworkChanged;

        if (_pnpWatcher != null)
        {
            _pnpWatcher.Stop();
            _pnpWatcher.Dispose();
            _pnpWatcher = null;
        }
    }

    private async void OnNetworkChanged(object? sender, EventArgs e)
    {
        var prevId = CurrentAdapter?.Id;
        var newAdapter = await ScanForAdapterAsync();

        if (newAdapter?.Id != prevId)
        {
            AdapterStateChanged?.Invoke(this, newAdapter);
        }
    }

    private static bool VerifyAppleUsbHardwarePresent()
    {
        try
        {
            using var searcher = new ManagementObjectSearcher(
                "SELECT DeviceID FROM Win32_PnPEntity WHERE DeviceID LIKE '%VID_05AC%'");
            using var collection = searcher.Get();
            return collection.Count > 0;
        }
        catch
        {
            return true; // Fallback to gateway heuristic
        }
    }
}

