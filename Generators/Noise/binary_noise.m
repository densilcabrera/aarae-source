function OUT = binary_noise(duration, chans, fs)
% Generates binary noise with random values of -1 and 1

if nargin == 0
    param = inputdlg({'Duration of the wave [s]';...
        'Number of channels';...
        'Sampling frequency [samples/s]'}, ...
        'Input parameters',1,{'1';'1';'48000'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        duration = param(1);
        chans = param(2);
        fs = param(3);
    end
else
    param = [];
end
if ~isempty(param) || nargin ~= 0
y = randn(round(duration*fs),chans)/10;
y(y>=0) = 1;
y(y<0) = -1;

    tag = ['BinNoise' num2str(duration)];
    
    OUT.audio = y;
    OUT.audio2 = flipud(y); % inverse that assumes flat spectrum (poor assumption)
    %OUT.audio2 = ifft(1./fft(y)); % alternative 'inverse'
    OUT.fs = fs;
    OUT.tag = tag;
    OUT.funcallback.name = 'binary_noise.m';
    OUT.funcallback.inarg = {duration, chans, fs};
else
    OUT = [];
end

end % End of function