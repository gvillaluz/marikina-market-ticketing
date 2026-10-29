using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;
using MarikinaMarket.API.Application.DTOs.Person.Request;
using MarikinaMarket.API.Application.DTOs.Person.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;

namespace MarikinaMarket.API.Application.Services;

public class PersonService(IPersonRepository repository) : IPersonService
{
    private const int PAGE_SIZE = 10;

    public async Task<PersonRecordResponse> GetAsync(int id)
    {
        ValidateId(id);
        return Map(await repository.GetAsync(id) ?? throw new RecordNotFoundException("Person not found."));
    }

    public async Task<PageResponse<PersonRecordResponse>> SearchAsync(PersonSearchRequest filters, int offset)
    {
        if (offset < 0 || filters.Search?.Length > 500)
            throw new ValidationException("Search must not exceed 500 characters and offset must be nonnegative.");
        var (items, total) = await repository.SearchAsync(filters.Search?.Trim(), offset, PAGE_SIZE);
        return new() { Items = items.Select(Map).ToList(), Total = total, HasMore = (long)offset + items.Count < total };
    }

    public async Task<PersonRecordResponse> SaveAsync(int? id, SavePersonRequest request)
    {
        if (id.HasValue) ValidateId(id.Value);
        if (request is null) throw new ValidationException("Person details are required.");
        Validator.ValidateObject(request, new ValidationContext(request), validateAllProperties: true);
        var phone = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber;
        if (phone is not null && !Regex.IsMatch(phone, @"\A09[0-9]{9}\z"))
            throw new ValidationException("Phone number must be 11 digits starting with 09.");
        var person = id.HasValue
            ? await repository.GetAsync(id.Value) ?? throw new RecordNotFoundException("Person not found.")
            : new Person { FullName = request.FullName.Trim(), Address = request.Address.Trim() };
        person.FullName = request.FullName.Trim();
        person.Address = request.Address.Trim();
        person.PhoneNumber = phone;
        if (!id.HasValue) await repository.AddAsync(person);
        await repository.SaveChangesAsync();
        return Map(person);
    }

    private static void ValidateId(int id)
    {
        if (id <= 0) throw new InvalidRequestException("Person ID must be greater than zero.");
    }

    public async Task<PageResponse<PersonCandidateResponse>> MatchAsync(PersonMatchRequest request)
    {
        Validator.ValidateObject(request, new ValidationContext(request), validateAllProperties: true);
        var tokens = Regex.Split(request.Name.ToLowerInvariant(), @"[^\p{L}\p{N}]+").Where(t => t.Length > 0).Distinct().ToArray();
        if (tokens.Length == 0) throw new ValidationException("Enter a person's name to check possible matches.");
        var address = string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim().ToLowerInvariant();
        var phone = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim();
        var (items, total) = await repository.MatchAsync(tokens, address, phone, request.Offset, PAGE_SIZE);
        return new() { Total = total, HasMore = (long)request.Offset + items.Count < total,
            Items = items.Select(p => new PersonCandidateResponse
            {
                Id = p.Id, FullName = p.FullName, Address = p.Address, PhoneNumber = p.PhoneNumber, CreatedAt = p.CreatedAt,
                MatchedFields = new[] {
                    tokens.All(t => p.FullName.Contains(t, StringComparison.OrdinalIgnoreCase)) ? "name" : null,
                    address != null && string.Equals(p.Address, address, StringComparison.OrdinalIgnoreCase) ? "address" : null,
                    phone != null && p.PhoneNumber == phone ? "phone" : null
                }.OfType<string>().ToList()
            }).ToList() };
    }

    private static PersonRecordResponse Map(Person person) => new()
    {
        Id = person.Id, FullName = person.FullName, Address = person.Address,
        PhoneNumber = person.PhoneNumber, CreatedAt = person.CreatedAt
    };
}
