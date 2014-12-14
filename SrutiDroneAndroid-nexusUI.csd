;-------------------------------------------------------------------------
; Drone Instrument/Sruti Box
; by Dave Seidel <mysterybear.net/>
; with contributions from joachim heintz
; and Andres Cabrera.
;
; Written with Csound 5.12.1 (http://www.csounds.com)
; and QuteCsound 0.6.0 (http://qutecsound.sourceforge.net/).
;
; To use, open in QuteCsound, make sure the Widgets window
; is open, and click the Start button.  Then use On/Off
; buttons to play or stop the drones.
;
; version 2.8 (xx-Oct-2010)
;	- option to record session as WAV file
;	- use vco2 for higher-quality saw, square, and (new) triangle waves;
;	  still using poscil3 for other waves (factored sound-producing code
;	  into a new UDO called "ogen")
; version 2.7 (09-Oct-2010)
;	- always play primary oscillator for each tone, independent of
;	  harmonic arpeggio or binaural beat output
;	- made all pitch controls (Ratio, 8ve, and Base) changeable in realtime
;	- add option to tune base frequency to conventional (Western) pitches,
;	  using pitch-class or note name 
; version 2.6 (26-Sep-2010)
;	- add level control for Risset effect (now labeled Harmonic Arpeggio);
;	  this allows the use of binaural beating by itself
;	- line up all effects horizontally
;	- use SpinBox for Harmonic Arpeggio Offset and Binaural Beats BPS, for
;	  finer control
;	- normalize level controls to use 0.0-1.0 range
;	- change multiplier for BB level from 5x to 4x, seems to match HA level better
;	- layout tweakage
; version 2.5 (12-Sep-2010)
;	- add precision to the base freq. per David First
; version 2.4 (12-Sep-2010)
;	- bugfix from Mark Van Peteghem in the binauralize UDO
; version 2.3 (10-Sep-2010)
;	- fixes from Andres
; version 2.2 (09-Sep-2010)
;	- binaural beat and reverb controls
;	- make Risset offset realtime
; version 2.1 (06-Sep-2010)
;	- fixed release on turnoff
;	- better "on" indicators fron joachim
;	- added binaural beating effect
; version 2.0 (06-Sep-2010)
;	- rewrite for QuteCsound
;
; Copyright 2005,2010, Dave Seidel. Some rights reserved.
; This work is licensed under a Creative Commons
; Attribution-Noncommercial 3.0 Unported License:
; http://creativecommons.org/licenses/by-nc/3.0/
;-------------------------------------------------------------------------


<CsoundSynthesizer>


<CsOptions>

;-odac:plughw:1,0
-odac -m8 -d

</CsOptions>


</CsOptions>


<CsHtml5>

<!DOCTYPE html>
<html>

<head>
  <title>SrutiDroneAndroid (nexusUI)</title>
  <script src="jquery-2.1.1.js"></script>
  <script src="nexusUI.js"></script>
  <script src="nexusUI-cs6.js"></script>
  <script>

    nx.onload = function() {
      cs6.init();

			base_freq.set(240);
			select_waveform.set({text: "Sine"});

      num_1.set(1);
      den_1.set(1);
      oct_1.set(0);
      vol_1.set({value: 0});
      vol_1.hslider = true;
      vol_1.mode = "relative";

      num_2.set(3);
      den_2.set(2);
      oct_2.set(0);
      vol_2.set({value: 0});
      vol_2.hslider = true;
      vol_2.mode = "relative";

      num_3.set(7);
      den_3.set(4);
      oct_3.set(0);
      vol_3.set({value: 0});
      vol_3.hslider = true;
      vol_3.mode = "relative";

      num_4.set(9);
      den_4.set(8);
      oct_4.set(1);
      vol_4.set({value: 0});
      vol_4.hslider = true;
      vol_4.mode = "relative";
    };

  </script>
</head>

<body>

	<div id="drone1">
		<canvas nx="number" id="num_1"></canvas>
		<canvas nx="number" id="den_1"></canvas>
		<canvas nx="number" id="oct_1"></canvas>
		<canvas nx="slider" id="vol_1" height="20" width="200"></canvas>
	</div>

	<div id="drone2">
		<canvas nx="number" id="num_2"></canvas>
		<canvas nx="number" id="den_2"></canvas>
		<canvas nx="number" id="oct_2"></canvas>
		<canvas nx="slider" id="vol_2" height="20" width="200"></canvas>
	</div>

	<div id="drone3">
		<canvas nx="number" id="num_3"></canvas>
		<canvas nx="number" id="den_3"></canvas>
		<canvas nx="number" id="oct_3"></canvas>
		<canvas nx="slider" id="vol_3" height="20" width="200"></canvas>
	</div>

	<div id="drone4">
		<canvas nx="number" id="num_4"></canvas>
		<canvas nx="number" id="den_4"></canvas>
		<canvas nx="number" id="oct_4"></canvas>
		<canvas nx="slider" id="vol_4" hslider="true" height="20" width="200"></canvas>
	</div>

	<div id="globals">
		<canvas nx="number" id="base_freq" value="120.0"></canvas>
		<canvas nx="select" id="select_waveform" choices="Sine,Saw,Square,Triangle,Prime,Fibonacci,Aymptotic Saw"></canvas>
	</div>

	<script>
		(function() {
			var score = [
		    'i 101 0 3600',
		    'i 102 0 3600',
		    'i 103 0 3600',
		    'i 104 0 3600'
			];
			  
		  csound.inputMessage(score.join('\n'));
		})();
	</script>

</body>
</html>

</CsHtml5>


<CsInstruments>

;-------------------------------------------------------------------------
; globals
;-------------------------------------------------------------------------

sr     = 22050
ksmps  = 100
nchnls = 2
0dbfs  = 1

;-------------------------------------------------------------------------
; global channels
;-------------------------------------------------------------------------

gaL1		init 0
gaR1		init 0
gaL2		init 0
gaR2		init 0
gaL3		init 0
gaR3		init 0
gaL4		init 0
gaR4		init 0

;-------------------------------------------------------------------------
; basic offset value for Risset effect
;-------------------------------------------------------------------------

giofs   	init		.01

;-------------------------------------------------------------------------
; multipler for binaural beat level
;-------------------------------------------------------------------------

gibblvl	init    	4

;-------------------------------------------------------------------------
; FFT size for pvsanal
;-------------------------------------------------------------------------

gifftsz	init		2048

;-------------------------------------------------------------------------
; initialize globals for values from UI
;-------------------------------------------------------------------------

gktbl init 0
gkbase init 0

gknum1	 init 0
gkden1 init 0
gk8ve1 init 0
gkamp1 init 0
gkbase1 init 0

; d2
gknum2	 init 0
gkden2	 init 0
gk8ve2 init 0
gkamp2 init 0
gkbase2	init 0

; d3
gknum3	 init 0
gkden3	 init 0
gk8ve3 init 0
gkamp3 init 0
gkbase3 init 0

; d4
gknum4	 init 0
gkden4 init 0
gk8ve4 init 0
gkamp4 init 0
gkbase4 	init 0

; risset arpeggio
gkrisofs	 init 0
gkrismix init 0

; binaural beats
gkbbmix  init 0
gkbbrate init 0

; output file
gSfile init ""

;---------------------------------------------------------------------------
; orchestra macros
;---------------------------------------------------------------------------

; base pitch in specified octave above base
#define BOCT(B'O) #$B.*(2^($O.))#

;---------------------------------------------------------------------------
; ogen macros
;---------------------------------------------------------------------------

; vco2 waveforms
#define	OGEN_VCO2		#0#
#define	OGEN_SAW		#$OGEN_VCO2+0#
#define	OGEN_SQUARE	#$OGEN_VCO2+10#
#define	OGEN_TRIANGLE	#$OGEN_VCO2+12#
; poscil3 waveforms
#define	OGEN_POSC		#100#
#define	OGEN_SINE		#$OGEN_POSC+0#
#define	OGEN_PRIME	#$OGEN_POSC+1#
#define	OGEN_FIB		#$OGEN_POSC+2#
#define	OGEN_ASYMP	#$OGEN_POSC+3#

;---------------------------------------------------------------------------
; polymorphous oscillator
; in:	iwaveform,kenvelope,kfrequency
; out:	asignal
;---------------------------------------------------------------------------

	opcode ogen, a, kki
	
kenv,kfreq,iwave	xin

	;print iwave

itabsz	init		1048576
asig 	init		0

		; sine wave
iSine	ftgenonce	$OGEN_SINE,	0, itabsz, 10, 1
		; prime wave
iPrime	ftgenonce	$OGEN_PRIME,	0, itabsz, 9,  1,1,0,  2,.5,0,  3,.3333,0,  5,.2,0,    7,.143,0,  11,.0909,0,  13,.077,0,   17,.0588,0,  19,.0526,0, 23,.0435,0, 27,.037,0
		; Fibonacci wave
iFib		ftgenonce	$OGEN_FIB,	0, itabsz, 9,  1,1,0,   2,.5,0,   3,.3333,0,  5,.2,0,   8,.125,0,  13,.0769,0,  21,.0476,0,  34,.0294,0,  55,.0182,0,  89,.0112,0, 144,.0069,0
		; David First's asymptotic sawtooth wave
iAsymp	ftgenonce	$OGEN_ASYMP,	0, itabsz, 9,  1,1,0,   1.732050807568877,.5773502691896259,0,   2.449489742783178,.408248290463863,0,   3.162277660168379,.3162277660168379,0,   3.872983346207417,.2581988897471611,0,   4.58257569495584,.2182178902359924,0,   5.291502622129182,.1889822365046136,0, 6,.1666666666666667,0,   6.70820393249937,.1490711984999859,0,   7.416198487095663,.1348399724926484,0,   8.124038404635961,.1230914909793327,0,   9.539392014169456,.1048284836721918,0,  10.2469507659596,.0975900072948533,0,  10.95445115010332,.0912870929175277,0,   11.6619037896906,.0857492925712544,0

	if (iwave >= $OGEN_POSC) then
asig		poscil3	kenv, kfreq, iwave
	else
asig		vco2		kenv, kfreq, iwave
	endif

		xout	asig
	
	endop

;---------------------------------------------------------------------------------------
; panner
;---------------------------------------------------------------------------------------

	opcode pan_equal_power, aa, ak
ain, kpan	xin
kangl	= 	1.57079633 * (kpan + 0.5)
		xout	ain * sin(kangl), ain * cos(kangl)
	endop

;---------------------------------------------------------------------------
; make binaural beats
;---------------------------------------------------------------------------

	opcode binauralize, aa, akk

; collect inputs
ain,kcent,kdiff	xin

; determine pitches
kp1		=		kcent + (kdiff/2)
kp2		=		kcent - (kdiff/2)
krat1	=		kp1 / kcent
krat2	=		kp2 / kcent

; take it apart
fsig		pvsanal	ain, gifftsz, gifftsz/4, gifftsz, 1

; create derived streams
fbinL	pvscale	fsig, krat1, 1
fbinR	pvscale	fsig, krat2, 1

; put it back together
abinL	pvsynth	fbinL
abinR	pvsynth	fbinR

; send it out
		xout	abinL, abinR

	endop
	
;---------------------------------------------------------------------------
; chnget with default
;---------------------------------------------------------------------------

opcode cget, k, Sk
	Snam,kdef xin
	kval chnget Snam
	if kval == 0 then
		;printf "%s: using default (%f)\n", kval, Snam, kdef	
		kval = kdef
		chnset kval, Snam
	else
	  ;printf "%s: %f\n", kval, Snam, kval
	endif
	xout kval
endop

opcode cgets, S, SS
	Snam,Sdef xin
	Sval chnget Snam
	kchk strcmpk Sval, ""
	if kchk == 0 then
		;printf "%s: using default (%f)\n", Sval, Snam, kdef	
		Sval = Sdef
		chnset Sval, Snam
	else
	  ;printf "%s: %f\n", kval, Snam, Sval
	endif
	xout Sval
endop

;---------------------------------------------------------------------------
; oscillators with optional Risset harmonic arpeggio and binaural beating
;---------------------------------------------------------------------------

;	instr 100

opcode drone, aa, i
	iinst xin

	iamp	  = ampdb(-15)/9
	ipan		= 0.0
	itbl		= i(gktbl)
	
	print itbl
	print iinst
	;printks2 "iinst = %f\n", iinst
	
	if (iinst == 1) then
	  knum		= gknum1
	  kden		= gkden1
	  kbase	= gkbase1
	elseif (iinst == 2) then
	  knum		= gknum2
	  kden		= gkden2
	  kbase	= gkbase2
	elseif (iinst == 3) then
	  knum		= gknum3
	  kden		= gkden3
	  kbase	= gkbase3
	elseif (iinst == 4) then
	  knum		= gknum4
	  kden		= gkden4
	  kbase	= gkbase4
	endif
	
	; determine pitch
	kfrac	=		knum/kden
	kfreq	=		kbase*kfrac
	
	; set up Risset effect
	koff		=   gkrisofs
	koff0	=		((kden*2)/knum)*koff		; inversely proportional to ratio
	koff1	=		koff0					; oscillator offset for arpeggio
	koff2	=		2*koff					; .
	koff3	=		3*koff					; .
	koff4	=		4*koff					; .
	
	; envelope
	kenv		linenr iamp, 2, 3, 0.01			; env needs release segment for turnoff2
	
	; generate primary tone
	a1		ogen		kenv, kfreq, itbl
	
	; generate Risset tones
	a2		ogen		kenv, kfreq+koff1, itbl		; nine oscillators with the same envelope
	a3		ogen		kenv, kfreq+koff2, itbl		; and waveform, but slightly different
	a4		ogen		kenv, kfreq+koff3, itbl		; frequencies, create harmonic arpeggio
	a5		ogen		kenv, kfreq+koff4, itbl
	a6		ogen		kenv, kfreq-koff1, itbl
	a7		ogen		kenv, kfreq-koff2, itbl
	a8		ogen		kenv, kfreq-koff3, itbl
	a9		ogen		kenv, kfreq-koff4, itbl
	
	; create simple output (just the primary oscillator)
	a1L,a1R pan_equal_power a1, ipan
	
	; create Risset output
	aout		sum		a2, a3, a4, a5, a6, a7, a8, a9
	a2L,a2R	pan_equal_power	aout*gkrismix, ipan
	
	; create binaural beating output
	a3L,a3R	binauralize	a1*(gkbbmix*gibblvl), kfreq, gkbbrate
	
	; combine and send to global output channels
	aoutL = a1L+a2L+a3L
	aoutR = a1R+a2R+a3R
	
	xout aoutL, aoutR
endop

instr 101
	;printks2 "gkamp1 = %f\n", gkamp1
	aL, aR drone 1
	gaL1 = (gaL1+aL)
	gaR1 = (gaL1+aR)
	
endin

instr 102
	;printks2 "gkamp2 = %f\n", gkamp2
	aL, aR drone 2
	gaL2 = (gaL2+aL)
	gaR2 = (gaL2+aR)
endin

instr 103
	;printks2 "gkamp3 = %f\n", gkamp3
	aL, aR drone 3
	gaL3 = (gaL3+aL)
	gaR3 = (gaL3+aR)
endin

instr 104
	;printks2 "gkamp4 = %f\n", gkamp4
	aL, aR drone 4
	gaL4 = (gaL4+aL)
	gaR4 = (gaL4+aR)
endin

;---------------------------------------------------------------------------
; write output to a file
;---------------------------------------------------------------------------

	instr FileOutput
	
if (strlen(gSfile) == 0) then
  ; if no filename given, exit
  turnoff
else
  aL, aR monitor
  fout gSfile, 2, aL, aR
endif

	endin

;---------------------------------------------------------------------------
; get/set base pitch and waveform
;---------------------------------------------------------------------------

	instr ControlLoop

	; base pitch
;	knotes chnget "cb_use_notes"
;	if (knotes == 0) then
; tuning by cycles per second
gkbase cget "base_freq", 240
;koct   =	  octcps(kbase0)
;kpch	   =	  pchoct(koct)
;kpch_i =	  int(kpch)
;kpch_f =	  frac(kpch)
;		chnset  kpch_i, "base_pch_int"
;		chnset  kpch_f, "base_pch_frac"
;	else
;	; tuning by pitch-class
;kpch_i	chnget	"base_pch_int"
;kpch_f	chnget	"base_pch_frac"
;kbase0	=		cpspch(kpch_i+(kpch_f/100))
;		chnset  kbase0, "base_freq"
;	endif

; waveform
ktbl cget "select_waveform", 0
if (ktbl == 0) then
  gktbl	=	$OGEN_SINE
elseif (ktbl == 1) then
  gktbl	=	$OGEN_SAW
elseif (ktbl == 2) then
  gktbl	=	$OGEN_SQUARE
elseif (ktbl == 3) then
  gktbl	=	$OGEN_TRIANGLE
elseif (ktbl == 4) then
  gktbl	=	$OGEN_PRIME
elseif (ktbl == 5) then
  gktbl	=	$OGEN_FIB
elseif (ktbl == 6) then
  gktbl	=	$OGEN_ASYMP
endif

; d1
gknum1	 cget "num_1", 1
gkden1 cget "den_1", 1
gk8ve1 cget "oct_1", 0
gkamp1 cget "vol_1", 0
gkbase1 = $BOCT.(gkbase'gk8ve1)

; d2
gknum2	 cget "nun_2", 3
gkden2	 cget "den_2", 2
gk8ve2 cget "oct_2", 0
gkamp2 cget "vol_2", 0
gkbase2	= $BOCT.(gkbase'gk8ve2)

; d3
gknum3	 cget "num_3", 7
gkden3	 cget "den_3", 4
gk8ve3 cget "oct_3", 0
gkamp3 cget "vol_3", 0
gkbase3 = $BOCT.(gkbase'gk8ve3)

; d4
gknum4	 cget "num_4", 9
gkden4 cget "den_4", 8
gk8ve4 cget "oct_4", 1
gkamp4 cget "vol_4", 0
gkbase4 	= $BOCT.(gkbase'gk8ve4)

; risset arpeggio
gkrisofs	 cget "risset_offset", 0.005
gkrismix cget "risset_mix", 0.25

; binaural beats
gkbbmix cget "bb_mix", 0.25
gkbbrate cget "bb_rate", 0.3

gkfb cget "reverb_feedback", 0.75
gkwet cget "reverb_level", 0.5

gSfile chnget "rec_filename"

	endin

;---------------------------------------------------------------------------
; global output instrument with optional reverb
;---------------------------------------------------------------------------

	instr SoundOutput
	
aL = (gaL1*gkamp1) + (gaL2*gkamp2) +(gaL3*gkamp3) + (gaL4*gkamp4)
aR = (gaR1*gkamp1) + (gaR2*gkamp2) +(gaR3*gkamp3) + (gaR4*gkamp4)

aLrv, aRrv reverbsc	aL, aR, gkfb, p4, sr/1.5, p5, 0
aoutL 	= (aL * gkwet) + (aLrv * (1 - gkwet))
aoutR 	= (aR * gkwet) + (aRrv * (1 - gkwet))
outs aL+aoutL, aR+aoutR

gaL1 = 0
gaR1 = 0
gaL2 = 0
gaR2 = 0
gaL3 = 0
gaR3 = 0
gaL4 = 0
gaR4 = 0
	
	endin
	
alwayson "ControlLoop"
alwayson "SoundOutput", 4000, 0.5
;alwayson "FileOutput"

</CsInstruments>


<CsScore>
</CsScore>


</CsoundSynthesizer>


<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>755</x>
 <y>72</y>
 <width>611</width>
 <height>603</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>85</r>
  <g>170</g>
  <b>127</b>
 </bgcolor>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>60</y>
  <width>55</width>
  <height>25</height>
  <uuid>{e207fe11-0cdd-444e-930d-29bf13c11fb2}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Drone 1</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>n_1</objectName>
  <x>70</x>
  <y>60</y>
  <width>48</width>
  <height>25</height>
  <uuid>{69bad91e-0026-4238-862e-12c143685397}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>118</x>
  <y>60</y>
  <width>11</width>
  <height>25</height>
  <uuid>{dac04e90-40e6-4165-b183-03b8f10511e3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>:</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>d_1</objectName>
  <x>129</x>
  <y>60</y>
  <width>48</width>
  <height>25</height>
  <uuid>{ef99bd92-1c6f-45f9-a32a-303c366b3332}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>d_2</objectName>
  <x>129</x>
  <y>90</y>
  <width>48</width>
  <height>25</height>
  <uuid>{aabc2b30-dc79-43af-88df-b977177aa58e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>2</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>118</x>
  <y>90</y>
  <width>11</width>
  <height>25</height>
  <uuid>{c3be46e9-f371-406a-ac25-0e0e07ac5c5f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>:</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>n_2</objectName>
  <x>70</x>
  <y>90</y>
  <width>48</width>
  <height>25</height>
  <uuid>{c32d5493-922d-4709-9f5a-56985fbb0475}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>3</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>90</y>
  <width>55</width>
  <height>25</height>
  <uuid>{e92844b5-0073-4da6-8d9b-991e8b0b0499}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Drone 2</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>d_3</objectName>
  <x>129</x>
  <y>120</y>
  <width>48</width>
  <height>25</height>
  <uuid>{af1ed01f-25bf-4565-85f8-0448d63214d8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>4</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>118</x>
  <y>120</y>
  <width>11</width>
  <height>25</height>
  <uuid>{07939aa1-6316-462f-8be9-976d94429e3a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>:</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>n_3</objectName>
  <x>70</x>
  <y>120</y>
  <width>48</width>
  <height>25</height>
  <uuid>{8e26cac5-5faa-410e-b2c2-1342978a5366}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>7</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>120</y>
  <width>55</width>
  <height>25</height>
  <uuid>{4df54217-074b-4984-b37d-2f9c0bfeadcc}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Drone 3</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>150</y>
  <width>55</width>
  <height>25</height>
  <uuid>{0ee4b373-0ead-405e-8333-c73008d4fd11}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Drone 4</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>n_4</objectName>
  <x>70</x>
  <y>150</y>
  <width>48</width>
  <height>25</height>
  <uuid>{09f87a96-555a-445a-82bd-478afb7abfb5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>9</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>118</x>
  <y>150</y>
  <width>11</width>
  <height>25</height>
  <uuid>{f216eb31-db8e-4ec4-be43-5c9f0c1aa2a0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>:</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>d_4</objectName>
  <x>129</x>
  <y>150</y>
  <width>48</width>
  <height>25</height>
  <uuid>{756d7d97-b16b-4877-a1a2-1a4f05a4753f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>2048</maximum>
  <randomizable group="0">false</randomizable>
  <value>8</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>base_freq</objectName>
  <x>71</x>
  <y>195</y>
  <width>120</width>
  <height>25</height>
  <uuid>{983d831d-92f7-4f17-9b74-9dab7db7059f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>0.00100000</resolution>
  <minimum>1</minimum>
  <maximum>20000</maximum>
  <randomizable group="0">false</randomizable>
  <value>120</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>196</y>
  <width>65</width>
  <height>25</height>
  <uuid>{3505dfd5-a0ec-404f-8e71-ec9c3e53e7a6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Base (Hz)</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDropdown">
  <objectName>menu_waveform</objectName>
  <x>69</x>
  <y>239</y>
  <width>114</width>
  <height>30</height>
  <uuid>{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <bsbDropdownItemList>
   <bsbDropdownItem>
    <name>  Sine</name>
    <value>0</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name>  Saw</name>
    <value>1</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name>  Square</name>
    <value>2</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name>  Triangle</name>
    <value>3</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name>  Prime</name>
    <value>4</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name>  Fibonacci</name>
    <value>5</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name>  Asymptotic Saw</name>
    <value>6</value>
    <stringvalue/>
   </bsbDropdownItem>
  </bsbDropdownItemList>
  <selectedIndex>0</selectedIndex>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>242</y>
  <width>55</width>
  <height>25</height>
  <uuid>{d2a792b5-5a54-4a15-894b-ff3ddf0d8dbf}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Wave</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>389</x>
  <y>355</y>
  <width>67</width>
  <height>25</height>
  <uuid>{2438c973-bcba-42b8-88c3-7adcaed53eb1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Feedback</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>8ve_1</objectName>
  <x>205</x>
  <y>60</y>
  <width>35</width>
  <height>25</height>
  <uuid>{c398c0c6-f76b-464f-a86c-51e15765a9dd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>-6</minimum>
  <maximum>6</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>8ve_2</objectName>
  <x>205</x>
  <y>90</y>
  <width>35</width>
  <height>25</height>
  <uuid>{051c6d7f-a070-42a6-8a8e-710d1439c9f5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>-6</minimum>
  <maximum>6</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>8ve_3</objectName>
  <x>205</x>
  <y>120</y>
  <width>35</width>
  <height>25</height>
  <uuid>{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>-6</minimum>
  <maximum>6</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>8ve_4</objectName>
  <x>205</x>
  <y>150</y>
  <width>35</width>
  <height>25</height>
  <uuid>{7185c5c5-613c-4002-ad91-7d7351bf3e43}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>-6</minimum>
  <maximum>6</maximum>
  <randomizable group="0">false</randomizable>
  <value>2</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>99</x>
  <y>31</y>
  <width>50</width>
  <height>25</height>
  <uuid>{32c98c25-6b0c-44ae-8aab-66b7991a0c3c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Ratio</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>205</x>
  <y>31</y>
  <width>35</width>
  <height>25</height>
  <uuid>{b6aa167a-e0fb-495a-82bf-45a5ef1fabee}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>8ve</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>206</x>
  <y>433</y>
  <width>60</width>
  <height>25</height>
  <uuid>{f0263ce2-9501-41a2-b3ab-203447d7ec93}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>BPS</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>215</x>
  <y>356</y>
  <width>70</width>
  <height>25</height>
  <uuid>{4e5e56dd-ef75-421b-9168-48c7a3c2f396}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Level</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>bb_mix</objectName>
  <x>283</x>
  <y>324</y>
  <width>80</width>
  <height>80</height>
  <uuid>{0764d8d5-22a9-489d-8ae5-4e19e0567038}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.14000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>reverb_feedback</objectName>
  <x>456</x>
  <y>324</y>
  <width>80</width>
  <height>80</height>
  <uuid>{77d49f7c-db91-404a-bede-14601a37da3d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.13000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>68</x>
  <y>292</y>
  <width>130</width>
  <height>30</height>
  <uuid>{f20e492d-a935-480f-b37f-8bce3552de37}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Harmonic Arpeggio</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>2</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>395</x>
  <y>433</y>
  <width>42</width>
  <height>26</height>
  <uuid>{69b5965f-ef1f-449f-9e76-0f2c7ba86ae5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Wet</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBScrollNumber">
  <objectName>feedback_display</objectName>
  <x>456</x>
  <y>404</y>
  <width>80</width>
  <height>25</height>
  <uuid>{bbaf98ce-16fe-4bea-82db-1aa7909b40bd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <color>
   <r>0</r>
   <g>255</g>
   <b>0</b>
  </color>
  <bgcolor mode="background">
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
  <value>0.80000000</value>
  <resolution>0.00100000</resolution>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <bordermode>border</bordermode>
  <borderradius>3</borderradius>
  <borderwidth>1</borderwidth>
  <randomizable group="0">false</randomizable>
  <mouseControl act=""/>
 </bsbObject>
 <bsbObject version="2" type="BSBScrollNumber">
  <objectName>bb_mix</objectName>
  <x>283</x>
  <y>404</y>
  <width>80</width>
  <height>25</height>
  <uuid>{78afa9a1-f836-4547-8d80-81486db02073}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <color>
   <r>0</r>
   <g>255</g>
   <b>0</b>
  </color>
  <bgcolor mode="background">
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
  <value>0.00000000</value>
  <resolution>0.01000000</resolution>
  <minimum>0.00000000</minimum>
  <maximum>5.00000000</maximum>
  <bordermode>border</bordermode>
  <borderradius>3</borderradius>
  <borderwidth>1</borderwidth>
  <randomizable group="0">false</randomizable>
  <mouseControl act=""/>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>reverb_level</objectName>
  <x>434</x>
  <y>433</y>
  <width>120</width>
  <height>25</height>
  <uuid>{4e72262c-67a7-4b25-b963-2cbae66d3ebd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.55000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>554</x>
  <y>433</y>
  <width>46</width>
  <height>27</height>
  <uuid>{f703a53a-5a85-4f19-8c0d-6d391fde0794}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Dry</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>bb_rate</objectName>
  <x>264</x>
  <y>433</y>
  <width>120</width>
  <height>25</height>
  <uuid>{5973dd8b-43a5-4e78-9fa9-19ff5ea90107}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>50.00000000</maximum>
  <value>2.50000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>risset_offset</objectName>
  <x>80</x>
  <y>433</y>
  <width>130</width>
  <height>25</height>
  <uuid>{5d4975a8-7006-449c-8c23-6d3b3dfa80f7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.03000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>268</x>
  <y>292</y>
  <width>102</width>
  <height>30</height>
  <uuid>{72bb78eb-c17b-444d-ab8c-458b1edf0e7d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Binaural Beats</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>2</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>465</x>
  <y>292</y>
  <width>60</width>
  <height>30</height>
  <uuid>{53253bed-f55d-4864-ab60-d4b0906df846}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Reverb</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>2</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>70</x>
  <y>3</y>
  <width>270</width>
  <height>25</height>
  <uuid>{6c37ef1c-719c-4f0b-915d-c8bb75376e39}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Sruti/Drone Box 2.8 - Dave Seidel &lt;mysterybear.net/></label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>11</fontsize>
  <precision>3</precision>
  <color>
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </color>
  <bgcolor mode="background">
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>risset_offset</objectName>
  <x>99</x>
  <y>460</y>
  <width>90</width>
  <height>25</height>
  <uuid>{f82caad1-7fd6-447a-98af-1416902075f6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>0.01000000</resolution>
  <minimum>0</minimum>
  <maximum>1</maximum>
  <randomizable group="0">false</randomizable>
  <value>0.03</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>bb_rate</objectName>
  <x>278</x>
  <y>460</y>
  <width>95</width>
  <height>25</height>
  <uuid>{e8c0a39e-2286-4754-bcd1-e6799ba36fa2}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>0.00100000</resolution>
  <minimum>0</minimum>
  <maximum>50</maximum>
  <randomizable group="0">false</randomizable>
  <value>2.5</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>21</x>
  <y>433</y>
  <width>60</width>
  <height>25</height>
  <uuid>{8e757ace-4ed5-4de8-b95f-c9fcba0f68d9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Offset</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBScrollNumber">
  <objectName>risset_mix</objectName>
  <x>96</x>
  <y>404</y>
  <width>80</width>
  <height>25</height>
  <uuid>{50511459-bbcd-4f22-8b93-4eb9cea421d9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <color>
   <r>0</r>
   <g>255</g>
   <b>0</b>
  </color>
  <bgcolor mode="background">
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
  <value>0.00000000</value>
  <resolution>0.01000000</resolution>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <bordermode>border</bordermode>
  <borderradius>3</borderradius>
  <borderwidth>1</borderwidth>
  <randomizable group="0">false</randomizable>
  <mouseControl act=""/>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>risset_mix</objectName>
  <x>96</x>
  <y>324</y>
  <width>80</width>
  <height>80</height>
  <uuid>{0740fcea-a7ec-4b55-b483-daf2f0f87e40}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.49000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>28</x>
  <y>357</y>
  <width>70</width>
  <height>25</height>
  <uuid>{3ab28aff-4bce-4d36-ba26-65c92ebe6b8e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Level</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>base_pch_int</objectName>
  <x>278</x>
  <y>195</y>
  <width>40</width>
  <height>25</height>
  <uuid>{f234e643-9206-45d2-90cc-21903a1a0b08}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>9</maximum>
  <randomizable group="0">false</randomizable>
  <value>4</value>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>base_pch_frac</objectName>
  <x>327</x>
  <y>195</y>
  <width>40</width>
  <height>25</height>
  <uuid>{53ac49f4-196e-48d5-817c-dac614e8d692}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>0</minimum>
  <maximum>11</maximum>
  <randomizable group="0">false</randomizable>
  <value>11</value>
 </bsbObject>
 <bsbObject version="2" type="BSBDropdown">
  <objectName>base_pch_frac</objectName>
  <x>373</x>
  <y>195</y>
  <width>43</width>
  <height>25</height>
  <uuid>{0f0d344d-e4ed-48c9-a710-9b2e2d5533c4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <bsbDropdownItemList>
   <bsbDropdownItem>
    <name> C</name>
    <value>0</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> C#</name>
    <value>1</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> D</name>
    <value>2</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> D#</name>
    <value>3</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> E</name>
    <value>4</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> F</name>
    <value>5</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> F#</name>
    <value>6</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> G</name>
    <value>7</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> G#</name>
    <value>8</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> A</name>
    <value>9</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> A#</name>
    <value>10</value>
    <stringvalue/>
   </bsbDropdownItem>
   <bsbDropdownItem>
    <name> B</name>
    <value>11</value>
    <stringvalue/>
   </bsbDropdownItem>
  </bsbDropdownItemList>
  <selectedIndex>11</selectedIndex>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBCheckBox">
  <objectName>cb_use_notes</objectName>
  <x>253</x>
  <y>198</y>
  <width>20</width>
  <height>20</height>
  <uuid>{e14b7297-ea7c-42dd-9a08-e62468e528ad}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <selected>false</selected>
  <label/>
  <pressedValue>1</pressedValue>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>188</x>
  <y>195</y>
  <width>67</width>
  <height>25</height>
  <uuid>{05a8ce7a-1422-45f1-846a-93ef4493186f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Notes</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>316</x>
  <y>195</y>
  <width>11</width>
  <height>25</height>
  <uuid>{1e42d19e-eb6d-48ef-a29a-3392d8b898c3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>.</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>13</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLineEdit">
  <objectName>rec_filename</objectName>
  <x>400</x>
  <y>526</y>
  <width>160</width>
  <height>25</height>
  <uuid>{223cd9b0-5674-42e6-9bb6-c90a3c766194}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>220</r>
   <g>218</g>
   <b>213</b>
  </bgcolor>
  <background>nobackground</background>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>304</x>
  <y>520</y>
  <width>90</width>
  <height>40</height>
  <uuid>{263cced0-0082-4cde-ade7-b0c65c6fde17}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Output file
(blank for none)</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>v_1</objectName>
  <x>269</x>
  <y>62</y>
  <width>200</width>
  <height>20</height>
  <uuid>{d6fa9204-10f6-450e-9bd9-162d1893831e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>v_2</objectName>
  <x>269</x>
  <y>94</y>
  <width>200</width>
  <height>20</height>
  <uuid>{894040fa-2abc-45cc-89eb-af79e8706f30}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.65000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>v_3</objectName>
  <x>268</x>
  <y>124</y>
  <width>200</width>
  <height>20</height>
  <uuid>{3df5cb6f-2644-4a87-bccf-4a14b8bc40a6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.51000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>v_4</objectName>
  <x>269</x>
  <y>154</y>
  <width>200</width>
  <height>20</height>
  <uuid>{e5de4bff-313a-424c-aba8-71709beff550}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.19000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
</bsbPanel>
<bsbPresets>
<preset name="magic (not lmy)" number="0" >
<value id="{69bad91e-0026-4238-862e-12c143685397}" mode="1" >4.00000000</value>
<value id="{ef99bd92-1c6f-45f9-a32a-303c366b3332}" mode="1" >3.00000000</value>
<value id="{aabc2b30-dc79-43af-88df-b977177aa58e}" mode="1" >2.00000000</value>
<value id="{c32d5493-922d-4709-9f5a-56985fbb0475}" mode="1" >3.00000000</value>
<value id="{af1ed01f-25bf-4565-85f8-0448d63214d8}" mode="1" >8.00000000</value>
<value id="{8e26cac5-5faa-410e-b2c2-1342978a5366}" mode="1" >9.00000000</value>
<value id="{09f87a96-555a-445a-82bd-478afb7abfb5}" mode="1" >6.00000000</value>
<value id="{756d7d97-b16b-4877-a1a2-1a4f05a4753f}" mode="1" >5.00000000</value>
<value id="{2f45e5ba-8d31-47a1-abfd-284ee246c74d}" mode="4" >0</value>
<value id="{8cfc7c9f-c14b-4e0a-969e-8c73d0e76eca}" mode="4" >0</value>
<value id="{983d831d-92f7-4f17-9b74-9dab7db7059f}" mode="1" >60.00000000</value>
<value id="{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}" mode="1" >5.00000000</value>
<value id="{c398c0c6-f76b-464f-a86c-51e15765a9dd}" mode="1" >2.00000000</value>
<value id="{051c6d7f-a070-42a6-8a8e-710d1439c9f5}" mode="1" >1.00000000</value>
<value id="{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}" mode="1" >2.00000000</value>
<value id="{7185c5c5-613c-4002-ad91-7d7351bf3e43}" mode="1" >1.00000000</value>
<value id="{0597468a-539e-46ff-ac9e-d27938ee4929}" mode="4" >0</value>
<value id="{11e96f5c-80dd-4079-b41d-d64a0a0eeaf4}" mode="4" >0</value>
<value id="{92247f2b-7cb0-4ba8-bc03-03361e1a10bd}" mode="4" >0</value>
<value id="{2dcc0403-16c4-45e2-9427-3b5b46f1e84b}" mode="4" >0</value>
<value id="{08fb344f-e380-40a0-abd0-26225f0d1532}" mode="4" >0</value>
<value id="{c5b5e85b-86f3-45db-abf9-2399bda7e100}" mode="4" >0</value>
<value id="{f0946452-bea5-454b-876c-ec1571771c49}" mode="4" >0</value>
<value id="{c5a7748a-5eda-4033-9d22-aba27d00482a}" mode="4" >0</value>
<value id="{0764d8d5-22a9-489d-8ae5-4e19e0567038}" mode="1" >2.54999995</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="1" >0.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="2" >0.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="1" >0.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="2" >0.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="1" >0.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="2" >0.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="1" >0.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="2" >0.00000000</value>
<value id="{77d49f7c-db91-404a-bede-14601a37da3d}" mode="1" >0.86000001</value>
<value id="{bbaf98ce-16fe-4bea-82db-1aa7909b40bd}" mode="1" >0.86000001</value>
<value id="{78afa9a1-f836-4547-8d80-81486db02073}" mode="1" >1.25000000</value>
<value id="{4e72262c-67a7-4b25-b963-2cbae66d3ebd}" mode="1" >0.52499998</value>
<value id="{5973dd8b-43a5-4e78-9fa9-19ff5ea90107}" mode="1" >3.33333325</value>
<value id="{c4670c9c-b87f-421c-948a-dba5ad97fd56}" mode="1" >3.33333325</value>
<value id="{5d4975a8-7006-449c-8c23-6d3b3dfa80f7}" mode="1" >0.01000000</value>
<value id="{0c9e4c5b-29a1-4ebc-8a93-5dcfe792139d}" mode="1" >0.01000000</value>
</preset>
<preset name="magic2 (not lmy)" number="1" >
<value id="{69bad91e-0026-4238-862e-12c143685397}" mode="1" >4.00000000</value>
<value id="{ef99bd92-1c6f-45f9-a32a-303c366b3332}" mode="1" >3.00000000</value>
<value id="{aabc2b30-dc79-43af-88df-b977177aa58e}" mode="1" >2.00000000</value>
<value id="{c32d5493-922d-4709-9f5a-56985fbb0475}" mode="1" >3.00000000</value>
<value id="{af1ed01f-25bf-4565-85f8-0448d63214d8}" mode="1" >8.00000000</value>
<value id="{8e26cac5-5faa-410e-b2c2-1342978a5366}" mode="1" >9.00000000</value>
<value id="{09f87a96-555a-445a-82bd-478afb7abfb5}" mode="1" >6.00000000</value>
<value id="{756d7d97-b16b-4877-a1a2-1a4f05a4753f}" mode="1" >5.00000000</value>
<value id="{2f45e5ba-8d31-47a1-abfd-284ee246c74d}" mode="4" >0</value>
<value id="{8cfc7c9f-c14b-4e0a-969e-8c73d0e76eca}" mode="4" >0</value>
<value id="{983d831d-92f7-4f17-9b74-9dab7db7059f}" mode="1" >60.00000000</value>
<value id="{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}" mode="1" >7.00000000</value>
<value id="{6e17afd2-2660-4517-809c-b8fccf81954e}" mode="1" >1.00000000</value>
<value id="{83621e9a-ebdd-48e3-9c0a-5119a5b774ff}" mode="1" >1.00000000</value>
<value id="{c398c0c6-f76b-464f-a86c-51e15765a9dd}" mode="1" >2.00000000</value>
<value id="{051c6d7f-a070-42a6-8a8e-710d1439c9f5}" mode="1" >1.00000000</value>
<value id="{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}" mode="1" >2.00000000</value>
<value id="{7185c5c5-613c-4002-ad91-7d7351bf3e43}" mode="1" >1.00000000</value>
<value id="{0597468a-539e-46ff-ac9e-d27938ee4929}" mode="4" >0</value>
<value id="{11e96f5c-80dd-4079-b41d-d64a0a0eeaf4}" mode="4" >0</value>
<value id="{92247f2b-7cb0-4ba8-bc03-03361e1a10bd}" mode="4" >0</value>
<value id="{2dcc0403-16c4-45e2-9427-3b5b46f1e84b}" mode="4" >0</value>
<value id="{08fb344f-e380-40a0-abd0-26225f0d1532}" mode="4" >0</value>
<value id="{c5b5e85b-86f3-45db-abf9-2399bda7e100}" mode="4" >0</value>
<value id="{f0946452-bea5-454b-876c-ec1571771c49}" mode="4" >0</value>
<value id="{c5a7748a-5eda-4033-9d22-aba27d00482a}" mode="4" >0</value>
<value id="{861629eb-54a7-4279-a1d6-bc80092e5de8}" mode="1" >0.00000000</value>
<value id="{861629eb-54a7-4279-a1d6-bc80092e5de8}" mode="4" >+</value>
<value id="{2e26c27e-6482-4c37-8af3-8311086124d2}" mode="1" >0.00000000</value>
<value id="{2e26c27e-6482-4c37-8af3-8311086124d2}" mode="4" >+</value>
<value id="{83b48281-b5e8-4069-885b-fb91b7001e50}" mode="1" >0.00000000</value>
<value id="{83b48281-b5e8-4069-885b-fb91b7001e50}" mode="4" >+</value>
<value id="{e536df3b-c63a-4442-a900-b896234ff6ce}" mode="1" >0.00000000</value>
<value id="{e536df3b-c63a-4442-a900-b896234ff6ce}" mode="4" >+</value>
<value id="{022a7091-793d-43a7-a49e-a31f8b76c14d}" mode="1" >1.87500000</value>
<value id="{0764d8d5-22a9-489d-8ae5-4e19e0567038}" mode="1" >2.54999995</value>
</preset>
<preset name="faery bells" number="2" >
<value id="{69bad91e-0026-4238-862e-12c143685397}" mode="1" >15.00000000</value>
<value id="{ef99bd92-1c6f-45f9-a32a-303c366b3332}" mode="1" >8.00000000</value>
<value id="{aabc2b30-dc79-43af-88df-b977177aa58e}" mode="1" >15.00000000</value>
<value id="{c32d5493-922d-4709-9f5a-56985fbb0475}" mode="1" >16.00000000</value>
<value id="{af1ed01f-25bf-4565-85f8-0448d63214d8}" mode="1" >1.00000000</value>
<value id="{8e26cac5-5faa-410e-b2c2-1342978a5366}" mode="1" >2.00000000</value>
<value id="{09f87a96-555a-445a-82bd-478afb7abfb5}" mode="1" >1.00000000</value>
<value id="{756d7d97-b16b-4877-a1a2-1a4f05a4753f}" mode="1" >1.00000000</value>
<value id="{2f45e5ba-8d31-47a1-abfd-284ee246c74d}" mode="4" >0</value>
<value id="{8cfc7c9f-c14b-4e0a-969e-8c73d0e76eca}" mode="4" >0</value>
<value id="{983d831d-92f7-4f17-9b74-9dab7db7059f}" mode="1" >60.00000000</value>
<value id="{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}" mode="1" >7.00000000</value>
<value id="{6e17afd2-2660-4517-809c-b8fccf81954e}" mode="1" >1.00000000</value>
<value id="{83621e9a-ebdd-48e3-9c0a-5119a5b774ff}" mode="1" >1.00000000</value>
<value id="{c398c0c6-f76b-464f-a86c-51e15765a9dd}" mode="1" >1.00000000</value>
<value id="{051c6d7f-a070-42a6-8a8e-710d1439c9f5}" mode="1" >2.00000000</value>
<value id="{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}" mode="1" >1.00000000</value>
<value id="{7185c5c5-613c-4002-ad91-7d7351bf3e43}" mode="1" >1.00000000</value>
<value id="{0597468a-539e-46ff-ac9e-d27938ee4929}" mode="4" >0</value>
<value id="{11e96f5c-80dd-4079-b41d-d64a0a0eeaf4}" mode="4" >0</value>
<value id="{92247f2b-7cb0-4ba8-bc03-03361e1a10bd}" mode="4" >0</value>
<value id="{2dcc0403-16c4-45e2-9427-3b5b46f1e84b}" mode="4" >0</value>
<value id="{08fb344f-e380-40a0-abd0-26225f0d1532}" mode="4" >0</value>
<value id="{c5b5e85b-86f3-45db-abf9-2399bda7e100}" mode="4" >0</value>
<value id="{f0946452-bea5-454b-876c-ec1571771c49}" mode="4" >0</value>
<value id="{c5a7748a-5eda-4033-9d22-aba27d00482a}" mode="4" >0</value>
<value id="{022a7091-793d-43a7-a49e-a31f8b76c14d}" mode="1" >1.87500000</value>
<value id="{0764d8d5-22a9-489d-8ae5-4e19e0567038}" mode="1" >4.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="1" >1.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="2" >1.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="1" >1.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="2" >1.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="1" >1.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="2" >1.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="1" >1.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="2" >1.00000000</value>
</preset>
<preset name="faery bells 2" number="3" >
<value id="{69bad91e-0026-4238-862e-12c143685397}" mode="1" >15.00000000</value>
<value id="{ef99bd92-1c6f-45f9-a32a-303c366b3332}" mode="1" >8.00000000</value>
<value id="{aabc2b30-dc79-43af-88df-b977177aa58e}" mode="1" >15.00000000</value>
<value id="{c32d5493-922d-4709-9f5a-56985fbb0475}" mode="1" >16.00000000</value>
<value id="{af1ed01f-25bf-4565-85f8-0448d63214d8}" mode="1" >1.00000000</value>
<value id="{8e26cac5-5faa-410e-b2c2-1342978a5366}" mode="1" >2.00000000</value>
<value id="{09f87a96-555a-445a-82bd-478afb7abfb5}" mode="1" >3.00000000</value>
<value id="{756d7d97-b16b-4877-a1a2-1a4f05a4753f}" mode="1" >2.00000000</value>
<value id="{2f45e5ba-8d31-47a1-abfd-284ee246c74d}" mode="4" >0</value>
<value id="{8cfc7c9f-c14b-4e0a-969e-8c73d0e76eca}" mode="4" >0</value>
<value id="{983d831d-92f7-4f17-9b74-9dab7db7059f}" mode="1" >60.00000000</value>
<value id="{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}" mode="1" >7.00000000</value>
<value id="{6e17afd2-2660-4517-809c-b8fccf81954e}" mode="1" >1.00000000</value>
<value id="{83621e9a-ebdd-48e3-9c0a-5119a5b774ff}" mode="1" >1.00000000</value>
<value id="{c398c0c6-f76b-464f-a86c-51e15765a9dd}" mode="1" >1.00000000</value>
<value id="{051c6d7f-a070-42a6-8a8e-710d1439c9f5}" mode="1" >2.00000000</value>
<value id="{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}" mode="1" >1.00000000</value>
<value id="{7185c5c5-613c-4002-ad91-7d7351bf3e43}" mode="1" >1.00000000</value>
<value id="{0597468a-539e-46ff-ac9e-d27938ee4929}" mode="4" >0</value>
<value id="{11e96f5c-80dd-4079-b41d-d64a0a0eeaf4}" mode="4" >0</value>
<value id="{92247f2b-7cb0-4ba8-bc03-03361e1a10bd}" mode="4" >0</value>
<value id="{2dcc0403-16c4-45e2-9427-3b5b46f1e84b}" mode="4" >0</value>
<value id="{08fb344f-e380-40a0-abd0-26225f0d1532}" mode="4" >0</value>
<value id="{c5b5e85b-86f3-45db-abf9-2399bda7e100}" mode="4" >0</value>
<value id="{f0946452-bea5-454b-876c-ec1571771c49}" mode="4" >0</value>
<value id="{c5a7748a-5eda-4033-9d22-aba27d00482a}" mode="4" >0</value>
<value id="{022a7091-793d-43a7-a49e-a31f8b76c14d}" mode="1" >1.87500000</value>
<value id="{0764d8d5-22a9-489d-8ae5-4e19e0567038}" mode="1" >4.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="1" >1.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="2" >1.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="1" >1.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="2" >1.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="1" >1.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="2" >1.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="1" >1.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="2" >1.00000000</value>
</preset>
<preset name="root-fourth-fifth-octave" number="4" >
<value id="{69bad91e-0026-4238-862e-12c143685397}" mode="1" >2.00000000</value>
<value id="{ef99bd92-1c6f-45f9-a32a-303c366b3332}" mode="1" >1.00000000</value>
<value id="{aabc2b30-dc79-43af-88df-b977177aa58e}" mode="1" >2.00000000</value>
<value id="{c32d5493-922d-4709-9f5a-56985fbb0475}" mode="1" >3.00000000</value>
<value id="{af1ed01f-25bf-4565-85f8-0448d63214d8}" mode="1" >3.00000000</value>
<value id="{8e26cac5-5faa-410e-b2c2-1342978a5366}" mode="1" >4.00000000</value>
<value id="{09f87a96-555a-445a-82bd-478afb7abfb5}" mode="1" >1.00000000</value>
<value id="{756d7d97-b16b-4877-a1a2-1a4f05a4753f}" mode="1" >1.00000000</value>
<value id="{2f45e5ba-8d31-47a1-abfd-284ee246c74d}" mode="4" >0</value>
<value id="{8cfc7c9f-c14b-4e0a-969e-8c73d0e76eca}" mode="4" >0</value>
<value id="{983d831d-92f7-4f17-9b74-9dab7db7059f}" mode="1" >60.00000000</value>
<value id="{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}" mode="1" >5.00000000</value>
<value id="{c398c0c6-f76b-464f-a86c-51e15765a9dd}" mode="1" >1.00000000</value>
<value id="{051c6d7f-a070-42a6-8a8e-710d1439c9f5}" mode="1" >1.00000000</value>
<value id="{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}" mode="1" >1.00000000</value>
<value id="{7185c5c5-613c-4002-ad91-7d7351bf3e43}" mode="1" >1.00000000</value>
<value id="{0597468a-539e-46ff-ac9e-d27938ee4929}" mode="4" >0</value>
<value id="{11e96f5c-80dd-4079-b41d-d64a0a0eeaf4}" mode="4" >0</value>
<value id="{92247f2b-7cb0-4ba8-bc03-03361e1a10bd}" mode="4" >0</value>
<value id="{2dcc0403-16c4-45e2-9427-3b5b46f1e84b}" mode="4" >0</value>
<value id="{08fb344f-e380-40a0-abd0-26225f0d1532}" mode="4" >0</value>
<value id="{c5b5e85b-86f3-45db-abf9-2399bda7e100}" mode="4" >0</value>
<value id="{f0946452-bea5-454b-876c-ec1571771c49}" mode="4" >0</value>
<value id="{c5a7748a-5eda-4033-9d22-aba27d00482a}" mode="4" >0</value>
<value id="{0764d8d5-22a9-489d-8ae5-4e19e0567038}" mode="1" >2.04999995</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="1" >0.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="2" >0.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="1" >0.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="2" >0.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="1" >0.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="2" >0.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="1" >0.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="2" >0.00000000</value>
<value id="{77d49f7c-db91-404a-bede-14601a37da3d}" mode="1" >0.86000001</value>
<value id="{bbaf98ce-16fe-4bea-82db-1aa7909b40bd}" mode="1" >0.86000001</value>
<value id="{78afa9a1-f836-4547-8d80-81486db02073}" mode="1" >2.04999995</value>
<value id="{4e72262c-67a7-4b25-b963-2cbae66d3ebd}" mode="1" >0.52499998</value>
<value id="{5973dd8b-43a5-4e78-9fa9-19ff5ea90107}" mode="1" >1.25000000</value>
<value id="{c4670c9c-b87f-421c-948a-dba5ad97fd56}" mode="1" >1.25000000</value>
<value id="{5d4975a8-7006-449c-8c23-6d3b3dfa80f7}" mode="1" >0.01000000</value>
<value id="{0c9e4c5b-29a1-4ebc-8a93-5dcfe792139d}" mode="1" >0.01000000</value>
</preset>
<preset name="root-fifth-seventh-ninth" number="5" >
<value id="{69bad91e-0026-4238-862e-12c143685397}" mode="1" >9.00000000</value>
<value id="{ef99bd92-1c6f-45f9-a32a-303c366b3332}" mode="1" >8.00000000</value>
<value id="{aabc2b30-dc79-43af-88df-b977177aa58e}" mode="1" >4.00000000</value>
<value id="{c32d5493-922d-4709-9f5a-56985fbb0475}" mode="1" >7.00000000</value>
<value id="{af1ed01f-25bf-4565-85f8-0448d63214d8}" mode="1" >2.00000000</value>
<value id="{8e26cac5-5faa-410e-b2c2-1342978a5366}" mode="1" >3.00000000</value>
<value id="{09f87a96-555a-445a-82bd-478afb7abfb5}" mode="1" >1.00000000</value>
<value id="{756d7d97-b16b-4877-a1a2-1a4f05a4753f}" mode="1" >1.00000000</value>
<value id="{2f45e5ba-8d31-47a1-abfd-284ee246c74d}" mode="4" >0</value>
<value id="{8cfc7c9f-c14b-4e0a-969e-8c73d0e76eca}" mode="4" >0</value>
<value id="{983d831d-92f7-4f17-9b74-9dab7db7059f}" mode="1" >60.00000000</value>
<value id="{5a9958a4-4a24-4c2e-8a93-9c900fc8b294}" mode="1" >5.00000000</value>
<value id="{c398c0c6-f76b-464f-a86c-51e15765a9dd}" mode="1" >2.00000000</value>
<value id="{051c6d7f-a070-42a6-8a8e-710d1439c9f5}" mode="1" >1.00000000</value>
<value id="{4e4f3e61-cb8d-49bd-94e4-92f77b8dda9f}" mode="1" >1.00000000</value>
<value id="{7185c5c5-613c-4002-ad91-7d7351bf3e43}" mode="1" >1.00000000</value>
<value id="{0597468a-539e-46ff-ac9e-d27938ee4929}" mode="4" >0</value>
<value id="{11e96f5c-80dd-4079-b41d-d64a0a0eeaf4}" mode="4" >0</value>
<value id="{92247f2b-7cb0-4ba8-bc03-03361e1a10bd}" mode="4" >0</value>
<value id="{2dcc0403-16c4-45e2-9427-3b5b46f1e84b}" mode="4" >0</value>
<value id="{08fb344f-e380-40a0-abd0-26225f0d1532}" mode="4" >0</value>
<value id="{c5b5e85b-86f3-45db-abf9-2399bda7e100}" mode="4" >0</value>
<value id="{f0946452-bea5-454b-876c-ec1571771c49}" mode="4" >0</value>
<value id="{c5a7748a-5eda-4033-9d22-aba27d00482a}" mode="4" >0</value>
<value id="{0764d8d5-22a9-489d-8ae5-4e19e0567038}" mode="1" >1.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="1" >1.00000000</value>
<value id="{bd87c226-5077-4660-84e1-f4dafbfff356}" mode="2" >1.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="1" >1.00000000</value>
<value id="{ab7d8f5b-2b2a-462c-8199-050ead18ba84}" mode="2" >1.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="1" >1.00000000</value>
<value id="{137d21e6-b6a2-4f9c-8495-111e5d44117e}" mode="2" >1.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="1" >1.00000000</value>
<value id="{e4e782ae-e528-42d0-a9f3-57081bddbc78}" mode="2" >1.00000000</value>
<value id="{77d49f7c-db91-404a-bede-14601a37da3d}" mode="1" >0.86000001</value>
<value id="{bbaf98ce-16fe-4bea-82db-1aa7909b40bd}" mode="1" >0.86000001</value>
<value id="{78afa9a1-f836-4547-8d80-81486db02073}" mode="1" >1.00000000</value>
<value id="{4e72262c-67a7-4b25-b963-2cbae66d3ebd}" mode="1" >0.52499998</value>
<value id="{5973dd8b-43a5-4e78-9fa9-19ff5ea90107}" mode="1" >1.25000000</value>
<value id="{5d4975a8-7006-449c-8c23-6d3b3dfa80f7}" mode="1" >0.02000000</value>
<value id="{f82caad1-7fd6-447a-98af-1416902075f6}" mode="1" >0.02000000</value>
<value id="{e8c0a39e-2286-4754-bcd1-e6799ba36fa2}" mode="1" >0.33333334</value>
<value id="{50511459-bbcd-4f22-8b93-4eb9cea421d9}" mode="1" >1.00000000</value>
<value id="{0740fcea-a7ec-4b55-b483-daf2f0f87e40}" mode="1" >1.00000000</value>
</preset>
</bsbPresets>
