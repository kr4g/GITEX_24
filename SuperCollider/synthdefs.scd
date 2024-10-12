// SynthDefs
(
SynthDef(\play_slice, {
	arg id = 0, index = 0, src, indices, pan = 0, gate = 1;

	var startsamp, stopsamp, phs, sig, lfo, dursecs, env;
	var duration = \duration.kr(1);
	var alpha = Rand(0.0,1.0);

	startsamp = Index.kr(indices, index);
	stopsamp = Index.kr(indices, index + 1);

	phs = Phasor.ar(0, BufRateScale.ir(src), startsamp, stopsamp, startsamp);
	sig = BufRd.ar(1, src, phs);
	dursecs = (stopsamp - startsamp) / BufSampleRate.ir(src);

	dursecs = min(dursecs, 1);

	env = EnvGen.kr(Env([0, 1, 1, 0], [dursecs * 0.25, dursecs * 0.5, dursecs * 0.25], \lin), gate: Impulse.kr(1/dursecs), doneAction: 0);

	sig = PitchShift.ar(sig, pitchRatio: \pRat.kr(1));

	sig = sig * env;

	// lfo = SinOsc.ar(LFNoise1.ar(ExpRand(0.02,0.03)).range(0.125/4, 0.25)).exprange(\minAmp.kr(0.01), \maxAmp.kr(1));
	// sig = sig * lfo;
	// SendTrig.kr(Impulse.kr(10), id, lfo);

	sig = Pan2.ar(sig, SinOsc.ar(LFNoise1.ar(ExpRand(0.03,0.05)).range(0.167, 0.667)));

	sig = sig * \amp.kr(1, 0.05) * EnvGen.kr(Env.perc(alpha * duration, (1.0 - alpha) * duration, curve: 2), doneAction: 2) * -16.dbamp;

	Out.ar(0, sig);
}).add;

SynthDef(\ampCtrl, {
	var sig = In.ar(0);
	var lfo = SinOsc.ar(LFNoise1.ar(ExpRand(0.02,0.03)).range(0.125/8, 0.125)).exprange(\minAmp.kr(0.001), \maxAmp.kr(1));
	sig = sig * lfo;
	SendTrig.kr(Impulse.kr(20), \id.kr(-1), lfo);
	Out.ar(0, sig);
}).add;

SynthDef(\verb, {
	var sig = In.ar(0);
	var verb = JPverb.ar(sig, t60: 3.0, size: 3.5, earlyDiff: 0.707, modDepth: 0.5, modFreq: 2.5);
	sig = XFade2.ar(sig, verb, (\amt.kr(0.5) * 2) - 1);
	Out.ar(0, sig);
}).add;
)
