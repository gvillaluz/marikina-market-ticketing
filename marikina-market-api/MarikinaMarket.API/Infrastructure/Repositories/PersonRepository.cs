using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MarikinaMarket.API.Infrastructure.Repositories;

public class PersonRepository(AppDbContext context) : IPersonRepository
{
    public Task<Person?> GetAsync(int id) => context.Persons.SingleOrDefaultAsync(p => p.Id == id);

    public async Task<(List<Person> Items, int Total)> SearchAsync(string? search, int offset, int limit)
    {
        var query = context.Persons.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.ToLowerInvariant();
            query = query.Where(p => p.FullName.ToLower().Contains(term) || p.Address.ToLower().Contains(term)
                || (p.PhoneNumber != null && p.PhoneNumber.Contains(term)));
        }
        var total = await query.CountAsync();
        var items = await query.OrderBy(p => p.FullName).ThenBy(p => p.Id).Skip(offset).Take(limit).ToListAsync();
        return (items, total);
    }

    public async Task AddAsync(Person person) => await context.Persons.AddAsync(person);

    public async Task<(List<Person> Items, int Total)> MatchAsync(string[] nameTokens, string? address, string? phone, int offset, int limit)
    {
        var query = context.Persons.AsNoTracking().Where(p =>
            nameTokens.All(token => p.FullName.ToLower().Contains(token))
            || (address != null && p.Address.ToLower() == address)
            || (phone != null && p.PhoneNumber == phone));
        var total = await query.CountAsync();
        return (await query.OrderBy(p => p.FullName).ThenBy(p => p.Id).Skip(offset).Take(limit).ToListAsync(), total);
    }
    public async Task SaveChangesAsync() => await context.SaveChangesAsync();
}
