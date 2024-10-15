(
~idxOSC = OSCdef(\receive_index, {
	arg msg;
	var id = msg[1], index = msg[2], duration = msg[3];
	~play_slice.value(id: id, index: index, duration: duration);
}, '/index');

~ampOSC = OSCdef(\receive_amp, {
	arg msg;
	var id = msg[1], amp = msg[2];
	if(id >= 1 and: id <= 4) {
		~ampCtrls[id - 1].set(\maxAmp, amp);
	};
}, '/amp');

~pitchOSC = OSCdef(\receive_pitch, {
	arg msg;
	var id = msg[1], pitch = msg[2];
	if(id >= 1 and: id <= 4) {
		~ampCtrls[id - 1].set(\pRat, pitch);
	};
}, '/pitch');

~verbOSC = OSCdef(\receive_verb, {
	arg msg;
	var amt = msg[1];
	~fx.set(\amt, amt);
}, '/verb');

// ~tr = OSCdef(\handleTrig, { |msg|
// 	var id = msg[2];
// 	NetAddr("127.0.0.1", 7400).sendMsg("/lfo" ++ id, msg[3]);
// }, '/tr');
)