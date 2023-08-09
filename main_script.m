% This script has been developed for Root Mean Square localization error
% experiment within a virtual environment. To run the experiment successfully,
% users are required to download HRIR responses from the open-source database, 
% which can be accessed at the following URL: 
% https://sofacoustics.org/data/database/bili%20(dtf)/IRC_1101_C_HRIR_96000.sofa
% 
% For further queries contact at sathish.sreeni58@gmail.com

clear;clc;close all

% Structure to store data
RMS = {};
RMS.subject_name = 'demo_C11';
RMS.subject_age = 24;
RMS.response.speaker_num = [];
RMS.response.sub_resp = [];
RMS.response.score = [];

% Load response app
resp_app = response_circular;
resp_app_handle = resp_app.UIFigure;
pause(2)

% Load auditory stimuli
load noise_96k.mat

% Load impulse response
fs = ncread("IRC_1101_C_HRIR_96000.sofa","Data.SamplingRate");
IR = ncread("IRC_1101_C_HRIR_96000.sofa","Data.IR");
pos = ncread("IRC_1101_C_HRIR_96000.sofa","SourcePosition");
azimuth = pos(1,:);
elevation = pos(2,:);
index = find(elevation == 0);
hrir = IR(:,:,index);
azimuth = azimuth(index);

% Variables for experiment
exp_ang = [276,288,300,312,324,336,348,0,12,24,36,48,60,72,84]; % stimulus presentation angle
exp_spk = 1:length(exp_ang);
mul = 1; % number of stimulus presentation from the single speaker
spk_azi = [];
for ii = 1:mul
    rng;
    a = randperm(length(exp_ang));
    for jj = 1:length(a)
        b = a(1,jj);
        spk_azi = [spk_azi exp_ang(1,b)];
    end
end
rng; spk_azi = spk_azi(randperm(length(spk_azi)));

% Arrays to store subject responses
num_of_trials = length(spk_azi);
RMS.response.speaker_num = zeros(1,num_of_trials);
RMS.present.speaker_angle = zeros(1,num_of_trials);
RMS.response.speaker_angle = zeros(1,num_of_trials);
RMS.response.sub_resp = zeros(1,num_of_trials);
RMS.response.score = zeros(1,num_of_trials);

% Experiment starts
for ii = 1:num_of_trials
    a = spk_azi(ii);
    impulse = hrir(:,:,find(azimuth == a));
    left = conv(impulse(:,1),signal);
    right = conv(impulse(:,2),signal);
    stim = [left,right];
    sound(stim,fs)
    speak_num(a)

    sub_ans = [];
    uiwait(resp_app_handle)
    RMS.response.speaker_num(ii) = speak_num(a);
    RMS.response.sub_resp(ii) = sub_ans;
    RMS.present.speaker_angle(ii) = a;
    RMS.response.speaker_angle(ii) = speak_ang(sub_ans);
    pause(1)
end
msgbox('experiment finished');

% scoring
for ii = 1:num_of_trials
    if RMS.response.speaker_num(ii) == RMS.response.sub_resp(ii)
        RMS.response.score(ii) = 1;
    else
        RMS.response.score(ii) = 0;
    end
end

% Response calculation:
A = 12; % angular seperation between loudspeakers
m = num_of_trials; % total number of responses
r = RMS.response.sub_resp;
k = RMS.response.speaker_num;
percentage_correct = (sum(RMS.response.score)/num_of_trials)*100;
RMS_error = zeros(1,num_of_trials);
for ii = 1:m
    a = r(ii)-k(ii);
    b = a^2;
    RMS_error(1,ii) = b;
end
RMS_error = sum(RMS_error);
RMS_error = sqrt(((A^2)/m)*RMS_error);

signed_bias = zeros(1,num_of_trials);
for ii = 1:m
    a = r(ii)-k(ii);
    signed_bias(1,ii) = a;
end
signed_bias = sum(signed_bias);
signed_bias = (A/m)*signed_bias;

% Write data to text file:
file = [RMS.subject_name '.txt'];
datafile = fopen(file,'w');
fprintf(datafile, 'trials\tspeaker_number\tsub_response\tscore\tpresentation_spkr\tresponse_spkr\n');
for ii = 1:num_of_trials
    fprintf(datafile, '%3.0f\t%11.0f\t%14.0f\t%11.0f\t%16.0f\t%12.0f\n',...
        ii,RMS.response.speaker_num(1,ii),RMS.response.sub_resp(1,ii),...
        RMS.response.score(1,ii),RMS.present.speaker_angle(1,ii),...
        RMS.response.speaker_angle(1,ii));
end
fprintf(datafile,'percentage correct = %3.3f\n',percentage_correct);
fprintf(datafile,'RMS error = %3.3f\n',RMS_error);
fprintf(datafile,'signal bias = %3.3f\n',signed_bias);
fclose(datafile);

M = [(1:num_of_trials)',RMS.response.speaker_num',RMS.response.sub_resp',...
    RMS.response.score',RMS.present.speaker_angle',RMS.response.speaker_angle'];
T = array2table(M);
T.Properties.VariableNames(1:6) = {'trials','presentation_spkr_num','response_spkr_num',...
    'score','presentation_spkr_ang','response_spkr_ang'};
writetable(T,strcat(RMS.subject_name,'.csv'))