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
	// "Ryan’s AirPods P"
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


// sources
(
var buffPath = PathName.new(PathName.new(thisProcess.nowExecutingPath).parentPath).parentPath ++ "/Buffers/Audio/";
~src1 = Buffer.read(s, buffPath ++ "src1.wav");
~src2 = Buffer.read(s, buffPath ++ "src2.wav");
~src3 = Buffer.read(s, buffPath ++ "src3.wav");
~src4 = Buffer.read(s, buffPath ++ "src4.wav");
)

(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "functions.scd").load;

// slices
(
Routine({
	~indices1 = Buffer(s);
	~sliceBuffer.value(~src1,~indices1,metric:9,threshold:0.05,windowSize:1024,hopSize:-1,minSliceLength:4,filterSize:51);
	s.sync;

	~indices2 = Buffer(s);
	~sliceBuffer.value(~src2,~indices2,metric:9,threshold:0.08,windowSize:1024,hopSize:-1,minSliceLength:4,filterSize:51);
	s.sync;

	~indices3 = Buffer(s);
	~sliceBuffer.value(~src3,~indices3,metric:9,threshold:0.02,windowSize:2048,hopSize:-1,minSliceLength:2,filterSize:11);
	s.sync;

	~indices4 = Buffer(s);
	~sliceBuffer.value(~src4,~indices4,metric:9,threshold:0.09,windowSize:2048,hopSize:-1,minSliceLength:4,filterSize:101);
	s.sync;
}).play;
)


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

~state = (
	1: (amp: 0.5, pitch: 1.0),
	2: (amp: 0.5, pitch: 1.0),
	3: (amp: 0.5, pitch: 1.0),
	4: (amp: 0.5, pitch: 1.0)
);
)

~fx = Synth.tail(nil, \verb);

// defs
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "synthdefs.scd").load;
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "oscdefs.scd").load;

