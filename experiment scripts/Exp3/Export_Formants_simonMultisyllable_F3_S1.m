%CD to the acoustic folder

cd("\\wcs-cifs\wc\smng\experiments\simonMultisyllable\acousticdata");

% List all participants
Participants = ["sp310" "sp318" "sp329" "sp338" "sp400" "sp401" "sp449" ...
    "sp455" "sp457" "sp459" "sp460" "sp469" "sp504" "sp524" "sp529" ...
    "sp546" "sp552" "sp555" "sp557"];

%"sp463" 

% Set up looping variable for participants
nParticipants = width(Participants);

ParticipantIndex = 1;

% Set up looping variable for trials
nTrial = 1;


% Select the first person

Participant = Participants(ParticipantIndex);

load(fullfile('.', Participant, 'data.mat'));
load(fullfile('.', Participant, 'expt.mat'));
load(fullfile('.', Participant, 'dataVals.mat'));


% Read data of the first trial

%%Time

T1 = data(nTrial).origOstTime.v1Start * 1000 / 2
T2 = data(nTrial).origOstTime.v1End * 1000 / 2

F3 = data(nTrial).fmts(:, 3);
F3 = F3(T1:T2);
Trial = repelem(nTrial, height(F3))'; %Trial number
Position = (1:height(F3))'; %Position within a trial
Word = repelem(expt.listWords(nTrial), height(F3))'; %Word
Speaker = repelem(Participant, height(F3))'; %Speaker
Phase = repelem(expt.listConds(nTrial), height(F3))'; %Phase
Shift =  repelem(convertCharsToStrings(expt.listShiftNames{1, nTrial}), height(F3))';

% Create tables with headers
DATA = table(F3, Trial, Position, Word, Speaker, Phase, Shift);

% Retain only the table headers

DATA(1:height(DATA),:) = [];

% Zoom into individual participants and collect data

while ParticipantIndex <= nParticipants

    % Zoom into one participant & Load data
    Participant = Participants(ParticipantIndex);

    load(fullfile('.', Participant, 'dataVals.mat'));
    load(fullfile('.', Participant, 'expt.mat'));
    load(fullfile('.', Participant, 'data.mat'));

    % Retain only the table headers

    DATA(1:height(DATA),:) = [];

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

        %%Time

        T1 = data(nTrial).origOstTime.v1Start * 1000 / 2
        T2 = data(nTrial).origOstTime.v1End * 1000 / 2

        F3 = data(nTrial).fmts(:, 3);
        F3 = F3(T1:T2);
        Trial = repelem(nTrial, height(F3))'; %Trial number
        Position = (1:height(F3))'; %Position within a trial
        Word = repelem(expt.listWords(nTrial), height(F3))'; %Word
        Speaker = repelem(Participant, height(F3))'; %Speaker
        Phase = repelem(expt.listConds(nTrial), height(F3))'; %Phase
        Shift =  repelem(convertCharsToStrings(expt.listShiftNames{1, nTrial}), height(F3))';

        % Create a temporary table with headers
        temp = table(F3, Trial, Position, Word, Speaker, Phase, Shift);

        % Join the temporary table with the master table
        DATA = [DATA; temp];

        % Go to the next trial
        nTrial = nTrial + 1;
    end

    % Write one person's data to disk

    writetable(DATA, strcat(Participant, '_F3_S1.csv'));

    % Go to the next participant
    ParticipantIndex = ParticipantIndex + 1;


end