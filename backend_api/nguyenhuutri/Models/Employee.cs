using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace nguyenhuutri.Models
{
    public class Employee
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [ForeignKey("UserId")]
        [JsonIgnore]
        public virtual User? User { get; set; }

        [Required]
        [MaxLength(20)]
        public string EmployeeCode { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Department { get; set; } = string.Empty; // Phòng ban

        [Required]
        [MaxLength(100)]
        public string Position { get; set; } = string.Empty;   // Chức vụ

        public DateTime? DateOfBirth { get; set; }

        public DateTime HireDate { get; set; } = DateTime.Now;

        [Column(TypeName = "decimal(18,2)")]
        public decimal BasicSalary { get; set; } = 0; // Lương cơ bản

        [MaxLength(20)]
        public string Status { get; set; } = "Active"; // Active, Inactive

        // Danh sách chấm công của nhân viên
        public virtual ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();
    }
}
