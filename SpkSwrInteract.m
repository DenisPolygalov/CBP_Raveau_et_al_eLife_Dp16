function [ SPK_SWR ] = SpkSwrInteract( CELL_TS, SWR_TS, t_lag_usec )
% function [ SPK_SWR ] = SpkSwrInteract( CELL_TS, SWR_TS, t_lag_usec )
% Quantify "participation" of a cell(s) (single unit) in a SWR
% (sharp wave associated ripple(s)).
% Input:
% CELL_TS - Nx1 cell array of spike train timestamps (in usec).
% SWR_TS - Mx3 matrix of SWR (start, peak, end) timestamps.
% t_lag_usec - scalar, time lag (in usec) around center of a ripple.
% spikes felt within +/- t_lag_usec around center of every ripple will be
% used for "lfix" (fixed time lag) type of quantification.
% Output:
% SPK_SWR - structure.
% SPK_SWR.lfix_nspk_per_swr  % number of spikes per SWR per cell
% SPK_SWR.lfix_frate_per_swr % firing rate of this cell within SWR
% SPK_SWR.lfix_perc_particip % percent of SWRs this cell participated in
% SPK_SWR.lvar_nspk_per_swr  % number of spikes per SWR per cell
% SPK_SWR.lvar_frate_per_swr % firing rate of this cell within SWR
% SPK_SWR.lvar_perc_particip % percent of SWRs this cell participated in

% *  Copyright (C) 2014 Denis Polygalov,
% *  Lab for Circuit and Behavioral Physiology,
% *  RIKEN Brain Science Institute, Saitama, Japan.
% *
% *  This program is free software; you can redistribute it and/or modify
% *  it under the terms of the GNU General Public License as published by
% *  the Free Software Foundation; either version 3 of the License, or
% *  (at your option) any later version.
% *
% *  This program is distributed in the hope that it will be useful,
% *  but WITHOUT ANY WARRANTY; without even the implied warranty of
% *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% *  GNU General Public License for more details.
% *
% *  You should have received a copy of the GNU General Public License
% *  along with this program; if not, a copy is available at
% *  http://www.fsf.org/

if ~iscell(CELL_TS)
   error('SpkSwrInteract: CELL_TS must be a cell array');
end

if size(SWR_TS,2) ~= 3
   error('SpkSwrInteract: SWR_TS must be a Mx3 matrix');
end

SPK_SWR = struct();

num_cells = length(CELL_TS);
num_swr = size(SWR_TS,1);
t_swr_sec = (2*t_lag_usec)/1e6;

SWR_TS_CNT = SWR_TS(:,2); % center timestamps of ripples

SPK_SWR.t_lag_ms = t_lag_usec/1e3;

SPK_SWR.lfix_nspk_per_swr  = zeros(num_cells,1);
SPK_SWR.lfix_frate_per_swr = zeros(num_cells,1);
SPK_SWR.lfix_perc_particip = zeros(num_cells,1);

SPK_SWR.lvar_nspk_per_swr  = zeros(num_cells,1);
SPK_SWR.lvar_frate_per_swr = zeros(num_cells,1);
SPK_SWR.lvar_perc_particip = zeros(num_cells,1);

for cid = 1:num_cells
   
   lfix_num_spk_in_swr = 0;
   lfix_nswr_fired = 0;
   
   lvar_num_spk_in_swr = 0;
   lvar_nswr_fired = 0;
   
   cell_ts_train = CELL_TS{cid}; % one spike train from single cell
   
   for rid = 1:num_swr
      
      % fixed time lag
      ts1 = SWR_TS_CNT(rid) - t_lag_usec;
      ts2 = SWR_TS_CNT(rid) + t_lag_usec;
      tmp = find(cell_ts_train <= ts2 & cell_ts_train >= ts1);
      if ~isempty(tmp)
         lfix_num_spk_in_swr = lfix_num_spk_in_swr + numel(tmp);
         lfix_nswr_fired = lfix_nswr_fired + 1;
      end
      
      % variable time lag
      ts1 = SWR_TS(rid,1);
      ts2 = SWR_TS(rid,3);
      tmp = find(cell_ts_train <= ts2 & cell_ts_train >= ts1);
      if ~isempty(tmp)
         lvar_num_spk_in_swr = lvar_num_spk_in_swr + numel(tmp);
         lvar_nswr_fired = lvar_nswr_fired + 1;
      end
      
   end
   
   SPK_SWR.lfix_nspk_per_swr(cid)  = lfix_num_spk_in_swr/num_swr; % number of spikes per SWR per cell
   SPK_SWR.lfix_frate_per_swr(cid) = lfix_num_spk_in_swr/(num_swr * t_swr_sec); % firing rate of this cell within SWR
   SPK_SWR.lfix_perc_particip(cid) = 100 * (lfix_nswr_fired/num_swr); % percent of SWRs this cell participated in
   
   SPK_SWR.lvar_nspk_per_swr(cid)  = lvar_num_spk_in_swr/num_swr; % number of spikes per SWR per cell
   SPK_SWR.lvar_frate_per_swr(cid) = lvar_num_spk_in_swr/(num_swr * t_swr_sec); % firing rate of this cell within SWR
   SPK_SWR.lvar_perc_particip(cid) = 100 * (lvar_nswr_fired/num_swr); % percent of SWRs this cell participated in
   
end

end

