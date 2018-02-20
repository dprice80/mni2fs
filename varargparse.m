function out = varargparse(args, params, defaults)

expected = params;

% Ensure we have a matching number of params and values.
if mod(length(args),2) ~= 0
  error('Invalid param-value arguments.');
end

% Extract provided params (odd elements) and values (even elements)
params   = args(1:2:end);
values   = args(2:2:end);

% For each expected param, either pop it from the provided params or set it to
% its default value.
for i=1:length(expected);
  key = expected{i};
  if ismember(key, params)
    j = find(strcmpi(key, params));
    out.(key) = values{j};
    params(j) = [];
    values(j) = [];
  else
    out.(key) = defaults{i};
  end
end

% Any additional param-value pairs are invalid.
if ~isempty(params)
  error(['Invalid param(s): ', params{:}]);
end

end % of varargparse