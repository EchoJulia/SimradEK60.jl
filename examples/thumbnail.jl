#!/usr/bin/env julia

using SimradEK60
using EchogramImages
using Images
using FileIO

# Finds raw files and converts them to image thumbnails based on 38kHz Sv

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

        ps38 = [p for p in ps if p.frequency == 38000]
        Sv38 = Sv(ps38)

        img = echogram(Sv38, vmin=-95, vmax = -40)

        img = imresize(img,(480,640))
        
        out ="$(basename(filename)).png"
        info("Writing $out ...")
        save(out, img)

    end
    
    
end

main(ARGS)
