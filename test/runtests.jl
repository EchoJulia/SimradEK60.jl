#!/usr/bin/env julia

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
rangeCorrected = [18.1677435f0]
Sac = -0.49f0

_Sv = Sv(Pr, lambda, G, psi, cv, alpha, pt, tau, Sac,
       rangeCorrected)


@test typeof(_Sv[1]) == Float32
@test _Sv[1] ≈ -94.1832


using SimradEK60TestData

# All pings

ps =collect(pings(EK60_SAMPLE));
@test length(ps) == 1716

# 38 kHz pings

ps38 = [p for p in ps if p.frequency == 38000];

@test length(ps38) == 572

# 70 kHz pings

ps70 = [p for p in ps if p.frequency == 70000];

@test length(ps70) == 0

# 120 kHz pings

ps120 = [p for p in ps if p.frequency == 120000];

@test length(ps120) == 572

# 200 kHz pings

ps200 = [p for p in ps if p.frequency == 200000];

@test length(ps200) == 572

# 38 kHz volume backscatter

Sv38 = Sv(ps38);

m, n = size(Sv38)
@test m == 3782
@test n == 572

@test typeof(Sv38[1,1]) == Float32

# Power

p38 = power(ps38)
m, n = size(p38)
@test m == 3782
@test n == 572
@test typeof(p38[1,1]) == Int16

pdb38 = powerdb(ps38)
m, n = size(pdb38)
@test m == 3782
@test n == 572

@test typeof(pdb38[1,1]) == Float32

pdb120 = powerdb(ps120)
pdb200 = powerdb(ps200)

# Volume backscatter

Sv120 = Sv(ps120)
Sv200 = Sv(ps200)

m, n = size(Sv200)
@test m == 3782
@test n == 572

# Athwartships

at38 = athwartshipangle(ps38);
at120 = athwartshipangle(ps120);
at200 = athwartshipangle(ps200);

m, n = size(at38)
@test m == 3782
@test n == 572

# Alongships

al38 = alongshipangle(ps38);
al120 = alongshipangle(ps120);
al200 = alongshipangle(ps200);

m, n = size(al38)
@test m == 3782
@test n == 572

# Range

_R = R(ps38[1])
@test typeof(_R[1]) == Float32
@test _R[1] == 0
@test _R[end] == 699.4475f0
_R = R(ps38)
@test _R[1] == 0
@test _R[end] == 699.4475f0

# TODO More tests
