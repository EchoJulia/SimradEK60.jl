using SimradEK60
using Base.Test

# SONAR equation for EK60

alpha = 0.009841439f0
pt = 1000.0f0
cv = 1448.2969f0
G = 25.92f0


lambda = 0.038113076f0

psi = -20.7f0
tau = 0.001024f0
Pr = -111.22823f0
rangeCorrected = 18.1677435f0
Sac = -0.49f0

_Sv = Sv(Pr, lambda, G, psi, cv, alpha, pt, tau, Sac,
       rangeCorrected)

@test typeof(_Sv) == Float32
@test _Sv == -94.183174f0

# All pings

ps =collect(pings(SimradRaw.EK60_SAMPLE));
@test length(ps) == 1092

# 38 kHz pings

ps38 = [p for p in ps if p.frequency == 38000];

@test length(ps38) == 273

# 70 kHz pings

ps70 = [p for p in ps if p.frequency == 70000];

@test length(ps70) == 273

# 120 kHz pings

ps120 = [p for p in ps if p.frequency == 120000];

@test length(ps120) == 273

# 200 kHz pings

ps200 = [p for p in ps if p.frequency == 200000];

@test length(ps200) == 273

# 38 kHz volume backscatter

Sv38 = Sv(ps38);

m, n = size(Sv38)
@test m == 5934
@test n == 273

@test typeof(Sv38[1,1]) == Float32

# Power

p38 = power(ps38)
m, n = size(p38)
@test m == 5934
@test n == 273
@test typeof(p38[1,1]) == Int16

pdb38 = powerdb(ps38)
m, n = size(pdb38)
@test m == 5934
@test n == 273

@test typeof(pdb38[1,1]) == Float32

pdb70 = powerdb(ps70)
pdb120 = powerdb(ps120)
pdb200 = powerdb(ps200)

# Volume backscatter

Sv70 = Sv(ps70)
Sv120 = Sv(ps120)
Sv200 = Sv(ps200)

m, n = size(Sv200)
@test m == 5934
@test n == 273

# Athwartships

at38 = athwartshipangle(ps38);
at70 = athwartshipangle(ps70);
at120 = athwartshipangle(ps120);
at200 = athwartshipangle(ps200);

m, n = size(at38)
@test m == 5934
@test n == 273

# Alongships

al38 = alongshipangle(ps38);
al70 = alongshipangle(ps70);
al120 = alongshipangle(ps120);
al200 = alongshipangle(ps200);

m, n = size(al38)
@test m == 5934
@test n == 273

# Range

_R = R(ps38[1])
@test typeof(_R[1]) == Float32
@test _R[1] == 0
@test _R[end] == 1099.5006f0
_R = R(ps38)
@test _R[1] == 0
@test _R[end] == 1099.5006f0


# Comparision with data that came from EKReadRaw MATLAB code

using MAT

filename = joinpath(dirname(@__FILE__),
                     "data/jr16003/EK60example.mat")

data = matread(filename)["data"]

@test al38 == data["pings"]["alongship_e"][:,1][1]
@test al70 == data["pings"]["alongship_e"][:,2][1]
@test al120 == data["pings"]["alongship_e"][:,3][1]
@test al200 == data["pings"]["alongship_e"][:,4][1]

@test at38 == data["pings"]["athwartship_e"][:,1][1]
@test at70 == data["pings"]["athwartship_e"][:,2][1]
@test at120 == data["pings"]["athwartship_e"][:,3][1]
@test at200 == data["pings"]["athwartship_e"][:,4][1]

@test isapprox(data["pings"]["power"][:,1][1], pdb38, atol = 0.000001)
@test isapprox(data["pings"]["power"][:,2][1], pdb70, atol = 0.000001)
@test isapprox(data["pings"]["power"][:,3][1], pdb120, atol = 0.000001)
@test isapprox(data["pings"]["power"][:,4][1], pdb200, atol = 0.000001)

