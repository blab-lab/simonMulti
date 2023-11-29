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

% Read data of the first trial
[row, col] = find(dataVals(nTrial).segment == "v1Start"); % Vowel location

F0 = dataVals(nTrial).f0{1, col}; %F0

%temp1 = linspace(0, 100, height(F0))';
%temp2 = [F0 temp1];
%temp3 = temp2(temp2(:, 2) > 25);

Int =dataVals(nTrial).int{1, col}; %Int
Trial = repelem(nTrial, height(F0))'; %Trial number
Position = (1:height(F0))'; %Position within a trial
Duration = repelem(dataVals(nTrial).dur{1, col}, height(F0))'; %Duration
Word = repelem(expt.listWords(nTrial), height(F0))'; %Word
Speaker = repelem(Participant, height(F0))'; %Speaker


% Create a table with headers
data = table(F0, Int, Trial, Position, Duration, Word, Speaker);

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

        [row, col] = find(dataVals(nTrial).segment == "v1Start"); % Vowel location

        if isempty(col)
            nTrial = nTrial + 1
            continue
        end

        F0 = dataVals(nTrial).f0{1, col}; %F0

        % Skip the current trial if the F1 values are missing
        if isempty(F0)
            nTrial = nTrial + 1
            continue
        end

        Int =dataVals(nTrial).int{1, col}; %Int
        Trial = repelem(nTrial, height(F0))'; %Trial number
        Position = (1:height(F0))'; %Position within a trial
        Duration = repelem(dataVals(nTrial).dur{1, col}, height(F0))'; %Duration
        Word = repelem(expt.listWords(nTrial), height(F0))'; %Word
        Speaker = repelem(Participant, height(F0))'; %Speaker
   
        % Create a temporary table with headers
        temp = table(F0, Int, Trial, Position, Duration, Word, Speaker);

        % Join the temporary table with the master table
        data = [data; temp];

        % Go to the next trial
        nTrial = nTrial + 1;
    end

    % Write one person's data to disk

    writetable(data, strcat(Participant, '_Prosody.csv'));

    % Go to the next participant
    ParticipantIndex = ParticipantIndex + 1;

end