(
ServerOptions.devices.do{ |item|
	item.postln;
}
)

(
Server.killAll;
s = Server.local;
s.options.outDevice_(
	// "MacBook Pro Speakers"
	// "External Headphones"
	"Ryan’s AirPods P"
	// "Scarlett 4i4 USB"
	// "Klipsch One II"
	// "UMC1820"
	// "MME : OUT 01-10 (BEHRINGER UMC 1820)"
);
// s.options.inDevice_("Built-in Microph");
s.options.numInputBusChannels_(0);
s.options.numOutputBusChannels_(2);
s.options.sampleRate_(48000);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
s.reboot;
)

Synth(\default);

// the folder containing the cop
// ~folder = FluidFilesPath();
// ~folder = "/Users/ryanmillett/SONAR/AudioFiles";
// ~folder = "/Users/ryanmillett/Downloads/Final_Normalized/1";

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

~src = Buffer.read(s, "/Users/ryanmillett/GITEX_V2/GITEX_24/Buffers/Audio/src4a.wav");

// slice the buffer in non real-time
(
~indices = Buffer(s);
FluidBufOnsetSlice.processBlocking(s,~src,metric:9,threshold:0.1,windowSize:2048,hopSize:-1,minSliceLength:4,filterSize:101,indices:~indices,action:{
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
~normed = FluidDataSet(s);
FluidUMAP(s,numNeighbours:3,minDist:0.15).fitTransform(~analyses,~umapped,action:{
	"umap done".postln;
	FluidNormalize(s).fitTransform(~umapped,~normed,{
		"transform done.".postln;
		~tree = FluidKDTree(s).fit(~normed, action: {"fit done".postln});
	});
});
)

~normed.write("/Users/ryanmillett/GITEX_V2/GITEX_24/Max/NeuralTides/data/umap_norm_4a.json", action: {"saved".postln});

// -------------------------------------------------------------------------------
(
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "synthdefs.scd").load;
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "functions.scd").load;
// (PathName.new(thisProcess.nowExecutingPath).parentPath ++ "oscdefs.scd").load;
)
// -------------------------------------------------------------------------------

(
~sources = (
	1: (src: ~src, indices: ~indices),
);

~synthQueue = (
	1: [],
);
)

// ~verb = Synth.tail(nil, \verb);

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
					// nearest.postln;
					view.highlight_(nearest);
					~play_slice.(id: 1, index: nearest.asInteger, duration: 3);
					previous = nearest;
				}
			});
		});
	}
});
)
