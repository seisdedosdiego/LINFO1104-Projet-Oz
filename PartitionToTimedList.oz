% Auteur : Diego Seisdedos Stoz
% NOMA : 4659-23-00

functor
import
    Project2025
    System
    Property
export
    partitionToTimedList: PartitionToTimedList
define

    fun {NoteToExtended N}
        case N
        of nil then nil
        [] silence then silence(duration:1.0)
        [] silence(duration:_) then N
        [] note(...) then N
        [] N1|_ then {Map N fun {$ X} {NoteToExtended X} end}
        [] A#B then
            note(name:A octave:B sharp:true duration:1.0 instrument:none)        
        [] A then
            Str = {AtomToString A}
        in
            case Str
            of [L] then
                note(name:{StringToAtom [L]} octave:4 sharp:false duration:1.0 instrument:none)
            [] [L '#'] then
                note(name:{StringToAtom [L]} octave:4 sharp:true duration:1.0 instrument:none)
            [] [L O] then
                note(name:{StringToAtom [L]} octave:{StringToInt [O]} sharp:false duration:1.0 instrument:none)
            [] [L '#' O] then
                note(name:{StringToAtom [L]} octave:{StringToInt [O]} sharp:true duration:1.0 instrument:none)
            else
                raise invalid_note(A) end
            end
        end
    end

    fun {TotalDuration L}
        case L
        of nil then 0.0
        [] H|T then
            D = case H
                of note(...) then H.duration
                [] silence(duration:D1) then D1
                [] _ then
                    if {IsList H} andthen H \= nil then
                        H.1.duration
                    else 0.0
                    end
                end
            in D + {TotalDuration T}
        end
    end

    fun {ScaleDurations L F}
        case L
        of nil then nil
        [] H|T then
            Scaled = case H
                of silence(duration:D) then
                    silence(duration:D * F)
                [] note(name:Name octave:O sharp:S duration:D instrument:I) then
                    note(name:Name octave:O sharp:S duration:D * F instrument:I)
                [] _ then
                    if {IsList H} then
                        {Map H fun {$ N} {ScaleDurations [N] F}.1 end}
                    else
                        raise scale_error(H) end
                    end
                end
        in
            Scaled | {ScaleDurations T F}
        end
    end

    fun {NoteToSemitone N}
        Base = case N.name
            of c then 0 [] d then 2 [] e then 4 [] f then 5
            [] g then 7 [] a then 9 [] b then 11
        end + (if N.sharp then 1 else 0 end)
    in
        Base + 12 * N.octave
    end

    fun {SemitoneToNote Sem Dur Inst}
        Oct = Sem div 12
        Pos = Sem mod 12
        Table = [c c d d e f f g g a a b]
        Sharps = [false true false true false false true false true false true false]
        Name = {Nth Table Pos+1}
        Sharp = {Nth Sharps Pos+1}
    in
        note(name:Name octave:Oct sharp:Sharp duration:Dur instrument:Inst)
    end

    fun {TransposeSound Sound S}
        case Sound
        of note(...) then
            Sem = {NoteToSemitone Sound}
        in
            {SemitoneToNote Sem + S Sound.duration Sound.instrument}
        [] silence(duration:_) then Sound
        [] _ then
            if {IsList Sound} then
                {Map Sound fun {$ N} {TransposeSound N S} end}
            else Sound end
        end
    end

    fun {MakeSilences N}
        if N == 0 then nil
        else silence(duration:1.0) | {MakeSilences N-1}
        end
    end

    fun {Repeat Elem N}
        if N =< 0 then nil
        else Elem | {Repeat Elem N-1}
        end
     end

    fun {Flatten P}
        case P
        of nil then nil
        [] H|T then
            if H == nil then
                {Flatten T}   % Ignore les éléments vides
            else
                case H
                of duration(seconds:D subpart:Sub) then
                    Flat = {Flatten Sub}
                    Total = {TotalDuration Flat}
                    Scale = if Total == 0.0 then 0.0 else D / Total end
                in
                    {Append {ScaleDurations Flat Scale} {Flatten T}}

                [] stretch(factor:F subpart:Sub) then
                    Flat = {Flatten Sub}
                in
                    {Append {ScaleDurations Flat F}  {Flatten T}}

                [] transpose(semitones:S subpart:Sub) then
                    Flat = {Flatten Sub}
                in
                    {Append {Map Flat fun {$ N} {TransposeSound N S} end} {Flatten T}}

                [] drone(note:N amount:K) then
                    Flat = {Flatten {Repeat N K}}
                in
                    {Append Flat {Flatten T}}

                [] mute(amount:N) then
                    {Append {MakeSilences N} {Flatten T}}

                else
                    Extended = {NoteToExtended H}
                in
                    Extended | {Flatten T}
                end
            end
        end
    end
    
    fun {PartitionToTimedList Partition}
        {Flatten Partition}
    end

end

