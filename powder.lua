local npan = require("npan")

local granmodule = {}
granmodule.state = {}


CARRIERMIN = 20
CARRIERMAX = 20000

MODFREQMIN = 0.5
MODFREQMAX = 20000

MODDEPTHMIN = 20
MODDEPTHMAX = 20000

PANMIN = 0
PANMAX = 1

RATEMIN = 0.01
RATEMAX = 1000

DURMIN = 0.1
DURMAX = 1000


local function box_muller(mu, sigma2) -- should be replaced with ziggurat at some point
	local theta = 2 * math.pi * math.random()
	local sqrt = math.sqrt(-2 * math.log(math.random()))
	return mu + sigma2 * sqrt * math.cos(theta), mu + sigma2 * sqrt * math.sin(theta)
end

local function uniform(min, max)
	return math.random() * (max - min) + min
end

function granmodule.init(multichan)
	granmodule.state.carriermu = 8 
	granmodule.state.carriersig = 0 
	granmodule.state.modfreqmu = 4
	granmodule.state.modfreqsig = 0
	granmodule.state.moddepthmu = 0
	granmodule.state.moddepthsig = 0
	granmodule.state.durmu = 100
	granmodule.state.dursig = 0
	granmodule.state.panhi = 1
	granmodule.state.panlo = 0
	granmodule.state.ratelo = 10
	granmodule.state.ratehi = 20
	granmodule.state.multichan = multichan
	if multichan==1 then
		npan.set_speakers({45, 1,   -- front left
      -45, 1,   -- front right
       90, 1,   -- side left
      -90, 1,   -- side right
      135, 1,   -- rear left
     -135, 1,   -- rear right rear
        0, 1,   -- front center
      180, 1 	-- rear center
	  })
	  	post("setting up multichan")
	end
	
end

local function restrict(min, max, val)
	return math.min(math.max(val, min), max)
end

function granmodule.generate()
	local pan

	if (granmodule.state.multichan==1) then
		local frac = uniform(granmodule.state.panlo, granmodule.state.panhi)
    	frac = restrict(PANMIN, PANMAX, frac)
		local degrees = frac * 360 + 180
		pan = npan.get_gains(degrees, 1)



	else
		pan = uniform(granmodule.state.panlo, granmodule.state.panhi)
    	pan = restrict(PANMIN, PANMAX, pan)
	end
	

	local amp = 1 --x[1][1] + 0.5
	amp = restrict(0, 1, amp)

	local rate = uniform(granmodule.state.ratelo, granmodule.state.ratehi)
	rate = restrict(RATEMIN, RATEMAX, rate)

	local dur =  box_muller(granmodule.state.durmu, granmodule.state.dursig) -- exponentially scaled
	dur = restrict(DURMIN, DURMAX, dur)

	local modFreq = 2 ^ box_muller(granmodule.state.modfreqmu, granmodule.state.modfreqsig) 
	modFreq = restrict(MODFREQMIN, MODFREQMAX, modFreq)

	local modDepth = 2 ^ box_muller(granmodule.state.moddepthmu, granmodule.state.moddepthsig) 
	modDepth = restrict(MODDEPTHMIN, MODDEPTHMAX, modDepth)

	local carrierfreq = 2 ^ box_muller(granmodule.state.carriermu, granmodule.state.carriersig) 
	carrierfreq = restrict(CARRIERMIN, CARRIERMAX, carrierfreq)
	
    return rate, dur, carrierfreq, modFreq, modDepth, amp, pan
end



function granmodule.update(...)
	local carriermu, carriersig, modfreqmu, modfreqsig, moddepthmu, moddepthsig, durmu, dursig, panhi, panlo, ratelo, ratehi = ...
    granmodule.state.carriermu = carriermu
    granmodule.state.carriersig = carriersig
    granmodule.state.modfreqmu = modfreqmu
    granmodule.state.modfreqsig = modfreqsig
    granmodule.state.moddepthmu = moddepthmu
    granmodule.state.moddepthsig = moddepthsig
    granmodule.state.durmu = durmu
    granmodule.state.dursig = dursig
    granmodule.state.panhi = panhi
    granmodule.state.panlo = panlo
	if (ratelo == 0) then
		ratelo = 50
		ratehi = 100
	end
    granmodule.state.ratelo = ratelo
	granmodule.state.ratehi = ratehi
end

return granmodule