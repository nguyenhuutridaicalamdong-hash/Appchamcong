using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using nguyenhuutri.Data;
using nguyenhuutri.DTOs;
using nguyenhuutri.Models;
using nguyenhuutri.Services;
using System.Security.Claims;

namespace nguyenhuutri.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IJwtService _jwtService;
        private readonly IEmailService _emailService;

        public AuthController(AppDbContext context, IJwtService jwtService, IEmailService emailService)
        {
            _context = context;
            _jwtService = jwtService;
            _emailService = emailService;
        }

        // 1. ĐĂNG KÝ TÀI KHOẢN QUA EMAIL (Yêu cầu chính)
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            if (await _context.Users.AnyAsync(u => u.Username.ToLower() == dto.Username.ToLower()))
            {
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại trên hệ thống!" });
            }

            if (await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower()))
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            var passwordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password);
            var role = string.IsNullOrEmpty(dto.Role) ? "Employee" : dto.Role;

            var user = new User
            {
                Username = dto.Username.Trim(),
                Email = dto.Email.Trim().ToLower(),
                PasswordHash = passwordHash,
                FullName = dto.FullName.Trim(),
                PhoneNumber = dto.PhoneNumber,
                Role = role,
                CreatedAt = DateTime.Now
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            int? employeeId = null;
            if (role == "Employee")
            {
                var count = await _context.Employees.CountAsync() + 1;
                var emp = new Employee
                {
                    UserId = user.Id,
                    EmployeeCode = $"NV{count:D4}",
                    Department = string.IsNullOrEmpty(dto.Department) ? "Chung" : dto.Department,
                    Position = string.IsNullOrEmpty(dto.Position) ? "Nhân viên" : dto.Position,
                    HireDate = DateTime.Now,
                    BasicSalary = 5000000,
                    Status = "Active"
                };
                _context.Employees.Add(emp);
                await _context.SaveChangesAsync();
                employeeId = emp.Id;
            }

            return Ok(new
            {
                message = "Đăng ký tài khoản thành công!",
                userId = user.Id,
                username = user.Username,
                email = user.Email,
                role = user.Role,
                employeeId
            });
        }

        // 2. ĐĂNG NHẬP: BƯỚC 1 (Username + Mật khẩu -> Tạo OTP và gửi qua Email)
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var user = await _context.Users
                .Include(u => u.Employee)
                .FirstOrDefaultAsync(u => u.Username.ToLower() == dto.Username.ToLower() || u.Email.ToLower() == dto.Username.ToLower());

            if (user == null)
            {
                return Unauthorized(new { message = "Tên đăng nhập hoặc mật khẩu không chính xác!" });
            }

            bool isPasswordValid = BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash);
            if (!isPasswordValid)
            {
                return Unauthorized(new { message = "Tên đăng nhập hoặc mật khẩu không chính xác!" });
            }

            // Sinh mã OTP ngẫu nhiên 6 chữ số
            var otpCode = new Random().Next(100000, 999999).ToString();
            user.OtpCode = otpCode;
            user.OtpExpiryTime = DateTime.UtcNow.AddMinutes(5);

            await _context.SaveChangesAsync();

            // Gửi OTP qua email (MailKit)
            await _emailService.SendOtpEmailAsync(user.Email, user.FullName, otpCode);

            return Ok(new
            {
                message = "Thông tin đăng nhập hợp lệ. Vui lòng nhập mã OTP đã gửi về email của bạn.",
                requireOtp = true,
                username = user.Username,
                email = user.Email,
                demoOtp = otpCode
            });
        }

        // 2. ĐĂNG NHẬP: BƯỚC 2 (Xác thực OTP -> Cấp JWT Token)
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            var user = await _context.Users
                .Include(u => u.Employee)
                .FirstOrDefaultAsync(u => u.Username.ToLower() == dto.Username.ToLower());

            if (user == null)
            {
                return BadRequest(new { message = "Không tìm thấy người dùng!" });
            }

            if (string.IsNullOrEmpty(user.OtpCode) || user.OtpCode != dto.OtpCode.Trim())
            {
                return BadRequest(new { message = "Mã OTP không chính xác!" });
            }

            if (user.OtpExpiryTime == null || user.OtpExpiryTime < DateTime.UtcNow)
            {
                return BadRequest(new { message = "Mã OTP đã hết hạn! Vui lòng đăng nhập lại." });
            }

            user.OtpCode = null;
            user.OtpExpiryTime = null;
            await _context.SaveChangesAsync();

            int? employeeId = user.Employee?.Id;
            var token = _jwtService.GenerateToken(user, employeeId);

            return Ok(new AuthResponseDto
            {
                Token = token,
                UserId = user.Id,
                Username = user.Username,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role,
                EmployeeId = employeeId
            });
        }

        // 3. ĐĂNG NHẬP / ĐĂNG KÝ BẰNG GOOGLE (Tính năng phụ trợ OAuth2)
        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginDto dto)
        {
            var email = dto.Email.Trim().ToLower();
            var user = await _context.Users
                .Include(u => u.Employee)
                .FirstOrDefaultAsync(u => u.Email.ToLower() == email);

            if (user == null)
            {
                // Tự động khởi tạo tài khoản nếu lần đầu đăng nhập Google
                var baseUsername = email.Split('@')[0];
                var username = baseUsername;
                if (await _context.Users.AnyAsync(u => u.Username.ToLower() == username.ToLower()))
                {
                    username = $"{baseUsername}_{new Random().Next(100, 999)}";
                }

                user = new User
                {
                    Username = username,
                    Email = email,
                    FullName = dto.FullName.Trim(),
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()),
                    Role = "Employee",
                    CreatedAt = DateTime.Now
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var count = await _context.Employees.CountAsync() + 1;
                var emp = new Employee
                {
                    UserId = user.Id,
                    EmployeeCode = $"NV{count:D4}",
                    Department = "Phòng Kỹ Thuật",
                    Position = "Nhân viên (Google Auth)",
                    HireDate = DateTime.Now,
                    BasicSalary = 6000000,
                    Status = "Active"
                };
                _context.Employees.Add(emp);
                await _context.SaveChangesAsync();

                user.Employee = emp;
            }

            int? employeeId = user.Employee?.Id;
            var token = _jwtService.GenerateToken(user, employeeId);

            return Ok(new AuthResponseDto
            {
                Token = token,
                UserId = user.Id,
                Username = user.Username,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role,
                EmployeeId = employeeId
            });
        }

        // 4. LẤY THÔNG TIN TÀI KHOẢN ĐANG ĐĂNG NHẬP
        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized();
            }

            var user = await _context.Users
                .Include(u => u.Employee)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null) return NotFound();

            return Ok(new
            {
                user.Id,
                user.Username,
                user.Email,
                user.FullName,
                user.PhoneNumber,
                user.Role,
                EmployeeId = user.Employee?.Id,
                EmployeeCode = user.Employee?.EmployeeCode,
                Department = user.Employee?.Department,
                Position = user.Employee?.Position
            });
        }
    }
}
