function wv_drag = DRAG(wv, alpha, f01, f02)
    % make a DRAG version of waveform object wv

% Copyright 2017 Yulin Wu, USTC
% mail4ywu@gmail.com/mail4ywu@icloud.com

    assert(isa(wv,'qes.waveform.waveform'));
    assert(f02 ~= 2*f01);
    wv = copy(wv); % make a copy is necessary
    if (~isempty(wv.df) && wv.df ~=0) || wv.phase ~= 0
        throw(MException('QOS_DRAG:incorrectUsage','Only envelop waveforms can be dragified.'))
    end
    % wv.df = 0; % original waveform has to be real
    % wv.phase = 0;
    delta = 2*pi*(f02-2*f01);
    wv_drag  = copy(wv)-1j*alpha/delta*qes.waveform.fcns.Deriv(wv);
    wv_drag.iq = true;
end