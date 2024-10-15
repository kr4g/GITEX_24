ServerOptions.devices.do{ |item| item.postln; };

(
Server.killAll;
s = Server.local;
s.options.outDevice_(
	// "MacBook Pro Speakers"
	// "Ryan’s AirPods P"
	"External Headphones"
	// "Ryan’s AirPods P"
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

// sources
(
var buffPath = PathName.new(PathName.new(thisProcess.nowExecutingPath).parentPath).parentPath ++ "/Buffers/Audio/";
~src1 = Buffer.read(s, buffPath ++ "src1.wav");
~src2 = Buffer.read(s, buffPath ++ "src2.wav");
~src3 = Buffer.read(s, buffPath ++ "src3.wav");
~src4 = Buffer.read(s, buffPath ++ "src4a.wav");
)

// functions
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "functions.scd").load;

// slices
(
Routine({
	"src1...".postln;
	~indices1 = Buffer(s);
	~sliceBuffer.value(~src1,~indices1,metric:9,threshold:0.1,windowSize:2048,hopSize:-1,minSliceLength:4,filterSize:101);
	s.sync;

	"src2...".postln;
	~indices2 = Buffer(s);
	~sliceBuffer.value(~src2,~indices2,metric:9,threshold:0.15,windowSize:2048,hopSize:-1,minSliceLength:4,filterSize:101);
	s.sync;

	"src3...".postln;
	~indices3 = Buffer(s);
	~sliceBuffer.value(~src3,~indices3,metric:9,threshold:0.1,windowSize:1024,hopSize:-1,minSliceLength:6,filterSize:101);
	s.sync;

	"src4...".postln;
	~indices4 = Buffer(s);
	~sliceBuffer.value(~src4,~indices4,metric:9,threshold:0.1,windowSize:2048,hopSize:-1,minSliceLength:4,filterSize:101);
	s.sync;
}).play;
// ~indices1 = Buffer.read(s, "/Users/ryanmillett/Downloads/idc1.wav");
// ~indices2 = Buffer.read(s, "/Users/ryanmillett/Downloads/idc2.wav");
// ~indices3 = Buffer.read(s, "/Users/ryanmillett/Downloads/idc3.wav");
// ~indices4 = Buffer.read(s, "/Users/ryanmillett/Downloads/idc4.wav");
)

// synthdefs
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "synthdefs.scd").load;

// data structures
(
~sources = (
	1: (src: ~src1, indices: ~indices1),
	2: (src: ~src2, indices: ~indices2),
	3: (src: ~src3, indices: ~indices3),
	4: (src: ~src4, indices: ~indices4)
);

~synthQueue = (
	1: [],
	2: [],
	3: [],
	4: []
);

~fx = Synth.tail(nil, \verb);
~ampBuses = Array.fill(4, { Bus.audio(s, 2) });
~ampCtrls = ~ampBuses.collect{ |bus, i|
	Synth(\ampCtrl, [
		\in, bus,
		\maxAmp, 1,
		\out, 0
	]);
};
)

// oscdefs
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "oscdefs.scd").load;

