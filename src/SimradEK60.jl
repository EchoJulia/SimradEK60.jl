__precompile__()
module SimradEK60

using SimradRaw

export Sv, pings, power, powerdb,  athwartshipangle, alongshipangle, R

################################################################################

# We split the RAW file into a series of EK60 specific pings.

# Whilst it is tempting to include latitude and longitude in the ping,
# this requires NMEA parsing and decisions about interpolation. Some
# people use external GPSs. Since the processing approach could be a
# user preference and potential source of errors, we choose not to
# include them. A caller can easily access NMEA datagrams produced by
# SimradRaw.jl and call PyNmea.

struct EK60Ping
    power::Vector{Int16}
    athwartshipangle::Vector{Int8}
    alongshipangle::Vector{Int8}
    filename::AbstractString
    offset::UInt64
    filetime::UInt64
    frequency::Float32
    soundvelocity::Float32
    sampleinterval::Float32
    absorptioncoefficient::Float32
    transmitpower::Float32
    pulselength::Float32
    gain::Float32
    equivalentbeamangle::Float32
    sacorrection::Float32
    sacorrectiontable::Vector{Float32}
    pulselengthtable::Vector{Float32}
end

################################################################################

# See Echoview documentation, Simrad Time Varied Gain (TVG) range
# correction, http://bit.ly/2pqzS2D

const TVG_RANGE_CORRECTION_OFFSET_SV = 2

"""
    R(r, s, T)

TVG range correction for Ex60

R is the corrected range (m)

r the uncorrected range (m)

s is the TvgRangeCorrectionOffset value 

T is the sample thickness (m)
"""
R(r, s, T) = max.(0f0, r-s*T)


"""
    R(ping::EK60Ping; soundvelocity = nothing)

Returns the corrected range (depth) of samples in `ping`.
"""
function R(ping::EK60Ping; soundvelocity = nothing)

    if soundvelocity == nothing
        soundvelocity = ping.soundvelocity
    end

    p = ping.power

    samplethickness = soundvelocity .* ping.sampleinterval / 2 # in metres of range

    #nsamples = length(p)

    r = [x* samplethickness for x in 0:length(p)-1]
    rangecorrected = R(r, TVG_RANGE_CORRECTION_OFFSET_SV, samplethickness)

end

R(pings::Vector{EK60Ping}; soundvelocity = nothing) =
    R(pings[1],soundvelocity=soundvelocity)

R(pings::Channel{EK60Ping}; soundvelocity = nothing) =
    R(collect(pings[1]), soundvelocity=soundvelocity)


################################################################################

# We must apply the SONAR equation and instrument corrections as
# described in http://bit.ly/2o1oOrq

## % An earlier MATLAB implementation
## % Sv = recvPower + 20 log10(Range) + (2 *  alpha * Range) - (10 * ...
## %           log10((xmitPower * (10^(gain/10))^2 * lambda^2 * ...
## %           c * tau * 10^(psi/10)) / (32 * pi^2)) - (2 * SaCorrection)

"""
    Sv(Pr, λ, G, Ψ, c, α, Pt, τ, Sa, R)
where:

R = the corrected range (m) - see TVG Range Correction

Pr = received power (dB re 1 W) - see Simrad EK numbers to Power

Pt = transmitted power (W)

α = absorption coefficient (dB/m)

G0 = transducer peak gain (non-dimensional) calculated as 10^(G/10)

G is the Transducer gain (dB re 1)

λ = wavelength (m) = c/f

f = frequency (Hz)

c = sound speed (m/s)

τ = transmit pulse duration (s) - also known as the
TransmittedPulseLength

ψ = Equivalent Two-way beam angle (Steradians) calculated as 10^(Ψ/10)

Ψ is the Two-way beam angle (dB re 1 Steradian)

Sa = Simrad correction factor (dB re 1m−1) determined during
calibration. This represents the correction required to the Sv
constant to harmonize the TS and NASC measurements.

"""
function Sv(Pr, λ, G, Ψ, c, α, Pt, τ, Sa, R)

    tvg =  max.(0, 20log10.(R))

    csv = 10log10.((Pt * (10^(G/10))^2 *  λ^2 * c * τ * 10^(Ψ/10)) /
                   (32 * Float32(pi)^2))

    Pr + tvg + (2 * α * R) - csv - 2Sa
end


"""
    maxrange(ping::EK60Ping)

Returns the maximum range of a `ping` taking into account s is the
TvgRangeCorrectionOffset value.

"""
function maxrange(ping::EK60Ping)
    l = length(ping.power)
    T = ping.soundvelocity * ping.sampleinterval / 2
    (l - TVG_RANGE_CORRECTION_OFFSET_SV) * T
end


"""
    pings(filename::AbstractString)

Returns an iterator over pings in the RAW file designated by
`filename`.

"""
function pings(filename::AbstractString)
    pings([filename])
end

