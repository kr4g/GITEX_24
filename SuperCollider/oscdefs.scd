(
~idxOSC = OSCdef(\receive_index, {
	arg msg;
	var id = msg[1], index = msg[2], duration = msg[3];
	// "ID: %, idx: %".format(id, index).postln
	~play_slice.value(id, index, duration, ~state[id][\pitch], ~state[id][\amp]);
}, '/index');

~ampOSC = OSCdef(\receive_amp, {
	arg msg;
	var id = msg[1], amp = msg[2];
	~state[id][\amp] = amp;
}, '/amp');

~pitchOSC = OSCdef(\receive_pitch, {
	arg msg;
	var id = msg[1], pitch = msg[2];
	msg.postln;
	~state[id][\pitch] = pitch;
}, '/pitch');

~verbOSC = OSCdef(\receive_verb, {
	arg msg;
	var amt = msg[1];
	~fx.set(\amt, amt);
}, '/verb');

// ~tr = OSCdef(\handleTrig, { |msg|
// 	var id = msg[2];
// 	// msg[3].postln;
// 	NetAddr("127.0.0.1", 7400).sendMsg("/lfo" ++ id, msg[3]);
// }, '/tr');
)