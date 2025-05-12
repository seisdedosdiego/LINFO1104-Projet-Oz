% Auteur : Diego Seisdedos Stoz
% NOMA : 4659-23-00

functor
import
    Project2025
    OS
    System
    Property
export
    mix: Mix
define

	CWD = {Atom.toString {OS.getCWD}}#"/"

	SampleRate = 44100.0
	Pi = 3.141592653589793

	fun {Mix P2T Music}
		SLs = {Map Music fun {$ M} {MixOne P2T M} end}
	in
		{MapList {MergeLists SLs} fun {$ S}
			if S < ~1.0 then ~1.0 
			elseif S > 1.0 then 1.0 
			else S end
		end}
	end

	fun {MixOne P2T Part}
		case Part
		of samples(S) then S
		[] partition(P) then {Synth {P2T P}}
		[] wave(F) then {Project2025.readFile CWD#F}
		[] merge(ML) then {Merge P2T ML}
		[] repeat(amount:K subpart:M) then {Repeat K P2T M}
		[] loop(duration:D subpart:M) then {Loop D P2T M}
		[] clip(low:L high:H subpart:M) then {Clip L H P2T M}
		[] echo(delay:Del decay:Dec repeat:Rep subpart:M) then {Echo Del Dec Rep P2T M}
		[] fade(start:Start finish:Finish subpart:M) then {Fade Start Finish P2T M}
		[] cut(start:Start finish:Finish subpart:M) then {Cut Start Finish P2T M}
		[] _ then {Flatten [Part]}
		end
	end

	fun {Merge P2T ML}
		SLs = {Map ML fun {$ F#M} {ScaleList F {MixOne P2T M}} end}
	in
		{MergeLists SLs}
	end

	fun {Repeat K P2T M}
		if K =< 0 then nil 
		else {Append {MixOne P2T M} {Repeat K-1 P2T M}} 
		end
	end

	fun {Loop D P2T M}
		Base = {MixOne P2T M}
		Len = {Length Base}
	in
		if Len == 0 then
			nil
		else
			local
				Total = {FloatToInt D * SampleRate}
				Times = Total div Len
				Rem = Total mod Len
			in
				{Append {RepeatList Times Base} {Take Base Rem}}
			end
		end
	end

	fun {Clip L H P2T M}
		{MapList {MixOne P2T M} fun {$ S}
			if S < L then L elseif S > H then H else S end
		end}
	end

	fun {Echo Delay Decay Rep P2T M}
		Base = {MixOne P2T M}
		DelS = {FloatToInt Delay * SampleRate}
		fun {EchoAt K}
			if K < 0 then nil
			else
				{Append {Zeros (K * DelS)} {ScaleList {Pow Decay {IntToFloat K}} Base}} | {EchoAt K-1}
			end
		end
	in
		{MergeLists {EchoAt Rep}}
	end

	fun {Fade Start Finish P2T M}
		SL = {MixOne P2T M}
		N = {Length SL}
		Si = {FloatToInt Start * 44100.0}
		Fi = {FloatToInt Finish * 44100.0}

		fun {FadeMap I L}
			case L
			of nil then nil
			[] S|T then
				Intensity =
					if I < Si then
						{IntToFloat I} / {IntToFloat Si}
					elseif I >= N - Fi then
						{IntToFloat (N - I - 1)} / {IntToFloat Fi}
					else
						1.0
					end
				Faded = S * Intensity
			in
				Faded | {FadeMap I+1 T}
			end
		end
	in
		if N =< Si + Fi then SL
		else {FadeMap 0 SL}
		end
	end

	fun {Cut Start Finish P2T M}
		SL = {MixOne P2T M}
		Si = Start
		Fi = Finish
	in
		{Take {Drop SL Si} (Fi - Si + 1)}
	end

	fun {Synth TL}
		case TL
		of nil then nil
		[] H|T then {Append {SynthOne H} {Synth T}}
		end
	end

	fun {SynthOne E}
		case E
		of note(name:N octave:O sharp:S duration:D instrument:_) then
			{GenNote N O S D}
		[] silence(duration:D) then
			{Zeros {FloatToInt D * SampleRate}}
		[] _ then
			SLs = {MapList E SynthOne}
		in
			{MergeLists SLs}
		end
	end

	fun {GenNote N O S D}
		fun {BaseOffset C}
			case C
			of 'a' then 0 
			[] 'b' then 2 
			[] 'c' then ~9 
			[] 'd' then ~7 
			[] 'e' then ~5 
			[] 'f' then ~4 
			[] 'g' then ~2
			end
		end
		Off = {BaseOffset N} + (O - 4) * 12 + (if S then 1 else 0 end)
		Freq = 440.0 * {Pow 2.0 ({IntToFloat Off} / 12.0)}
		Nsam = {FloatToInt D * SampleRate}

		fun {Gen I}
			if I >= Nsam then nil
			else
				S = 0.5 * ({Sin ((2.0 * Pi * Freq * {IntToFloat I}) / SampleRate)})
			in
				S | {Gen I+1}
			end
		end
	in
		{Gen 0}
	end 

	fun {Length L}
		case L of nil then 0 [] _|T then 1+{Length T} end
	end

	fun {Zeros N}
		if N =< 0 then nil else 0.0 | {Zeros N-1} end
	end

	fun {ScaleList F L}
		case L of nil then nil [] H|T then (H*F) | {ScaleList F T} end
	end

	fun {RepeatList K L}
		if K =< 0 then nil 
		else {Append L {RepeatList K-1 L}} end
	end

	fun {Take L N}
		if N =< 0 then nil 
		else 
			case L 
			of nil then nil 
			[] H|T then H|{Take T N-1} 
			end 
		end
	end

	fun {Drop L N}
		if N =< 0 then L 
		else 
			case L 
			of nil then nil 
			[] _|T then {Drop T N-1} 
			end 
		end
	end

	fun {MergeLists Ls}
		MaxLen = {MaxLength Ls}
		fun {Build I}
			if I >= MaxLen then nil 
			else {SumAt Ls I} | {Build I+1} 
			end
		end
	in
		{Build 0}
	end

	fun {MaxLength Ls}
		case Ls 
			of nil then 0 
			[] L|Rest then Max = {Length L} 
			in 
				if Max > {MaxLength Rest} then Max 
				else {MaxLength Rest} 
			end 
		end
	end

	fun {SumAt Ls I}
		case Ls 
		of nil then 0.0 
		[] L|Rest then {SafeGet L I} + {SumAt Rest I}
		end
	end

	fun {SafeGet L I}
		if I < 0 then 0.0 
		else 
			case L 
			of nil then 0.0 
			[] H|T then 
				if I == 0 then H 
				else {SafeGet T I-1} 
				end 
			end 
		end
	end

	fun {MapList L F}
		case L 
		of nil then nil 
		[] H|T then {F H} | {MapList T F}
		else nil
		end
	end

end
