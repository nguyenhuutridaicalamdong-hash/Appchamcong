using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using nguyenhuutri.Models;

namespace nguyenhuutri.Services
{
    public interface IJwtService
    {
        string GenerateToken(User user, int? employeeId = null);
    }

    public class JwtService : IJwtService
    {
        private readonly IConfiguration _configuration;

        public JwtService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string GenerateToken(User user, int? employeeId = null)
        {
            var jwtKey = _configuration["Jwt:Key"] ?? "NguyenHuuTriAttendanceAppSuperSecretKey2026!@#$%^&*";
            var issuer = _configuration["Jwt:Issuer"] ?? "AttendanceAPI";
            var audience = _configuration["Jwt:Audience"] ?? "AttendanceAppClient";

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role),
                new Claim("FullName", user.FullName)
            };

            if (employeeId.HasValue)
            {
                claims.Add(new Claim("EmployeeId", employeeId.Value.ToString()));
            }

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddDays(7),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
