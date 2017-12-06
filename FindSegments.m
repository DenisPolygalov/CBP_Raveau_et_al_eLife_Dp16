function [S] = FindSegments(X, thr_amp, thr_len)
% function [S] = FindSegments(X, thr_amp, thr_len)
%
% return M x 2 matrix of INDICES of COLUMN-vector X, where values of X 
% were above or equal than threshold value 'thr_amp' AND 
% longer or equal than 'thr_len' value. 'thr_len' must be specified 
% in number of elements of X (2,3,4, ... length(X) - 1)

% *  Copyright (C) 2012 Denis Polygalov,
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

% --- Written with a lot of help from George Fedorov ---

if ~isvector(X)
   error('FindSegments: X must be a vector');
end

if ~isreal(X)
   error('FindSegments: X must be a vector of real values');
end

if all(X <= thr_amp)
   error('FindSegments: amplitude threshold (thr_amp) is too high');
end

if all(X > thr_amp) % or maybe 'all(X >= thr_amp)' ??
   error('FindSegments: amplitude threshold (thr_amp) is too low');
end

thr_len = floor(thr_len);

if thr_len < 2
   error('FindSegments: length threshold (thr_len) is too short (less than 2)');
end

if thr_len > (length(X) - 1)
   error('FindSegments: length threshold (thr_len) is too long (longer than length(X) - 1)');
end

if isvector(X) && size(X,1) == 1 % row vector is given
   X = X';
   fprintf('FindSegments: row vector supplied as X. Check your code.\n');
end

% special case when thr_amp is exactly equal to min(x)
if all(X >= thr_amp)
   S = [1, length(X)];
   % TODO: assign additional values for return (if necessary)
   % <---
   % <---
   return;
end

% filter X by amplitude

% x1 = (X >= thr_amp); gives us sequence of ones and zeros.
% Ideally we need to find indices of all continues chunks of ones longer or
% equal than thr_len.
% In order to detect 0 -> 1 and 1 -> 0 transitions in x1 we using diff().
d_X = diff(X >= thr_amp);

% Unfortunately, a way of processing of the content of d_X depend on how
% x1 is begin and end, - from zero or from one.

if X(1) <= thr_amp && X(end) <= thr_amp    % 0 0 1 1 1 1 0 0
   begs = find(d_X > 0) + 1;
   ends = find(d_X < 0);
   %
elseif X(1) > thr_amp && X(end) > thr_amp  % 1 1 0 0 0 0 1 1
   begs = [1; find(d_X > 0) + 1];
   ends = [find(d_X < 0); length(X)];
   %
elseif X(1) > thr_amp && X(end) <= thr_amp % 1 1 0 1 1 0 0 0
   begs = [1; find(d_X > 0) + 1];
   ends = find(d_X < 0);
   %
elseif X(1) <= thr_amp && X(end) > thr_amp % 0 0 0 1 1 0 1 1
   begs = find(d_X > 0) + 1;
   ends = [find(d_X < 0); length(X)];
   %
else
   error('FindSegments: algorithm error (1)'); % should never happen
end

if length(begs) ~= length(ends)
   error('FindSegments: algorithm error (2)');
end

% filter segments by length (remove short segments)
d_I = (ends - begs + 1) >= thr_len;
S = [begs(d_I), ends(d_I)];
