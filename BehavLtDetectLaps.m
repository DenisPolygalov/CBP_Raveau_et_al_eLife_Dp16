function [ LAPS ] = BehavLtDetectLaps( TSusec, Xcm, x_min, x_max, ...
   t_min_sec, max_ret, max_vel_cmsec, pic_fname)
% function [ LAPS ] = BehavLtDetectLaps( TSusec, Xcm, x_min, x_max, ...
%    t_min_sec, max_ret, max_vel_cmsec, pic_fname)
% 
% This function is useful for 'linear track' type of experiments only.
% It takes 1 dimentional vector of animal's position values (Xcm) and 
% correspondent vector of timestamps (TSusec) and detect 'LAPS' - time 
% periods when animal was actually running along the track - i.e. excluding
% time spent in either side box and/or incomplete travels between boxes.
% 
% Input parameters:
% TSusec, - Nx1 vector of timestamps in MICROSECONDS (camera timestamps)
% Xcm, - Nx1 vector of animal's position in CENTIMETERS.
% 
% x_min, x_max - scalar values in units of Xcm correspond to locatons
% of transition between start/stop of the track and left/right boxes.
% 
% t_min_sec, - scalar value, minimal time the animal must spend in each
% side box for current travel to be accepted as complete lap.
% 
% max_ret - scalar value 0 ~ 1.0 (in theory) or 0.05 ~ 0.25 (practically)
% correspond to proportion of "returns" allowed within each lap. 
% If portion of "returns" exceed max_ret value then the whole lap will be
% excluded from output.
% 
% max_vel_cmsec - scalar value, maximal velocity of the animal. This used
% for removing artifacts that look like laps but have too short duration
% 
% pic_fname - string, filename for optional picture of path and detected
% laps. Use empty string '' if you don't want these pictires to be
% generated.
% 
% *** WARNING ***
% 1. THIS FUNCTION MAY FAIL DUE TO HIGH UNCERTAINTY OF BEHAVIOUR DATA, SO
% CHECK AND PREPARE YOUR BEHAVIOUR DATA BEFORE USING WITH THIS FUNCTION.
% 2. THIS FUNCTION DOES NOT "PAIR" LAPS IN ANY WAY.
% 3. ALWAYS CHECK THE QUALITY OF THE OUTPUT LAP DETECTION.

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

if ~isvector(TSusec)
   error('BehavDetectLaps: TSusec must be a column vector');
end

if ~isvector(Xcm)
   error('BehavDetectLaps: Xcm must be a column vector');
end

if numel(TSusec) ~= numel(Xcm)
   error('BehavDetectLaps: TSusec and Xcm must be the same size');
end

L_decents = cell(1,1);
ld_cnt = 0;
R_decents = cell(1,1);
rd_cnt = 0;

dt_sec = mean(diff(TSusec/1e6));

S1 = FindSegments(Xcm, x_max, int32(t_min_sec/dt_sec));

if isempty(S1)
   error('BehavDetectLaps: unable to detect any laps-like data');
end

nseg = size(S1,1);
nxi = abs(ceil((x_max - x_min)/5)); % number of 5cm chunks

% First stage of filtering.
for si = 1:nseg
   
   if si == 1
      l_wall = 1;
   else
      l_wall = S1(si-1,2);
   end
   if si == nseg
      r_wall = numel(Xcm);
   else
      r_wall = S1(si+1,1);
   end
   
   ii = S1(si,1);
   while(1)
      if Xcm(ii) <= x_min
         ld_cnt = ld_cnt + 1;
         L_decents{ld_cnt,1} = [ ii, S1(si,1) ];
         break;
      end
      ii = ii - 1;
      if ii <= l_wall, break; end
   end
   
   ii = S1(si,2);
   while(1)
      if Xcm(ii) <= x_min
         rd_cnt = rd_cnt + 1;
         R_decents{rd_cnt,1} = [ S1(si,2), ii ];
         break;
      end
      ii = ii + 1;
      if ii >= r_wall, break; end
   end
   
end

% Second stage of filtering. 
% Try to detect "turn back" events within each lap
% and remove such laps from L_decents R_decents
L_decents_2 = cell(1,1);
ld_cnt_2 = 1;
R_decents_2 = cell(1,1);
rd_cnt_2 = 1;

if ~isempty(L_decents)
   for ii = 1:length(L_decents)
      % ideally lap_data should contain monotonically INcreasing data only
      lap_data = Xcm(L_decents{ii,1}(1,1):L_decents{ii,1}(1,2));
      xi = linspace(1, numel(lap_data), nxi);
      yi = interp1(1:numel(lap_data), lap_data, xi);
      [lap_xmax, lap_imax, lap_xmin, ~] = extrema(yi);
      if numel(lap_imax) == 1                        % strictly INcreasing
         L_decents_2{ld_cnt_2,1} = L_decents{ii};
         ld_cnt_2 = ld_cnt_2 + 1;
      else                                           % have bumps
         if numel(lap_xmax) < numel(lap_xmin)
            lap_xmin = lap_xmin(1:numel(lap_xmax));
         end
         if numel(lap_xmax) > numel(lap_xmin)
            lap_xmax = lap_xmax(1:numel(lap_xmin));
         end
         lap_dec = lap_xmax - lap_xmin;
         if sum(lap_dec(2:end))/lap_dec(1) < max_ret
            L_decents_2{ld_cnt_2,1} = L_decents{ii};
            ld_cnt_2 = ld_cnt_2 + 1;
         end
      end
   end
