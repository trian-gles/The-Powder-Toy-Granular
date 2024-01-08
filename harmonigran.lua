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

MULTICHAN = false

local function box_muller(mu, sigma2) -- should be replaced with ziggurat at some point
	local theta = 2 * math.pi * math.random()
	local sqrt = math.sqrt(-2 * math.log(math.random()))
	return mu + sigma2 * sqrt * math.cos(theta), mu + sigma2 * sqrt * math.sin(theta)
end

local function uniform(min, max)
	return math.random() * (max - min) + min
end

local function formatProbs(bins)
	local count = 0
	for i, v in ipairs(bins) do
		count = count + v
	end


	local total = 0
	for i, v in ipairs(bins) do
		total = total + v / count
		bins[i] = total
	end

	return count
end

function granmodule.init(dist)
	granmodule.state.carriermu = 8 
	granmodule.state.carriersig = 0 
	granmodule.state.modfreqmu = 4
	granmodule.state.modfreqsig = 0
	granmodule.state.moddepthmu = 0
	granmodule.state.moddepthsig = 0
	granmodule.state.durmu = 200
	granmodule.state.dursig = 10
	granmodule.state.panhi = 1
	granmodule.state.panlo = 0
	granmodule.state.ratelo = 2
	granmodule.state.ratehi = 4
	granmodule.state.dist = dist

	granmodule.state.partiallo = 1
	granmodule.state.partialhi = 16

	granmodule.state.fundmu = 110
	granmodule.state.fundsig = 2

	granmodule.state.probas = {}

	granmodule.state.amp = 0

	

	for i=1,16 do
		granmodule.state.probas[i] = 0
	end

	granmodule.state.probas[1] = 1

	if MULTICHAN then
		npan.set_speakers({45, 1,   -- front left
      -45, 1,   -- front right
       90, 1,   -- side left
      -90, 1,   -- side right
      135, 1,   -- rear left
     -135, 1,   -- rear right rear
        0, 1,   -- front center
      180, 1 	-- rear center
	  })
	end
	
end

local function restrict(min, max, val)
	return math.min(math.max(val, min), max)
end

function granmodule.generate()
	local pan

	if MULTICHAN then
		local frac = uniform(granmodule.state.panlo, granmodule.state.panhi)
    	frac = restrict(PANMIN, PANMAX, frac)
		local degrees = frac * 360 + 180
		pan = npan.get_gains(degrees, 1)



	else
		pan = uniform(granmodule.state.panlo, granmodule.state.panhi)
    	pan = restrict(PANMIN, PANMAX, pan)
	end

	local fundint = math.random()
	local partialnum = 0

	for i, prob in ipairs(granmodule.state.probas) do
		if fundint < prob then
			partialnum = i
			break
		end
	end

	local fund = box_muller(granmodule.state.fundmu, granmodule.state.fundsig)
	
	local carrierfreq = fund * partialnum + granmodule.state.dist
	carrierfreq = restrict(CARRIERMIN, CARRIERMAX, carrierfreq)
	local amp = granmodule.state.amp --x[1][1] + 0.5
	amp = restrict(0, 1, amp)

	local rate = uniform(granmodule.state.ratelo, granmodule.state.ratehi)
	rate = restrict(RATEMIN, RATEMAX, rate)

	local dur =  box_muller(granmodule.state.durmu, granmodule.state.dursig) / math.sqrt(partialnum) -- exponentially scaled
	dur = restrict(DURMIN, DURMAX, dur)

	--local modFreq = 2 ^ box_muller(granmodule.state.modfreqmu, granmodule.state.modfreqsig) 
	--modFreq = restrict(MODFREQMIN, MODFREQMAX, modFreq)

	--local modDepth = 2 ^ box_muller(granmodule.state.moddepthmu, granmodule.state.moddepthsig) 
	--modDepth = restrict(MODDEPTHMIN, MODDEPTHMAX, modDepth)

    return rate, dur, carrierfreq, amp, pan--modFreq, modDepth, amp, pan
end



function granmodule.update(...)
	granmodule.state.probas = table.pack(...)
	local count = formatProbs(granmodule.state.probas)
	if count == 0 then
		granmodule.state.amp = 0
		count = 1
	else
		granmodule.state.amp = 1
	end
	granmodule.state.ratelo = 16000/count
	granmodule.state.ratehi = granmodule.state.ratelo + 2
	
end



return granmodule