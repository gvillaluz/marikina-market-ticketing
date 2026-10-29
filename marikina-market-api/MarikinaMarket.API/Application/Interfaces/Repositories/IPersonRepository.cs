using MarikinaMarket.API.Domain.Entities;

namespace MarikinaMarket.API.Application.Interfaces.Repositories;

public interface IPersonRepository
{
    Task<Person?> GetAsync(int id);
    Task<(List<Person> Items, int Total)> MatchAsync(string[] nameTokens, string? address, string? phone, int offset, int limit);
    Task<(List<Person> Items, int Total)> SearchAsync(string? search, int offset, int limit);
    Task AddAsync(Person person);
    Task SaveChangesAsync();
}
