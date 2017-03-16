classdef resonatorReadout < qes.measurement.prob
    % measure state |1> probabilty, a resonator readout multiple qubits
    
% Copyright 2016 Yulin Wu, University of Science and Technology of China
% mail4ywu@gmail.com/mail4ywu@icloud.com
    
    properties
        n
        delay % syncDelay is add automatically, this is just a logical dely
        r_amp % expose qubit setting r_amp for tunning
        mw_src_power % expose qubit setting r_uSrcPower for tunning
        mw_src_frequency % expose qubit setting r_fc for tunning
    end
    properties (SetAccess = protected)
        qubits
		jpa
		adDelayStep
    end
    properties (SetAccess = private, GetAccess = protected)
        da
        da_i_chnl
        da_q_chnl
		mw_src
        setupRMWSrc = false;
		
		jpaBiasSrc
		jpaPumpMWSrc
        jpaPumpDA
% 		jpaPumpDAIChnl
% 		jpaPumpDAQChnl
        setupJPA = false;
		
		r_wv
		jpa_pump_wv
    end
    methods
        function obj = resonatorReadout(qubits)
            if ~iscell(qubits)
                if ~ischar(qubits) && ~isa(qubits,'sqc.qobj.qubit')
                    throw(MException('resonatorReadout:invalidInput',...
						'the input qubits should be a cell array of qubit objects or qubit names.'));
                else
                    qubits = {qubits};
                end
            end
			for ii = 1:numel(qubits)
				if ischar(qubits{ii})
					qubits{ii} = sqc.util.qName2Qubit(qubits{ii});
				end
			end
            prop_names = {'syncDelay_r','r_avg','syncDelay_z','r_fc','r_ln','r_truncatePts','r_uSrcPower',...
                {'channels','r_da_i','instru'},{'channels','r_da_q','instru'},...
                {'channels','r_da_i','chnl'},{'channels','r_da_q','chnl'},...
                {'channels','r_ad_i','instru'},{'channels','r_ad_q','instru'},...
                {'channels','r_ad_i','chnl'},{'channels','r_ad_q','chnl'},...
                {'channels','r_mw','instru'},{'channels','r_mw','chnl'},...
                'r_jpa'};
            b = sqc.util.samePropVal(qubits,prop_names);
            for ii = 1:numel(prop_names)
                if b(ii)
                    continue;
                end
				if iscell(prop_names{ii})
					str = cell2mat(cellfun(@(s_)strcat(s_,'.'),prop_names{ii}, 'UniformOutput', false));
					str(end) = [];
					throw(MException('resonatorReadout:settingsMismatch',...
						'the qubits to readout has different %s setting.',str));
				else
					throw(MException('resonatorReadout:settingsMismatch',...
						'the qubits to readout has different %s setting.',prop_names{ii}));
				end
            end
            
            num_qubits = numel(qubits);
%             da_i_names = {};
%             for ii = 1:num_qubits
%                 da_i_names{end+1} = qubits{ii}.channels.r_da_i.instru;
%             end
%             da_i_names = unique(da_i_names);
%             if numel(da_i_names) > 1
%                 throw(MException('resonatorReadout:daMismatch',...
% 					'the qubits to readout has different DAs for I channel.'));
%             end
%             da_q_names = {};
%             for ii = 1:num_qubits
%                 da_q_names{end+1} = qubits{ii}.channels.r_da_q.instru;
%             end
%             da_q_names = unique(da_q_names);
%             if numel(da_q_names) > 1
%                 throw(MException('resonatorReadout:daMismatch',...
% 					'the qubits to readout has different DAs for Q channel.'));
%             end
%             if ~strcmp(da_q_names{1},da_i_names{1})
%                 throw(MException('resonatorReadout:daMismatch',...
% 					'can not output I and Q on different awgs.'));
%             end

            da_i_names = qubits{1}.channels.r_da_i.instru;
            da_q_names = qubits{1}.channels.r_da_q.instru;
            if ~strcmp(da_q_names,da_i_names)
                throw(MException('resonatorReadout:daMismatch',...
					'can not output I and Q on different awgs.'));
            end
            
