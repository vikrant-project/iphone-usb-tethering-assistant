using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public interface IDiagnosticsService
{
    Task<DiagnosticSuiteResult> RunFullDiagnosticsAsync(CancellationToken cancellationToken = default);
}

