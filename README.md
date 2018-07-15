# SimradEK60.jl

[![Build Status](https://travis-ci.org/EchoJulia/SimradEK60.jl.svg?branch=master)](https://travis-ci.org/EchoJulia/SimradEK60.jl)

## Introduction

Based on SimradRaw.jl, this project reads and intepretes Simrad EK60
RAW files, extracting power and phase angle information and allowing
calculation of volume backscatter, Sv.


## Example

```
using SimradEK60
using SimradEK60TestData
filename = EK60_SAMPLE
ps = collect(pings(filename))
ps38 = [p for p in ps if p.frequency == 38000]
Sv38 = Sv(ps38)
al38 = alongshipangle(ps38)
at38 = athwartshipangle(ps38)
_R = R(ps38)
_t = filetime(ps38) # timestamps
```

## References

1. [Simrad EK60 Context sensitive on-line help](http://www.simrad.net/ek60_ref_english/default.htm)

2. MacLennan, David, and E. John Simmonds. Fisheries acoustics. Vol. 5. Springer Science & Business Media, 2013.

3. Echoview documentation, http://bit.ly/2o1oOrq  http://bit.ly/2pqzS2D
