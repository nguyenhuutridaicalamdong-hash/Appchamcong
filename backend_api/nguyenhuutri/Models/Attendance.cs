using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace nguyenhuutri.Models
{
    public class Attendance
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        [JsonIgnore]
        public virtual Employee? Employee { get; set; }

        [Required]
        public DateTime Date { get; set; } = DateTime.Today;

        public DateTime? CheckInTime { get; set; }

        public DateTime? CheckOutTime { get; set; }

        // Trạng thái: "Đúng giờ", "Đi muộn", "Về sớm", "Vắng mặt"
        [MaxLength(50)]
        public string Status { get; set; } = "Chưa chấm công";

        public double WorkingHours { get; set; } = 0;

        [MaxLength(255)]
        public string? Note { get; set; }
    }
}
