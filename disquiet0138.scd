s.boot;
//We wan't to know what is going on
s.meter;
s.plotTree;
// Moare Power!!!
(
s.options.maxNodes = 1024*4;
s.options.memSize = 8192*4;
)

// The synthDef
(
SynthDef.new(\simpleOsc,{
	arg out=0, freq=440, vol=0.002, pan=0, fmAmount=0, t_trig=1;
	var sig, env;
	env = EnvGen.kr(Env.perc(0.01,1),t_trig,doneAction: 0);
	sig = SinOsc.ar(freq + SinOsc.kr(Rand(5,100),mul: fmAmount));
	Out.ar(out,Pan2.ar(sig*env*vol,pan));
}).add;
)

//testing of synthDef - no need to evaluate
a = Synth.new(\simpleOsc,[\vol,0.5]);
a.set(\t_trig,1);

(
var num;
num = 1000;
num.do({|i|
	Synth.new(\simpleOsc,[\freq,200+exprand(1,1000),\vol,1/num,\pan,rrand(-1,1),\fmAmount,rrand(0,100)]);
});
)

// Due to processing not sending on the correct port; listen to all ports:
~netAddr = NetAddr("127.0.0.1", nil); //local
(
~synthArray = Array.newClear(1280);

OSCdef(\fromP5,{
	arg msg, time, addr, recvPort;
	var lowerFreq = 25;
	var higherFreq = 15000;
	var fM = msg[2];

	if(~synthArray[msg[1]].isNil, // || ~synthArray[msg[1]].isPlaying.not, //check if a synth exists
	{
		//create one if it does not
		~synthArray[msg[1]] = Synth.new(\simpleOsc,[\freq, (msg[3]/msg[2]).linexp(0,0.8,lowerFreq,higherFreq), \pan, msg[1].linlin(390,1280,-1,1,\minmmax), \fmAmount, fM]);
	},{
		//pass new params and retrigger if it does
		var frequencie = (msg[3]/msg[2]).linexp(0,0.8,lowerFreq,higherFreq);
		frequencie.postln;
			~synthArray[msg[1]].set(\t_trig, 1, \freq, frequencie, \fmAmount, fM);
	});
},"/test",~netAddr);
)

// check how many synths were instansiated.
(
x=0;
~synthArray.do({|i|
	if(i.isNil,{x=x+1;});
});
~synthArray.size-x;
)

//Recording
s.record;

s.recordNode.stop;
