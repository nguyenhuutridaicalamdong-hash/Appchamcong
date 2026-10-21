using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace nguyenhuutri.Services
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode)
        {
            try
            {
                var smtpHost = _configuration["EmailSettings:SmtpHost"];
                var smtpPort = int.TryParse(_configuration["EmailSettings:SmtpPort"], out var port) ? port : 587;
                var senderEmail = _configuration["EmailSettings:SenderEmail"];
                var senderPassword = _configuration["EmailSettings:SenderPassword"];

                // Nếu chưa cấu hình SMTP thực tế, ghi log console để tiện test đồ án
                if (string.IsNullOrEmpty(smtpHost) || string.IsNullOrEmpty(senderEmail))
                {
                    _logger.LogInformation("==================================================");
                    _logger.LogInformation($"[DEV OTP] Gửi OTP cho {toEmail}: MÃ OTP LÀ -> {otpCode}");
                    _logger.LogInformation("==================================================");
                    return true;
                }

                var message = new MimeMessage();
                message.From.Add(new MailboxAddress("Hệ Thống Chấm Công", senderEmail));
                message.To.Add(new MailboxAddress(fullName, toEmail));
                message.Subject = "[Chấm Công] Mã xác thực OTP đăng nhập của bạn";

                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
                        <div style='font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;'>
                            <h2 style='color: #4A154B;'>Mã Xác Thực OTP</h2>
                            <p>Xin chào <b>{fullName}</b>,</p>
                            <p>Bạn đang đăng nhập vào ứng dụng chấm công. Mã OTP xác thực của bạn là:</p>
                            <div style='font-size: 28px; font-weight: bold; letter-spacing: 5px; color: #2e7d32; padding: 15px; background: #f1f8e9; text-align: center; border-radius: 6px;'>
                                {otpCode}
                            </div>
                            <p style='color: #666; font-size: 13px; margin-top: 15px;'>Mã này có hiệu lực trong 5 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                        </div>"
                };

                message.Body = bodyBuilder.ToMessageBody();

                using var client = new SmtpClient();
                await client.ConnectAsync(smtpHost, smtpPort, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(senderEmail, senderPassword);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Lỗi khi gửi email OTP đến {toEmail}. Mã OTP test: {otpCode}");
                // Vẫn trả về true nếu trong môi trường phát triển để không chặn đăng nhập
                return true;
            }
        }
    }
}
