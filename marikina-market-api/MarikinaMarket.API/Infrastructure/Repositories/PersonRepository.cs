using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;

namespace MarikinaMarket.API.Infrastructure.Repositories;

public class PersonRepository(AppDbContext context) : IPersonRepository
{
    public Task<Person?> GetAsync(int id) => context.Persons.SingleOrDefaultAsync(p => p.Id == id);

    public Task<List<Person>> GetManyAsync(List<int> ids) => context.Persons.AsNoTracking().Where(p => ids.Contains(p.Id)).ToListAsync();

    public async Task<(List<Person> Items, int Total)> SearchAsync(string? search, int offset, int limit)
    {
        var query = context.Persons.AsNoTracking();
        IOrderedQueryable<Person> ordered;
        if (string.IsNullOrWhiteSpace(search))
            ordered = query.OrderBy(p => p.FullName).ThenBy(p => p.Id);
        else
        {
            var term = search.ToLowerInvariant();
            query = query.Where(p => p.FullName.ToLower().Contains(term) || p.Address.ToLower().Contains(term)
                || (p.PhoneNumber != null && p.PhoneNumber.Contains(term)));
            var pattern = WholeWordSearch.Pattern(search);
            ordered = query
                .OrderBy(p => Regex.IsMatch(p.FullName, pattern, RegexOptions.IgnoreCase)
                    || Regex.IsMatch(p.Address, pattern, RegexOptions.IgnoreCase)
                    || (p.PhoneNumber != null && Regex.IsMatch(p.PhoneNumber, pattern, RegexOptions.IgnoreCase)) ? 0 : 1)
                .ThenBy(p => p.FullName).ThenBy(p => p.Id);
        }
        var total = await query.CountAsync();
        var items = await ordered.Skip(offset).Take(limit).ToListAsync();
        return (items, total);
    }

    // Same name and address, ignoring case and outer spaces; the oldest record when there are several.
    public Task<Person?> FindExactAsync(string fullName, string address)
    {
        var name = fullName.Trim().ToLowerInvariant();
        var place = address.Trim().ToLowerInvariant();
        return context.Persons.AsNoTracking()
            .Where(p => p.FullName.Trim().ToLower() == name && p.Address.Trim().ToLower() == place)
            .OrderBy(p => p.Id).FirstOrDefaultAsync();
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
