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
~indices1 = ~sliceBuffer.(~src1,metric:9,threshold:0.05,windowSize:1024,hopSize:-1,minSliceLength:4,filterSize:51);
~indices2 = ~sliceBuffer.(~src2,metric:9,threshold:0.08,windowSize:1024,hopSize:-1,minSliceLength:4,filterSize:51);
~indices3 = ~sliceBuffer.(~src3,metric:9,threshold:0.02,windowSize:2048,hopSize:-1,minSliceLength:2,filterSize:11);
~indices4 = ~sliceBuffer.(~src4,metric:9,threshold:0.09,windowSize:2048,hopSize:-1,minSliceLength:4,filterSize:101);
)


(
~sources = (
	1: (src: ~src1, indices: ~indices1),
	2: (src: ~src2, indices: ~indices2),
	3: (src: ~src3, indices: ~indices3),
	4: (src: ~src4, indices: ~indices4)
);
)

// defs
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "synthdefs.scd").load;
(PathName.new(thisProcess.nowExecutingPath).parentPath ++ "oscdefs.scd").load;

