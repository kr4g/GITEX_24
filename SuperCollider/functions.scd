(
~sliceBuffer = { |src, indices, metric = 9, threshold = 0.05, windowSize = 1024, hopSize = -1, minSliceLength = 2, filterSize = 51|
	FluidBufOnsetSlice.processBlocking(s, src, metric: metric, threshold: threshold, windowSize: windowSize, hopSize: hopSize, minSliceLength: minSliceLength, filterSize: filterSize, indices: indices, action: {
		"found % slice points".format(indices.numFrames).postln;
		"average duration per slice: %".format(src.duration / (indices.numFrames+1)).postln;
		"-----------------------------------".postln;
	});
};

~play_slice = {
	arg id = -1, index = -1, duration = 1, pitchRatio = 1, amp = 1;
	var newSynth = nil;
	var src, indices;

	src = ~sources[id][\src];
	indices = ~sources[id][\indices];

	if (~synthQueue[id].size >= 4) {
		if (~synthQueue[id][0].isPlaying) {
			~synthQueue[id][0].free;
		};
		~synthQueue[id] = ~synthQueue[id].drop(1);
	};

	newSynth = Synth(\play_slice, [
		\src, src,
		\indices, indices,
		\id, id,
		\index, index,
		\duration, duration,
		\pRat, pitchRatio,
		\amp, amp
	]).onFree();

	~synthQueue[id] = ~synthQueue[id].add(newSynth);
};
)
