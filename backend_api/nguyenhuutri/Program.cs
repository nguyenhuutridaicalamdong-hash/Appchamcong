using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using nguyenhuutri.Data;
using nguyenhuutri.Models;
using nguyenhuutri.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình DbContext kết nối SQL Server (Database: nguyenhuutri)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Đăng ký các dịch vụ Custom Services (JWT, Email OTP)
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IEmailService, EmailService>();

// 3. Cấu hình CORS để Flutter App gọi API không bị chặn
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 4. Cấu hình Xác thực JWT Bearer
var jwtKey = builder.Configuration["Jwt:Key"] ?? "nguyenhuutriAttendanceAppSuperSecretKey2026!@#$%^&*nguyenhuutri";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "nguyenhuutri";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "nguyenhuutriAppClient";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// 5. Cấu hình Swagger hỗ trợ nút "Authorize" nhập Bearer Token (Tên API: nguyenhuutri)
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "nguyenhuutri Web API - Hệ Thống Chấm Công Nhân Viên",
        Version = "v1",
        Description = "API Quản lý chấm công nhân viên sinh viên Nguyễn Hữu Trí - Phân quyền Admin, Nhân viên, Khách hàng với 2FA OTP & CRUD"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập token JWT theo định dạng: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// 6. Tự động khởi tạo cơ sở dữ liệu nguyenhuutri và dữ liệu mẫu (Seed Admin)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<AppDbContext>();
        // Tự động tạo cơ sở dữ liệu 'nguyenhuutri' nếu chưa có trong SQL Server
        context.Database.EnsureCreated();

        // Khởi tạo tài khoản Quản trị viên (Admin)
        if (!context.Users.Any(u => u.Role == "Admin"))
        {
            var adminUser = new User
            {
                Username = "admin",
                Email = "admin@nguyenhuutri.com",
                FullName = "Nguyễn Hữu Trí (Admin)",
                PhoneNumber = "0988888888",
                Role = "Admin",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"),
                CreatedAt = DateTime.Now
            };
            context.Users.Add(adminUser);
            context.SaveChanges();
        }

        // Khởi tạo tài khoản Nhân viên mẫu để test
        if (!context.Users.Any(u => u.Role == "Employee"))
        {
            var empUser = new User
            {
                Username = "nhanvien1",
                Email = "nhanvien1@nguyenhuutri.com",
                FullName = "Nhân Viên Mẫu 1",
                PhoneNumber = "0912345678",
                Role = "Employee",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
                CreatedAt = DateTime.Now
            };
            context.Users.Add(empUser);
            context.SaveChanges();

            var empProfile = new Employee
            {
                UserId = empUser.Id,
                EmployeeCode = "NV0001",
                Department = "Phòng Kỹ Thuật",
                Position = "Lập trình viên",
                HireDate = DateTime.Now,
                BasicSalary = 12000000,
                Status = "Active"
            };
            context.Employees.Add(empProfile);
            context.SaveChanges();
        }
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Lỗi xảy ra khi khởi tạo cơ sở dữ liệu nguyenhuutri.");
    }
}

// Cấu hình HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "nguyenhuutri API v1");
    });
}

// Bật CORS cho Flutter gọi API
app.UseCors("AllowAll");

// app.UseHttpsRedirection(); // Tắt HTTPS redirect để Android Emulator kết nối HTTP 10.0.2.2:5184 không bị lỗi

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
