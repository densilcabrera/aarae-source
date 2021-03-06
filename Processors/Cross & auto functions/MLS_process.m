function OUT = MLS_process(IN, offset, DCCoupling, d2stack, cycles, n)
% This function is used to analyse signals that were recorded using the MLS
% generator within AARAE. The output is an impulse response.
%
% This function calls code by M.R.P. Thomas  - please refer to
% the following folder AARAE/Generators/Noise/mls, which contains his code,
% documentation and license.
%
% SETTINGS
%   Offset: Positive offset causes negative time shift (default = 0).
%
%   DC recovery: 1 to recover DC value, 0 to not do so (e.g. for
%   loudspeaker measurements. See Thomas' documentation for more
%   information.
%
%   IR stack in dimension 2 (if available): in AARAE, dimenson 2 is used
%   for channels, and if it is singleton, then multiple IRs can be stacked
%   in dimension 2 instead of in dimension 4. If d2stack == 1, then this
%   will be done; otherwise IRs are always stacked in dimension 4.
%   
% code by Densil Cabrera
% version 1 (31 July 2014)

if isstruct(IN)
    audio = IN.audio;
    %fs = IN.fs;
    %     if isfield(IN,'audio2')
    %         audio2 = IN.audio2;
    %     end
    if isfield(IN,'properties')
        if isfield(IN.properties,'cycles') && isfield(IN.properties,'n')
            cycles = IN.properties.cycles;
            n = IN.properties.n;
        else
            disp('Required properties fields not found')
        end
    else
        disp('Required properties fields not found')
    end
    OUT = IN;
else
    audio = IN;
end


% Dialog box parameters
if nargin ==1
    param = inputdlg({'Offset in samples';... %
        'DC recovery [0 | 1]';
        'IR stack in dimension 2 if available [0 | 1]'},...%
        'MLS process settings',...
        [1 60],...
        {'0';'1';'1'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        offset = param(1);
        DCCoupling = param(2);
        d2stack = param(3);
    else
        OUT=[];
        return
    end
else
    param = [];
end

[~, chans, bands, dim4] = size(audio);

% Stack IRs in dimension 4 if AARAE's multi-cycle mode was used
if isfield(IN,'properties')
    if isfield(IN.properties,'startflag') && dim4==1
        startflag = IN.properties.startflag;
        dim4 = length(startflag);
        audiotemp = zeros((cycles+1)*(2^n-1),chans,bands,dim4);
        for d=1:dim4
            audiotemp(:,:,:,d) = ...
                audio(startflag(d):startflag(d)+(cycles+1)*(2^n-1)-1,:,:);
        end
    end
end

if exist('audiotemp','var')
    audio = audiotemp;
end

if d2stack == 1 && chans == 1 && dim4 > 1
    audio = permute(audio,[1,4,3,2]);
    chans = dim4;
    dim4 = 1;
end


impalign = 0; % not used by generator
ir = zeros(2^n,chans,bands,dim4);
for d4=1:dim4
    for b = 1:bands
        ir(:,:,b,d4) = AnalyseMLSSequence(audio(:,:,b,d4),offset,cycles,n,DCCoupling,impalign);
    end
end

if isstruct(IN)
    OUT.audio = ir;
    OUT.funcallback.name = 'MLS_process.m';
    OUT.funcallback.inarg = {offset, DCCoupling, d2stack, cycles, n};
else
    OUT = ir;
end