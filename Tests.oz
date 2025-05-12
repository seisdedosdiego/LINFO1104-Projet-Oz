% Auteur : Diego Seisdedos Stoz
% NOMA : 4659-23-00

functor
import
    Project2025
    Mix
    System
    Property
export
    test: Test
define

    PassedTests = {Cell.new 0}
    TotalTests  = {Cell.new 0}

    FiveSamples = 0.00011337868 % Duration to have only five samples

    fun {Normalize Samples}
        {Map Samples fun {$ S} {IntToFloat {FloatToInt S*10000.0}} end}
    end

    proc {Assert Cond Msg}
        TotalTests := @TotalTests + 1
        if {Not Cond} then
            {System.show Msg}
        else
            PassedTests := @PassedTests + 1
        end
    end

    proc {AssertEquals A E Msg}
        TotalTests := @TotalTests + 1
        if A \= E then
            {System.show Msg}
            {System.show actual(A)}
            {System.show expect(E)}
        else
            PassedTests := @PassedTests + 1
        end
    end

    fun {NoteToExtended Note}
        case Note
        of note(...) then
            Note
        [] silence(duration: _) then
            Note
        [] _|_ then
            {Map Note NoteToExtended}
        [] nil then
            nil
        [] silence then
            silence(duration:1.0)
        [] Name#Octave then
            note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
        [] Atom then
            case {AtomToString Atom}
            of [_] then
                note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
            [] [N O] then
                note(name:{StringToAtom [N]}
                     octave:{StringToInt [O]}
                     sharp:false
                     duration:1.0
                     instrument: none)
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TEST PartitionToTimedNotes

    proc {TestNotes P2T}
        P1 = [a0 b1 c#2 d#3 e silence]
        E1 = {Map P1 NoteToExtended}
    in
        {AssertEquals {P2T P1} E1 "TestNotes"}
    end

    proc {TestChords P2T}
        P = [[a4 c#5 e5]]
        E = [
           [
            note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            note(name:c octave:5 sharp:true  duration:1.0 instrument:none)
            note(name:e octave:5 sharp:false duration:1.0 instrument:none)
           ]
        ]
    in
        {AssertEquals {P2T P} E "TestChords"}
    end

    proc {TestIdentity P2T}
        P = [
           note(name:a octave:4 sharp:false duration:1.0 instrument:none)
           silence(duration:0.5)
           [
              note(name:c octave:5 sharp:true duration:1.0 instrument:none)
              note(name:e octave:5 sharp:false duration:1.0 instrument:none)
           ]
        ]
    in
        {AssertEquals {P2T P} P "TestIdentity"}
    end

    proc {TestDuration P2T}
        P = [duration(seconds:3.0 subpart:[a4 b4])]
        E = [
            note(name:a octave:4 sharp:false duration:1.5 instrument:none)
            note(name:b octave:4 sharp:false duration:1.5 instrument:none)
        ]
    in
        {AssertEquals {P2T P} E "TestDuration"}
    end

    proc {TestStretch P2T}
        P = [stretch(factor:2.0 subpart:[a4 b4])]
        E = [
           note(name:a octave:4 sharp:false duration:2.0 instrument:none)
           note(name:b octave:4 sharp:false duration:2.0 instrument:none)
        ]
    in
        {AssertEquals {P2T P} E "TestStretch"}
    end

    proc {TestDrone P2T}
        P = [drone(note:a4 amount:3)]
        E = [
            note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            note(name:a octave:4 sharp:false duration:1.0 instrument:none)
        ]
    in
        {AssertEquals {P2T P} E "TestDrone"}
    end

    proc {TestMute P2T}
        P = [mute(amount:2)]
        E = [
           silence(duration:1.0)
           silence(duration:1.0)
        ]
    in
        {AssertEquals {P2T P} E "TestMute"}
    end

    proc {TestTranspose P2T}
        P = [transpose(semitones:2 subpart:[a4 c4 c#4 b4])]
        E = [
           note(name:b octave:4 sharp:false duration:1.0 instrument:none)
           note(name:d octave:4 sharp:false duration:1.0 instrument:none)
           note(name:d octave:4 sharp:true  duration:1.0 instrument:none)
           note(name:c octave:5 sharp:true  duration:1.0 instrument:none)
        ]
    in
        {AssertEquals {P2T P} E "TestTranspose"}
    end

    proc {TestP2TChaining P2T}
        P = [duration(seconds:4.0 subpart: [
               stretch(factor:2.0 subpart: [
                    transpose(semitones:2 subpart: [a4 b4])
               ])
            ])]
        E = [
           note(name:b octave:4 sharp:false duration:2.0 instrument:none)
           note(name:c octave:5 sharp:true duration:2.0 instrument:none)
        ]
    in
        {AssertEquals {P2T P} E "TestP2TChaining"}
    end

    proc {TestEmptyChords P2T}
        P = [a4 nil b4]
        E = [
            note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            note(name:b octave:4 sharp:false duration:1.0 instrument:none)
        ]
    in
        {AssertEquals {P2T P} E "TestEmptyChords"}
    end

    proc {TestP2T P2T}
        {TestNotes P2T}
        {TestChords P2T}
        {TestIdentity P2T}
        {TestDuration P2T}
        {TestStretch P2T}
        {TestDrone P2T}
        {TestMute P2T}
        {TestTranspose P2T}
        {TestP2TChaining P2T}
        {TestEmptyChords P2T}
        {AssertEquals {P2T nil} nil 'nil partition'}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TEST Mix

    proc {TestSamples P2T Mix}
        E1 = [0.1 ~0.2 0.3]
        M1 = [samples(E1)]
    in
        {AssertEquals {Mix P2T M1} E1 'TestSamples'}
    end

    proc {TestPartition P2T Mix}
        P = [a4 silence b4]
        M = [partition(P)]
        S = {Mix P2T M}
    in
        {Assert S \= nil 'TestPartition'}
    end

    proc {TestWave P2T Mix} 
        M = [wave('wave/animals/cow.wav')]
        S = {Mix P2T M}
    in
        {Assert S \= nil 'TestWave'}
    end

    proc {TestMerge P2T Mix}
        E = [0.5 0.5 0.5]
        M = [merge([(1.0#samples([0.3 0.3 0.3])) (1.0#samples([0.2 0.2 0.2]))])]
    in
        {AssertEquals {Mix P2T M} E 'TestMerge'}
    end

    proc {TestReverse P2T Mix}
        M = [samples([1.0 0.5 0.0]) reverse]
        R = {Mix P2T M}
    in
        {AssertEquals R [0.0 0.5 1.0] 'TestReverse'}
    end

    proc {TestRepeat P2T Mix}
        M = [
            repeat(amount:3 subpart:[0.1])
            ]
        E = [0.1 0.1 0.1]
    in
        {AssertEquals {Mix P2T M} E 'TestRepeat'}
    end
    
    proc {TestLoop P2T Mix}
        M = [loop(duration: FiveSamples subpart:partition([a4]))]
        S = {Mix P2T M}
    in
        {Assert S \= nil "TestLoop"}
    end

    proc {TestClip P2T Mix}
        M = [clip(low:~0.15 high:0.15 subpart:[~0.2 0.0 0.2])]
        E = [~0.15 0.0 0.15]
    in
        {AssertEquals {Mix P2T M} E 'TestClip'}
    end

    proc {TestEcho P2T Mix}
        M = [echo(delay:FiveSamples decay:0.5 repeat:1 subpart:[1.0])]
        E = [1.0 0.0 0.0 0.0 0.0 0.5]
    in
        {AssertEquals {Normalize {Mix P2T M}} {Normalize E} 'TestEcho'}
    end

    proc {TestFade P2T Mix}
        M = [fade(start:FiveSamples finish:FiveSamples subpart:[1.0 1.0 1.0 1.0 1.0 1.0])]
        R = {Mix P2T M}
    in
        {Assert {Length R} == 6 'TestFade'}
    end

    proc {TestCut P2T Mix}
        Start = 1
        Finish = 2
        M = [cut(start:Start finish:Finish subpart:[1.0 2.0 3.0 4.0])]
        E = [2.0 3.0]
    in
        {AssertEquals {Mix P2T M} E 'TestCut'}
    end

    proc {TestMix P2T Mix}
        {TestSamples P2T Mix}
        {TestPartition P2T Mix}
        {TestWave P2T Mix}
        {TestMerge P2T Mix}
        {TestRepeat P2T Mix}
        {TestLoop P2T Mix}
        {TestClip P2T Mix}
        {TestEcho P2T Mix}
        {TestFade P2T Mix}
        {TestCut P2T Mix}
        {AssertEquals {Mix P2T nil} nil 'nil music'}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc {Test Mix P2T}
        {Property.put print print(width:100)}
        {Property.put print print(depth:100)}
        {System.show 'tests have started'}
        {TestP2T P2T}
        {System.show 'P2T tests have run'}
        {TestMix P2T Mix}
        {System.show 'Mix tests have run'}
        {System.show test(passed:@PassedTests total:@TotalTests)}
    end
end