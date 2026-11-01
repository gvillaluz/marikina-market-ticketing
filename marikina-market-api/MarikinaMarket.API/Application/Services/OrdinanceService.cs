using MarikinaMarket.API.Application.DTOs.Ordinance.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.DTOs.SystemConfiguration.Response;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Application.DTOs.Ordinance.Request;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;

namespace MarikinaMarket.API.Application.Services
{
    public class OrdinanceService : IOrdinanceService
    {
        private readonly IOrdinanceRepository _repository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly AuditLogContext? _audit;
        private readonly IAuditLogService? _auditService;

        public OrdinanceService(IOrdinanceRepository repository, IUnitOfWork unitOfWork, AuditLogContext? audit = null,
            IAuditLogService? auditService = null)
        {
            _repository = repository;
            _unitOfWork = unitOfWork;
            _audit = audit;
            _auditService = auditService;
        }

        public async Task<List<OrdinanceSummaryResponse>> GetOrdinances()
        {
            var ordinances = await _repository.GetOrdinances();

            return ordinances.Select(Summary).ToList();
        }

        public async Task<OrdinanceDetailResponse> GetByIdAsync(int id)
        {
            ValidateId(id);
            var ordinance = await _repository.GetByIdAsync(id)
                ?? throw new RecordNotFoundException("Ordinance not found.");
            return MapResponse(ordinance, new OrdinanceDetailResponse
            {
                OrdinanceNo = ordinance.OrdinanceNo,
                Series = ordinance.Series,
                Section = ordinance.Section,
                Title = ordinance.Title
            });
        }

