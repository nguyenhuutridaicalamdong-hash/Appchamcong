using System.ComponentModel.DataAnnotations;

namespace nguyenhuutri.DTOs
{
    public class CheckInDto
    {
        public int? EmployeeId { get; set; } // Nếu không truyền sẽ lấy từ token của nhân viên hiện tại
        public string? Note { get; set; }
    }

    public class CheckOutDto
    {
        public int? EmployeeId { get; set; } // Nếu không truyền sẽ lấy từ token
        public string? Note { get; set; }
    }

    public class AttendanceResponseDto
    {
        public int Id { get; set; }
        public int EmployeeId { get; set; }
        public string EmployeeName { get; set; } = string.Empty;
        public string EmployeeCode { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public DateTime? CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public string Status { get; set; } = string.Empty;
        public double WorkingHours { get; set; }
        public string? Note { get; set; }
    }

    public class AttendanceReportDto
    {
        public int TotalAttendances { get; set; }
        public int OnTimeCount { get; set; }
        public int LateCount { get; set; }
        public double TotalWorkingHours { get; set; }
        public List<AttendanceResponseDto> Details { get; set; } = new List<AttendanceResponseDto>();
    }
}
