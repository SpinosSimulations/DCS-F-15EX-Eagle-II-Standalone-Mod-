






ADI_BALL = {R = 0.60, PER_DEG = 0.025, MRAD = 17.4533, STRIPE = 0.030, D = 0.006, SKY = 1000, GND = -1000}
ADI_BALL.K = math.ceil((ADI_BALL.R + ADI_BALL.D) / ADI_BALL.D - 1e-9)
ADI_BALL.NJ = math.floor(ADI_BALL.STRIPE / ADI_BALL.D + 0.5)



function ADI_BALL.step(pitch_mrad)
	local B = ADI_BALL
	local h = pitch_mrad / B.MRAD * B.PER_DEG
	if math.abs(h) <= B.K * B.D then
		local k = math.floor(h / B.D + 0.5)
		return k, -1, h - k * B.D
	end
	local f = h % B.STRIPE
	local j = math.floor(f / B.D + 0.5)
	local res = f - j * B.D
	if j >= B.NJ then j = j - B.NJ end
	return h > 0 and B.SKY or B.GND, j, res
end
