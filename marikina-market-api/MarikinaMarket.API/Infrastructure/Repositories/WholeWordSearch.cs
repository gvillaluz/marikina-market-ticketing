using System.Text.RegularExpressions;

namespace MarikinaMarket.API.Infrastructure.Repositories;

// The typed search as a "whole word" rule: no letter or digit right before or after it. An underscore does not
// count as a letter. Accented Latin letters (for example the n with a tilde) are listed by range because the
// database does not treat them as letters on its own. Only plain look-ahead and look-behind are used, so .NET and
// PostgreSQL read the rule the same way.
public static class WholeWordSearch
{
    private const string Letter = @"[\w\u00C0-\u024F]";

    public static string Pattern(string search) =>
        $@"(?:(?<!{Letter})|(?<=_)){Regex.Escape(search.Trim())}(?:(?!{Letter})|(?=_))";
}
