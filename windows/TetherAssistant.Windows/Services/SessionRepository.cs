using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Data.Sqlite;

namespace TetherAssistant.Windows.Services;

public class SessionRepository : ISessionRepository
{
    private readonly string _connectionString;

    public SessionRepository()
    {
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(localAppData, "TetherAssistant");
        Directory.CreateDirectory(folder);
        string dbPath = Path.Combine(folder, "tether_sessions.db");
        _connectionString = $"Data Source={dbPath};";

        InitializeDatabase();
    }

    private void InitializeDatabase()
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        using var walCmd = connection.CreateCommand();
        walCmd.CommandText = "PRAGMA journal_mode = WAL;";
        walCmd.ExecuteNonQuery();

        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                start_time TEXT NOT NULL,
                end_time TEXT,
                bytes_received INTEGER NOT NULL,
                bytes_sent INTEGER NOT NULL,
                peak_speed REAL NOT NULL,
                adapter_name TEXT NOT NULL
            );";
        cmd.ExecuteNonQuery();
    }

    public async Task SaveSessionAsync(SessionRecord record)
    {
        await using var connection = new SqliteConnection(_connectionString);
        await connection.OpenAsync();

        await using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            INSERT OR REPLACE INTO sessions (id, start_time, end_time, bytes_received, bytes_sent, peak_speed, adapter_name)
            VALUES ($id, $start, $end, $rx, $tx, $peak, $name);";
        cmd.Parameters.AddWithValue("$id", record.Id.ToString());
        cmd.Parameters.AddWithValue("$start", record.StartTimeUtc.ToString("o"));
        cmd.Parameters.AddWithValue("$end", record.EndTimeUtc?.ToString("o") ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("$rx", record.BytesReceived);
        cmd.Parameters.AddWithValue("$tx", record.BytesSent);
        cmd.Parameters.AddWithValue("$peak", record.PeakDownloadSpeedMbps);
        cmd.Parameters.AddWithValue("$name", record.AdapterName);

        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<IReadOnlyList<SessionRecord>> GetRecentSessionsAsync(int limit = 50)
    {
        var list = new List<SessionRecord>();
        await using var connection = new SqliteConnection(_connectionString);
        await connection.OpenAsync();

        await using var cmd = connection.CreateCommand();
        cmd.CommandText = @"SELECT id, start_time, end_time, bytes_received, bytes_sent, peak_speed, adapter_name 
                            FROM sessions ORDER BY start_time DESC LIMIT $limit;";
        cmd.Parameters.AddWithValue("$limit", limit);

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var id = Guid.Parse(reader.GetString(0));
            var start = DateTime.Parse(reader.GetString(1));
            DateTime? end = reader.IsDBNull(2) ? null : DateTime.Parse(reader.GetString(2));
            long rx = reader.GetInt64(3);
            long tx = reader.GetInt64(4);
            double peak = reader.GetDouble(5);
            string name = reader.GetString(6);

            list.Add(new SessionRecord(id, start, end, rx, tx, peak, name));
        }

        return list;
    }

    public async Task ClearHistoryAsync()
    {
        await using var connection = new SqliteConnection(_connectionString);
        await connection.OpenAsync();

        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "DELETE FROM sessions; VACUUM;";
        await cmd.ExecuteNonQueryAsync();
    }
}