%             da_i_chnls = [];
%             for ii = 1:num_qubits
%                 da_i_chnls(end+1) = qubits{ii}.channels.r_da_i.chnl;
%             end
%             da_i_chnls = unique(da_i_chnls);
%             if numel(da_i_chnls) > 1
%                 throw(MException('resonatorReadout:daChannelMismatch',...
% 					'the qubits to readout has different DA channels for I channel.'));
%             end
%             da_q_chnls = [];
%             for ii = 1:num_qubits
%                 da_q_chnls(end+1) = qubits{ii}.channels.r_da_q.chnl;
%             end
%             da_q_chnls = unique(da_q_chnls);
%             if numel(da_q_chnls) > 1
%                 throw(MException('resonatorReadout:daChannelMismatch',...
% 					'the qubits to readout has different DA channels for Q channel.'));
%             end

            da_i_chnls = qubits{1}.channels.r_da_i.chnl;
            da_q_chnls = qubits{1}.channels.r_da_q.chnl;
            if da_i_chnls == da_q_chnls
                throw(MException('resonatorReadout:daChnlSettingError',...
					'can not output I and Q on the same channel.'));
            end
            
%             ad_i_names = {};
%             for ii = 1:num_qubits
%                 ad_i_names{end+1} = qubits{ii}.channels.r_ad_i.instru;
%             end
%             ad_i_names = unique(ad_i_names);
%             if numel(ad_i_names) > 1
%                 throw(MException('resonatorReadout:adMismatch',...
% 					'the qubits to readout has different ADs for I channel.'));
%             end
%             ad_q_names = {};
%             for ii = 1:num_qubits
%                 ad_q_names{end+1} = qubits{ii}.channels.r_ad_q.instru;
%             end
%             ad_q_names = unique(ad_q_names);
%             if numel(ad_q_names) > 1
%                 throw(MException('resonatorReadout:adMismatch',...
% 					'the qubits to readout has different ADs for Q channel.'));
%             end
%             if ~strcmp(ad_q_names{1},ad_i_names{1})
%                 throw(MException('resonatorReadout:adMismatch',...
% 					'can not digitize I and Q on different ADs.'));
%             end

            ad_i_names = qubits{1}.channels.r_ad_i.instru;
            ad_q_names = qubits{1}.channels.r_ad_q.instru;
            if ~strcmp(ad_q_names,ad_i_names)
                throw(MException('resonatorReadout:adMismatch',...
					'can not digitize I and Q on different ADs.'));
            end
             
%             ad_i_chnls = [];
%             for ii = 1:num_qubits
%                 ad_i_chnls(end+1) = qubits{ii}.channels.r_ad_i.chnl;
%             end
%             ad_i_chnls = unique(ad_i_chnls);
%             if numel(ad_i_chnls) > 1
%                 throw(MException('resonatorReadout:daChannelMismatch',...
% 					'the qubits to readout has different AD channels for I channel.'));
%             end
%             ad_q_chnls = [];
%             for ii = 1:num_qubits
%                 ad_q_chnls(end+1) = qubits{ii}.channels.r_ad_q.chnl;
%             end
%             ad_q_chnls = unique(ad_q_chnls);
%             if numel(ad_q_chnls) > 1
%                 throw(MException('resonatorReadout:daChannelMismatch',...
% 					'the qubits to readout has different AD channels for Q channel.'));
%             end

            ad_i_chnls = qubits{1}.channels.r_ad_i.chnl;
            ad_q_chnls = qubits{1}.channels.r_ad_q.chnl;
            if ad_i_chnls == ad_q_chnls
                throw(MException('resonatorReadout:adChnlSettingError',...
					'can not digitize I and Q with the same channel.'));
            end
            
            ad = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',ad_i_names);
            da = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',da_i_names);
            rs = ad.samplingRate/da.samplingRate;
            ad.recordLength = ceil(rs*qubits{1}.r_ln);
            iq_obj = sqc.measure.iq_ustc_ad(ad);
            iq_obj.n = qubits{1}.r_avg;
            num_qubits = numel(qubits);
            demod_freq = zeros(1,num_qubits);
            for ii = 1:num_qubits
                demod_freq(ii) = qubits{ii}.r_freq- qubits{1}.r_fc;
            end
            iq_obj.freq = demod_freq;
            iq_obj.startidx = qubits{1}.r_truncatePts(1)+1;
            iq_obj.endidx = ad.recordLength-qubits{1}.r_truncatePts(2);
            prob_obj = sqc.measure.prob_iq_ustc_ad_j(iq_obj);
            prob_obj.qubits = qubits;
            obj = obj@qes.measurement.prob(prob_obj);
            obj.n = prob_obj.n;
            obj.qubits = qubits;

