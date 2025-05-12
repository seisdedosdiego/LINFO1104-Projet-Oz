% Auteur : Diego Seisdedos Stoz  
% NOMA : 4659-23-00

local 
    % Partition simple : do-ré-mi-fa-sol-fa-mi-ré-do
    Melody = partition(c4|d4|e4|f4|g4|f4|e4|d4|c4)
 
    % Animal fourni : cat
    cat = wave("wave/animals/cat.wav")
 
    % Mélange des 2
    Music = merge([
      0.7 # Melody
      0.3 # echo(delay:0.5 decay:0.6 repeat:2 cat)
    ])
 
in
    {Project2025.run Mix PartitionToTimedList Music}.
end