"""
    pings(filenames::Vector{AbstractString}})

Returns an iterator over pings in the RAW files designated by
`filenames`.

"""
function pings(filenames::Vector{String})

    function _it(chn1)

        for filename in filenames
            open(filename) do f
                while !eof(f)
                    offset = position(f)
                    datagram = readencapsulateddatagram(f)
                    if datagram.dgheader.datagramtype == "RAW0"

                        transducer = config.configurationtransducers[datagram.channel]
                        idx = findfirst(transducer.pulselengthtable, datagram.pulselength)
                        sacorrection = transducer.sacorrectiontable[idx]

                        ping = EK60Ping(datagram.power,
                                        datagram.athwartshipangle,
                                        datagram.alongshipangle,
                                        filename,
                                        offset,
                                        filetime(datagram.dgheader.datetime),
                                        datagram.frequency,
                                        datagram.soundvelocity,
                                        datagram.sampleinterval,
                                        datagram.absorptioncoefficient,
                                        datagram.transmitpower,
                                        datagram.pulselength,
                                        transducer.gain,
                                        transducer.equivalentbeamangle,
                                        sacorrection,
                                        transducer.sacorrectiontable,
                                        transducer.pulselengthtable)

                        put!(chn1, ping)

                    elseif datagram.dgheader.datagramtype == "CON0"
                        config = datagram
                    end
                end
            end
        end
    end

    return Channel(_it, ctype=EK60Ping)
end




"""
    Sv(ping::EK60Ping;
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing)

Returns a `Vector` of Sv, the (Mean) Volume backscattering strength (MVBS) in (dB re
1 m-1) for a given `ping`.

The function accepts a number of optional arguments which, if
specified, override the ping's own settings. This facilitates external
calibration.

"""
function Sv(ping::EK60Ping;
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing)

    if frequency == nothing
        frequency = ping.frequency
    end

    if gain == nothing
        gain = ping.gain
    end

    if equivalentbeamangle == nothing
        equivalentbeamangle = ping.equivalentbeamangle
    end

    if soundvelocity == nothing
        soundvelocity = ping.soundvelocity
    end

    if absorptioncoefficient == nothing
        absorptioncoefficient = ping.absorptioncoefficient
    end

    if transmitpower == nothing
        transmitpower= ping.transmitpower
    end

    if pulselength == nothing
        pulselength = ping.pulselength
    end

    if sacorrection == nothing
        sacorrection = ping.sacorrection
    end

    pdb = powerdb(ping)

    rangecorrected = R(ping, soundvelocity = soundvelocity)

    λ =  soundvelocity / frequency # calculate wavelength

    Sv(pdb, λ, gain, equivalentbeamangle,
            soundvelocity, absorptioncoefficient,
            transmitpower, pulselength, sacorrection,
            rangecorrected)

end

"""
    Sv(pings::Vector{EK60Ping};
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing)

Returns an `Array` of Sv, the (Mean) Volume backscattering strength (MVBS) in (dB re
1 m-1) for a set of contiguous `pings`.

The function accepts a number of optional arguments which, if
specified, override the pings' own settings. This facilitates external
calibration.

"""
function Sv(pings::Vector{EK60Ping};
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing)
    s = [Sv(ping,
            frequency=frequency,
            gain=gain,
            equivalentbeamangle=equivalentbeamangle,
            soundvelocity=soundvelocity,
            absorptioncoefficient=absorptioncoefficient,
            transmitpower=transmitpower,
            pulselength=pulselength,
            sacorrection=sacorrection) for ping in pings]
    hcat(s...)
end


function Sv(pings::Channel{EK60Ping};
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing)
    Sv(collect(pings),
            frequency=frequency,
            gain=gain,
            equivalentbeamangle=equivalentbeamangle,
            soundvelocity=soundvelocity,
            absorptioncoefficient=absorptioncoefficient,
            transmitpower=transmitpower,
            pulselength=pulselength,
            sacorrection=sacorrection)
end

#

"""
    athwartshipangle(ping::EK60Ping)

Returns the athwartship phase angle difference vector for the given
ping.

"""
athwartshipangle(ping::EK60Ping) = ping.athwartshipangle

function athwartshipangle(pings::Vector{EK60Ping})
    s = [ping.athwartshipangle for ping in pings]
    hcat(s...)
end

athwartshipangle(pings::Channel{EK60Ping}) = athwartshipangle(collect(pings))

@deprecate(athwartshipanglematrix, athwartshipangle)

#

"""
    alongshipangle(ping::EK60Ping)

Returns the alongship phase angle difference vector for the given
ping.

"""
alongshipangle(ping::EK60Ping) = ping.alongshipangle

function alongshipangle(pings::Vector{EK60Ping})
    s = [ping.alongshipangle for ping in pings]
    hcat(s...)
end

alongshipangle(pings::Channel{EK60Ping}) = alongshipangle(collect(pings))

@deprecate(alongshipanglematrix, alongshipangle)

#

power(ping::EK60Ping) = ping.power

function power(pings::Vector{EK60Ping})
    s = [ping.power for ping in pings]
    hcat(s...)
end

power(pings::Channel{EK60Ping}) = power(collect(pings))

#

const POWER_MULTIPLIER = Float32(10 * log10(2) / 256)

powerdb(x) = power(x) .* POWER_MULTIPLIER


end # module
