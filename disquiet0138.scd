s.boot;
s.meter;
s.plotTree;
s.scope;
s.options.maxNodes = 1024*4;
s.options.memSize = 8192*4;


(
SynthDef.new(\simpleOsc,{
	arg out=0, freq=440, vol=0.001, pan=0, fmAmount=0, t_trig=1;
	var sig, env;
	env = EnvGen.kr(Env.perc(0.01,1),t_trig,doneAction: 0);
	sig = SinOsc.ar(freq + SinOsc.kr(Rand(5,100),mul: fmAmount));
	Out.ar(out,Pan2.ar(sig*env*vol,pan));
}).add;
)

a = Synth.new(\simpleOsc,[\vol,0.5]);
a.set(\t_trig,1);


SynthDef.new(\percOsc,{
	arg out=0, freq=440, vol=1/1280,pan=0;
	var sig, env;
	sig = SinOsc.ar(freq);
	env = EnvGen.kr(Env.perc(0.01,0.1),doneAction:2);
	Out.ar(out,Pan2.ar(sig*vol*env,pan));
}).add;



( //testing of synthDef
var num;
num = 1000;
num.do({|i|
	Synth.new(\simpleOsc,[\freq,200+exprand(1,1000),\vol,1/num,\pan,rrand(-1,1),\fmAmount,rrand(0,100)]);
});
)

~netAddr = NetAddr("127.0.0.1", nil); //local
(
~synthArray = Array.newClear(1280);

OSCdef(\fromP5,{
	arg msg, time, addr, recvPort;
	if(~synthArray[msg[1]].isNil, // || ~synthArray[msg[1]].isPlaying.not, //check if a synth exists
	{
		//create one if it does not
		~synthArray[msg[1]] = Synth.new(\simpleOsc,[\freq, (msg[3]/msg[2]).linexp(0,0.8,50,10000), \pan, msg[1].linlin(330,1000,-1,1,\minmmax), \fmAmount, 0]);
	},{
		//change fm amount if it does
		var frequencie = (msg[3]/msg[2]).linexp(0,0.8,50,12000);
		frequencie.postln;
		~synthArray[msg[1]].set(\t_trig, 1, \freq, frequencie, \fmAmount, 0);
	});
},"/test",~netAddr);
)

(
x=0;
~synthArray.do({|i|
	if(i.isNil,{x=x+1;});
});
~synthArray.size-x;
)