%           mw_src_name = qubits{1}.channels.r_mw.instru;
% 			mw_src_chnl = obj.qubits{1}.channels.r_mw.chnl;
%             for ii = 2:num_qubits
%                 if ~strcmp(obj.qubits{ii}.channels.r_mw.instru, mw_src_name) ||...
% 					obj.qubits{ii}.channels.r_mw.chnl ~= mw_src_chnl
%                     throw(MException('resonatorReadout:settingsMismatch',...
% 						'the qubits to readout has different mw sources/channel.'));
%                 end
%             end
% 			uSrc = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',mw_src_name);

			uSrc = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',qubits{1}.channels.r_mw.instru);
            obj.mw_src = uSrc.GetChnl(qubits{1}.channels.r_mw.chnl);
            obj.mw_src_power = qubits{1}.r_uSrcPower;
            obj.mw_src_frequency = qubits{1}.r_fc;
            obj.da = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',da_i_names);
            obj.da_i_chnl = da_i_chnls;
            obj.da_q_chnl = da_q_chnls;
            r_amp_ = zeros(1,num_qubits);
            for ii = 1:num_qubits
                r_amp_(ii) = obj.qubits{ii}.r_amp;
            end
            obj.r_amp = r_amp_;
            obj.adDelayStep = ad.delayStep;

            if ~isempty(qubits{1}.r_jpa)
				prop_names = {'r_jpa_biasAmp','r_jpa_pumpFreq','r_jpa_pumpPower','r_jpa_pumpAmp','r_jpa_longer'};
				b = sqc.util.samePropVal(qubits,prop_names);
				for ii = 1:numel(prop_names)
					if b(ii)
						continue;
					end
					throw(MException('resonatorReadout:settingsMismatch',...
						'the qubits to readout has different %s settings.',prop_names{ii}));
                end
                obj.jpa = sqc.util.qName2Obj(qubits{1}.r_jpa);
				obj.jpa.opDuration = qubits{1}.r_ln + 2*qubits{1}.r_jpa_longer;
                
                biasSrc = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',obj.jpa.channels.bias.instru);
                obj.jpaBiasSrc = biasSrc.GetChnl(obj.jpa.channels.bias.chnl);
                pumpMWSrc = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',obj.jpa.channels.pump_mw.instru);
                obj.jpaPumpMWSrc = pumpMWSrc.GetChnl(obj.jpa.channels.pump_mw.chnl);
                if ~strcmp(obj.jpa.channels.pump_i.instru,obj.jpa.channels.pump_q.instru)
                    throw(MException('resonatorReadout:daMismatch',...
                        'can not output I and Q on different DACs.'));
                end
                obj.jpaPumpDA = qes.qHandle.FindByClassProp('qes.hwdriver.hardware','name',obj.jpa.channels.pump_i.instru);
                if obj.jpa.channels.pump_i.chnl == obj.jpa.channels.pump_q.chnl
                    throw(MException('resonatorReadout:daChnlSettingError',...
                        'can not output I and Q on the same channel.'));
                end
                obj.jpa.pumpAmp = qubits{1}.r_jpa_pumpAmp;
				obj.jpa.pumpFreq = qubits{1}.r_jpa_pumpFreq;
				obj.jpa.pumpPower = qubits{1}.r_jpa_pumpPower;
				obj.jpa.biasAmp = qubits{1}.r_jpa_biasAmp;
				
                obj.setupJPA = true;
                obj.numericscalardata = false;
            end
            
            obj.delay = 0;
        end
        function set.qubits(obj,val)
            if ~iscell(val)
                val = {val};
            end
            for ii = 1:numel(val)
                if ~isa(val{ii},'sqc.qobj.qubit')
                    throw(MException('resonatorReadout:invalidInput',...
						'at least one of qubits is not a sqc.qobj.qubit class object.'));
                end
            end
            obj.qubits = val;
        end
        function set.mw_src_power(obj,val)
            if numel(val) ~= numel(obj.mw_src)
                throw(MException('resonatorReadout:invalidInput',...
					'size of mw_src_power not matching the numbers of mw_src.'));
            end
            obj.mw_src_power = val;
            obj.setupRMWSrc = true;
        end
        function set.mw_src_frequency(obj,val)
            if numel(val) ~= numel(obj.mw_src)
                throw(MException('resonatorReadout:invalidInput',...
					'size of mw_src_frequency not matching the numbers of mw_src.'));
            end
            obj.mw_src_frequency = val;
            obj.setupRMWSrc = true;
        end
        function set.r_amp(obj,val)
            if numel(val) ~= numel(obj.qubits)
                throw(MException('resonatorReadout:invalidInput',...
					'size of r_amp not matching the numbers of qubits.'));
            end
            obj.r_amp = val;
        end
		function set.delay(obj,val)
            % as the awg only knows the da output delay step, thus here it is necessary to ceil the 
            % readout waveform output delay to a multiple of adDelayStep
			obj.delay = obj.adDelayStep*ceil((val)/obj.adDelayStep);
            if ~isempty(obj.qubits{1}.r_jpa)
                obj.jpa.startDelay = obj.delay-obj.qubits{1}.r_jpa_longer;
            end
		end
        function Run(obj)
            obj.GenWave();
            obj.Prep();
			obj.r_wv.awg.SetTrigOutDelay(obj.r_wv.awgchnl,obj.delay);
            obj.r_wv.SendWave();
            if ~isempty(obj.jpa)
                obj.jpa_pump_wv.SendWave();
            end
            obj.data = obj.instrumentObject();
            obj.extradata = obj.instrumentObject.extradata;
            obj.dataready = true;
        end
    end
    methods (Access = private)
        function GenWave(obj)
            num_qubits = numel(obj.qubits);
			for ii = 1:num_qubits
                wv_{ii} = feval(['sqc.wv.',obj.qubits{ii}.r_wvTyp],obj.qubits{ii}.r_ln);
                wvSettings = obj.qubits{ii}.r_wvSettings;
                if ~isempty(wvSettings)
                    fnames = fieldnames(wvSettings);
                    for jj = 1:numel(fnames)
                        wv_{ii}.(fnames{jj}) = wvSettings.(fnames{jj});
                    end
                end
                wv_{ii}.amp = obj.r_amp(ii);
                % here iq is delibrately set to true because even if df = 0
                % we need the waveform to be an iq waveform
                wv_{ii}.iq = true;
                wv_{ii}.df = (obj.qubits{ii}.r_freq - obj.qubits{ii}.r_fc)/obj.da.samplingRate;
            end
            obj.r_wv = wv_{1};
            for ii = 2:num_qubits
                obj.r_wv = obj.r_wv + wv_{ii};
            end
            obj.r_wv.awg = obj.da;
            obj.r_wv.awgchnl = [obj.da_i_chnl,obj.da_q_chnl];
            obj.r_wv.hw_delay = true; % important
            obj.r_wv.output_delay = obj.delay+obj.qubits{1}.syncDelay_r; % syncDelay_z is added as a small calibration.
			
			if ~isempty(obj.qubits{1}.r_jpa)
				obj.jpa_pump_wv = sqc.wv.rect_cos(obj.jpa.opDuration);
				obj.jpa_pump_wv.amp = obj.jpa.pumpAmp;
				obj.jpa_pump_wv.awg = obj.jpaPumpDA;
                obj.jpa_pump_wv.iq = true;
				obj.jpa_pump_wv.awgchnl = [obj.jpa.channels.pump_i.chnl,obj.jpa.channels.pump_q.chnl];
				obj.jpa_pump_wv.hw_delay = true; % important
                % syncDelay_pump is added as a small calibration to compensate hardware imperfection while startDelay is a logical delay.
				obj.jpa_pump_wv.output_delay = max(0,obj.jpa.startDelay+obj.jpa.syncDelay_pump);
            end
        end

        function Prep(obj)
            % do necessary preparations before run
            if obj.setupRMWSrc
                obj.mw_src.power = obj.mw_src_power;
                obj.mw_src.frequency = obj.mw_src_frequency;
                obj.mw_src.on = true;
                obj.setupRMWSrc = false;
            end
            if obj.setupJPA
				obj.jpaBiasSrc.dcval = obj.jpa.biasAmp;
				obj.jpaBiasSrc.on = true;
				obj.jpaPumpMWSrc.frequency = obj.jpa.pumpFreq;
				obj.jpaPumpMWSrc.power = obj.jpa.pumpPower;
				obj.jpaPumpMWSrc.on = true;
                obj.setupJPA = false;
            end
        end
    end
end