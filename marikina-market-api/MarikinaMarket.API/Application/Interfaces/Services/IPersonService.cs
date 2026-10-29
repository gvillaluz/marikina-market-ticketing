using MarikinaMarket.API.Application.DTOs.Person.Request;
using MarikinaMarket.API.Application.DTOs.Person.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;

namespace MarikinaMarket.API.Application.Interfaces.Services;

public interface IPersonService
{
    Task<PersonRecordResponse> GetAsync(int id);
    Task<PageResponse<PersonCandidateResponse>> MatchAsync(PersonMatchRequest request);
    Task<PageResponse<PersonRecordResponse>> SearchAsync(PersonSearchRequest filters, int offset);
    Task<PersonRecordResponse> SaveAsync(int? id, SavePersonRequest request);
}
