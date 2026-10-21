using System.ComponentModel.DataAnnotations;

namespace nguyenhuutri.DTOs
{
    public class CreateEmployeeDto
    {
        // Thông tin tài khoản đăng nhập
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }

        // Thông tin nhân viên
        [Required]
        public string EmployeeCode { get; set; } = string.Empty;

        [Required]
        public string Department { get; set; } = string.Empty;

        [Required]
        public string Position { get; set; } = string.Empty;

        public DateTime? DateOfBirth { get; set; }

        public DateTime HireDate { get; set; } = DateTime.Now;

        public decimal BasicSalary { get; set; } = 0;

        public string Status { get; set; } = "Active";
    }

    public class UpdateEmployeeDto
    {
        [Required]
        public string FullName { get; set; } = string.Empty;

        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }

        [Required]
        public string Department { get; set; } = string.Empty;

        [Required]
        public string Position { get; set; } = string.Empty;

        public DateTime? DateOfBirth { get; set; }

        public decimal BasicSalary { get; set; }

        public string Status { get; set; } = "Active";
    }

    public class EmployeeResponseDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string Role { get; set; } = string.Empty;

        public string EmployeeCode { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public string Position { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public DateTime HireDate { get; set; }
        public decimal BasicSalary { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
