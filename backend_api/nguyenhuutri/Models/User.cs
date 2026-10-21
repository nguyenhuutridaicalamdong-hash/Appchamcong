using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace nguyenhuutri.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [JsonIgnore]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        // Roles: "Admin", "Employee", "Customer"
        [Required]
        [MaxLength(20)]
        public string Role { get; set; } = "Employee";

        // Cho xác thực OTP 2FA
        [MaxLength(10)]
        public string? OtpCode { get; set; }

        public DateTime? OtpExpiryTime { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation property liên kết với thông tin nhân viên (nếu là nhân viên)
        public virtual Employee? Employee { get; set; }
    }
}
