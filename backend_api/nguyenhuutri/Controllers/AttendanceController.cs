using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using nguyenhuutri.Data;
using nguyenhuutri.DTOs;
using nguyenhuutri.Models;
using System.Security.Claims;

namespace nguyenhuutri.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AttendanceController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AttendanceController(AppDbContext context)
        {
            _context = context;
        }

        private int? GetCurrentEmployeeId()
        {
            var empClaim = User.FindFirst("EmployeeId")?.Value;
            if (int.TryParse(empClaim, out int empId))
            {
                return empId;
            }
            return null;
        }

        // 1. CHECK-IN (Chấm công vào)
        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] CheckInDto dto)
        {
            int? employeeId = dto.EmployeeId ?? GetCurrentEmployeeId();

            if (!employeeId.HasValue)
            {
                return BadRequest(new { message = "Không xác định được mã nhân viên để chấm công!" });
            }

            var today = DateTime.Today;

            // Kiểm tra xem hôm nay đã check-in chưa
            var existing = await _context.Attendances
                .FirstOrDefaultAsync(a => a.EmployeeId == employeeId.Value && a.Date == today);

            if (existing != null && existing.CheckInTime.HasValue)
            {
                return BadRequest(new { message = "Hôm nay bạn đã Check-in rồi!", checkInTime = existing.CheckInTime });
            }

            var now = DateTime.Now;
            // Quy định: Nếu sau 08:30 sáng tính là "Đi muộn"
            var lateThreshold = today.AddHours(8).AddMinutes(30);
            var status = now > lateThreshold ? "Đi muộn" : "Đúng giờ";

            if (existing == null)
            {
                existing = new Attendance
                {
                    EmployeeId = employeeId.Value,
                    Date = today,
                    CheckInTime = now,
                    Status = status,
                    Note = dto.Note
                };
                _context.Attendances.Add(existing);
            }
            else
            {
                existing.CheckInTime = now;
                existing.Status = status;
                if (!string.IsNullOrEmpty(dto.Note)) existing.Note = dto.Note;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = $"Check-in thành công ({status})!",
                attendanceId = existing.Id,
                checkInTime = existing.CheckInTime,
                status = existing.Status
            });
        }

        // 2. CHECK-OUT (Chấm công ra)
        [HttpPost("check-out")]
        public async Task<IActionResult> CheckOut([FromBody] CheckOutDto dto)
        {
            int? employeeId = dto.EmployeeId ?? GetCurrentEmployeeId();

            if (!employeeId.HasValue)
            {
                return BadRequest(new { message = "Không xác định được mã nhân viên để chấm công!" });
            }

            var today = DateTime.Today;

            var existing = await _context.Attendances
                .FirstOrDefaultAsync(a => a.EmployeeId == employeeId.Value && a.Date == today);

            if (existing == null || !existing.CheckInTime.HasValue)
            {
                return BadRequest(new { message = "Bạn chưa Check-in hôm nay, không thể Check-out!" });
            }

            var now = DateTime.Now;
            existing.CheckOutTime = now;

            // Tính số giờ làm việc
            var duration = now - existing.CheckInTime.Value;
            existing.WorkingHours = Math.Round(duration.TotalHours, 2);

            if (!string.IsNullOrEmpty(dto.Note))
            {
                existing.Note = string.IsNullOrEmpty(existing.Note) ? dto.Note : $"{existing.Note}; {dto.Note}";
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Check-out thành công!",
                checkInTime = existing.CheckInTime,
                checkOutTime = existing.CheckOutTime,
                workingHours = existing.WorkingHours
            });
        }

        // 3. TRẠNG THÁI HÔM NAY CỦA NHÂN VIÊN HIỆN TẠI
        [HttpGet("today")]
        public async Task<IActionResult> GetTodayStatus()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return BadRequest(new { message = "Tài khoản hiện tại không gắn với hồ sơ nhân viên!" });
            }

            var today = DateTime.Today;
            var record = await _context.Attendances
                .FirstOrDefaultAsync(a => a.EmployeeId == employeeId.Value && a.Date == today);

            return Ok(new
            {
                isCheckedIn = record != null && record.CheckInTime.HasValue,
                isCheckedOut = record != null && record.CheckOutTime.HasValue,
                checkInTime = record?.CheckInTime,
                checkOutTime = record?.CheckOutTime,
                status = record?.Status ?? "Chưa chấm công",
                workingHours = record?.WorkingHours ?? 0
            });
        }

        // 4. LỊCH SỬ CHẤM CÔNG CỦA NHÂN VIÊN ĐANG ĐĂNG NHẬP
        [HttpGet("my-history")]
        public async Task<IActionResult> GetMyHistory([FromQuery] int? month, [FromQuery] int? year)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return BadRequest(new { message = "Tài khoản hiện tại không gắn với hồ sơ nhân viên!" });
            }

            var query = _context.Attendances
                .Include(a => a.Employee)
                .ThenInclude(e => e!.User)
                .Where(a => a.EmployeeId == employeeId.Value)
                .AsQueryable();

            if (month.HasValue) query = query.Where(a => a.Date.Month == month.Value);
            if (year.HasValue) query = query.Where(a => a.Date.Year == year.Value);

            var list = await query
                .OrderByDescending(a => a.Date)
                .Select(a => new AttendanceResponseDto
                {
                    Id = a.Id,
                    EmployeeId = a.EmployeeId,
                    EmployeeName = a.Employee != null && a.Employee.User != null ? a.Employee.User.FullName : string.Empty,
                    EmployeeCode = a.Employee != null ? a.Employee.EmployeeCode : string.Empty,
                    Department = a.Employee != null ? a.Employee.Department : string.Empty,
                    Date = a.Date,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    Status = a.Status,
                    WorkingHours = a.WorkingHours,
                    Note = a.Note
                })
                .ToListAsync();

            return Ok(list);
        }

        // 5. ADMIN XEM TẤT CẢ CHẤM CÔNG (Có lọc theo ngày, nhân viên)
        [Authorize(Roles = "Admin")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAll([FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] int? employeeId)
        {
            var query = _context.Attendances
                .Include(a => a.Employee)
                .ThenInclude(e => e!.User)
                .AsQueryable();

            if (employeeId.HasValue) query = query.Where(a => a.EmployeeId == employeeId.Value);
            if (fromDate.HasValue) query = query.Where(a => a.Date >= fromDate.Value.Date);
            if (toDate.HasValue) query = query.Where(a => a.Date <= toDate.Value.Date);

            var list = await query
                .OrderByDescending(a => a.Date)
                .Select(a => new AttendanceResponseDto
                {
                    Id = a.Id,
                    EmployeeId = a.EmployeeId,
                    EmployeeName = a.Employee != null && a.Employee.User != null ? a.Employee.User.FullName : string.Empty,
                    EmployeeCode = a.Employee != null ? a.Employee.EmployeeCode : string.Empty,
                    Department = a.Employee != null ? a.Employee.Department : string.Empty,
                    Date = a.Date,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    Status = a.Status,
                    WorkingHours = a.WorkingHours,
                    Note = a.Note
                })
                .ToListAsync();

            return Ok(list);
        }

        // 6. ADMIN XEM BÁO CÁO THỐNG KÊ (4.5đ)
        [Authorize(Roles = "Admin")]
        [HttpGet("report")]
        public async Task<IActionResult> GetReport([FromQuery] int? month, [FromQuery] int? year)
        {
            int targetMonth = month ?? DateTime.Now.Month;
            int targetYear = year ?? DateTime.Now.Year;

            var attendances = await _context.Attendances
                .Include(a => a.Employee)
                .ThenInclude(e => e!.User)
                .Where(a => a.Date.Month == targetMonth && a.Date.Year == targetYear)
                .ToListAsync();

            var report = new AttendanceReportDto
            {
                TotalAttendances = attendances.Count,
                OnTimeCount = attendances.Count(a => a.Status == "Đúng giờ"),
                LateCount = attendances.Count(a => a.Status == "Đi muộn"),
                TotalWorkingHours = Math.Round(attendances.Sum(a => a.WorkingHours), 2),
                Details = attendances.Select(a => new AttendanceResponseDto
                {
                    Id = a.Id,
                    EmployeeId = a.EmployeeId,
                    EmployeeName = a.Employee?.User?.FullName ?? string.Empty,
                    EmployeeCode = a.Employee?.EmployeeCode ?? string.Empty,
                    Department = a.Employee?.Department ?? string.Empty,
                    Date = a.Date,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    Status = a.Status,
                    WorkingHours = a.WorkingHours,
                    Note = a.Note
                }).ToList()
            };

            return Ok(report);
        }

                // 8. RESET CHẤM CÔNG HÔM NAY (Cho phép nhân viên hoặc Admin đặt lại trạng thái để test demo)
        [HttpPost("reset-today")]
        public async Task<IActionResult> ResetToday([FromQuery] int? employeeId)
        {
            int? targetEmpId = employeeId ?? GetCurrentEmployeeId();
            if (!targetEmpId.HasValue)
            {
                return BadRequest(new { message = "Không xác định được nhân viên để đặt lại trạng thái!" });
            }

            var today = DateTime.Today;
            var records = await _context.Attendances
                .Where(a => a.EmployeeId == targetEmpId.Value && a.Date == today)
                .ToListAsync();

            if (records.Any())
            {
                _context.Attendances.RemoveRange(records);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Đã đặt lại trạng thái chấm công hôm nay thành công!" });
        }

        // 7. ADMIN XÓA BẢN GHI CHẤM CÔNG (CRUD: Delete)
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var record = await _context.Attendances.FindAsync(id);
            if (record == null)
            {
                return NotFound(new { message = "Không tìm thấy bản ghi chấm công!" });
            }

            _context.Attendances.Remove(record);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa bản ghi chấm công thành công!" });
        }
    }
}
