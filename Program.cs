using System.IO;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var builder = WebApplication.CreateBuilder(args);

// Enable console logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

app.MapPost("/api/equipment", async (HttpContext ctx) =>
{
    try
    {
        Console.WriteLine("Received POST request");

        using var reader = new StreamReader(ctx.Request.Body);
        var json = await reader.ReadToEndAsync();
        Console.WriteLine($"JSON content: {json}");

        var connectionString = "Server=localhost;Database=equipmentTORO;User ID=sa;Password=Bur123!;TrustServerCertificate=true;";
        await using var conn = new SqlConnection(connectionString);
        await conn.OpenAsync();
        Console.WriteLine("Database connection opened");

        await using var cmd = new SqlCommand("dbo.InsertEquipmentFromJson", conn)
        {
            CommandType = System.Data.CommandType.StoredProcedure
        };
        cmd.Parameters.Add(new SqlParameter("@json", System.Data.SqlDbType.NVarChar, -1) { Value = json });

        await cmd.ExecuteNonQueryAsync();
        Console.WriteLine("Stored procedure executed");

        return Results.Ok(new { inserted = true });
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine("Error in API:");
        Console.Error.WriteLine(ex);
        return Results.Problem("Internal server error");
    }
});

app.Run("http://0.0.0.0:5050");

