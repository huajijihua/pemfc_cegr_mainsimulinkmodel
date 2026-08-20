function preflight = routeA_focused_preflight(model, paths, defaults, cfg, inputs, bridges)
% Validate the focused runner/model contract before any simulation starts.
%
% This is a workflow gate, not a physical validation claim. It verifies the
% active model asset, active cEGR variant, declared SimulationInput writes,
% model-parameter settings, and the live model consumers of critical gas
% boundary variables. The formal runner records the returned evidence in the
% study MAT file.

preflight = struct( ...
    'schemaVersion', "RouteA_Focused_Preflight_v01", ...
    'status', "not_checked", ...
    'passed', false, ...
    'model', string(model), ...
    'modelFile', string(paths.modelFile), ...
    'runner', "run_routeA_focused_study", ...
    'runnerFile', string(which('run_routeA_focused_study')), ...
    'modelChecksum', uint32([]), ...
    'activeVariant', struct(), ...
    'parameterConsumers', struct([]), ...
    'simulationInput', struct(), ...
    'bridge', struct(), ...
    'resultContract', struct(), ...
    'failureReasons', strings(0, 1));

reasons = strings(0, 1);
if ~bdIsLoaded(char(model))
    reasons(end + 1, 1) = "model_not_loaded";
end
if ~isfile(char(paths.modelFile))
    reasons(end + 1, 1) = "model_file_missing";
end
if strlength(preflight.runnerFile) == 0 || ...
        ~isfile(char(preflight.runnerFile))
    reasons(end + 1, 1) = "formal_runner_not_resolved";
end
if string(defaults.modelId) ~= string(cfg.modelId)
    reasons(end + 1, 1) = "model_id_mismatch";
end

if bdIsLoaded(char(model))
    preflight.modelChecksum = checksumWithoutSimscapeLogging(char(model));
    mw = get_param(char(model), 'ModelWorkspace');
    variant = variantEvidence(mw);
    preflight.activeVariant = variant;
    if ~variant.present || variant.value ~= 1
        reasons(end + 1, 1) = "active_cegr_variant_is_not_open_mode";
    end
    preflight.parameterConsumers = consumerEvidence(char(model));
    consumerPresent = [preflight.parameterConsumers.present];
    if any(~consumerPresent)
        reasons(end + 1, 1) = "critical_parameter_consumer_missing";
    end
end

preflight.bridge = bridgeEvidence(bridges);
if ~preflight.bridge.present || preflight.bridge.writePointCount == 0
    reasons(end + 1, 1) = "focused_parameter_bridge_missing";
end

preflight.simulationInput = simulationInputEvidence(inputs, cfg, ...
    preflight.bridge.modelWritePoints);
if ~preflight.simulationInput.present
    reasons(end + 1, 1) = "simulation_input_not_prepared";
end
if ~isempty(preflight.simulationInput.missingBridgeWrites)
    reasons(end + 1, 1) = "simulation_input_bridge_write_missing";
end
if ~isempty(preflight.simulationInput.missingModelParameters)
    reasons(end + 1, 1) = "simulation_input_model_parameter_missing";
end
if ~preflight.simulationInput.loadInitialStateOff
    reasons(end + 1, 1) = "cold_start_contract_not_applied";
end
if ~preflight.simulationInput.stopTimeMatches
    reasons(end + 1, 1) = "simulation_stop_time_mismatch";
end
if ~preflight.simulationInput.solverMatches
    reasons(end + 1, 1) = "simulation_solver_mismatch";
end

preflight.resultContract = resultEvidence(cfg);
if ~preflight.resultContract.pathReady
    reasons(end + 1, 1) = "result_directory_not_ready";
end
if preflight.resultContract.caseCount ~= numel(cfg.cases)
    reasons(end + 1, 1) = "case_count_contract_mismatch";
end

preflight.failureReasons = unique(reasons, 'stable');
preflight.passed = isempty(preflight.failureReasons);
if preflight.passed
    preflight.status = "passed_workflow_gate";
else
    preflight.status = "blocked_before_simulation";
end
end

function value = checksumWithoutSimscapeLogging(model)
originalLogType = get_param(model, 'SimscapeLogType');
wasDirty = strcmp(get_param(model, 'Dirty'), 'on');
cleanup = onCleanup(@() restoreState(model, originalLogType, wasDirty)); %#ok<NASGU>
set_param(model, 'SimscapeLogType', 'none');
value = Simulink.BlockDiagram.getChecksum(model);
end

function restoreState(model, logType, wasDirty)
set_param(model, 'SimscapeLogType', logType);
if ~wasDirty
    set_param(model, 'Dirty', 'off');
end
end

function value = variantEvidence(modelWorkspace)
value = struct('name', "routeA_cegr_valve_mode_id", ...
    'present', false, 'value', NaN, 'expectedOpenValue', 1, ...
    'status', "missing");
if ~hasVariable(modelWorkspace, char(value.name))
    return;
end
value.present = true;
value.value = double(modelWorkspace.getVariable(char(value.name)));
if value.value == value.expectedOpenValue
    value.status = "open_active";
else
    value.status = "non_open_active";
end
end

function values = consumerEvidence(model)
names = ["routeA_cegr_valve_mode_id"; ...
    "focused_cathode_inlet_temperature_C"; "env_T"; "env_p"; ...
    "env_yO2"; "env_yH20"];