@test ps38[1].absorptioncoefficient ==  data["pings"]["absorptioncoefficient"][1][1]
@test ps70[1].absorptioncoefficient ==  data["pings"]["absorptioncoefficient"][2][1]
@test ps120[1].absorptioncoefficient ==  data["pings"]["absorptioncoefficient"][3][1]
@test ps200[1].absorptioncoefficient ==  data["pings"]["absorptioncoefficient"][4][1]

@test ps38[1].transmitpower ==  data["pings"]["transmitpower"][1][1]
@test ps70[1].transmitpower ==  data["pings"]["transmitpower"][2][1]
@test ps120[1].transmitpower ==  data["pings"]["transmitpower"][3][1]
@test ps200[1].transmitpower ==  data["pings"]["transmitpower"][4][1]

@test ps38[1].soundvelocity ==  data["pings"]["soundvelocity"][1][1]
@test ps38[1].pulselength ==  data["pings"]["pulselength"][1][1]
@test ps38[1].sampleinterval ==  data["pings"]["sampleinterval"][1][1]


#println(SimradEK60.R(ps38[1])[1:10])
#println(data["pings"]["range"][1][1:10])
# TODO Check that this test would fail
@test isapprox(R(ps38[1])[3:end], data["pings"]["range"][1][1:end-2], atol = 0.000001)

@test ps38[1].gain ==  data["config"]["gain"][1]
@test ps70[1].gain ==  data["config"]["gain"][2]
@test ps120[1].gain ==  data["config"]["gain"][3]
@test ps200[1].gain ==  data["config"]["gain"][4]

@test ps38[1].frequency ==  data["config"]["frequency"][1]
@test ps70[1].frequency ==  data["config"]["frequency"][2]
@test ps120[1].frequency ==  data["config"]["frequency"][3]
@test ps200[1].frequency ==  data["config"]["frequency"][4]

@test ps38[1].equivalentbeamangle ==  data["config"]["equivalentbeamangle"][1]

@test isapprox(ps38[1].sacorrectiontable,  data["config"]["sacorrectiontable"][1], atol = 0.000001)
@test isapprox(ps70[1].sacorrectiontable,  data["config"]["sacorrectiontable"][2], atol = 0.000001)
@test isapprox(ps120[1].sacorrectiontable,  data["config"]["sacorrectiontable"][3], atol = 0.000001)
@test isapprox(ps200[1].sacorrectiontable,  data["config"]["sacorrectiontable"][4], atol = 0.000001)

@test isapprox(ps38[1].pulselengthtable,  data["config"]["pulselengthtable"][1], atol = 0.000001)
@test isapprox(ps70[1].pulselengthtable,  data["config"]["pulselengthtable"][2], atol = 0.000001)
@test isapprox(ps120[1].pulselengthtable,  data["config"]["pulselengthtable"][3], atol = 0.000001)
@test isapprox(ps200[1].pulselengthtable,  data["config"]["pulselengthtable"][4], atol = 0.000001)

# We are very close to ReadEKRaw

sv = data["pings"]["Sv"][:,1][1]
# println(Sv38[1:10,1:10])
# println(sv[1:10,1:10])
@test isapprox(Sv38, sv)

sv = data["pings"]["Sv"][:,2][1]
@test isapprox(Sv70, sv)

sv = data["pings"]["Sv"][:,3][1]
@test isapprox(Sv120, sv)

sv = data["pings"]["Sv"][:,4][1]
@test isapprox(Sv200, sv)

# Comparison with EchoView

using DataFrames

filename = joinpath(dirname(@__FILE__),
                    "data/jr16003/EK60_example.sv.csv")

sv = readtable(filename, header=false, skipstart=1)

sv =sv[:,14:end]
sv = convert(Array,sv)'

# Echoview drops the first sample, so we do too for comparison

@test isapprox(Sv38[2:end,:], sv, atol=0.5)

println("Worst case error $(maximum(Sv38[2:end,:] - sv))")


# NB Can only get to within about 0.018dB accuracy of Echoview

println("ReadEKRaw")
println(data["pings"]["Sv"][:,1][1][end-10:end,1:10])
println("Echoview")
println(sv[end-10:end,1:10])
println("This library")
println(Sv38[end-10:end,1:10])
