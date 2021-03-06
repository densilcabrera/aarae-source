function  OUT = mls(n,cycles,fs)
% This function is used to generate a maximum length sequence signal (mls),
% which can be used to measure impulse responses.
%
% This function calls code by M.R.P. Thomas  - please refer to
% the following folder AARAE/Generators/Noise/mls, which contains his code,
% documentation and license.
%
% INPUTS:
% Bit length is an integer from 2 to 24, which will generate an mls signal
% of length (2^n)-1.  For example:
%   n     signal length       duration @ fs = 48 kHz    self-SNR of 1 cycle
%   15    32767               0.6826 s                    90 dB
%   16    65535               1.3653 s                    96 dB
%   17    131071              2.7306 s                   102 dB                 
%   18    262143              5.4613 s                   108 dB
%   19    524287              10.9226 s                  114 dB
%   20    1048575             21.8452 s                  120 dB
%   21    2097151             43.6906 s                  126 dB
%
% (Note that the self-SNR of 1 cycle assumes that there is no noise added
% from a system. In practice, doubling the length of the signal will
% increase SNR by 3 dB, rather than 6 dB).
%
% The signal length should be longer than the period of interest and longer
% than the period of significant power in the impulse response (to avoid
% temporal aliasing).
%
% Note that because MLS relies on circular cross-correlation analysis 
% (rather than linear) to derive an impulse response, there must be at
% least two cycles, the first of which is not used directly for analysis.
% More details about this are given in Thomas' documentation (in
% the folder mentioned above).
%
% Increasing the number of cyles should increase the signal to noise ratio,
% notwithstanding certain issues (such as time variance in the system).
% Three or more cycles allows synchronous averaging to increase SNR.
%
% Note that the number of cycles in an MLS sequence (as generated by this
% function) is a separate concept to the number of cycles that AARAE's
% Generator GUI creates (by repeatedly calling this function). The
% processor that is used to derive the impulse response takes advantage of
% both of these levels of repetition.
%
% The function outputs the MLS sequence (in the audio field), together with
% the time-reversed MLS signal (as audio2). The signal is time reversed for
% compatability with the general use of audio2 as an inverse filter.
% However, you should not normally use AARAE's '*' button (which convolves
% audio with audio2) to obtain the impulse response, although it will
% probably still work to an extent, because it does linear convolution
% rather than the required circular convolution (or cross-correlation with
% the non-reversed signal). Instead use the processor MLS_process to
% derive the impulse response, which is in AARAE's Cross & auto functions
% folder (in Processors).
%
% code by Densil Cabrera
% Version 2 (31 July 2014)


if nargin == 0
    param = inputdlg({'Bit length [2-24]';...
                       'Number of cycles [2 or more]';...
                       'Sampling frequency [Hz]'},...
                       'MLS input parameters',1,{'16';'2';'48000'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        n = round(param(1));
        if n > 24, n = 24; end;
        if n < 2, n = 2; end;
        cycles = round(param(2));
        if cycles < 2, cycles = 2; end
        fs = param(3);
    end
else
    param = [];
end
if ~isempty(param) || nargin ~= 0
    [sequence, mls] = GenerateMLSSequence(cycles, n, 0);
    OUT.audio = sequence;
    OUT.audio2 = flipud(mls');
    OUT.fs = fs;
    OUT.tag = ['MLS' num2str(n)];
    OUT.properties.n = n;
    OUT.properties.cycles = cycles;
    OUT.funcallback.name = 'mls.m';
    OUT.funcallback.inarg = {n,cycles,fs};
else
    OUT = [];
end
end % End of function