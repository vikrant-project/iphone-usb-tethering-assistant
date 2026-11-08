using System;
using System.Collections.Generic;

namespace TetherAssistant.Windows.Models;

public enum DiagnosticStage
{
    DriverAndPhysicalLink,
    GatewayReachability,
    DnsResolution,
    InternetWanReachability
}

public enum DiagnosticSeverity
{
    Pass,
    Warning,
    Failure
}

public sealed record DiagnosticStageResult
{
    public required DiagnosticStage Stage { get; init; }
    public required string StageName { get; init; }
    public required DiagnosticSeverity Severity { get; init; }
    public required double LatencyMilliseconds { get; init; }
    public required string? Details { get; init; }
    public required string? TroubleshootingAdvice { get; init; }
}

public sealed record DiagnosticSuiteResult
{
    public required DateTime TimestampUtc { get; init; }
    public required bool IsHealthy { get; init; }
    public required IReadOnlyList<DiagnosticStageResult> Stages { get; init; }
    public required string OverallSummary { get; init; }
}

