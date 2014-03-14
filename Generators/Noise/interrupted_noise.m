function OUT = interrupted_noise(fexponent, burst_duration, ...
    silence_duration, nbursts, fs, fhigh, flow, nchan)
% This function generates a sequence of interrupted noise bursts, for the
% purpose of measuring reverberation time. Each noise burst is an
% independent random waveform.
%
% The noise is generated by random phase in the frequency domain, allowing
% band limits and spectral slope to be applied efficiently.
%
% Multiple independent channels can be generated (e.g., for multiple test
% loudspeaker channels - although there are plusses and minuses of using
% that approach).
%
% The amplitude of each noise burst is normalized to allow maximum playback
% level.
%
% Audio3 can be used to guide analysis: it has ones during the stimuli
% and zeros between stimuli. Bear in mind that the measurement system and
% the acoustic system will introduce latency, so the recorded signal is
% likely to be delayed relative to audio3.
%
% The function does not output audio2 (although a previous version did, and
% the relevant code has been commented out).
%
% Code by Densil Cabrera
% version 1.02 (17 December 2013)

if nargin == 0
    param = inputdlg({'Spectral slope [dB/octave]';...
        'Duration of each noise burst [s]';...
        'Duration of silence after each noise burst [s]';...
        'Number of noise bursts';...
        'Sampling frequency [samples/s]';...
        'High cutoff frequency [Hz]';...
        'Low cutoff frequency [Hz]';...
        'Number of independent channels'},...
        'Noise burst sequence input parameters', ...
        1,{'0';'1';'2';'5';'48000';'20000';'20';'1'});
    param = str2num(char(param));
    if length(param) < 7, param = []; end
    if ~isempty(param)
        fexponent = (param(1)-3)/3;
        burst_duration = param(2);
        silence_duration = param(3);
        nbursts = param(4);
        fs = param(5);
        fhigh = param(6);
        flow = param(7);
        nchan = param(8);
        
        
    end
elseif nargin < 8, nchan = 1;
else
    param = [];
end


if ~isempty(param) || nargin ~= 0
    
    burstlen = 2*ceil(burst_duration*fs/2);
    silencelen = round(silence_duration * fs);
    
    totallen = nbursts * (burstlen + silencelen);
    burstwave = zeros(totallen, nchan);
    %burstwave2 = burstwave;
    audio3 = zeros(totallen, 1);
    
    for n = 1:nbursts
        
        
        
        
        % magnitude slope function (for half spectrum, not including DC and
        % Nyquist)
        magslope = ((1:burstlen/2-1)./(burstlen/4)).^(fexponent*0.5)';
        %magslope2 = ((1:burstlen/2-1)./(burstlen/4)).^(-fexponent*0.5)';
        
        % bandpass filter
        if fhigh < flow
            ftemp = flow;
            flow = fhigh;
            fhigh = ftemp;
        end
        if flow >= burstlen / fs
            lowcut = floor(flow * burstlen / fs);
            magslope(1:lowcut) = 0;
            %magslope2(1:lowcut) = 0;
        end
        if fhigh <= fs/2 - burstlen / fs
            highcut = ceil(fhigh * burstlen / fs);
            magslope(highcut:end) = 0;
            %magslope2(highcut:end) = 0;
        end
        
        % generate noise in the frequency domain, by random phase
        phase = 2*pi.*rand(burstlen/2-1,nchan);
        noisyslope = repmat(magslope,1,nchan) .* exp(1i*phase);
        %noisyslope2 = repmat(magslope2,1,nchan) .* exp(1i*phase);
        
        % transform to time domain
        y = ifft([zeros(1,nchan);noisyslope;zeros(1,nchan);flipud(conj(noisyslope))]);
        %yinv = ifft([zeros(1,nchan);noisyslope2;zeros(1,nchan);flipud(conj(noisyslope2))]);
        
        
        % normalize burst
        y = y ./ max(max(abs(y)));
        %yinv = yinv ./ max(max(abs(yinv)));
        
        burstwave((n-1)*(burstlen+silencelen)+1:(n-1)*(burstlen+silencelen)+burstlen,:) = y;
        %burstwave2((n-1)*(burstlen+silencelen)+1:(n-1)*(burstlen+silencelen)+burstlen,:) = yinv;
        audio3((n-1)*(burstlen+silencelen)+1:(n-1)*(burstlen+silencelen)+burstlen)=1;
    end
    
    
    
    
    
    
    
    
    switch round(fexponent*10)/10
        case -2.7
            tag = 'Hoff interrupted noise';% (-5 dB/oct in constant percentage bandwidth analysis)
        case -2
            tag = 'Red interrupted noise';% (or brown or brownian) noise (-3 dB/oct in cpb analysis)
        case -1
            tag = 'Pink interrupted noise';% (0 dB/oct in cpb analysis)
        case 0
            tag = 'White interrupted noise';% (+3 dB/oct in cpb analysis)
        case 1
            tag = 'Blue interrupted noise';% (+6 dB/oct in cpb analysis)
        case 2
            tag = 'Violet interrupted noise';% (+9 dB/oct in cpb analysis)
        otherwise
            tag = 'Interrupted  noise';
            % i.e., dBperOctave = 3*fexponent + 3
    end
    
    
    
    OUT.audio = burstwave;
    %OUT.audio2 = flipdim(burstwave2,1);
    OUT.audio3 = audio3;
    OUT.fs = fs;
    OUT.tag = tag;
    OUT.param = [fexponent, burst_duration, ...
    silence_duration, nbursts, fs, fhigh, flow, nchan];
else
    OUT = [];
end


end




