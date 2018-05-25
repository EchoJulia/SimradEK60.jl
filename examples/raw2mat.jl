#!/usr/bin/env julia

using SimradEK60
using MAT

# Finds raw files and converts them to MATLAB files

function main(args)
    filenames = args
    
    if length(filenames) == 1
        dir = filenames[1]
        if isdir(dir)
            filenames =  filter(x->endswith(x,".raw"), readdir(dir))
            filenames = ["$(dir)$(x)" for x in filenames]
        end
    end

    for filename in filenames
        info("Processing $filename ...")
        ps = collect(pings(filename))

        frequencies = unique([p.frequency for p in ps])
  
        dict = Dict()
        
        for f in frequencies
            fr = trunc(Int,f / 1000)
            psf = [p for p in ps if p.frequency == f]
            dict["Sv$fr"] = Sv(psf)
            dict["al$fr"] = alongshipangle(psf)
            dict["at$fr"] = athwartshipangle(psf)
            dict["R$fr"] = R(psf)
            dict["t$fr"] = filetime(psf) # timestamps    
        end

        out ="$(basename(filename)).mat"
        info("Writing $out ...")
        matwrite(out, dict)

    end
    
    
end

main(ARGS)
