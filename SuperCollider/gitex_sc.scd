(
ServerOptions.devices.do{ |item|
	item.postln;
}
)

(
s = Server.local;
s.options.outDevice_(
	"MacBook Pro Speakers"
	// "External Headphones"
	// "Scarlett 4i4 USB"
	// "Klipsch One II"
	// "UMC1820"
	// "MME : OUT 01-10 (BEHRINGER UMC 1820)"
);
s.options.inDevice_("Built-in Microph");
s.options.numOutputBusChannels_(2);
s.options.numInputBusChannels_(0);
s.options.sampleRate_(48000);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
s.reboot;
)

// the folder containing the cop
// ~folder = FluidFilesPath();
// ~folder = "/Users/ryanmillett/SONAR/AudioFiles";
~folder = "/Users/ryanmillett/Downloads/Final_Normalized/1";

// load into a buffer
~loader = FluidLoadFolder(~folder).play(s,{"done loading folder".postln;});

// sum to mono (if not mono)
(
if(~loader.buffer.numChannels > 1){
	~src = Buffer(s);
	~loader.buffer.numChannels.do{
		arg chan_i;
		FluidBufCompose.processBlocking(s,
			~loader.buffer,
			startChan:chan_i,
			numChans:1,
			gain:~loader.buffer.numChannels.reciprocal,
			destination:~src,
			destGain:1,
			action:{"copied channel: %".format(chan_i).postln}
		);
	};
}{
	"loader buffer is already mono".postln;
	~src = ~loader.buffer;
};
)

~src.write("/Users/ryanmillett/Downloads/src1.wav");

// slice the buffer in non real-time
(
~indices = Buffer(s);
FluidBufOnsetSlice.processBlocking(s,~src,metric:9,threshold:0.01,windowSize:2048,hopSize:-1,minSliceLength:2,filterSize:51,indices:~indices,action:{
	"found % slice points".format(~indices.numFrames).postln;
	"average duration per slice: %".format(~src.duration / (~indices.numFrames+1)).postln;
});
)

// analysis
(
~analyses = FluidDataSet(s);
~indices.loadToFloatArray(action:{
	arg fa;
	var mfccs = Buffer(s);
	var stats = Buffer(s);
	var flat = Buffer(s);

	fa.doAdjacentPairs{
		arg start, end, i;
		var num = end - start;

		FluidBufMFCC.processBlocking(s,~src,start,num,features:mfccs,numCoeffs:13,startCoeff:1);
		FluidBufStats.processBlocking(s,mfccs,stats:stats,select:[\mean]);
		FluidBufFlatten.processBlocking(s,stats,destination:flat);

		~analyses.addPoint(i,flat);

		"analyzing slice % / %".format(i+1,fa.size-1).postln;

		if((i%100) == 99){s.sync;}
	};

	s.sync;

	~analyses.print;
});
)

(
~umapped = FluidDataSet(s);
FluidUMAP(s,numNeighbours:9,minDist:0.15).fitTransform(~analyses,~umapped,action:{"umap done".postln});
)

~umapped.print;

// normalize
(
~normed = FluidDataSet(s);
FluidNormalize(s).fitTransform(~umapped,~normed);
)

~normed = FluidDataSet(s);
~normed.read("/Users/ryanmillett/GITEX/Max/NeuralTides/data/dr_full.json", action: {"loaded".postln});

~normed.print;

~normed.write("/Users/ryanmillett/GITEX/Max/NeuralTides/data/umap_norm_4.json", action: {"saved".postln});

// fit a kdtree
~tree = FluidKDTree(s).fit(~normed, action: {"fit done".postln});

// SynthDefs
(
SynthDef(\play_slice, {
	arg id = 0, index = 0, src, indices, amp = 1, pan = 0, gate = 1;

	var startsamp, stopsamp, phs, sig, lfo, dursecs, env;

	startsamp = Index.kr(indices, index);
	stopsamp = Index.kr(indices, index + 1);
	phs = Phasor.ar(0, BufRateScale.ir(src), startsamp, stopsamp, startsamp);
	sig = BufRd.ar(1, src, phs);
	dursecs = (stopsamp - startsamp) / BufSampleRate.ir(src);

	dursecs = min(dursecs, 1);

	env = EnvGen.kr(Env([0, 1, 1, 0], [dursecs * 0.125, dursecs * 0.5, dursecs * 0.375], \lin), gate: Impulse.kr(1/dursecs), doneAction: 0);

	sig = sig * env;

	// lfo = SinOsc.ar(LFNoise1.ar(ExpRand(0.02,0.03)).range(0.125/4, 0.25)).exprange(\minAmp.kr(0.01), \maxAmp.kr(1));
	// sig = sig * lfo;
	// SendTrig.kr(Impulse.kr(10), id, lfo);

	sig = Pan2.ar(sig, SinOsc.ar(LFNoise1.ar(ExpRand(0.03,0.05)).range(0.167, 0.667)));

	sig = sig * amp * EnvGen.kr(Env.perc(0, \duration.kr(1)), doneAction: 2);

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
	sig = XFade2.ar(sig, verb, (\amt.kr(0.67) * 2) - 1);
	Out.ar(0, sig);
}).add;
)

(
Routine({
	4.do{ |i|
		Synth(\ampCtrl, [
			\id, i + 1,
		]);
	};
}).play;
)

(
~oscdef = OSCdef(\receiveIndex, { |msg|
	var index = msg[1];
	index.postln;
	~play_slice.(index.asInteger);
}, '/index');

~tr = OSCdef(\handleTrig, { |msg|
	var id = msg[2];
	// msg[3].postln;
	NetAddr("127.0.0.1", 7400).sendMsg("/lfo" ++ id, msg[3]);
}, '/tr');
)

(
~verb = Synth.tail(nil, \verb);

~synthQueue = [];

~play_slice = {
	arg index, id = 1, src = nil, indices = nil;
	var newSynth = nil;

	if (~synthQueue.size >= 8) {
		if (~synthQueue[0].isPlaying) {
			~synthQueue[0].free;
		};
		~synthQueue = ~synthQueue.drop(1);
	};

	newSynth = Synth(\play_slice, [
		\src, ~src,
		\indices, ~indices,
		\id, id,
		\index, index,
		\duration, 1
	]).onFree();

	~synthQueue = ~synthQueue.add(newSynth);
};
)

// plot
(
~normed.dump({
	arg dict;
	var point = Buffer.alloc(s,2);
	var previous = nil;
	dict.postln;
	defer{
		FluidPlotter(dict:dict,mouseMoveAction:{
			arg view, x, y;
			// [x,y].postln;
			point.setn(0,[x,y]);
			~tree.kNearest(point,1,{
				arg nearest;
				if(nearest != previous){
					nearest.postln;
					view.highlight_(nearest);
					~play_slice.(nearest.asInteger);
					previous = nearest;
				}
			});
		});
	}
});
)



s.record("/Users/ryanmillett/Downloads/audio2.wav", numChannels: 2, duration: 10);
(
x = Synth(\play_slice, [
		\src, ~src,
		\indices, ~indices,
		\id, 1,
		\index, 566,
		\duration, 10
	]).onFree();
)
x.free;
