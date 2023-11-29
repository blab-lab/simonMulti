%CD to the acoustic folder

cd("\\wcs-cifs\wc\smng\experiments\simonMultisyllable\acousticdata");

% List all participants
Participants = ["sp310" "sp318" "sp329" "sp338" "sp400" "sp401" "sp449" ...
    "sp455" "sp457" "sp459" "sp460" "sp463" "sp469" "sp504" "sp524" "sp529" ...
    "sp546" "sp552" "sp555" "sp557"];

% Set up looping variable for participants
nParticipants = width(Participants);

ParticipantIndex = 1;

% Set up looping variable for trials
nTrial = 1;

% Set up looping frame

% Select the first person

Participant = Participants(ParticipantIndex);

load(fullfile('.', Participant, 'dataVals.mat'));
load(fullfile('.', Participant, 'expt.mat'));

%Find the location of the vowels

[row, Indx1] = find(dataVals(nTrial).segment == "v1Start"); % Vowel location

% Read data of the first trial

%First syllable
F1 = dataVals(nTrial).f1{1, Indx1}; %F1
F2 = dataVals(nTrial).f2{1, Indx1}; %F2
Trial = repelem(nTrial, height(F1))'; %Trial number
Position = (1:height(F1))'; %Position within a trial
Duration = repelem(dataVals(nTrial).dur{1, Indx1}, height(F1))'; %Duration
Word = repelem(expt.listWords(nTrial), height(F1))'; %Word
Speaker = repelem(Participant, height(F1))'; %Speaker
Phase = repelem(expt.listConds(nTrial), height(F1))'; %Phase
Shift =  repelem(convertCharsToStrings(expt.listShiftNames{1, nTrial}), height(F1))';


% Create tables with headers
data = table(F1, F2, Trial, Position, Duration, Word, Speaker, Phase, Shift);

% Retain only the table headers

data(1:height(data),:) = [];

% Zoom into individual participants and collect data

while ParticipantIndex <= nParticipants

    % Zoom into one participant & Load data
    Participant = Participants(ParticipantIndex);

    load(fullfile('.', Participant, 'dataVals.mat'));
    load(fullfile('.', Participant, 'expt.mat'));

    % Retain only the table headers

    data(1:height(data),:) = [];

    % Zoom into individual trials

    nRow = width(dataVals);

    % Set up looping variable for trial

    nTrial = 1;

    % Obtain info
    while nTrial <= nRow

        %Check if this row is empty
        if isempty(dataVals(nTrial).segment)
            nTrial = nTrial + 1
            continue
        end

        %Find the location of the vowels

        [row, Indx1] = find(dataVals(nTrial).segment == "v1Start"); % Vowel location

        if isempty(Indx1)
            nTrial = nTrial + 1
            continue
        end
        %% Access the first syllable
        F1 = dataVals(nTrial).f1{1, Indx1}; %F1

        % Skip the current trial if the F1 values are missing
        if isempty(F1)
            nTrial = nTrial + 1
            continue
        end

        F2 = dataVals(nTrial).f2{1, Indx1}; %F2
        Trial = repelem(nTrial, height(F1))'; %Trial number
        Position = (1:height(F1))'; %Position within a trial
        Duration = repelem(dataVals(nTrial).dur{1, Indx1}, height(F1))'; %Duration
        Word = repelem(expt.listWords(nTrial), height(F1))'; %Word
        Speaker = repelem(Participant, height(F1))'; %Speaker
        Phase = repelem(expt.listConds(nTrial), height(F1))'; %Phase
        Shift =  repelem(convertCharsToStrings(expt.listShiftNames{1, nTrial}), height(F1))';

        % Create a temporary table with headers
        temp = table(F1, F2, Trial, Position, Duration, Word, Speaker, Phase, Shift);

        % Join the temporary table with the master table
        data = [data; temp];

        % Go to the next trial
        nTrial = nTrial + 1;
    end

    % Write one person's data to disk

    writetable(data, strcat(Participant, '_Formant.csv'));

    % Go to the next participant
    ParticipantIndex = ParticipantIndex + 1;

end