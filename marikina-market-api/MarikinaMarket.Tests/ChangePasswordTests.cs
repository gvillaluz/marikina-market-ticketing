using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Auth.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Xunit;

namespace MarikinaMarket.Tests;

public class ChangePasswordTests
{
    private const string RuleMessage = "Use at least 8 characters, with a number and a capital letter.";

    [Fact]
    public async Task Forced_change_is_refused_when_the_account_does_not_need_one()
    {
        var calls = new List<string>();
        var user = CreateUser(mustChangePassword: false);
        var service = CreateService(calls, user, IdentityResult.Success, IdentityResult.Success);

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            service.MandatoryChangePasswordAsync(Request("Abcdefg1"), user.Id));

        Assert.Equal("Your password does not need to be changed.", error.Message);
        Assert.DoesNotContain("ChangePasswordAsync", calls);
        Assert.DoesNotContain("UpdateUserAsync", calls);
        Assert.DoesNotContain("CommitAsync", calls);
    }

    [Fact]
    public async Task Forced_change_keeps_the_flag_when_the_password_is_rejected()
    {
        var calls = new List<string>();
        var user = CreateUser(mustChangePassword: true);
        var rejected = IdentityResult.Failed(new IdentityError { Code = "PasswordMismatch", Description = "Incorrect password." });
        var service = CreateService(calls, user, rejected, IdentityResult.Success);

        var result = await service.MandatoryChangePasswordAsync(Request("Abcdefg1"), user.Id);

        Assert.False(result.Succeeded);
        Assert.True(user.MustChangePassword);
        Assert.Equal(["BeginTransactionAsync", "GetUserAsync", "ChangePasswordAsync", "RollbackAsync"], calls);
    }

    [Fact]
    public async Task Forced_change_is_undone_when_clearing_the_flag_fails()
    {
        var calls = new List<string>();
        var user = CreateUser(mustChangePassword: true);
        var saveFailed = IdentityResult.Failed(new IdentityError { Code = "ConcurrencyFailure", Description = "Optimistic concurrency failure, object has been modified." });
        var service = CreateService(calls, user, IdentityResult.Success, saveFailed);

        var result = await service.MandatoryChangePasswordAsync(Request("Abcdefg1"), user.Id);

        Assert.False(result.Succeeded);
        Assert.Equal(["BeginTransactionAsync", "GetUserAsync", "ChangePasswordAsync", "UpdateUserAsync:False", "RollbackAsync"], calls);
    }

    [Fact]
    public async Task Forced_change_saves_the_password_and_clears_the_flag_together()
    {
        var calls = new List<string>();
        var user = CreateUser(mustChangePassword: true);
        var service = CreateService(calls, user, IdentityResult.Success, IdentityResult.Success);

        var result = await service.MandatoryChangePasswordAsync(Request("Abcdefg1"), user.Id);

        Assert.True(result.Succeeded);
        Assert.False(user.MustChangePassword);
        Assert.Equal(["BeginTransactionAsync", "GetUserAsync", "ChangePasswordAsync", "UpdateUserAsync:False", "CommitAsync"], calls);
    }

    [Theory]
    [InlineData("Abc1")]
    [InlineData("Abcdef1")]
    [InlineData("abcdefg1")]
    [InlineData("Abcdefgh")]
    public void New_password_rule_gives_one_message(string newPassword)
    {
        var errors = Validate(Request(newPassword));

        var error = Assert.Single(errors);
        Assert.Equal(RuleMessage, error.ErrorMessage);
        Assert.Equal([nameof(ChangePasswordRequest.NewPassword)], error.MemberNames);
    }

    [Fact]
    public void New_password_rule_accepts_eight_characters_with_a_number_and_a_capital()
        => Assert.Empty(Validate(Request("Abcdefg1")));

    private static List<ValidationResult> Validate(ChangePasswordRequest request)
    {
        var errors = new List<ValidationResult>();
        Validator.TryValidateObject(request, new ValidationContext(request), errors, validateAllProperties: true);
        return errors;
    }

    private static ChangePasswordRequest Request(string newPassword) => new()
    {
        CurrentPassword = "Temporary1",
        NewPassword = newPassword,
        ConfirmNewPassword = newPassword
    };

    private static User CreateUser(bool mustChangePassword) => new()
    {
        Id = 41,
        FirstName = "Liza",
        LastName = "Ramos",
        DateOfBirth = new DateOnly(1990, 5, 14),
        HouseNumber = "12",
        Street = "Shoe Avenue",
        Barangay = "Sta. Elena",
        City = "Marikina",
        MustChangePassword = mustChangePassword
    };

    private static AuthService CreateService(List<string> calls, User user, IdentityResult changeResult, IdentityResult updateResult)
    {
        var repository = ReviewBoundaryProxy.Create<IUserRepository>((method, _) =>
        {
            switch (method.Name)
            {
                case nameof(IUserRepository.GetUserAsync):
                    calls.Add(method.Name);
                    return Task.FromResult<User?>(user);
                case nameof(IUserRepository.ChangePasswordAsync):
                    calls.Add(method.Name);
                    return Task.FromResult(changeResult);
                case nameof(IUserRepository.UpdateUserAsync):
                    calls.Add(method.Name + ":" + user.MustChangePassword);
                    return Task.FromResult(updateResult);
                default:
                    throw new InvalidOperationException("Unexpected repository call: " + method.Name);
            }
        });
        var unitOfWork = ReviewBoundaryProxy.Create<IUnitOfWork>((method, _) =>
        {
            calls.Add(method.Name);
            return Task.CompletedTask;
        });
        return new AuthService(repository, null!, unitOfWork, null!, null!);
    }
}
