using System.Linq.Expressions;
using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;

namespace MarikinaMarket.Tests;

// Test helpers used by many test classes. They lived inside the old vendor sign-up tests, which were removed.

// Builds an interface stub whose every call goes to one handler.
public class ReviewBoundaryProxy : DispatchProxy
{
    public Func<MethodInfo, object?[], object?> Handler { get; set; } = null!;
    protected override object? Invoke(MethodInfo? method, object?[]? args) => Handler(method!, args ?? []);
    public static T Create<T>(Func<MethodInfo, object?[], object?> handler) where T : class
    {
        var proxy = Create<T, ReviewBoundaryProxy>();
        ((ReviewBoundaryProxy)(object)proxy).Handler = handler;
        return proxy;
    }
}

// An in-memory stand-in for a database table that supports adding rows and querying them.
internal sealed class RegistrationDbSet<T>(List<T> records) : DbSet<T>, IQueryable<T> where T : class
{
    private readonly IQueryable<T> _source = records.AsQueryable();
    public override Microsoft.EntityFrameworkCore.Metadata.IEntityType EntityType => throw new NotSupportedException();
    Type IQueryable.ElementType => typeof(T);
    Expression IQueryable.Expression => _source.Expression;
    IQueryProvider IQueryable.Provider => new VendorTicketQueryProvider(_source.Provider, new());
    IEnumerator<T> IEnumerable<T>.GetEnumerator() => _source.GetEnumerator();
    public override ValueTask<EntityEntry<T>> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        records.Add(entity);
        return ValueTask.FromResult<EntityEntry<T>>(null!);
    }
}
