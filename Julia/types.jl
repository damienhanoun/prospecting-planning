using Dates

export Period, TimePreferenceKind, PeriodWithPreference, PREFERENCE_WEIGHTS

struct Period
    start::DateTime
    duration::Int  # in minutes
end

@enum TimePreferenceKind begin
    Preferred
    Unpreferred
    Neutral
end

struct PeriodWithPreference
    start::DateTime
    duration::Int  # in minutes
    timePreferenceKind::TimePreferenceKind
end

Base.isless(p1::PeriodWithPreference, p2::PeriodWithPreference) = p1.start < p2.start

const PREFERENCE_WEIGHTS = Dict(
    Preferred => 10,
    Unpreferred => -10,
    Neutral => 0
)