values = repmat(struct('name', "", 'present', false, 'users', strings(0, 1)), ...
    numel(names), 1);
vars = Simulink.findVars(model, 'SearchReferencedModels', 'on');
for idx = 1:numel(names)
    values(idx).name = names(idx);
    matches = find(string({vars.Name}) == names(idx));
    if isempty(matches)
        continue;
    end
    users = strings(0, 1);
    for matchIndex = matches(:).'
        users = [users; string(vars(matchIndex).Users(:))]; %#ok<AGROW>
    end
    values(idx).users = unique(users, 'stable');
    values(idx).present = ~isempty(values(idx).users);
end
end

function value = bridgeEvidence(bridges)
value = struct('present', false, 'caseCount', 0, 'writePointCount', 0, ...
    'modelWritePoints', strings(0, 1), 'statusValues', strings(0, 1), ...
    'compatibilityOnlyCount', 0);
indices = find(~cellfun(@isempty, bridges));
if isempty(indices)
    return;
end
value.present = true;
value.caseCount = numel(indices);
allPoints = strings(0, 1);
statusValues = strings(0, 1);
compatibilityOnlyCount = 0;
for idx = indices(:).'
    bridge = bridges{idx};
    if isfield(bridge, 'modelWritePoints')
        allPoints = [allPoints; string(bridge.modelWritePoints(:))]; %#ok<AGROW>
    end
    if isfield(bridge, 'mapping') && isstruct(bridge.mapping)
        statuses = string({bridge.mapping.status}).';
        statusValues = [statusValues; statuses]; %#ok<AGROW>
        compatibilityOnlyCount = compatibilityOnlyCount + sum( ...
            statuses == "not_applicable");
    end
end
value.modelWritePoints = unique(allPoints, 'stable');
value.writePointCount = numel(value.modelWritePoints);
value.statusValues = unique(statusValues, 'stable');
value.compatibilityOnlyCount = compatibilityOnlyCount;
end

function value = simulationInputEvidence(inputs, cfg, bridgePoints)
requiredModelParameters = ["StopTime"; "Solver"; "SolverType"; "RelTol"; ...
    "AbsTol"; "MaxStep"; "LoadInitialState"; "SignalLogging"; ...
    "SignalLoggingName"; "ReturnWorkspaceOutputs"; "SimscapeLogType"];
value = struct('present', false, 'caseCount', 0, ...
    'variableNames', strings(0, 1), 'modelParameterNames', strings(0, 1), ...
    'blockParameterNames', strings(0, 1), ...
    'missingBridgeWrites', bridgePoints, ...
    'missingModelParameters', requiredModelParameters, ...
    'loadInitialStateOff', false, 'stopTimeMatches', false, ...
    'solverMatches', false, 'loggingContract', false);
indices = find(~cellfun(@isempty, inputs));
if isempty(indices)
    return;
end
in = inputs{indices(1)};
value.present = true;
value.caseCount = numel(indices);
value.variableNames = entryNames(in.Variables, 'Name');
value.modelParameterNames = entryNames(in.ModelParameters, 'Name');
value.blockParameterNames = entryNames(in.BlockParameters, 'BlockPath');
value.missingBridgeWrites = setdiff(bridgePoints, value.variableNames, 'stable');
value.missingModelParameters = setdiff(requiredModelParameters, ...
    value.modelParameterNames, 'stable');
loadState = entryValue(in.ModelParameters, 'LoadInitialState');
stopTime = entryValue(in.ModelParameters, 'StopTime');
solver = entryValue(in.ModelParameters, 'Solver');
signalLogging = entryValue(in.ModelParameters, 'SignalLogging');
signalLoggingName = entryValue(in.ModelParameters, 'SignalLoggingName');
value.loadInitialStateOff = strcmpi(string(loadState), "off");
value.stopTimeMatches = numericTextMatches(stopTime, cfg.researchDuration_s);
value.solverMatches = strcmpi(string(solver), string(cfg.solver));
value.loggingContract = strcmpi(string(signalLogging), "on") && ...
    strcmp(string(signalLoggingName), "logsout");
end

function names = entryNames(entries, fieldName)
names = strings(0, 1);
if isempty(entries)
    return;
end
try
    names = string({entries.(fieldName)}).';
catch
    names = strings(0, 1);
end
end

function value = entryValue(entries, name)
value = "";
if isempty(entries)
    return;
end
index = find(string({entries.Name}) == string(name), 1);
if isempty(index)
    return;
end
try
    value = entries(index).Value;
catch
    value = "";
end
end

function passed = numericTextMatches(value, expected)
number = str2double(string(value));
passed = isfinite(number) && abs(number - double(expected)) <= ...
    max(1e-9, 1e-9 * abs(double(expected)));
end

function value = resultEvidence(cfg)
resultDirectory = fileparts(char(cfg.resultFile));
if strlength(string(resultDirectory)) > 0 && ~isfolder(resultDirectory)
    mkdir(resultDirectory);
end
value = struct('path', string(cfg.resultFile), ...
    'directory', string(resultDirectory), 'pathReady', ...
    strlength(string(cfg.resultFile)) > 0 && isfolder(resultDirectory), ...
    'caseCount', numel(cfg.cases), ...
    'overwritePolicy', "new_validation_directory_only");
end
