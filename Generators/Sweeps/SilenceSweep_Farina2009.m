function OUT = SilenceSweep_Farina2009(fs,gapdur)
% This function generates the 'silence sweep' as described by Angelo
% Farina:
%
% Angelo Farina (2009) "Silence Sweep: a novel method for measuring
% electro-acoustical devices," 126th AES Convention, Munich, Germany
%
% The test signal consists of a period of silence, then the silence sweep,
% then the exponential sweep
%
% Use the SilenceSweepAnalysis (in Non-LTI analysis) to analyse recordings
% made with this test signal.




if nargin == 0
    
    param = inputdlg({'Sampling rate (Hz)';...
        'Duration of gap between silence, silence sweep and sweep'},...
        'Silence Sweep',... 
        [1 60],... 
        {'48000';'1'}); 
    
    param = str2num(char(param)); 
    
    if length(param) < 2, param = []; end 
    if ~isempty(param) 
        fs = round(param(1));
        gapdur = param(2);
    else
        % get out of here if the user presses 'cancel'
        OUT = [];
        return
    end
end


if fs < 44100, fs = 44100; end

if ~isempty(gapdur) && ~isempty(fs)
    
    % Generate MLS repeated sequence
    n = 17;
    cycles = 41;
    mls = GenerateMLSSequence(cycles, n, 0);
    
    mlslen = 2^n-1;
    mls(mlslen*floor(cycles/2)+1:mlslen*ceil(cycles/2)) = 0;
    
    % generate sweep 10 octaves
    SI = 1/fs;
    dur = 10*mlslen*SI;
    ampl = 0.5;
    start_freq = 20;
    end_freq = 20480;
    rcos_ms1 = 1;
    rcos_ms2 = 100;
    scale_inv = 1;
    w1 = 2*pi*start_freq; w2 = 2*pi*end_freq;
    K = (dur*w1)/(log(w2/w1));
    L = log(w2/w1)/dur;
    t = (1:10*mlslen-1)*SI;
    phi = K*(exp(t*L) - 1);
    freq = K*L*exp(t*L);
    %freqaxis = freq/(2*pi);
    amp_env = 10.^((log10(0.5))*log2(freq/freq(1)));
    S = ampl*sin(phi);
    rcos_len1 = round(length(S)*((rcos_ms1*1e-3)/dur));
    rcos_len2 = round(length(S)*((rcos_ms2*1e-3)/dur));
    sig_len = length(S);
    rcoswin1 = hann(2*rcos_len1).';
    rcoswin2 = hann(2*rcos_len2).';
    S = [S(1:rcos_len1).*rcoswin1(1:rcos_len1),S(rcos_len1+1:sig_len-rcos_len2),S(sig_len-rcos_len2+1:sig_len).*rcoswin2((rcos_len2+1):(rcos_len2*2))]';
    Sinv = flip(S).*amp_env';

    % correction for allpass delay
    Sinvfft = fft(Sinv);
    Sinvfft = Sinvfft.*exp(1i*2*pi*(0:(sig_len-1))*(sig_len-1)/sig_len)';
    Sinv = real(ifft(Sinvfft));

    if scale_inv == 1
       fftS = fft(S);
       mid_freq = (start_freq + end_freq)/2;
       index = round(mid_freq/(fs/sig_len));
       const1 = abs(conj(fftS(index))/(abs(fftS(index))^2));
       const2 = abs(Sinvfft(index));
       IRscalingfactor = const1/const2;
       % Sinv = Sinv * IRscalingfactor; % scaling factor is applied in
       % convolveaudiowithaudio2
    else
        IRscalingfactor = 1;
    end
    
    % convolve mls (incl silence gap) with sweep
    fftlen = length(mls) + length(S) - 1;
    gaplen = round(fs*gapdur);
    audio = [zeros(gaplen,1); ifft(fft(mls,fftlen) .* fft(S,fftlen)); zeros(gaplen,1)];
    audio = ampl * audio ./ max(abs(audio));
    audio(1:length(S)) = 0; % silence
    audio(1+end-(length(S)+gaplen):end) = [zeros(gaplen,1);S]; % sweep
    
    OUT.fs = fs;
    OUT.audio = audio;
    OUT.audio2 = Sinv;
    OUT.tag = 'SilenceSweep';
    OUT.funcallback.name = 'SilenceSweep_Farina2009.m'; 
    OUT.funcallback.inarg = {fs,gapdur};
    OUT.properties.IRscalingfactor = IRscalingfactor;
    OUT.properties.gapdur = gapdur;
    OUT.properties.SilenceSweep = 1; % currently the analyser just checks that this exists. In future this could have more meaning.
else
    OUT = [];
end


%**************************************************************************
% Copyright (c) 2015, Densil Cabrera
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%  * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%  * Neither the name of the The University of Sydney nor the names of its contributors
%    may be used to endorse or promote products derived from this software
%    without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
% OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%**************************************************************************