end

if ~isempty(R_decents)
   for ii = 1:length(R_decents)
      % ideally lap_data should contain monotonically DEcreasing data only
      lap_data = Xcm(R_decents{ii,1}(1,1):R_decents{ii,1}(1,2));
      xi = linspace(1, numel(lap_data), nxi);
      yi = interp1(1:numel(lap_data), lap_data, xi);
      [lap_xmax, lap_imax, lap_xmin, ~] = extrema(yi);
      if numel(lap_imax) == 1                        % strictly DEcreasing
         R_decents_2{rd_cnt_2,1} = R_decents{ii};
         rd_cnt_2 = rd_cnt_2 + 1;
      else                                           % have bumps
         if numel(lap_xmax) < numel(lap_xmin)
            lap_xmin = lap_xmin(1:numel(lap_xmax));
         end
         if numel(lap_xmax) > numel(lap_xmin)
            lap_xmax = lap_xmax(1:numel(lap_xmin));
         end
         lap_dec = lap_xmax - lap_xmin;
         if sum(lap_dec(2:end))/lap_dec(1) < max_ret
            R_decents_2{rd_cnt_2,1} = R_decents{ii};
            rd_cnt_2 = rd_cnt_2 + 1;
         end
      end
   end
end

% Third stage of filtering.
% Try to detect unrealistically short (in terms of time) laps.
min_lap_dur_sec = (x_max - x_min) / max_vel_cmsec;

L_decents_3 = cell(1,1);
ld_cnt_3 = 1;
R_decents_3 = cell(1,1);
rd_cnt_3 = 1;

if ~isempty(L_decents_2)
   lap_ts_idx = cell2mat(L_decents_2);
   lap_dts_sec = ( TSusec(lap_ts_idx(:,2)) - TSusec(lap_ts_idx(:,1)) ) / 1e6;
   for ii = 1:length(L_decents_2)
      if lap_dts_sec(ii) >= min_lap_dur_sec
         L_decents_3{ld_cnt_3,1} = L_decents_2{ii};
         ld_cnt_3 = ld_cnt_3 + 1;
      end
   end
end

if ~isempty(R_decents_2)
   lap_ts_idx = cell2mat(R_decents_2);
   lap_dts_sec = ( TSusec(lap_ts_idx(:,2)) - TSusec(lap_ts_idx(:,1)) ) / 1e6;
   for ii = 1:length(R_decents_2)
      if lap_dts_sec(ii) >= min_lap_dur_sec
         R_decents_3{rd_cnt_3,1} = R_decents_2{ii};
         rd_cnt_3 = rd_cnt_3 + 1;
      end
   end
end

L_decents = L_decents_3;
R_decents = R_decents_3;

% plot picture if requested
if ~isempty(pic_fname)
   
   TS = (TSusec-TSusec(1))/(1e6*60); % convert to relative minutes
   
   hfig = figure('visible','off');
   hax = subplot(1,1,1);
   
   set(hfig, 'CurrentAxes', hax);
   cla(hax, 'reset');
   
   plot(hax, TS, Xcm, 'm');
   hold(hax, 'on');
   
   if ~isempty(L_decents{1})
      for ll = 1:length(L_decents)
         plot(hax, TS( L_decents{ll}(1):L_decents{ll}(2) ), ...
                  Xcm( L_decents{ll}(1):L_decents{ll}(2) ), 'r', 'LineWidth', 2 );
      end
   end
   
   if ~isempty(R_decents{1})
      for rr = 1:length(R_decents)
         plot(hax, TS( R_decents{rr}(1):R_decents{rr}(2) ), ...
                  Xcm( R_decents{rr}(1):R_decents{rr}(2) ), 'k', 'LineWidth', 2 );
      end
   end
   
   xlabel(hax, 'Time, min');
   ylabel(hax, 'X coordinate, cm');
   axis(hax, 'tight');
   set(gcf, 'paperunits', 'centimeters'); % 16 x 8 cm 
   set(gcf, 'papersize', [16, 8]);
   set(gcf, 'paperposition', [0, 0, 16, 8]);
   print('-djpeg', '-r600', pic_fname);
end

% prepare results

LAPS = struct();

LAPS.Lidx = cell2mat(L_decents);
LAPS.Lts = TSusec(LAPS.Lidx);

LAPS.Ridx = cell2mat(R_decents);
LAPS.Rts = TSusec(LAPS.Ridx);

% handle special case of single lap.

if isequal(size(LAPS.Lidx),[2 1])
   LAPS.Lidx = transpose(LAPS.Lidx);
end

if isequal(size(LAPS.Ridx),[2 1])
   LAPS.Ridx = transpose(LAPS.Ridx);
end

if isequal(size(LAPS.Lts),[2 1])
   LAPS.Lts = transpose(LAPS.Lts);
end

if isequal(size(LAPS.Rts),[2 1])
   LAPS.Rts = transpose(LAPS.Rts);
end


end