        public async Task<OrdinanceSummaryResponse> CreateAsync(SaveOrdinanceRequest request)
        {
            var ordinanceNo = ValidateRequest(request);
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                var ordinance = new Ordinance
                {
                    OrdinanceNo = ordinanceNo,
                    Series = request.Series.Trim(),
                    Section = request.Section.Trim(),
                    Title = request.Title.Trim(),
                    Category = request.Category,
                    Severity = request.Severity, WarningEligible = request.WarningEligible,
                    SpecificCategory = request.Category == ViolationCategory.Others ? request.SpecificCategory!.Trim() : null,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true
                };
                await _repository.AddAsync(ordinance);
                await _unitOfWork.SaveChangesAsync();
                var tiers = request.PenaltyTiers.Select(t => CreateTier(ordinance.Id, t)).ToList();
                ordinance.PenaltyTiers = tiers;
                await _repository.AddTiersAsync(tiers);
                await _unitOfWork.SaveChangesAsync();
                if (_audit?.Entry is not null) _audit.Entry.TargetId = ordinance.Id.ToString(System.Globalization.CultureInfo.InvariantCulture);
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
                return Summary(ordinance);
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        public async Task<OrdinanceSummaryResponse> UpdateAsync(int id, SaveOrdinanceRequest request)
        {
            ValidateId(id);
            var ordinanceNo = ValidateRequest(request);
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                var ordinance = await _repository.GetByIdAsync(id)
                    ?? throw new RecordNotFoundException("Ordinance not found.");

                if (ordinance.OrdinanceNo != ordinanceNo) ordinance.OrdinanceNo = ordinanceNo;
                if (ordinance.Series != request.Series.Trim()) ordinance.Series = request.Series.Trim();
                if (ordinance.Section != request.Section.Trim()) ordinance.Section = request.Section.Trim();
                if (ordinance.Title != request.Title.Trim()) ordinance.Title = request.Title.Trim();
                if (ordinance.Category != request.Category) ordinance.Category = request.Category;
                ordinance.SpecificCategory = request.Category == ViolationCategory.Others ? request.SpecificCategory!.Trim() : null;
                ordinance.Severity = request.Severity;
                ordinance.WarningEligible = request.WarningEligible;

                await ReconcileTiersAsync(ordinance, request.PenaltyTiers);

                ordinance.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.SaveChangesAsync();
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
                return Summary(ordinance);
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        private async Task ReconcileTiersAsync(Ordinance ordinance, List<SavePenaltyTierRequest> requests)
        {
            var requestedNumbers = requests.Select(t => Math.Max(1, t.OffenseNumber)).ToHashSet();
            var removed = ordinance.PenaltyTiers.Where(t => !requestedNumbers.Contains(t.OffenseNumber)).ToList();
            _repository.RemoveTiers(removed);
            foreach (var tier in removed) ordinance.PenaltyTiers.Remove(tier);

            var existing = ordinance.PenaltyTiers.ToDictionary(t => t.OffenseNumber);
            var added = new List<OrdinancePenaltyTier>();
            foreach (var request in requests)
            {
                var number = Math.Max(1, request.OffenseNumber);
                if (existing.TryGetValue(number, out var tier))
                {
                    tier.FineKind = request.FineKind;
                    tier.PenaltyAmount = request.PenaltyAmount;
                    tier.MaximumFine = request.MaximumFine;
                    tier.PenaltyTerms = request.PenaltyTerms?.Trim();
                    tier.AllowBloodDonation = request.AllowBloodDonation;
                    tier.AllowCommunityService = request.AllowCommunityService;
                }
                else
                {
                    var newTier = CreateTier(ordinance.Id, request);
                    ordinance.PenaltyTiers.Add(newTier);
                    added.Add(newTier);
                }
            }
            if (added.Count > 0) await _repository.AddTiersAsync(added);
        }

        private static void ValidateId(int id)
        {
            if (id <= 0) throw new InvalidRequestException("Ordinance ID must be greater than zero.");
        }

        private static string ValidateRequest(SaveOrdinanceRequest request)
        {
            if (request is null) throw new InvalidRequestException("Ordinance data is required.");
            ValidateText(request.OrdinanceNumber, "Ordinance number", 100);
            ValidateText(request.Series, "Series", 100);
            ValidateText(request.Section, "Section of ordinance", 100);
            ValidateText(request.Title, "Title", 250);
            var number = request.OrdinanceNumber.Trim();
            if (number.Any(character => character < '0' || character > '9'))
                throw new InvalidRequestException("Ordinance number must contain only digits, without a prefix or series.");
            if (!Enum.IsDefined(request.Category) || request.Category is ViolationCategory.Licensing or ViolationCategory.Noise)
                throw new InvalidRequestException("Invalid ordinance category.");
            if (request.Category == ViolationCategory.Others)
                ValidateText(request.SpecificCategory, "Specific category", 100);
            if (!request.Severity.HasValue || !Enum.IsDefined(request.Severity.Value))
                throw new InvalidRequestException("A valid ordinance scoring severity is required.");
            if (request.PenaltyTiers is null || request.PenaltyTiers.Count == 0)
                throw new InvalidRequestException("At least one penalty tier is required.");

            var numbers = new HashSet<int>();
            foreach (var tier in request.PenaltyTiers)
            {
                if (tier is null) throw new InvalidRequestException("Penalty tiers cannot contain null entries.");
                if (tier.OffenseNumber < 0)
                    throw new InvalidRequestException("Offense number cannot be negative.");
                if (!numbers.Add(Math.Max(1, tier.OffenseNumber)))
                    throw new InvalidRequestException("Offense numbers must be unique; base and first offense both use 1.");
                if (!Enum.IsDefined(tier.FineKind))
                    throw new InvalidRequestException("Invalid fine kind.");
                if (Math.Max(1, tier.OffenseNumber) != 1 && (tier.AllowBloodDonation || tier.AllowCommunityService))
                    throw new InvalidRequestException("Blood donation and community service eligibility are only configurable for first offense.");
                if (tier.PenaltyTerms?.Trim().Length > 1000)
                    throw new InvalidRequestException("Penalty terms must not exceed 1000 characters.");
                if (tier.FineKind == FineKind.Fixed)
                {
                    ValidateMoney(tier.PenaltyAmount, 0, "Fixed fine");
                    if (tier.MaximumFine.HasValue) throw new InvalidRequestException("Fixed fines cannot have an up-to cap.");
                }
                else if (tier.FineKind == FineKind.UpTo)
                {
                    ValidateMoney(tier.MaximumFine, 100, "Up-to maximum fine");
                    if (tier.PenaltyAmount.HasValue) throw new InvalidRequestException("Up-to tiers require an assessed amount during recording, not a fixed fine.");
                }
                else
                {
                    ValidateText(tier.PenaltyTerms, "Unconfirmed penalty terms", 1000);
                    if (tier.PenaltyAmount.HasValue || tier.MaximumFine.HasValue)
                        throw new InvalidRequestException("Unconfirmed tiers cannot specify a monetary fine.");
                }
            }
            return number;
        }

        private static void ValidateText(string? value, string field, int? maxLength = null)
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidRequestException($"{field} is required.");
            if (maxLength.HasValue && value.Trim().Length > maxLength.Value)
                throw new InvalidRequestException($"{field} must not exceed {maxLength.Value} characters.");
        }

        private static void ValidateMoney(decimal? value, decimal minimum, string field)
        {
            if (!value.HasValue || value < minimum || value > 9999999999999999.99m
                || decimal.Round(value.Value, 2) != value)
                throw new InvalidRequestException($"{field} must be between {minimum} and 9999999999999999.99 with at most two decimal places.");
        }

        private static OrdinancePenaltyTier CreateTier(int ordinanceId, SavePenaltyTierRequest request) => new()
        {
            OrdinanceId = ordinanceId,
            OffenseNumber = Math.Max(1, request.OffenseNumber),
            FineKind = request.FineKind, PenaltyAmount = request.PenaltyAmount,
            MaximumFine = request.MaximumFine, PenaltyTerms = request.PenaltyTerms?.Trim(),
            AllowBloodDonation = request.AllowBloodDonation, AllowCommunityService = request.AllowCommunityService
        };

        private static OrdinanceSummaryResponse Summary(Ordinance ordinance) =>
            MapResponse(ordinance, new OrdinanceSummaryResponse
            {
                OrdinanceNo = ordinance.OrdinanceNo, 
                Series = ordinance.Series,
                Section = ordinance.Section,
                Title = ordinance.Title
            });

        private static T MapResponse<T>(Ordinance ordinance, T response) where T : OrdinanceSummaryResponse
        {
            response.Id = ordinance.Id;
            response.Category = ordinance.Category;
            response.SpecificCategory = ordinance.SpecificCategory;
            response.CreatedAt = ordinance.CreatedAt;
            response.UpdatedAt = ordinance.UpdatedAt;
            response.IsActive = ordinance.IsActive;
            response.Severity = ordinance.Severity;
            response.WarningEligible = ordinance.WarningEligible;
            response.PenaltyTiers = ordinance.PenaltyTiers.OrderBy(t => t.OffenseNumber).Select(t => new OrdinancePenaltyTierResponse
            {
                Id = t.Id, OffenseNumber = t.OffenseNumber, FineKind = t.FineKind, PenaltyAmount = t.PenaltyAmount,
                MinimumFine = t.FineKind == FineKind.UpTo ? 100m : null, MaximumFine = t.MaximumFine,
                PenaltyTerms = t.PenaltyTerms, AllowBloodDonation = t.AllowBloodDonation, AllowCommunityService = t.AllowCommunityService
            }).ToList();
            response.PenaltyTierCount = ordinance.PenaltyTiers.Count;
            return response;
        }

        public async Task<CountResponse> GetActiveCountAsync()
        {
            return new CountResponse
            {
                Count = await _repository.GetActiveCountAsync()
            };
        }
    }
}
