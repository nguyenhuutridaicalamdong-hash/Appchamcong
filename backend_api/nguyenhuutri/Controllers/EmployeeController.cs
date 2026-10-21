using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using nguyenhuutri.Data;
using nguyenhuutri.DTOs;
using nguyenhuutri.Models;

namespace nguyenhuutri.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Yêu cầu đăng nhập, Admin toàn quyền, Nhân viên có thể xem
    public class EmployeeController : ControllerBase
    {
        private readonly AppDbContext _context;

        public EmployeeController(AppDbContext context)
        {
            _context = context;
        }

        // 1. GET: Lấy danh sách nhân viên (CRUD: Read All + Tìm kiếm)
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] string? department)
        {
            var query = _context.Employees
                .Include(e => e.User)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                query = query.Where(e => 
                    (e.User != null && e.User.FullName.ToLower().Contains(term)) ||
                    e.EmployeeCode.ToLower().Contains(term) ||
                    (e.User != null && e.User.Email.ToLower().Contains(term)));
            }

            if (!string.IsNullOrWhiteSpace(department))
            {
                query = query.Where(e => e.Department.ToLower() == department.Trim().ToLower());
            }

            var list = await query
                .OrderByDescending(e => e.Id)
                .Select(e => new EmployeeResponseDto
                {
                    Id = e.Id,
                    UserId = e.UserId,
                    Username = e.User != null ? e.User.Username : string.Empty,
                    Email = e.User != null ? e.User.Email : string.Empty,
                    FullName = e.User != null ? e.User.FullName : string.Empty,
                    PhoneNumber = e.User != null ? e.User.PhoneNumber : null,
                    Role = e.User != null ? e.User.Role : "Employee",
                    EmployeeCode = e.EmployeeCode,
                    Department = e.Department,
                    Position = e.Position,
                    DateOfBirth = e.DateOfBirth,
                    HireDate = e.HireDate,
                    BasicSalary = e.BasicSalary,
                    Status = e.Status
                })
                .ToListAsync();

            return Ok(list);
        }

        // 2. GET: Lấy chi tiết nhân viên theo ID (CRUD: Read Detail)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var e = await _context.Employees
                .Include(emp => emp.User)
                .FirstOrDefaultAsync(emp => emp.Id == id);

            if (e == null)
            {
                return NotFound(new { message = $"Không tìm thấy nhân viên với ID = {id}" });
            }

            var result = new EmployeeResponseDto
            {
                Id = e.Id,
                UserId = e.UserId,
                Username = e.User != null ? e.User.Username : string.Empty,
                Email = e.User != null ? e.User.Email : string.Empty,
                FullName = e.User != null ? e.User.FullName : string.Empty,
                PhoneNumber = e.User != null ? e.User.PhoneNumber : null,
                Role = e.User != null ? e.User.Role : "Employee",
                EmployeeCode = e.EmployeeCode,
                Department = e.Department,
                Position = e.Position,
                DateOfBirth = e.DateOfBirth,
                HireDate = e.HireDate,
                BasicSalary = e.BasicSalary,
                Status = e.Status
            };

            return Ok(result);
        }

        // 3. POST: Thêm mới nhân viên (CRUD: Create - Dành cho Admin)
        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateEmployeeDto dto)
        {
            if (await _context.Users.AnyAsync(u => u.Username.ToLower() == dto.Username.ToLower()))
            {
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại!" });
            }

            if (await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower()))
            {
                return BadRequest(new { message = "Email đã tồn tại!" });
            }

            if (await _context.Employees.AnyAsync(e => e.EmployeeCode.ToLower() == dto.EmployeeCode.ToLower()))
            {
                return BadRequest(new { message = "Mã nhân viên đã tồn tại!" });
            }

            // Tạo tài khoản User
            var user = new User
            {
                Username = dto.Username.Trim(),
                Email = dto.Email.Trim().ToLower(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                FullName = dto.FullName.Trim(),
                PhoneNumber = dto.PhoneNumber,
                Role = "Employee",
                CreatedAt = DateTime.Now
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            // Tạo hồ sơ Employee
            var employee = new Employee
            {
                UserId = user.Id,
                EmployeeCode = dto.EmployeeCode.Trim().ToUpper(),
                Department = dto.Department.Trim(),
                Position = dto.Position.Trim(),
                DateOfBirth = dto.DateOfBirth,
                HireDate = dto.HireDate,
                BasicSalary = dto.BasicSalary,
                Status = string.IsNullOrEmpty(dto.Status) ? "Active" : dto.Status
            };

            _context.Employees.Add(employee);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = employee.Id }, new EmployeeResponseDto
            {
                Id = employee.Id,
                UserId = user.Id,
                Username = user.Username,
                Email = user.Email,
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber,
                Role = user.Role,
                EmployeeCode = employee.EmployeeCode,
                Department = employee.Department,
                Position = employee.Position,
                DateOfBirth = employee.DateOfBirth,
                HireDate = employee.HireDate,
                BasicSalary = employee.BasicSalary,
                Status = employee.Status
            });
        }

        // 4. PUT: Cập nhật thông tin nhân viên (CRUD: Update - Dành cho Admin)
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateEmployeeDto dto)
        {
            var employee = await _context.Employees
                .Include(e => e.User)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (employee == null)
            {
                return NotFound(new { message = "Không tìm thấy nhân viên cần cập nhật!" });
            }

            // Cập nhật thông tin User
            if (employee.User != null)
            {
                employee.User.FullName = dto.FullName.Trim();
                employee.User.PhoneNumber = dto.PhoneNumber;

                if (!string.IsNullOrEmpty(dto.Email) && dto.Email.ToLower() != employee.User.Email.ToLower())
                {
                    if (await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower() && u.Id != employee.UserId))
                    {
                        return BadRequest(new { message = "Email mới đã được tài khoản khác sử dụng!" });
                    }
                    employee.User.Email = dto.Email.Trim().ToLower();
                }
            }

            // Cập nhật thông tin Employee
            employee.Department = dto.Department.Trim();
            employee.Position = dto.Position.Trim();
            employee.DateOfBirth = dto.DateOfBirth;
            employee.BasicSalary = dto.BasicSalary;
            employee.Status = dto.Status;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật thông tin nhân viên thành công!" });
        }

        // 5. DELETE: Xóa nhân viên (CRUD: Delete - Dành cho Admin)
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var employee = await _context.Employees
                .Include(e => e.User)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (employee == null)
            {
                return NotFound(new { message = "Không tìm thấy nhân viên cần xóa!" });
            }

            // Xóa User sẽ tự động xóa Employee và Attendances liên quan nhờ Cascade delete
            if (employee.User != null)
            {
                _context.Users.Remove(employee.User);
            }
            else
            {
                _context.Employees.Remove(employee);
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = $"Đã xóa thành công nhân viên mã {employee.EmployeeCode}!" });
        }
    }
}
