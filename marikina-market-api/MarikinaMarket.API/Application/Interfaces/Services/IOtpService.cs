using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.Interfaces.Services
{
    public interface IOtpService
    {
        Task<string> GenerateOtpAsync(int userId, OtpPurpose purpose, int expiryMinutes = 10);
        Task<(string Code, OtpVerification Otp)> GenerateOtpWithRecordAsync(int userId, OtpPurpose purpose, int expiryMinutes = 10);
        Task InvalidateOtpAsync(int otpId);
        Task<OtpVerificationResult> ValidateOtpAsync(int userId, OtpPurpose purpose, string code);
        Task<OtpVerification?> GetLatestOtpAsync(int userId, OtpPurpose purpose);
    }
}
